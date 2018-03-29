/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 * TODO : remove and create new class with name TimeCardTriggerHandler.
 */
public with sharing class TimeCardTriggerController {

    public static void handleAfterInsert(Set<Id> newTimeCardsIds, List<Time_Card__c> newTimeCards) {
        Database.executeBatch(new BatchRecalculateTimeCardCost(newTimeCardsIds), 200);
        markContractsToRefresh(newTimeCards);
    }

    public static void handleAfterUpdate(List<Time_Card__c> updatedTimeCards, List<Time_Card__c> beforeUpdateTimeCards) {
        // Services Spend calculations : Date, Total Hours and Employee in Time Card cannot be updated, such time cards will be deleted from FB side and created again.
    }

    public static void handleAfterDelete(List<Time_Card__c> deletedTimeCards) {
        markContractsToRefresh(deletedTimeCards);
        // TODO Mark contracts for recalculations
    }

    private static void markContractsToRefresh(List<Time_Card__c> changedTimeCards) {
        Set<Id> contractSet = new Set<Id>();
        for (Time_Card__c tc : changedTimeCards) {
            Id clientId = tc.Client__c;
            if (clientId != null) {
                contractSet.add(clientId);
            }
        }

        List<DContract__c> toUpdateList = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id IN: contractSet AND Require_Services_Spend_Refresh__c = false];
        for (DContract__c dContract : toUpdateList) {
            dContract.Require_Services_Spend_Refresh__c = true;
        }

        if (toUpdateList.size() > 0) {
            Database.update(toUpdateList, false); // TODO Mailer or update validation in DContract
        }
    }
}