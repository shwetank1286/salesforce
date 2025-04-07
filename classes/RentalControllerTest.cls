@isTest
public class RentalControllerTest {
    @testSetup
    public static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact linked to the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Generate a unique username using timestamp
        String uniqueUsername = 'testuser' + System.currentTimeMillis() + '@example.com.test';

        // Fetch the correct portal profile
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Community%' LIMIT 1];

        // Create a Customer Community User (portal user)
        User portalUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = uniqueUsername,
            Alias = 'tusr' + String.valueOf(System.currentTimeMillis()).right(4), // Unique Alias
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id // Ensure correct association
        );
        insert portalUser;

        // Create a test Car
        Car__c testCar = new Car__c(Name = 'Test Car', State__c = 'Goa', City__c = 'Panaji');
        insert testCar;

        // Create a test Rental
        Rental__c testRental = new Rental__c(
            Contact_Relation__c = testContact.Id,
            Car_Relation__c = testCar.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3)
        );
        insert testRental;
    }

    @isTest
    public static void testGetUserBookings() {
        // Fetch the test user
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];

        // Run the method as the test user
        System.runAs(testUser) {
            Test.startTest();
            List<Rental__c> bookings = RentalController.getUserBookings();
            Test.stopTest();

            // Assertions
            System.assertNotEquals(0, bookings.size(), 'Expected at least one booking.');
            System.assertEquals(Date.today().addDays(1), bookings[0].Start_Date__c, 'Booking start date does not match.');
        }
    }

    @isTest
    public static void testUpdateBookingDatesSuccess() {
        // Fetch the test user and rental
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];
        Rental__c testRental = [SELECT Id FROM Rental__c LIMIT 1];

        // Run the method as the test user
        System.runAs(testUser) {
            Test.startTest();
            String result = RentalController.updateBookingDates(
                testRental.Id,
                Date.today().addDays(5),
                Date.today().addDays(7)
            );
            Test.stopTest();

            // Assertions
            System.assertEquals('Success: Booking updated!', result, 'Booking update failed.');
        }
    }

    @isTest
    public static void testUpdateBookingDatesConflict() {
        // Fetch the test user and rental
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];
        Rental__c testRental = [SELECT Id, Car_Relation__c FROM Rental__c LIMIT 1];

        // Create a conflicting rental
        Rental__c conflictingRental = new Rental__c(
            Contact_Relation__c = testRental.Contact_Relation__c,
            Car_Relation__c = testRental.Car_Relation__c,
            Start_Date__c = Date.today().addDays(6),
            End_Date__c = Date.today().addDays(8)
        );
        insert conflictingRental;

        // Run the method as the test user
        System.runAs(testUser) {
            Test.startTest();
            String result = RentalController.updateBookingDates(
                testRental.Id,
                Date.today().addDays(6),
                Date.today().addDays(8)
            );
            Test.stopTest();

            // Assertions
            System.assertEquals(
                'Error: Date range conflicts with another booking.',
                result,
                'Expected a conflict error but got a different result.'
            );
        }
    }
}