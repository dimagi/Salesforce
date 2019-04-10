/**
 * Updates Life Time MRR in the Domain custom objects, data taken from Subscriptions formula field.
 */
public class CalculateDomainsLifeTimeMRRBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
       return Database.getQueryLocator('SELECT Id, Lifetime_MRR__c FROM Domain__c');
    }

    public void execute(Database.BatchableContext context, List<SObject> domains) {
        Map<Id, Decimal> domainsLifetimeMRRs = new Map<Id, Decimal>();

        // Calculation Lifetime MRR for domain
        for (Accounting_Subscription__c subscription : [SELECT Lifetime_MRR__c, Accounting_subscriber_domain__c FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c IN: domains]) {
            if (subscription.Lifetime_MRR__c != null) {
                if (domainsLifetimeMRRs.containsKey(subscription.Accounting_subscriber_domain__c)) {
                    Decimal lifetimeMRR = domainsLifetimeMRRs.get(subscription.Accounting_subscriber_domain__c);
                    lifetimeMRR += subscription.Lifetime_MRR__c;
                    domainsLifetimeMRRs.put(subscription.Accounting_subscriber_domain__c, lifetimeMRR);
                } else {
                    domainsLifetimeMRRs.put(subscription.Accounting_subscriber_domain__c, subscription.Lifetime_MRR__c);
                }
            }
        }

        // Set Lifetime MRR for domain
        List<Domain__c> toUpdate = new LIst<Domain__c>();
        for (SObject sObjDomain : domains) {
            Domain__c d = (Domain__c) sObjDomain;
            Decimal lifetimeMRR = domainsLifetimeMRRs.get(d.Id);
            if (lifetimeMRR == null) {
                lifetimeMRR = 0;
            }
            d.Lifetime_MRR__c = lifetimeMRR;
            toUpdate.add(d);
        }

        update toUpdate;
    }

    public void finish(Database.BatchableContext context) {
        Database.executeBatch(new DeactivateDuplicatedSubscriptionsBatch(), 4);
    }
}