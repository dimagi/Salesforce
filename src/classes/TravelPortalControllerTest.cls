/**
 * Test class for TravelPortalController.
 * Covers all methods with positive and negative test cases.
 */
@isTest
private class TravelPortalControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test employee
        SFDC_Employee__c employee = new SFDC_Employee__c(
            Employee_First_Name__c = 'Test',
            Employee_Last_Name__c = 'Employee',
            Email_Address__c = 'testemployee@dimagi.com',
            Division__c = 'SaaS',
            Exchange_Rate__c = 1.0
        );
        insert employee;

        // Create a second employee to test ownership checks
        SFDC_Employee__c otherEmployee = new SFDC_Employee__c(
            Employee_First_Name__c = 'Other',
            Employee_Last_Name__c = 'Employee',
            Email_Address__c = 'otheremployee@dimagi.com',
            Division__c = 'SaaS',
            Exchange_Rate__c = 1.0
        );
        insert otherEmployee;

        // Create test country
        Country__c country = new Country__c(
            Name = 'Test Country',
            Travel_Risk_Level__c = 'Moderate'
        );
        insert country;

        // Create test trip owned by first employee
        Trip__c trip = new Trip__c(
            Traveler__c = employee.Id,
            Destination_Country__c = country.Id,
            Destination_City__c = 'Test City',
            Departure_Date__c = Date.today().addDays(10),
            Return_Date__c = Date.today().addDays(17),
            Trip_Purpose__c = 'Project Travel',
            Risk_Level__c = 'Moderate',
            Risk_Level_Source__c = 'Derived from Country'
        );
        insert trip;
    }

    @isTest
    static void testGetTripsAll() {
        Test.startTest();
        List<Trip__c> trips = TravelPortalController.getTrips('all', 'testemployee@dimagi.com');
        Test.stopTest();
        System.assert(trips.size() > 0, 'Should return at least one trip');
    }

    @isTest
    static void testGetTripsMine() {
        Test.startTest();
        List<Trip__c> trips = TravelPortalController.getTrips('mine', 'testemployee@dimagi.com');
        Test.stopTest();
        System.assert(trips.size() > 0, 'Should return trips for this employee');
        for (Trip__c t : trips) {
            System.assertEquals('testemployee@dimagi.com',
                [SELECT Email_Address__c FROM SFDC_Employee__c WHERE Id = :t.Traveler__c LIMIT 1].Email_Address__c,
                'All trips should belong to the current employee');
        }
    }

    @isTest
    static void testGetTripsInvalidEmail() {
        Test.startTest();
        List<Trip__c> trips = TravelPortalController.getTrips('all', 'nobody@dimagi.com');
        Test.stopTest();
        System.assertEquals(0, trips.size(), 'Should return empty list for unknown email');
    }

    @isTest
    static void testSearchCountries() {
        Test.startTest();
        List<Country__c> results = TravelPortalController.searchCountries('Test');
        Test.stopTest();
        System.assert(results.size() > 0, 'Should find Test Country');
        System.assertEquals('Test Country', results[0].Name);
    }

    @isTest
    static void testSearchCountriesShortTerm() {
        Test.startTest();
        List<Country__c> results = TravelPortalController.searchCountries('T');
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return empty for single character search');
    }

    @isTest
    static void testGetCountryRiskLevel() {
        Country__c country = [SELECT Id FROM Country__c WHERE Name = 'Test Country' LIMIT 1];
        Test.startTest();
        String riskLevel = TravelPortalController.getCountryRiskLevel(country.Id);
        Test.stopTest();
        System.assertEquals('Moderate', riskLevel, 'Should return Moderate risk level');
    }

    @isTest
    static void testGetCountryRiskLevelNull() {
        Test.startTest();
        String riskLevel = TravelPortalController.getCountryRiskLevel(null);
        Test.stopTest();
        System.assertEquals(null, riskLevel, 'Should return null for null Id');
    }

    @isTest
    static void testSaveTripInsert() {
        Country__c country = [SELECT Id FROM Country__c WHERE Name = 'Test Country' LIMIT 1];
        Trip__c newTrip = new Trip__c(
            Destination_Country__c = country.Id,
            Destination_City__c = 'New City',
            Departure_Date__c = Date.today().addDays(20),
            Return_Date__c = Date.today().addDays(25),
            Trip_Purpose__c = 'Conference',
            Risk_Level__c = 'Moderate',
            Risk_Level_Source__c = 'Derived from Country'
        );
        Test.startTest();
        Id tripId = TravelPortalController.saveTrip(newTrip, 'testemployee@dimagi.com');
        Test.stopTest();
        System.assertNotEquals(null, tripId, 'Should return a trip Id');
        Trip__c saved = [SELECT Traveler__c FROM Trip__c WHERE Id = :tripId LIMIT 1];
        SFDC_Employee__c emp = [SELECT Id FROM SFDC_Employee__c WHERE Email_Address__c = 'testemployee@dimagi.com' LIMIT 1];
        System.assertEquals(emp.Id, saved.Traveler__c, 'Traveler should be set to current employee');
    }

    @isTest
    static void testSaveTripInvalidDates() {
        Country__c country = [SELECT Id FROM Country__c WHERE Name = 'Test Country' LIMIT 1];
        Trip__c badTrip = new Trip__c(
            Destination_Country__c = country.Id,
            Departure_Date__c = Date.today().addDays(20),
            Return_Date__c = Date.today().addDays(15),
            Trip_Purpose__c = 'Conference',
            Risk_Level__c = 'Low'
        );
        Test.startTest();
        try {
            TravelPortalController.saveTrip(badTrip, 'testemployee@dimagi.com');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Correctly threw AuraHandledException for invalid dates');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteTrip() {
        Trip__c trip = [SELECT Id FROM Trip__c LIMIT 1];
        Test.startTest();
        TravelPortalController.deleteTrip(trip.Id, 'testemployee@dimagi.com');
        Test.stopTest();
        List<Trip__c> remaining = [SELECT Id FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals(0, remaining.size(), 'Trip should be deleted');
    }

    @isTest
    static void testDeleteTripWrongOwner() {
        Trip__c trip = [SELECT Id FROM Trip__c LIMIT 1];
        Test.startTest();
        try {
            TravelPortalController.deleteTrip(trip.Id, 'otheremployee@dimagi.com');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Correctly threw exception for non-owner delete');
        }
        Test.stopTest();
    }
}