public class DeleteRecords {
    public static void deleteAllRecords() {
        // Delete all records from Rental_Payment__c first
        List<Rental_Payment__c> rentalPayments = [SELECT Id FROM Rental_Payment__c];
        delete rentalPayments;

        // Delete all records from Rental__c
        List<Rental__c> rentals = [SELECT Id FROM Rental__c];
        delete rentals;
    }
}