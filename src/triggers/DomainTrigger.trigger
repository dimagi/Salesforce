trigger DomainTrigger on Domain__c (before update) {

    if(Trigger.isBefore && Trigger.isUpdate) {
        DomainTriggerController.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

}