public with sharing class RentCar {

    @AuraEnabled
    public static String rent(Id carId, Date startDate, Date endDate, Id customerId) {
        // Check for empty fields
        if (carId == null || startDate == null || endDate == null || customerId == null) {
            return 'Error: These fields are required.';
        }

        // Check if start date is after end date
        if (startDate > endDate) {
            return 'Error: Start date cannot be after end date.';
        }

        Date today = Date.today();
        // Check if start date is before today
        if (startDate < today) {
            return 'Error: Start date must be today or later.';
        }

        // Check for conflicting bookings
        List<Rental__c> conflictingBookings = [
            SELECT Id FROM Rental__c
            WHERE Car_Relation__c = :carId
            AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)
            LIMIT 1
        ];

        if (!conflictingBookings.isEmpty()) {
            return 'Error: Car is already booked for these dates.';
        }

        // Create new rental booking
        Rental__c rental = new Rental__c();
        rental.Car_Relation__c = carId;
        rental.Contact_Relation__c = customerId;
        rental.Start_Date__c = startDate;
        rental.End_Date__c = endDate;
        rental.Rental_Status__c = 'Pending';

        try {
            insert rental;
            return 'Success: Car booked successfully!';
        } catch (Exception e) {
            return 'Error: Booking failed - ' + e.getMessage();
        }
    }
}