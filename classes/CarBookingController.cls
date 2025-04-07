public without sharing class CarBookingController {
    @AuraEnabled
    public static String createBooking(Id carId, Date startDate, Date endDate, String pickUpTime, String dropTime, String licenseNumber, String rentalType) {
        User loggedInUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (loggedInUser.ContactId == null) {
            return 'Error: No contact record found for the logged-in user.';
        }
        Id customerId = loggedInUser.ContactId;

        if (carId == null || startDate == null || endDate == null || String.isEmpty(licenseNumber)) {
            return 'Error: All required fields must be provided.';
        }

        if (rentalType == 'Hourly' && (String.isEmpty(pickUpTime) || String.isEmpty(dropTime))) {
            return 'Error: Pick-up and drop times are required for hourly rentals.';
        }

        if (startDate < Date.today()) {
            return 'Error: Start date must be today or later.';
        }
        if (endDate < startDate) {
            return 'Error: End date cannot be before start date.';
        }

        Time pickTime = parseTime(pickUpTime);
        Time dropTimeVal = parseTime(dropTime);

        List<Rental__c> conflictingBookings = [
            SELECT Id 
            FROM Rental__c
            WHERE Car_Relation__c = :carId
            AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)
            AND (Pick_Up_Time__c = null OR (Pick_Up_Time__c <= :dropTimeVal AND Drop_Time__c >= :pickTime))
            LIMIT 1
        ];
        if (!conflictingBookings.isEmpty()) {
            return 'Error: Car is already booked for these dates and times.';
        }

        Rental__c rental = new Rental__c();
        rental.Car_Relation__c = carId;
        rental.Contact_Relation__c = customerId;
        rental.Start_Date__c = startDate;
        rental.End_Date__c = endDate;
        rental.Pick_Up_Time__c = pickTime;
        rental.Drop_Time__c = dropTimeVal;
        rental.License_Number__c = licenseNumber;
        rental.Rental_Status__c = 'Pending';

        try {
            insert rental;
            return rental.Id;
        } catch (DmlException e) {
            return 'Error: Booking failed - ' + e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> fetchStates() {
        Set<String> states = new Set<String>();
        for (Car__c car : [SELECT State__c FROM Car__c WHERE State__c != null]) {
            states.add(car.State__c);
        }
        return new List<String>(states);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> fetchCities(String selectedState) {
        List<String> cities = new List<String>();
        for (Car__c car : [SELECT City__c FROM Car__c WHERE State__c = :selectedState AND City__c != null]) {
            cities.add(car.City__c);
        }
        return cities;
    }

    //  Helper method to convert 24-hour format string (HH:mm or HH:mm:ss) to Time
    private static Time parseTime(String timeStr) {
        if (String.isEmpty(timeStr)) return null;

        List<String> parts = timeStr.split(':');
        if (parts.size() < 2 || parts.size() > 3) {
            throw new AuraHandledException('Invalid time format (expected HH:mm or HH:mm:ss): ' + timeStr);
        }

        Integer hour = Integer.valueOf(parts[0]);
        Integer minute = Integer.valueOf(parts[1]);
        Integer second = (parts.size() == 3) ? Integer.valueOf(parts[2]) : 0;

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
            throw new AuraHandledException('Invalid time values in: ' + timeStr);
        }

        return Time.newInstance(hour, minute, second, 0);
    }
}