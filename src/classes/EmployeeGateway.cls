public class EmployeeGateway {

    public static Map<Id, String> getEmployeeBusinessUnitNames(Set<Id> employeeRecordIds) {
        Map<Id, String> businessUnitNames = new Map<Id, String>();
        for(SFDC_Employee__c emp : [SELECT Id, Business_Unit__c, Business_Unit__r.Name
                                    FROM SFDC_Employee__c
                                    WHERE Id IN: employeeRecordIds AND Business_Unit__c != null]) {
            businessUnitNames.put(emp.Business_Unit__c, emp.Business_Unit__r.Name);
        }
        return businessUnitNames;
    }

    public static void setUsersOnEmployees(Map<String, SFDC_Employee__c> employeesByEmail) {
        for(User u : [SELECT Id, Username FROM User WHERE Username IN: employeesByEmail.keySet()]) {
            employeesByEmail.get(u.Username).SF_User__c = u.Id;
        }
    }
}