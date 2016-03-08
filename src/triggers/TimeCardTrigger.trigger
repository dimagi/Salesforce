trigger TimeCardTrigger on Time_Card__c (after insert, after update, after delete, after undelete) {
    
    TimeCardTriggerController tc = new TimeCardTriggerController();


    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)) {
        tc.rollUpTimeCardsTotalSpent(trigger.new);
    }
    else if (trigger.isAfter && trigger.isDelete) {
        tc.rollUpTimeCardsTotalSpent(trigger.old);
    }
}