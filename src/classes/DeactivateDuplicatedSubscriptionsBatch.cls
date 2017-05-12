public class DeactivateDuplicatedSubscriptionsBatch implements Database.Stateful, Database.Batchable<Domain__c> {

    public List<Domain__c> start(Database.BatchableContext context) {
       AggregateResult[] groupedResults = [SELECT Accounting_subscriber_domain__c, COUNT(Id) FROM Accounting_Subscription__c
                        WHERE Accounting_subscriber_domain__c != null AND Accounting_subscriber_domain__c != '' AND
                        is_active__c = true GROUP BY Accounting_subscriber_domain__c HAVING COUNT(Id) > 1];

        Set<Id> domainsId = new Set<Id>();
        for (AggregateResult result : groupedResults) {
            Id domainId = (Id) result.get('Accounting_subscriber_domain__c');
            domainsId.add(domainId);
        }

        return [SELECT Id FROM Domain__c WHERE Id IN: domainsId];
    }

    public void execute(Database.BatchableContext context, List<Domain__c> domains) {
        List<Accounting_Subscription__c> subscriptionsToUpdate = new List<Accounting_Subscription__c>();
        for (Domain__c domain : domains) {
            List<Accounting_Subscription__c> domainSubsc = [SELECT Id, is_active__c, LastModifiedDate FROM Accounting_Subscription__c
                                                            WHERE is_active__c = true AND Accounting_subscriber_domain__c =: domain.Id
                                                            ORDER BY LastModifiedDate ASC];
            if (domainSubsc.size() > 1) {
                domainSubsc.remove(domainSubsc.size() - 1); // the last one is updated last time so we want
                                                            // remove it from list and update others as inactive
                for (Accounting_Subscription__c sub : domainSubsc) {
                    sub.is_active__c = false;
                }
                subscriptionsToUpdate.addAll(domainSubsc);
            }
        }

        if (subscriptionsToUpdate.size() > 0) {
            update subscriptionsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}