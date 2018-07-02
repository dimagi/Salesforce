/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 */
public with sharing class TimeCardTriggerController {

    public static void handleAfterInsert(List<Time_Card__c> newTimeCards) {
        Set<Id> contractsIds = new Set<Id>();
        for (Time_Card__c tc : newTimeCards) {
            contractsIds.add(tc.Client__c);
        }
        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
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
                    contractsIds.add(tc.Client__c);
                    Time_Card__c tcToUpdate = null;

                    if (tc.FTE_Contract__c != null) {
                        tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = oldTC.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card with updated client

                        tcToUpdate = new Time_Card__c(Id = tc.Id, FTE_Contract__c = null, FTE_hours__c = 0, Need_recalculation__c = true);
                    }

                    if (tcToUpdate == null) {
                        tcToUpdate = new Time_Card__c(Id = tc.Id, Need_recalculation__c = true);
                    }
                    timeCardsToUpdate.add(tcToUpdate);
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
        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
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
        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
    }
}