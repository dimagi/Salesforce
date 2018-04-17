public class EmployeeSnapshotTriggerHandler {

    public static void handleAfterUpdate(List<SFDC_Employee_Snapshot__c> updatedSnapshots, Map<Id, SFDC_Employee_Snapshot__c> oldSnapshots) {
        List<SFDC_Employee_Snapshot__c> updatedSalary = new List<SFDC_Employee_Snapshot__c>();
        for (SFDC_Employee_Snapshot__c emplSnp : updatedSnapshots) {
            SFDC_Employee_Snapshot__c oldSnp = oldSnapshots.get(emplSnp.Id);
            if (oldSnp.Per_Week_Hours__c != emplSnp.Per_Week_Hours__c
                    || oldSnp.Salary__c != emplSnp.Salary__c
                    || oldSnp.Exchange_Rate__c != emplSnp.Exchange_Rate__c) {
                updatedSalary.add(new SFDC_Employee_Snapshot__c(Id = emplSnp.Id, Salary_Updated__c = true));
            }
        }
        if (updatedSalary.size() > 0) {
            update updatedSalary;
        }
    }
}