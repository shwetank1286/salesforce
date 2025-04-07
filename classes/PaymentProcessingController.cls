public with sharing class PaymentProcessingController {
    @AuraEnabled
    public static Decimal calculateCarCost(String carId, Date startDate, Date endDate, String rentalType, String pickUpTime, String dropTime) {
        List<Car__c> cars = [SELECT Daily_Charge__c FROM Car__c WHERE Id = :carId LIMIT 1];
        if (cars.isEmpty()) {
            throw new AuraHandledException('Car not found with ID: ' + carId);
        }

        Decimal dailyCharge = cars[0].Daily_Charge__c != null ? cars[0].Daily_Charge__c : 0;
        Decimal hourlyCharge = dailyCharge * 0.10;

        if (rentalType == 'Hourly') {
            return calculateHourlyCost(startDate, endDate, pickUpTime, dropTime, hourlyCharge);
        } else {
            return calculateDailyCost(startDate, endDate, dailyCharge);
        }
    }

    @AuraEnabled
    public static String processPayment(
        String contactId, String carId, String rentalId, Date startDate, Date endDate,
        String licenseNumber, String paymentMethod, String rentalType, String paymentDetails
    ) {
        try {
            List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
            if (contacts.isEmpty()) {
                return 'Error: Contact with ID ' + contactId + ' not found';
            }
            Contact contact = contacts[0];

            List<Car__c> cars = [SELECT Daily_Charge__c FROM Car__c WHERE Id = :carId LIMIT 1];
            if (cars.isEmpty()) {
                return 'Error: Car with ID ' + carId + ' not found';
            }
            Car__c car = cars[0];

            List<Rental__c> rentals = [SELECT Id, Rental_Status__c, Pick_Up_Time__c, Drop_Time__c FROM Rental__c WHERE Id = :rentalId LIMIT 1];
            if (rentals.isEmpty()) {
                return 'Error: Rental with ID ' + rentalId + ' not found';
            }
            Rental__c rental = rentals[0];
            rental.Rental_Status__c = 'Active';

            Map<String, Object> paymentDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(paymentDetails);

            Rental_Payment__c payment = new Rental_Payment__c();
            payment.Car_Id__c = carId;
            payment.Booking_Id__c = rentalId;
            payment.Customer_Id__c = contact.Id;
            payment.Name = (carId + licenseNumber).left(80);
            payment.Payment_Date__c = Date.today();

            Decimal dailyCharge = car.Daily_Charge__c != null ? car.Daily_Charge__c : 0;
            Decimal hourlyCharge = dailyCharge * 0.10;
            Decimal amount = rentalType == 'Hourly'
                ? calculateHourlyCost(startDate, endDate, timeToString(rental.Pick_Up_Time__c), timeToString(rental.Drop_Time__c), hourlyCharge)
                : calculateDailyCost(startDate, endDate, dailyCharge);

            payment.Amount__c = amount;

            if (paymentMethod == 'Cash') {
                payment.Mode_of_Payment__c = 'Cash';
                payment.cash__c = true;
                payment.RecordTypeId = Schema.SObjectType.Rental_Payment__c.getRecordTypeInfosByName().get('Cash').getRecordTypeId();
            } else if (paymentMethod == 'UPI') {
                payment.Mode_of_Payment__c = 'UPI';
                payment.UPI_ID__c = (String) paymentDetailsMap.get('upiId');
                payment.RecordTypeId = Schema.SObjectType.Rental_Payment__c.getRecordTypeInfosByName().get('UPI').getRecordTypeId();
            } else if (paymentMethod == 'Card') {
                payment.Mode_of_Payment__c = 'Card';
                Integer expiryYear = Integer.valueOf((String) paymentDetailsMap.get('expiryYear'));
                Integer expiryMonth = Integer.valueOf((String) paymentDetailsMap.get('expiryMonth'));
                Integer lastDay = Date.daysInMonth(expiryYear, expiryMonth);
                payment.Card_Expiry_Date__c = Date.newInstance(expiryYear, expiryMonth, lastDay);
                payment.Card_Owner_Name__c = (String) paymentDetailsMap.get('cardholderName');
                payment.Card_Number__c = (String) paymentDetailsMap.get('cardNumber');
                payment.CVV__c = Integer.valueOf((String) paymentDetailsMap.get('cvv'));
                payment.RecordTypeId = Schema.SObjectType.Rental_Payment__c.getRecordTypeInfosByName().get('Card').getRecordTypeId();
            }

            insert payment;
            update rental;

            return 'success';
        } catch (Exception e) {
            return 'Error creating payment record: ' + e.getMessage();
        }
    }

    public static Decimal calculateDailyCost(Date startDate, Date endDate, Decimal charge) {
        Integer days = Math.max(1, startDate.daysBetween(endDate));
        return charge * days;
    }

    public static Decimal calculateHourlyCost(Date startDate, Date endDate, String pickUpTime, String dropTime, Decimal hourlyCharge) {
        if (String.isEmpty(pickUpTime) || String.isEmpty(dropTime)) {
            return 0;
        }
        DateTime startDT = DateTime.newInstance(startDate, stringToTime(pickUpTime));
        DateTime endDT = DateTime.newInstance(endDate, stringToTime(dropTime));

        Long totalMinutes = (endDT.getTime() - startDT.getTime()) / (1000 * 60);
        Decimal hours = totalMinutes / 60.0;
        return hourlyCharge * hours.setScale(2);
    }

    private static Time stringToTime(String timeStr) {
        List<String> parts = timeStr.split(':');
        if (parts.size() != 2) throw new AuraHandledException('Invalid time format: ' + timeStr);
        return Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0);
    }

    private static String timeToString(Time timeVal) {
        if (timeVal == null) return null;
        return String.valueOf(timeVal.hour()).leftPad(2, '0') + ':' + String.valueOf(timeVal.minute()).leftPad(2, '0');
    }
}