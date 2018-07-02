trigger EmployeeSnapshotTrigger on SFDC_Employee_Snapshot__c (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        EmployeeSnapshotTriggerHandler.handleAfterInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isUpdate) {
        EmployeeSnapshotTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}