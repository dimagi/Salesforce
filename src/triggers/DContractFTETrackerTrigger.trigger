trigger DContractFTETrackerTrigger on DContract__c (before update, after update) {
    if (Trigger.isBefore && FTETrackerHelper.loadWorkCardJobStatus().isRunning) {
        DContractTriggerController.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter) {
        DContractTriggerController.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}