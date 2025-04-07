public with sharing class RentalCancellationController {
   
    @AuraEnabled(cacheable=true)
    public static List<Rental__c> getUserRentals() {
        try {
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (currentUser.ContactId == null) {
                throw new AuraHandledException('No associated Contact found for this user.');
            }
            return [SELECT Id, Name, Car_Relation__r.Name, Start_Date__c, End_Date__c, Rental_Status__c,
                    Car_Relation__c, Actual_End_Date__c, CreatedDate
                    FROM Rental__c
                    WHERE Contact_Relation__c = :currentUser.ContactId
                    ORDER BY Start_Date__c DESC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching rentals: ' + e.getMessage());
        }
    }
 
    @AuraEnabled
    public static void cancelRental(Id rentalId) {
        try {
            Rental__c rental = [SELECT Id, Rental_Status__c, Contact_Relation__c
                               FROM Rental__c
                               WHERE Id = :rentalId
                               AND Rental_Status__c != 'Cancelled'
                               AND Contact_Relation__c = :[SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId
                               LIMIT 1];
            
            Rental_Payment__c payment = [SELECT Id, Amount__c, Customer_Id__c, Penalty__c
                                        FROM Rental_Payment__c
                                        WHERE Booking_Id__c = :rentalId
                                        LIMIT 1];
            
            rental.Rental_Status__c = 'Cancelled';
            
            update payment;
            update rental;
        } catch (QueryException qe) {
            throw new AuraHandledException('Rental not found, already cancelled, or no payment record found.');
        } catch (Exception e) {
            throw new AuraHandledException('Error cancelling rental: ' + e.getMessage());
        }
    }
 
    @AuraEnabled
    public static void updateRentalDates(Id rentalId, Date startDate, Date endDate) {
        try {
            if (startDate == null || endDate == null) {
                throw new AuraHandledException('Start Date and End Date are required.');
            }
            if (startDate >= endDate) {
                throw new AuraHandledException('End Date must be after Start Date.');
            }
            if (startDate < Date.today()) {
                throw new AuraHandledException('Start Date cannot be in the past.');
            }
            if (endDate < Date.today()) {
                throw new AuraHandledException('End Date cannot be in the past.');
            }
            Rental__c rental = [SELECT Id, Car_Relation__c, Start_Date__c, End_Date__c, Rental_Status__c, Actual_End_Date__c
                                FROM Rental__c
                                WHERE Id = :rentalId
                                AND Rental_Status__c != 'Cancelled'
                                AND Contact_Relation__c = :[SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId
                                LIMIT 1];
            List<Rental__c> overlappingRentals = [SELECT Id
                                                  FROM Rental__c
                                                  WHERE Car_Relation__c = :rental.Car_Relation__c
                                                  AND Id != :rentalId
                                                  AND Rental_Status__c != 'Cancelled'
                                                  AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)];
            
            if (!overlappingRentals.isEmpty()) {
                throw new AuraHandledException('Date conflict: This car is already booked for the selected dates.');
            }
            rental.Start_Date__c = startDate;
            rental.End_Date__c = endDate;
            update rental;
        } catch (QueryException qe) {
            throw new AuraHandledException('Rental not found or already cancelled.');
        } catch (Exception e) {
            throw new AuraHandledException('Error updating rental dates: ' + e.getMessage());
        }
    }
 
    @AuraEnabled(cacheable=true)
    public static Contact getUserContact() {
        try {
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (currentUser.ContactId == null) {
                throw new AuraHandledException('No associated Contact found for this user.');
            }
            return [SELECT Redeemable_Cash__c FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching contact: ' + e.getMessage());
        }
    }
 
    @AuraEnabled
    public static Rental_Payment__c getRentalPayment(Id rentalId) {
        try {
            List<Rental_Payment__c> payments = [SELECT Id, Amount__c, Advance_Amount__c
                                                FROM Rental_Payment__c
                                                WHERE Booking_Id__c = :rentalId
                                                LIMIT 1];
            return payments.isEmpty() ? null : payments[0];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching payment details: ' + e.getMessage());
        }
    }
 
    @AuraEnabled
    public static void processPayment(Id rentalId, String paymentMode, Boolean useRedeemableCash,
                                    String cardNumber, String cardOwnerName, String cardExpiryDate,
                                    String cvv, String upiId, Decimal amount) {
        try {
            if (String.isBlank(paymentMode)) {
                throw new AuraHandledException('Payment mode is required.');
            }
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Rental__c rental = [SELECT Id, Rental_Status__c, Contact_Relation__c, Name, Car_Relation__r.Name
                                FROM Rental__c
                                WHERE Id = :rentalId
                                AND Rental_Status__c = 'Final Pending'
                                LIMIT 1];
            
            Rental_Payment__c payment = [SELECT Id, Booking_Id__c, Customer_Id__c, Mode_of_Payment__c,
                                        Amount__c, Payment_Date__c, Status__c, Advance_Amount__c,
                                        Card_Number__c, Card_Owner_Name__c, Card_Expiry_Date__c,
                                        CVV__c, UPI_ID__c, cash__c
                                        FROM Rental_Payment__c
                                        WHERE Booking_Id__c = :rentalId
                                        LIMIT 1];
            
            payment.Mode_of_Payment__c = paymentMode;
            payment.Payment_Date__c = Date.today();
            payment.Status__c = 'Completed';
            
            Decimal actualAmountToPay = amount;
            if (useRedeemableCash) {
                Contact contact = [SELECT Redeemable_Cash__c FROM Contact WHERE Id = :rental.Contact_Relation__c LIMIT 1];
                Decimal currentRedeemableCash = contact.Redeemable_Cash__c != null ? contact.Redeemable_Cash__c : 0;
                Decimal cashToUse = Math.min(currentRedeemableCash, amount);
                actualAmountToPay = amount - cashToUse;
                contact.Redeemable_Cash__c = currentRedeemableCash - cashToUse;
                if (contact.Redeemable_Cash__c < 0) {
                    contact.Redeemable_Cash__c = 0;
                }
                update contact;
            }
            payment.Amount__c = actualAmountToPay;
            
            if (paymentMode == 'Card') {
                if (String.isBlank(cardNumber) || String.isBlank(cardOwnerName) || String.isBlank(cardExpiryDate) || String.isBlank(cvv)) {
                    throw new AuraHandledException('All card details are required.');
                }
                payment.Card_Number__c = cardNumber;
                payment.Card_Owner_Name__c = cardOwnerName;
                payment.Card_Expiry_Date__c = Date.valueOf(cardExpiryDate);
                payment.CVV__c = Integer.valueOf(cvv);
            } else if (paymentMode == 'UPI') {
                if (String.isBlank(upiId)) {
                    throw new AuraHandledException('UPI ID is required.');
                }
                payment.UPI_ID__c = upiId;
            } else if (paymentMode == 'Cash') {
                payment.cash__c = true;
            }
            
            update payment;
            rental.Rental_Status__c = 'Completed';
            update rental;

            // Send email notification
            Contact userContact = [SELECT Email, Name FROM Contact WHERE Id = :rental.Contact_Relation__c LIMIT 1];
            if (String.isNotBlank(userContact.Email)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { userContact.Email });
                email.setSubject('Payment Confirmation - Rental ' + rental.Name);
                email.setPlainTextBody(
                    'Dear ' + userContact.Name + ',\n\n' +
                    'We are pleased to inform you that your final payment for the rental has been successfully processed.\n\n' +
                    'Rental Details:\n' +
                    'Rental ID: ' + rental.Name + '\n' +
                    'Car: ' + rental.Car_Relation__r.Name + '\n' +
                    'Payment Amount: ' + actualAmountToPay.format() + '\n' +
                    'Payment Date: ' + Date.today().format() + '\n\n' +
                    'Thank you for choosing our service!\n\n' +
                    'Best regards,\n' +
                    'Your Rental Team'
                );
                email.setSaveAsActivity(true);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                if (!results[0].isSuccess()) {
                    System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
                }
            }
        } catch (QueryException qe) {
            throw new AuraHandledException('No payment record found for this rental or rental not in Final Pending status.');
        } catch (Exception e) {
            throw new AuraHandledException('Error processing payment: ' + e.getMessage());
        }
    }
 
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRentalCancellationInfo(Id rentalId) {
        try {
            Rental__c rental = [SELECT Id, Rental_Status__c, Contact_Relation__c
                               FROM Rental__c
                               WHERE Id = :rentalId
                               AND Rental_Status__c != 'Cancelled'
                               LIMIT 1];
            
            Rental_Payment__c payment = [SELECT Id, Amount__c
                                       FROM Rental_Payment__c
                                       WHERE Booking_Id__c = :rentalId
                                       LIMIT 1];
            
            Contact userContact = [SELECT Redeemable_Cash__c
                                 FROM Contact
                                 WHERE Id = :rental.Contact_Relation__c
                                 LIMIT 1];
            
            Map<String, Object> result = new Map<String, Object>();
            result.put('redeemableCash', userContact.Redeemable_Cash__c != null ? userContact.Redeemable_Cash__c : 0);
            result.put('totalAmount', payment.Amount__c);
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching cancellation info: ' + e.getMessage());
        }
    }
}