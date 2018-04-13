/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 */
public with sharing class TimeCardTriggerController {

    public static void handleAfterInsert(Set<Id> newTimeCardsIds, List<Time_Card__c> newTimeCards) {
    }

    public static void handleAfterUpdate(List<Time_Card__c> updatedTimeCards, List<Time_Card__c> beforeUpdateTimeCards) {
    }

    public static void handleAfterDelete(List<Time_Card__c> deletedTimeCards) {
        Map<Id, Decimal> servicesSpendMap = new Map<Id, Decimal>();
        for (Time_Card__c tc : deletedTimeCards) {
            Decimal value = (tc.Total__c * (tc.Time_Card_Salary__c != null ? tc.Time_Card_Salary__c : 0) * (tc.Billing_Rate__c != null ? tc.Billing_Rate__c : 0)).setScale(8);
            System.debug('TC value : ' + value + ' removed from ' + tc.Client__r.Name + ' with parent: '
                            + tc.Client__r.Parent_Contract__c != null ? tc.Client__r.Parent_Contract__r.Name : '');
            if (servicesSpendMap.containsKey(tc.Client__c)) {
                servicesSpendMap.put(tc.Client__c, value + servicesSpendMap.get(tc.Client__c));
            } else {
                servicesSpendMap.put(tc.Client__c, value);
            }

            if (tc.Client__r.Parent_Contract__c != null) { // we must also add childs service spend to the parent object
                if (servicesSpendMap.containsKey(tc.Client__r.Parent_Contract__c)) {
                    servicesSpendMap.put(tc.Client__r.Parent_Contract__c, value + servicesSpendMap.get(tc.Client__r.Parent_Contract__c));
                } else {
                    servicesSpendMap.put(tc.Client__r.Parent_Contract__c, value);
                }
            }
        }

        updateContractServicesSpend(servicesSpendMap);
    }

    public static void updateContractServicesSpend(Map<Id, Decimal> servicesSpendMap) {
        for (DContract__c child : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Id IN: servicesSpendMap.keySet() AND Parent_Contract__c != '']) {
            if (servicesSpendMap.containsKey(child.Parent_Contract__c)) {
                servicesSpendMap.put(child.Parent_Contract__c, servicesSpendMap.get(child.Parent_Contract__c) + servicesSpendMap.get(child.Id));
            } else {
                servicesSpendMap.put(child.Parent_Contract__c, servicesSpendMap.get(child.Id));
            }
        }

        if (servicesSpendMap.size() > 0) {
            List<DContract__c> toUpdate = [SELECT Id, Require_Services_Spend_Refresh__c, Calculated_Services_Spend__c, Services_Spend__c FROM DContract__c WHERE Id IN: servicesSpendMap.keySet()];
            for (DContract__c dContract : toUpdate) {
                dContract.Require_Services_Spend_Refresh__c = true;
                dContract.Calculated_Services_Spend__c = (dContract.Calculated_Services_Spend__c != null ? dContract.Calculated_Services_Spend__c : 0) - servicesSpendMap.get(dContract.Id);
            }
            Database.update(toUpdate, false);
        }
    }
}