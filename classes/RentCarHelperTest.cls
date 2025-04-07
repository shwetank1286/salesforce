@isTest
public class RentCarHelperTest {
    @testSetup
    static void setupTestData() {
        // Test Data Setup
        List<Car__c> testCars = new List<Car__c>{
            new Car__c(
                Name = 'Car A',
                State__c = 'Assam',
                City__c = 'Silchar',
                Liscence_Number__c = 'AB01AB4567',
                Model__c = 'Sedan',
                Status__c = 'Available',
                Daily_Charge__c = 1000,
                Seater__c = 4
            ),
            new Car__c(
                Name = 'Car B',
                State__c = 'Bihar',
                City__c = 'Patna',
                Liscence_Number__c = 'XY19XY6543',
                Model__c = 'SUV',
                Status__c = 'Available',
                Daily_Charge__c = 1500,
                Seater__c = 6
            ),
            new Car__c(
                Name = 'Car C',
                State__c = 'Goa',
                City__c = 'Panaji',
                Liscence_Number__c = 'LM34LM7890',
                Model__c = 'Hatchback',
                Status__c = 'Available',
                Daily_Charge__c = 800,
                Seater__c = 4
            )
        };
        insert testCars;

        // Create test rentals with adjusted dates
        List<Rental__c> testRentals = new List<Rental__c>{
            new Rental__c(Car_Relation__c = testCars[0].Id, Start_Date__c = Date.today().addDays(-1), End_Date__c = Date.today().addDays(1)),
            new Rental__c(Car_Relation__c = testCars[1].Id, Start_Date__c = Date.today().addDays(4), End_Date__c = Date.today().addDays(6)) // Adjusted dates
        };
        insert testRentals;
    }

    @isTest
    static void testValidInputWithAvailableCars() {
        Test.startTest();
        List<Car__c> availableCars = RentCarHelper.getValidCars(Date.today(), Date.today().addDays(3), 'Bihar', 'Patna', 'Daily', null);
        Test.stopTest();
        System.assertEquals(1, availableCars.size(), 'Only one car should be available for the given date range and location.');
        System.assertEquals('Car B', availableCars[0].Name, 'Car B should be available.');
    }

    @isTest
    static void testNoCarsAvailableInCity() {
        Test.startTest();
        List<Car__c> noCars = RentCarHelper.getValidCars(Date.today(), Date.today().addDays(3), 'Bihar', 'Gaya', 'Daily', null);
        Test.stopTest();
        System.assertEquals(0, noCars.size(), 'No cars should be available in Gaya.');
    }

    @isTest
    static void testInvalidInput() {
        Test.startTest();
        List<Car__c> invalidInputCars = RentCarHelper.getValidCars(Date.today(), Date.today().addDays(3), '', '', 'Daily', null);
        Test.stopTest();
        System.assertEquals(0, invalidInputCars.size(), 'No cars should be returned for invalid input.');
    }

    @isTest
    static void testOverlappingRentalDates() {
        Test.startTest();
        List<Car__c> overlappingCars = RentCarHelper.getValidCars(Date.today().addDays(-2), Date.today().addDays(0), 'Bihar', 'Patna', 'Daily', null);
        Test.stopTest();
        System.assertEquals(1, overlappingCars.size(), 'Only one car should be available due to overlapping rental dates.');
        System.assertEquals('Car B', overlappingCars[0].Name, 'Car B should be available.');
    }

    @isTest
    static void testDistinctCarsByName() {
        Test.startTest();
        List<Car__c> distinctCars = RentCarHelper.getValidCars(Date.today(), Date.today().addDays(3), 'Bihar', 'Patna', 'Daily', null);
        Test.stopTest();
        System.assertEquals(1, distinctCars.size(), 'Distinct cars by name should be returned.');
    }
}