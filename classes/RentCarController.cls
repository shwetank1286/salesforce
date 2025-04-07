public without sharing class RentCarController {

    

    @AuraEnabled
    public static String rent(Id carId, Date startDate, Date endDate, String licenseNumber) {
        // Fetch logged-in user's contact ID
        User loggedInUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        if (loggedInUser.ContactId == null) {
            return 'Error: No contact record found for the logged-in user.';
        }
     
        Id customerId = loggedInUser.ContactId;

        // Check if the car and dates are valid
        if (carId == null || startDate == null || endDate == null) {
            return 'Error: These fields are required.';
        }

        if (startDate < Date.today()) {
            return 'Error: Start date must be today or later.';
        }

        // Check if the car is available
        List<Rental__c> conflictingBookings = [
            SELECT Id FROM Rental__c
            WHERE Car_Relation__c = :carId
            AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)
            LIMIT 1
        ];

        if (!conflictingBookings.isEmpty()) {
            return 'Error: Car is already booked for these dates.';
        }
        
        // Fetch customer and check their license
        Contact customer = [SELECT Id, License_Number__c FROM Contact WHERE Id = :customerId LIMIT 1];

        // Check if the provided license is already stored by another user
        // Integer duplicateLicenseCount = [
        //     SELECT COUNT() FROM Contact 
        //     WHERE License_Number__c = :licenseNumber 
        //     AND Id != :customer.Id
        // ];

        // if (duplicateLicenseCount > 0) {
        //     return 'Error: This license number is already registered with another user.';
        // }

        // Update the license number if it's blank
        // if (String.isBlank(customer.License_Number__c)) {
        //     customer.License_Number__c = licenseNumber;
        //     try {
        //         update customer;  
        //         System.debug('L up ' + customer.Id);
        //     } catch (DmlException e) {
        //         return 'Error ' + e.getMessage();
        //     }
        // } else if (!customer.License_Number__c.equalsIgnoreCase(licenseNumber)) {
        //     return 'Error: A different license number is already stored for this user.';
        // }

        // Create and insert the rental record
        Rental__c rental = new Rental__c();
        rental.Car_Relation__c = carId;
        rental.Contact_Relation__c = customerId;
        rental.Start_Date__c = startDate;
        rental.End_Date__c = endDate;
        rental.License_Number__c = licenseNumber;
        rental.Rental_Status__c = 'Pending';

        try {
            insert rental;

            return rental.Id ;
            //return ;

             

        } catch (DmlException e) {
            System.debug('error: ' + e.getMessage());
            return 'Error: Booking failed - ' + e.getMessage();
        }




        
    }





     

    @AuraEnabled(cacheable=true)
    public static List<String> getStates() {
        Set<String> states = new Set<String>();

        for(Car__c car : [SELECT State__c from Car__c ])
        {
            states.add(car.State__c);
        }
        return new List<String>(states);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCities(String selectedState) {
        List<String> cities = new List<String>();

        for(Car__c car : [SELECT City__c FROM Car__c WHERE State__c = :selectedState])
        {
            cities.add(car.City__c);
        }

        return cities;
    }

//     @AuraEnabled(cacheable=true)
// public static boolean requireLicense(String licenseNumber) {
//     // Check if the provided license number already exists in any Contact record
//     Integer count = [SELECT COUNT() FROM Contact WHERE License_Number__c = :licenseNumber];

//     return (count == 0); // Return true if no record exists (meaning it needs to be stored)
// }
}