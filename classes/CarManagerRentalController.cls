public with sharing class CarManagerRentalController {
    
    @AuraEnabled(cacheable=true)
    public static List<Rental__c> getAllRentals() {
        try {
            return [SELECT Id, Name, Contact_Relation__r.Name, Car_Relation__r.Name, 
                    Start_Date__c, End_Date__c, Actual_End_Date__c, Rental_Status__c
                    FROM Rental__c
                    WHERE Rental_Status__c IN ('Active', 'Final Pending')
                    WITH SECURITY_ENFORCED
                    ORDER BY Start_Date__c DESC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching rentals: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void submitRental(Id rentalId) {
        try {
            Rental__c rental = [SELECT Id, Rental_Status__c, Actual_End_Date__c
                               FROM Rental__c
                               WHERE Id = :rentalId
                               AND Rental_Status__c = 'Active'
                               WITH SECURITY_ENFORCED
                               LIMIT 1];
            
            rental.Rental_Status__c = 'Final Pending';
            rental.Actual_End_Date__c = Date.today();
            
            if (Schema.sObjectType.Rental__c.isUpdateable()) {
                update rental;
            } else {
                throw new AuraHandledException('Insufficient permissions to update rental.');
            }
        } catch (QueryException qe) {
            throw new AuraHandledException('Rental not found or not in Active status.');
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting rental: ' + e.getMessage());
        }
    }
}