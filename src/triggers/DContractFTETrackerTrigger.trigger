trigger DContractFTETrackerTrigger on DContract__c (after update) {
    Set<Id> contracts = new Set<Id>();
    for (DContract__c upsertedContract : Trigger.new) {
        DContract__c oldValue = Trigger.oldMap.get(upsertedContract.Id);
        if (oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c) {
            contracts.add(upsertedContract.Id);
        }
    }
    if (contracts.size() > 0) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(contracts, Date.today().year()), 1);
        } else {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(contracts, Date.today().year()));
        }
    }
}