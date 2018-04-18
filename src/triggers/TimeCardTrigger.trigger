/**
 * Time Card trigger, used for recalculations cost and billing rates. Handles updates for FTE Tracker.
 */
trigger TimeCardTrigger on Time_Card__c (after insert, after update, after delete) {
    if(Trigger.isAfter && Trigger.isInsert) {
        TimeCardTriggerController.handleAfterInsert(Trigger.newMap.keySet(), Trigger.new);
    } else if(Trigger.isAfter && Trigger.isUpdate) {
        TimeCardTriggerController.handleAfterUpdate(Trigger.new, Trigger.old);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        TimeCardTriggerController.handleAfterDelete(Trigger.old);
    }
}