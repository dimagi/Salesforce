/**
 * Controller for the TravelComponent Visualforce component.
 * Uses @RemoteAction (JavaScript Remoting) instead of @AuraEnabled so it works
 * from the Salesforce Sites context (salesforce-sites.com) without Lightning Out.
 *
 * Business logic mirrors TravelPortalController exactly.
 */
public class TravelComponentController {

    public String employeeEmail { get; set; }
    public DimagiToolsController pageController { get; set; }

    @RemoteAction
    public static List<Trip__c> getTrips(String viewType, String employeeEmail) {
        SFDC_Employee__c employee = getEmployee(employeeEmail);
        if (employee == null) return new List<Trip__c>();

        if (viewType == 'mine') {
            return [
                SELECT Id, Name, Traveler__c, Traveler__r.Name,
                       Traveler__r.Employee_First_Name__c,
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
                SELECT Id, Name, Traveler__c, Traveler__r.Name,
                       Traveler__r.Employee_First_Name__c,
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

    @RemoteAction
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
     * Saves (upserts) a Trip__c. Trip data is passed as a JSON string because
     * @RemoteAction does not support SObject parameters directly.
     * Returns the saved record Id as a String.
     */
    @RemoteAction
    public static String saveTrip(String tripJson, String employeeEmail) {
        SFDC_Employee__c employee = getEmployee(employeeEmail);
        if (employee == null) {
            throw new AuraHandledException('Could not find employee record for ' + employeeEmail);
        }

        Trip__c trip = (Trip__c) JSON.deserialize(tripJson, Trip__c.class);

        if (trip.Return_Date__c != null && trip.Departure_Date__c != null
                && trip.Return_Date__c < trip.Departure_Date__c) {
            throw new AuraHandledException('Return date must be on or after departure date.');
        }

        if (trip.Id == null) {
            trip.Traveler__c = employee.Id;
        } else {
            List<Trip__c> existing = [SELECT Traveler__c FROM Trip__c WHERE Id = :trip.Id LIMIT 1];
            if (existing.isEmpty() || existing[0].Traveler__c != employee.Id) {
                throw new AuraHandledException('You can only edit your own trips.');
            }
        }

        upsert trip;
        return trip.Id;
    }

    @RemoteAction
    public static void deleteTrip(String tripId, String employeeEmail) {
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

    @RemoteAction
    public static String getEmployeeId(String employeeEmail) {
        SFDC_Employee__c emp = getEmployee(employeeEmail);
        return emp != null ? emp.Id : null;
    }

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
