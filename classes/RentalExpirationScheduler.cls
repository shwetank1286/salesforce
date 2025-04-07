public with sharing class RentalExpirationScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Datetime thirtyMinutesAgo = Datetime.now().addMinutes(-30);
        List<Rental__c> rentalsToUpdate = [SELECT Id, Rental_Status__c
                                           FROM Rental__c
                                           WHERE Rental_Status__c = 'Pending'
                                           AND CreatedDate < :thirtyMinutesAgo];
        
        for (Rental__c rental : rentalsToUpdate) {
            rental.Rental_Status__c = 'Expired';
        }
        if (!rentalsToUpdate.isEmpty()) {
            update rentalsToUpdate;
        }
    }
}