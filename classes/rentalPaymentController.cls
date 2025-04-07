public with sharing class rentalPaymentController {

    @AuraEnabled
    public static Decimal getCarAmount(string carId, Date startDate, Date endDate){
        List<Car__c> cars = [SELECT Daily_Charge__c FROM Car__c WHERE Id = :carId LIMIT 1];
        Decimal amount = cars[0].Daily_Charge__c != null ? Decimal.valueOf(String.valueOf(cars[0].Daily_Charge__c)) : 0;
        return dailyAmount(startDate, endDate, amount);
    }

    @AuraEnabled
    public static string createRentalPayment(
        String contactId,
        String carId,
        String rentalId,
        Date startDate,
        Date endDate,
        String licenseNumber,
        String paymentMethod, 
        String rentalType,
        String paymentDetails){
        
        try {
            // Check if contact exists
            List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
            if (contacts.isEmpty()) {
                return 'Error: Contact with ID ' + contactId + ' not found';
            }
            
            // Check if car exists
            List<Car__c> cars = [SELECT Daily_Charge__c FROM Car__c WHERE Id = :carId LIMIT 1];
            if (cars.isEmpty()) {
                return 'Error: Car with ID ' + carId + ' not found';
            }

            Rental__c getRental = [select id, Rental_Status__c from Rental__c where id=:rentalId];
            getRental.Rental_Status__c = 'Active';

            Map<String, Object> paymentMethodInClass = (Map<String, Object>) JSON.deserializeUntyped(paymentDetails);

            Rental_Payment__c payment = new Rental_Payment__c();
            payment.Car_Id__c = carId;
            payment.Booking_Id__c = rentalId;
            payment.Customer_Id__c = contacts[0].Id;
            payment.Name = (carId + licenseNumber).left(255);
            payment.Payment_Date__c = endDate;

            Decimal amount = cars[0].Daily_Charge__c != null ? Decimal.valueOf(String.valueOf(cars[0].Daily_Charge__c)) : 0;

            if(rentalType == 'Hourly'){
                payment.Amount__c = dailyAmount(startDate, endDate, amount);
            } else {
                payment.Amount__c = dailyAmount(startDate, endDate, amount);
            }

            if(paymentMethod == 'Cash'){
                payment.Mode_of_Payment__c = 'Cash';
                payment.cash__c = TRUE;
                payment.RecordTypeId = '012NS000003q7rhYAA';
            } else if(paymentMethod == 'UPI'){
                payment.Mode_of_Payment__c = 'UPI';
                String upiIdFromUser = (String) paymentMethodInClass.get('upiId');
                payment.UPI_ID__c = upiIdFromUser;
                payment.RecordTypeId = '012NS000003q7mrYAA';
            } else if(paymentMethod == 'Card'){
                
                payment.Mode_of_Payment__c = 'Card';
                
                String expiryYearStr = (String) paymentMethodInClass.get('expiryYear'); // Cast to String
                Integer expiryYear = Integer.valueOf(expiryYearStr);
                
                String expiryMonthStr = (String) paymentMethodInClass.get('expiryMonth'); // Cast to String
                Integer expiryMonth = Integer.valueOf(expiryMonthStr);
                
                Integer lastDay = Date.daysInMonth(expiryYear, expiryMonth);

                Date expiryDateForCard = Date.newInstance(expiryYear, expiryMonth, lastDay);
                payment.Card_Expiry_Date__c = expiryDateForCard;

                String cardOwnerName = (String) paymentMethodInClass.get('cardholderName');
                payment.Card_Owner_Name__c = cardOwnerName;

                String cardNumber = (String) paymentMethodInClass.get('cardNumber');
                payment.Card_Number__c = cardNumber;
                
                String cvvStr = (String) paymentMethodInClass.get('cvv'); // Cast to String
                Integer cvv = Integer.valueOf(cvvStr);
                
                payment.CVV__c = cvv;
                
                payment.RecordTypeId = '012NS000003q7q5YAA';
                system.debug(expiryYear);
                system.debug(expiryMonth);
                system.debug(lastDay);
                system.debug(expiryDateForCard);
                system.debug(cvv);
                system.debug(cardOwnerName);
                system.debug(cardNumber);
                system.debug(expiryDateForCard);

                
            }
            
            insert payment;
            system.debug(payment);
            update getRental;
            return 'success';
        } catch (Exception e) {
            return 'Error creating payment record: ' + e.getMessage();
        }
    }

    // Rest of the class remains the same
    public static Decimal dailyAmount(Date startDate, Date endDate, Decimal charge) {
        Integer difference = Math.max(1, startDate.daysBetween(endDate));
        return charge * difference;
    }
}