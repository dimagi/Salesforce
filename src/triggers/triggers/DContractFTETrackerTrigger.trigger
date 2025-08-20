trigger DContractFTETrackerTrigger on DContract__c (before update, after update) {
    if (Trigger.isBefore && FTETrackerHelper.loadWorkCardJobStatus().isRunning) {
        for (DContract__c upsertedContract : Trigger.new) {
            DContract__c oldValue = Trigger.oldMap.get(upsertedContract.Id);
            if ((oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c)) {
                upsertedContract.addError('FTE Tracker is currently calculating Empolyee Work Cards, try update FTE Tracker field later.');
            }
        }
    } else if (Trigger.isAfter) {
        Set<Id> contracts = new Set<Id>();
        List<DContract__c> contractsTOUpdate = new List<DContract__c>();
        Boolean fteJob = FTETrackerHelper.loadWorkCardJobStatus().isRunning;

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
            if (!Test.isRunningTest()) {
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(), 1);
            } else {
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch());
            }
        }
    }
}