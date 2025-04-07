public with sharing class CarAvailabilityHelper {
    @AuraEnabled(cacheable=true)
    public static List<Car__c> fetchAvailableCars(Date startDate, Date endDate, String state, String city, Integer numberOfHours, String pickUpTime, String dropTime) {
        if (String.isEmpty(state) || String.isEmpty(city) || startDate == null || endDate == null) {
            return new List<Car__c>();
        }

        if (numberOfHours != null && (numberOfHours <= 0 || String.isEmpty(pickUpTime) || String.isEmpty(dropTime))) {
            return new List<Car__c>();
        }

        Time pickUpTimeValue = parseTime(pickUpTime);
        Time dropTimeValue = parseTime(dropTime);

        List<Car__c> availableCars = [
            SELECT Id, Name, State__c, City__c
            FROM Car__c
            WHERE State__c = :state AND City__c = :city
        ];

        if (availableCars.isEmpty()) return new List<Car__c>();

        Set<Id> availableCarIds = new Set<Id>();
        for (Car__c car : availableCars) {
            availableCarIds.add(car.Id);
        }

        Set<Id> bookedCarIds = new Set<Id>();
        List<Rental__c> existingRentals = [
            SELECT Car_Relation__c, Pick_Up_Time__c, Drop_Time__c
            FROM Rental__c
            WHERE Car_Relation__c IN :availableCarIds
            AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)
            AND (Pick_Up_Time__c = null OR (Pick_Up_Time__c <= :dropTimeValue AND Drop_Time__c >= :pickUpTimeValue))
        ];

        for (Rental__c rental : existingRentals) {
            bookedCarIds.add(rental.Car_Relation__c);
        }

        Map<String, Car__c> validCarMap = new Map<String, Car__c>();
        for (Car__c car : availableCars) {
            if (!bookedCarIds.contains(car.Id) && !validCarMap.containsKey(car.Name)) {
                validCarMap.put(car.Name, car);
            }
        }

        return validCarMap.values();
    }

    // Strict 24-hour time parsing (supports HH:mm or HH:mm:ss)
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