trigger DContractFTETrackerTrigger on DContract__c (after insert, after update) {

    for (DContract__c upsertedContract : Trigger.new) {
        if (Trigger.isInsert) {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(upsertedContract.Id, Date.today().year()), 2);
        } else {
            DContract__c oldValue = Trigger.oldMap.get(upsertedContract.Id);
            if (oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c) {
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(upsertedContract.Id, Date.today().year()), 2);
            }
        }
    }
}