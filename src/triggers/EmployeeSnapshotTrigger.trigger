trigger EmployeeSnapshotTrigger on SFDC_Employee_Snapshot__c (after update) {
    EmployeeSnapshotTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}