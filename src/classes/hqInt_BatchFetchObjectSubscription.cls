public class hqInt_BatchFetchObjectSubscription implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful {

    public hqInt_BatchFetchObjectSubscription(integer pbatchNo) {

    }

    public Iterable<Integer> start(Database.BatchableContext BC) {

        return null;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
    }

    public void finish(Database.BatchableContext info) {

    }

    public void updateMissingRelations() {
        // this method updates relation to the domain object from subscriptions
        List<Accounting_Subscription__c> subscriptions = [SELECT Id, Name, Accounting_subscriber_domain__c, Accounting_Subscriber__r.domain__c FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c = '' AND Accounting_Subscriber__r.domain__c != ''];
        System.debug('---subscriptions with blank domain relation---' + subscriptions);

        if (subscriptions.size() > 0) {
            Set<String> domainNames = new Set<String>();
            for (Accounting_Subscription__c subscription : subscriptions) {
                domainNames.add(subscription.Accounting_Subscriber__r.domain__c);
            }
            System.debug('---domainNames---' + domainNames);

            if (domainNames.size() == 0) {
                return;
            }

            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Subscription__c subscription : subscriptions) {
                Id domainId = mapDomainNameId.get(subscription.Accounting_Subscriber__r.domain__c);
                if (domainId != null) {
                    subscription.Accounting_subscriber_domain__c = domainId;
                }
            }
    
            update subscriptions;
        }
    }
}