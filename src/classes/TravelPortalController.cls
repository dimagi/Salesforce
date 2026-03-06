/**
 * Controller for the Travel Management portal tab.
 * Follows the same pattern as EmployeeFileController — resolves the logged-in
 * user via email address to their SFDC_Employee__c record.
 */
public without sharing class TravelPortalController {

    /**
     * Returns upcoming and active trips.
     * viewType = 'all'  - all employees, return date >= today
     * viewType = 'mine' - current employee only, return date >= today
     */
    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getTrips(String viewType, String employeeEmail) {
        SFDC_Employee__c employee = getEmployee(employeeEmail);
        if (employee == null) return new List<Trip__c>();

        if (viewType == 'mine') {
            return [
                SELECT Id, Name, Traveler__c, Traveler__r.Employee_First_Name__c,
                       Traveler__r.Employee_Last_Name__c, Traveler__r.Division__c,
                       Destination_Country__c, Destination_Country__r.Name,
                       Destination_City__c, Departure_Date__c, Return_Date__c,
                       Total_Days__c, Trip_Purpose__c, Accommodation__c,
                       Local_Contact_Number__c, Risk_Level__c, Risk_Level_Source__c,
                       Notes__c
                FROM Trip__c
                WHERE Traveler__c = :employee.Id
                AND Return_Date__c >= TODAY
                ORDER BY Departure_Date__c ASC
            ];
        } else {
            return [
                SELECT Id, Name, Traveler__c, Traveler__r.Employee_First_Name__c,
                       Traveler__r.Employee_Last_Name__c, Traveler__r.Division__c,
                       Destination_Country__c, Destination_Country__r.Name,
                       Destination_City__c, Departure_Date__c, Return_Date__c,
                       Total_Days__c, Trip_Purpose__c, Accommodation__c,
                       Local_Contact_Number__c, Risk_Level__c, Risk_Level_Source__c,
                       Notes__c
                FROM Trip__c
                WHERE Return_Date__c >= TODAY
                ORDER BY Departure_Date__c ASC
            ];
        }
    }

    /**
     * Searches Country__c records by name for the country typeahead.
     * Returns Id, Name, and Travel_Risk_Level__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<Country__c> searchCountries(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new List<Country__c>();
        }
        String term = '%' + searchTerm + '%';
        return [
            SELECT Id, Name, Travel_Risk_Level__c
            FROM Country__c
            WHERE Name LIKE :term
            ORDER BY Name ASC
            LIMIT 10
        ];
    }

    /**
     * Returns the Travel_Risk_Level__c for a given Country__c Id.
     * Called after country selection in the trip form to pre-populate risk level.
     */
    @AuraEnabled(cacheable=true)
    public static String getCountryRiskLevel(Id countryId) {
        if (countryId == null) return null;
        List<Country__c> countries = [
            SELECT Travel_Risk_Level__c
            FROM Country__c
            WHERE Id = :countryId
            LIMIT 1
        ];
        return countries.isEmpty() ? null : countries[0].Travel_Risk_Level__c;
    }

    /**
     * Saves (upserts) a Trip__c record.
     * On insert, sets Traveler__c to the current employee.
     * Returns the Id of the saved record.
     */
    @AuraEnabled
    public static Id saveTrip(Trip__c trip, String employeeEmail) {
        SFDC_Employee__c employee = getEmployee(employeeEmail);
        if (employee == null) {
            throw new AuraHandledException('Could not find employee record for ' + employeeEmail);
        }

        // Validate return date
        if (trip.Return_Date__c != null && trip.Departure_Date__c != null
                && trip.Return_Date__c < trip.Departure_Date__c) {
            throw new AuraHandledException('Return date must be on or after departure date.');
        }

        // On insert, set the traveler to the current employee
        if (trip.Id == null) {
            trip.Traveler__c = employee.Id;
        } else {
            // On update, verify the current employee owns this trip
            List<Trip__c> existing = [SELECT Traveler__c FROM Trip__c WHERE Id = :trip.Id LIMIT 1];
            if (existing.isEmpty() || existing[0].Traveler__c != employee.Id) {
                throw new AuraHandledException('You can only edit your own trips.');
            }
        }

        upsert trip;
        return trip.Id;
    }

    /**
     * Deletes a Trip__c record.
     * Validates that the current employee owns the trip before deleting.
     */
    @AuraEnabled
    public static void deleteTrip(Id tripId, String employeeEmail) {
        SFDC_Employee__c employee = getEmployee(employeeEmail);
        if (employee == null) {
            throw new AuraHandledException('Could not find employee record for ' + employeeEmail);
        }

        List<Trip__c> trips = [SELECT Id, Traveler__c FROM Trip__c WHERE Id = :tripId LIMIT 1];
        if (trips.isEmpty()) {
            throw new AuraHandledException('Trip not found.');
        }
        if (trips[0].Traveler__c != employee.Id) {
            throw new AuraHandledException('You can only delete your own trips.');
        }

        delete trips[0];
    }

    /**
     * Private helper — resolves email address to SFDC_Employee__c record.
     * Matches the pattern used in EmployeeFileController.
     */
    private static SFDC_Employee__c getEmployee(String employeeEmail) {
        if (String.isBlank(employeeEmail)) return null;
        List<SFDC_Employee__c> employees = [
            SELECT Id, Employee_First_Name__c, Employee_Last_Name__c,
                   Division__c, Direct_Manager_Lookup__c
            FROM SFDC_Employee__c
            WHERE Email_Address__c = :employeeEmail
            LIMIT 1
        ];
        return employees.isEmpty() ? null : employees[0];
    }
}