/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 */
public with sharing class TimeCardTriggerController {

    public static void handleAfterInsert(List<Time_Card__c> newTimeCards) {

    }

    public static void handleAfterUpdate(List<Time_Card__c> updatedTimeCards, Map<Id, Time_Card__c> beforeUpdateTimeCards) {
        if (RecursiveTriggerHelper.hasRecursiveFlag()) {
            return;
        }

        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
        Set<Id> contractsIds = new Set<Id>();
        for (Time_Card__c tc : updatedTimeCards) {
            if (tc.FTE_Only__c != true) {
                Time_Card__c oldTC = beforeUpdateTimeCards.get(tc.Id);
                if (tc.Client__c != oldTC.Client__c) {
                    contractsIds.add(oldTC.Client__c);
                    tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = oldTC.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card with updated client
                }
            }
        }

        if (tags.size() > 0) {
            insert tags;
        }
        if (timeCardsToUpdate.size() > 0) {
            RecursiveTriggerHelper.setRecursiveFlag();
            update timeCardsToUpdate;
        }
        markContractsToRefresh(contractsIds);
    }

    public static void handleAfterDelete(List<Time_Card__c> deletedTimeCards) {
        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        Set<Id> contractsIds = new Set<Id>();
        for (Time_Card__c tc : deletedTimeCards) {
            if (tc.FTE_Only__c != true) {
                contractsIds.add(tc.Client__c);
            }
            if (tc.FTE_Contract__c != null) {
                tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = tc.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card to remove
            }
        }

        if (tags.size() > 0) {
            insert tags;
        }
        markContractsToRefresh(contractsIds);
    }

    public static void markContractsToRefresh(Set<Id> contractIds) {
        List<DContract__c> contractsToRefresh = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id IN: contractIds AND Require_Services_Spend_Refresh__c = false];
        for (DContract__c dContract : contractsToRefresh) {
            dContract.Require_Services_Spend_Refresh__c = true;
        }
        if (contractsToRefresh.size() > 0) {
            Database.SaveResult[] srList = Database.update(contractsToRefresh, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
        }
    }
}