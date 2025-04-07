@isTest
public class RentCarTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create a test Car
        Car__c testCar = new Car__c(
            Name = 'Test Car',
            State__c = 'Goa',
            City__c = 'Panaji',
            Model__c = 'Sedan',
            Status__c = 'Available',
            Daily_Charge__c = 1000,
            Seater__c = 4,
            Liscence_Number__c = 'GA03EF9012'
        );
        insert testCar;
    }

    @isTest
    static void testRentSuccess() {
        // Query test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Valid rental booking
        Test.startTest();
        String result = RentCar.rent(testCar.Id, Date.today().addDays(1), Date.today().addDays(3), testContact.Id);
        Test.stopTest();

        System.debug('Result from RentCar.rent: ' + result);
        System.assertEquals('Success: Car booked successfully!', result, 'The car should be booked successfully.');
    }

    @isTest
    static void testRentMissingFields() {
        // Query test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Missing fields
        Test.startTest();
        String result = RentCar.rent(null, Date.today().addDays(1), Date.today().addDays(3), testContact.Id);
        Test.stopTest();

        System.assertEquals('Error: These fields are required.', result, 'Error should be returned for missing fields.');
    }

    @isTest
    static void testRentStartDateAfterEndDate() {
        // Query test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Start date after end date
        Test.startTest();
        String result = RentCar.rent(testCar.Id, Date.today().addDays(3), Date.today().addDays(1), testContact.Id);
        Test.stopTest();

        System.assertEquals('Error: Start date cannot be after end date.', result, 'Error should be returned for invalid date range.');
    }

    @isTest
    static void testRentStartDateBeforeToday() {
        // Query test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Start date before today
        Test.startTest();
        String result = RentCar.rent(testCar.Id, Date.today().addDays(-1), Date.today().addDays(1), testContact.Id);
        Test.stopTest();

        System.assertEquals('Error: Start date must be today or later.', result, 'Error should be returned for past start date.');
    }

    @isTest
    static void testRentCarAlreadyBooked() {
        // Query test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];

        // Create a conflicting booking
        Rental__c existingRental = new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = testContact.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Rental_Status__c = 'Active' // Use a valid picklist value
        );
        insert existingRental;

        // Attempt to book the same car for overlapping dates
        Test.startTest();
        String result = RentCar.rent(testCar.Id, Date.today().addDays(2), Date.today().addDays(4), testContact.Id);
        Test.stopTest();

        System.assertEquals('Error: Car is already booked for these dates.', result, 'Error should be returned for conflicting booking.');
    }
}