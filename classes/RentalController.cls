public class RentalController {
    @AuraEnabled(cacheable=true)
    public static List<Rental__c> getUserBookings() {
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        Contact userContact = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
       
        return [
            SELECT Id, Name, Start_Date__c, End_Date__c,
                   Car_Relation__r.Name
            FROM Rental__c
            WHERE Contact_Relation__c = :userContact.Id
            ORDER BY Start_Date__c DESC
        ];
    }
 
    @AuraEnabled
    public static String updateBookingDates(Id rentalId, Date newStartDate, Date newEndDate) {
        Rental__c rental = [SELECT Id, Start_Date__c, End_Date__c, Car_Relation__c
                            FROM Rental__c WHERE Id = :rentalId LIMIT 1];
 
        // Check for collisions
        List<Rental__c> conflictingRentals = [
            SELECT Id FROM Rental__c
            WHERE Car_Relation__c = :rental.Car_Relation__c
            AND Id != :rental.Id
            AND ((Start_Date__c <= :newEndDate AND End_Date__c >= :newStartDate))
        ];
       
        if (!conflictingRentals.isEmpty()) {
            return 'Error: Date range conflicts with another booking.';
        }
 
        // Update rental record
        rental.Start_Date__c = newStartDate;
        rental.End_Date__c = newEndDate;
        update rental;
       
        return 'Success: Booking updated!';
    }
}