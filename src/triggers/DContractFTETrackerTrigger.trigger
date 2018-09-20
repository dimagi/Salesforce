trigger DContractFTETrackerTrigger on DContract__c (after update) {
    Set<Id> contracts = new Set<Id>();
    List<DContract__c> contractsTOUpdate = new List<DContract__c>();

    for (DContract__c upsertedContract : Trigger.new) {
        DContract__c oldValue = Trigger.oldMap.get(upsertedContract.Id);
        if ((oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c) && (upsertedContract.Skip_FTE_Tracker_Trigger__c == false)) {
            contracts.add(upsertedContract.Id);
        } else if (upsertedContract.Skip_FTE_Tracker_Trigger__c == true) { // we want skip this batch job FTE Contract is uploaded by CSV File, we want have full controll and run moving hours batch job after Generating work cards
            contractsTOUpdate.add(new DContract__c(Id = upsertedContract.Id, Skip_FTE_Tracker_Trigger__c = false));
        }
    }

    if (contractsTOUpdate.size() > 0) {
        update contractsTOUpdate;
    }

    if (contracts.size() > 0) {
        Integer yearValue = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue()
                                : Date.today().year();
        if (!Test.isRunningTest()) {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(new Set<Id>(), contracts, yearValue), 1);
        } else {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(new Set<Id>(), contracts, yearValue));
        }
    }
}