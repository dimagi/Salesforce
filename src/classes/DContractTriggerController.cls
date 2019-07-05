public class DContractTriggerController {

    public static void handleBeforeUpdate(List<DContract__c> updated,  Map<Id, DContract__c> beforeUpdate) {
        for (DContract__c upsertedContract : updated) {
            DContract__c oldValue = beforeUpdate.get(upsertedContract.Id);
            if ((oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c)) {
                upsertedContract.addError('FTE Tracker is currently calculating Empolyee Work Cards, try update FTE Tracker field later.');
            }
        }
    }

    public static void handleAfterUpdate(List<DContract__c> updated, Map<Id, DContract__c> beforeUpdate) {
        Set<Id> contracts = new Set<Id>();
        List<DContract__c> contractsToUpdate = new List<DContract__c>();
        Boolean fteJob = FTETrackerHelper.loadWorkCardJobStatus().isRunning;

        for (DContract__c upsertedContract : updated) {
            DContract__c oldValue = beforeUpdate.get(upsertedContract.Id);
            if ((oldValue == null || oldValue.FTE_Tracker__c != upsertedContract.FTE_Tracker__c) && (upsertedContract.Skip_FTE_Tracker_Trigger__c == false)) {
                contracts.add(upsertedContract.Id);
            } else if (upsertedContract.Skip_FTE_Tracker_Trigger__c == true) { // we want skip this batch job FTE Contract is uploaded by CSV File, we want have full controll and run moving hours batch job after Generating work cards
                contractsToUpdate.add(new DContract__c(Id = upsertedContract.Id, Skip_FTE_Tracker_Trigger__c = false));
            }
        }

        if (contractsToUpdate.size() > 0) {
            update contractsToUpdate;
        }

        FTETrackerHelper.markTemplates(contracts);

        if (contracts.size() > 0) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new FTETimeAllocator(false), 1);
            }
        }
    }
}