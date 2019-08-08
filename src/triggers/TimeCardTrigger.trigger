/**
 * Time Card trigger, used for recalculations cost and billing rates. Handles updates for FTE Tracker.
 */
trigger TimeCardTrigger on Time_Card__c (before insert, after insert, after update, after delete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TimeCardTriggerController.handleBeforeInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isInsert) {
        TimeCardTriggerController.handleAfterInsert(Trigger.new);
    } else if(Trigger.isAfter && Trigger.isUpdate) {
        TimeCardTriggerController.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        TimeCardTriggerController.handleAfterDelete(Trigger.old);
    }
}