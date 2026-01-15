/**
 * Logic for the different triggers defined on Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/13/2012
 */
public with sharing class OpportunityTriggers {

    private static final Set<String> PRODUCTS_AS_TAGS = new Set<String>{'CommCare', 'CommConnect', 'CommTrack'};

    public static void updateDomainAccountRelation(List<Opportunity> oppsNew, Map<Id, Opportunity> oldOppsMap) {
        Set<Id> oppsWithUpdatedAccount = new Set<Id>();
        Map<Id, Id> oppToAccountMap = new Map<Id, Id>();

        for (Opportunity newOpp : oppsNew) {
            Opportunity oldOpp = oldOppsMap.get(newOpp.Id);
            if (newOpp.AccountId != null && newOpp.AccountId != oldOpp.AccountId) {
                oppsWithUpdatedAccount.add(newOpp.Id);
                oppToAccountMap.put(newOpp.Id, newOpp.AccountId);
            }
        }

        if (oppsWithUpdatedAccount.size() > 0) {
            List<Domain__c> domainsToUpdate = new List<Domain__c>();
            List<Domain__c> domains = [SELECT Id, Name, Account__c, Opportunity__c FROM Domain__c WHERE Opportunity__c IN: oppsWithUpdatedAccount];
            for (Domain__c domain : domains) {
                Id accountId = oppToAccountMap.get(domain.Opportunity__c);
                if (accountId != null) {
                    domain.Account__c = accountId;
                    domainsToUpdate.add(domain);
                }
            }
            if (domainsToUpdate.size() > 0) {
                update domainsToUpdate;
            }
        }
    }
}