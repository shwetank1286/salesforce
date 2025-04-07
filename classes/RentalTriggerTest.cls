@isTest
public class RentalTriggerTest {
    
    @TestSetup
    static void setup() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id,
            Redeemable_Cash__c = 0.00 // Initial cash
        );
        insert testContact;

        // Create a test Car
        Car__c testCar = new Car__c(
            Name = 'Test Car',
            Daily_Charge__c = 1000.00,
            Fuel_Type__c = 'Petrol',
            Liscence_Number__c = 'TN99AB1234', // Matches 'XX 99 XX 9999'
            Maintenance_Date__c = Date.today(),
            Model__c = 'Sedan',
            Seater__c = 5,
            Status__c = 'Available',
            Transmission__c = 'Manual'
        );
        insert testCar;
    }
    
    @isTest
    static void testRedeemableCashUpdate() {
        // Query test data
        Contact testContact = [SELECT Id, Redeemable_Cash__c FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Verify initial state
        System.assertEquals(0.00, testContact.Redeemable_Cash__c, 'Initial cash should be 0');

        // Create a Rental record
        Rental__c testRental = new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = testContact.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            Rental_Status__c = 'Active'
        );

        Test.startTest();
        insert testRental;
        Test.stopTest();

        // Verify update
        testContact = [SELECT Redeemable_Cash__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.Redeemable_Cash__c >= 1 && testContact.Redeemable_Cash__c <= 25, 
            'Cash should be between 1 and 25 after one rental');
    }
    
    @isTest
    static void testMultipleRentalsSameContact() {
        // Query test data
        Contact testContact = [SELECT Id, Redeemable_Cash__c FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Create a list of Rental records for the same Contact
        List<Rental__c> rentals = new List<Rental__c>();
        rentals.add(new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = testContact.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            Rental_Status__c = 'Active'
        ));
        rentals.add(new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = testContact.Id,
            Start_Date__c = Date.today().addDays(3),
            End_Date__c = Date.today().addDays(5),
            Rental_Status__c = 'Active'
        ));

        // Insert both rentals in one transaction
        Test.startTest();
        insert rentals;
        Test.stopTest();

        // Verify update
        testContact = [SELECT Redeemable_Cash__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.Redeemable_Cash__c >= 2 && testContact.Redeemable_Cash__c <= 50, 
            'Cash should be between 2 and 50 after two rentals');
    }
    
    @isTest
    static void testRentalWithNullContact() {
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Create a Rental with null Contact_Relation__c
        Rental__c testRental = new Rental__c(
            Car_Relation__c = testCar.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            Rental_Status__c = 'Active'
        );

        Test.startTest();
        insert testRental;
        Test.stopTest();

        // Verify no exception and no update to any Contact
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE Redeemable_Cash__c > 0];
        System.assertEquals(0, contactCount, 'No contacts should be updated when Contact_Relation__c is null');
    }
    
    @isTest
    static void testNoMatchingContacts() {
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Create a Rental with a non-existent Contact ID
        Rental__c testRental = new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = '003000000000000AAA', // Fake Contact ID
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(2),
            Rental_Status__c = 'Active'
        );

        Test.startTest();
        try {
            insert testRental;
            System.assert(false, 'Expected exception for invalid Contact_Relation__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'), 
                'Expected insufficient access error');
        }
        Test.stopTest();
    }
}