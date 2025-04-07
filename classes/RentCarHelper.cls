public with sharing class RentCarHelper {

@AuraEnabled(cacheable = true)
public static List<Car__c> getValidCars(Date startDate, Date endDate, String state, String city,  String rentalType  ,Integer numberOfHours ) {
    if (String.isEmpty(state) || String.isEmpty(city) || startDate == null || endDate == null) {
        return new List<Car__c>(); 
    }
    
    List<Car__c> availableCars = [
        SELECT Id, Name, State__c, City__c
        FROM Car__c
        WHERE State__c = :state AND City__c = :city 
    ];

    if (availableCars.isEmpty()) {
        return new List<Car__c>();  // No cars found
    }

    Set<Id> availableCarIds = new Set<Id>();
    for (Car__c car : availableCars) {
        availableCarIds.add(car.Id);
    }

    Set<Id> bookedCarIds = new Set<Id>();
    List<Rental__c> existingRentals = [
        SELECT Car_Relation__c 
        FROM Rental__c
        WHERE Car_Relation__c IN :availableCarIds
        AND (Start_Date__c <= :endDate AND End_Date__c >= :startDate)
    ];
    
    for (Rental__c rental : existingRentals) {
        bookedCarIds.add(rental.Car_Relation__c);
    }

    // Ensure distinct cars by name
    Map<String, Car__c> validCarMap = new Map<String, Car__c>();
    for (Car__c car : availableCars) {
        if (!bookedCarIds.contains(car.Id) && !validCarMap.containsKey(car.Name)) {
            validCarMap.put(car.Name, car);
        }
    }

    return validCarMap.values();
}
}