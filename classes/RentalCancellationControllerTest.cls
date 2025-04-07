@isTest
public class RentalCancellationControllerTest {

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

        // Create a test Rental
        Rental__c testRental = new Rental__c(
            Car_Relation__c = testCar.Id,
            Contact_Relation__c = testContact.Id,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(3),
            Rental_Status__c = 'Active'
        );
        insert testRental;

        // Create a portal user associated with the Contact
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        User portalUser = new User(
            Alias = 'testusr',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com',
            ContactId = testContact.Id
        );
        insert portalUser;
    }

    @isTest
    static void testGetUserRentals() {
        // Query the portal user created in the test setup
        User portalUser = [SELECT Id FROM User WHERE Alias = 'testusr' LIMIT 1];

        // Run as the portal user
        System.runAs(portalUser) {
            Test.startTest();
            List<Rental__c> rentals = RentalCancellationController.getUserRentals();
            Test.stopTest();

            System.assertEquals(1, rentals.size(), 'There should be one rental for the user.');
            System.assertEquals('Active', rentals[0].Rental_Status__c, 'The rental status should be Active.');
        }
    }

    @isTest
    static void testCancelRental() {
        // Query test data
        Rental__c testRental = [SELECT Id, Rental_Status__c FROM Rental__c LIMIT 1];

        // Cancel the rental
        Test.startTest();
        RentalCancellationController.cancelRental(testRental.Id);
        Test.stopTest();

        // Verify the rental status is updated to 'Cancelled'
        testRental = [SELECT Rental_Status__c FROM Rental__c WHERE Id = :testRental.Id];
        System.assertEquals('Cancelled', testRental.Rental_Status__c, 'The rental status should be Cancelled.');
    }

    @isTest
    static void testCancelRentalAlreadyCancelled() {
        // Query test data
        Rental__c testRental = [SELECT Id FROM Rental__c LIMIT 1];

        // Cancel the rental
        testRental.Rental_Status__c = 'Cancelled';
        update testRental;

        // Attempt to cancel the already cancelled rental
        Test.startTest();
        try {
            RentalCancellationController.cancelRental(testRental.Id);
            System.assert(false, 'Expected an exception for already cancelled rental.');
        } catch (AuraHandledException e) {
            System.assertEquals('Rental not found or already cancelled.', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateRentalDatesSuccess() {
        // Query test data
        Rental__c testRental = [SELECT Id, Start_Date__c, End_Date__c FROM Rental__c LIMIT 1];

        // Update the rental dates
        Test.startTest();
        RentalCancellationController.updateRentalDates(testRental.Id, Date.today().addDays(2), Date.today().addDays(4));
        Test.stopTest();

        // Verify the rental dates are updated
        testRental = [SELECT Start_Date__c, End_Date__c FROM Rental__c WHERE Id = :testRental.Id];
        System.assertEquals(Date.today().addDays(2), testRental.Start_Date__c, 'The start date should be updated.');
        System.assertEquals(Date.today().addDays(4), testRental.End_Date__c, 'The end date should be updated.');
    }

    @isTest
static void testUpdateRentalDatesConflict() {
    // Query test data
    Rental__c testRental = [SELECT Id, Car_Relation__c, Contact_Relation__c FROM Rental__c LIMIT 1];

    // Create a conflicting rental with overlapping dates
    Rental__c conflictingRental = new Rental__c(
        Car_Relation__c = testRental.Car_Relation__c,
        Contact_Relation__c = testRental.Contact_Relation__c,
        Start_Date__c = Date.today().addDays(3),
        End_Date__c = Date.today().addDays(5),
        Rental_Status__c = 'Active'
    );
    insert conflictingRental;

    // Attempt to update the rental dates to conflict with the existing rental
    Test.startTest();
    try {
        RentalCancellationController.updateRentalDates(testRental.Id, Date.today().addDays(3), Date.today().addDays(5));
        System.assert(false, 'Expected an exception for date conflict.');
    } catch (AuraHandledException e) {
        System.debug('Exception Message: ' + e.getMessage());
        System.assertEquals('Date conflict: This car is already booked for the selected dates.', e.getMessage(),
            'The exception message should indicate a date conflict.');
    }
    Test.stopTest();
}

    @isTest
    static void testUpdateRentalDatesInvalidDates() {
        // Query test data
        Rental__c testRental = [SELECT Id FROM Rental__c LIMIT 1];

        // Attempt to update the rental with invalid dates
        Test.startTest();
        try {
            RentalCancellationController.updateRentalDates(testRental.Id, Date.today().addDays(5), Date.today().addDays(3));
            System.assert(false, 'Expected an exception for invalid date range.');
        } catch (AuraHandledException e) {
            System.assertEquals('End Date must be after Start Date.', e.getMessage());
        }
        Test.stopTest();
    }
}