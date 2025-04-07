@isTest
public class RentCarControllerTest {    

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact linked to the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id,
            License_Number__c = 'AB 12 CD 3456' // Valid license number
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

        // Create a test Car with all required fields
        Car__c testCar = new Car__c(
            Name = 'Test Car',
            State__c = 'Goa',
            City__c = 'Panaji',
            Model__c = 'Sedan',
            Status__c = 'Available',
            Daily_Charge__c = 1000,
            Seater__c = 4,
            Liscence_Number__c = 'MH12AM0018'
        );
        insert testCar;
    }

    @isTest
    static void testRentCarSuccess() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];

        System.runAs(testUser) {
            Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];
            Date startDate = Date.today().addDays(1);
            Date endDate = startDate.addDays(2);

            Test.startTest();
            String result = RentCarController.rent(testCar.Id, startDate, endDate, 'AB 12 CD 3456');
            Test.stopTest();

            System.assertEquals('Success: Car booked successfully!', result);
        }
    }

    @isTest
    static void testRentCarFailureCarBooked() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];

        System.runAs(testUser) {
            Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];
            Date startDate = Date.today().addDays(1);
            Date endDate = startDate.addDays(2);

            // Insert a conflicting booking
            Rental__c rental = new Rental__c(
                Car_Relation__c = testCar.Id,
                Contact_Relation__c = testUser.ContactId,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Rental_Status__c = 'Pending'
            );
            insert rental;

            Test.startTest();
            String result = RentCarController.rent(testCar.Id, startDate, endDate, 'AB 12 CD 3456');
            Test.stopTest();

            System.assertEquals('Error: Car is already booked for these dates.', result);
        }
    }

    @isTest
    static void testRentCarFailureInvalidDates() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Username LIKE 'testuser%@example.com.test' LIMIT 1];

        System.runAs(testUser) {
            Car__c testCar = [SELECT Id FROM Car__c LIMIT 1];
            Date pastDate = Date.today().addDays(-1);
            Date futureDate = Date.today().addDays(2);

            Test.startTest();
            String result = RentCarController.rent(testCar.Id, pastDate, futureDate, 'AB 12 CD 3456');
            Test.stopTest();

            System.assertEquals('Error: Start date must be today or later.', result);
        }
    }

    @isTest
    static void testGetStates() {
        Test.startTest();
        List<String> states = RentCarController.getStates();
        Test.stopTest();

        System.assert(states.contains('Goa'), 'Expected state "Goa" not found.');
        System.assert(states.size() > 0, 'States should not be empty');
    }

    @isTest
    static void testGetCities() {
        Test.startTest();
        List<String> cities = RentCarController.getCities('Goa');
        Test.stopTest();

        System.assert(cities.contains('Panaji'), 'Expected city "Panaji" not found.');
        System.assert(cities.size() > 0, 'Cities should not be empty');
    }
}