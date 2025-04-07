@isTest
public class GetRedeemableCashTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id,
            Redeemable_Cash__c = 50 // Initial redeemable cash
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

        // Create a portal user associated with the contact
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

        // Insert a rental as the portal user
        System.runAs(portalUser) {
            Rental__c testRental = new Rental__c(
                Car_Relation__c = testCar.Id,
                Contact_Relation__c = testContact.Id,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(2),
                Rental_Status__c = 'Active'
            );
            insert testRental;
        }
    }

    @isTest
    static void testGetRedeemableCashSuccess() {
        // Test when a recent rental exists and redeemable cash is set
        Test.startTest();
        Decimal redeemableCash = GetRedeemableCash.getRedeemableCash();
        Test.stopTest();

        System.assertEquals(50, redeemableCash, 'Redeemable cash should match the value set in the test data.');
    }

    @isTest
    static void testGetRedeemableCashNoRental() {
        // Create a new contact for the new portal user
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact newContact = new Contact(
            FirstName = 'New',
            LastName = 'User',
            AccountId = testAccount.Id
        );
        insert newContact;

        // Create a new portal user associated with the new contact
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];
        User portalUser = new User(
            Alias = 'newusr',
            Email = 'newuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'New User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newuser' + System.currentTimeMillis() + '@example.com',
            ContactId = newContact.Id
        );
        insert portalUser;

        // Run as the new portal user
        System.runAs(portalUser) {
            Test.startTest();
            Decimal redeemableCash = GetRedeemableCash.getRedeemableCash();
            Test.stopTest();

            System.assertEquals(0, redeemableCash, 'Redeemable cash should be 0 when no rental exists.');
        }
    }

    @isTest
    static void testGetRedeemableCashNullValue() {
        // Query the contact created in the test setup
        Contact testContact = [SELECT Id, Redeemable_Cash__c FROM Contact WHERE Redeemable_Cash__c = 50 LIMIT 1];

        // Update the contact to have null redeemable cash
        testContact.Redeemable_Cash__c = null;
        update testContact;

        Test.startTest();
        Decimal redeemableCash = GetRedeemableCash.getRedeemableCash();
        Test.stopTest();

        System.assertEquals(0, redeemableCash, 'Redeemable cash should be 0 when the field is null.');
    }
}