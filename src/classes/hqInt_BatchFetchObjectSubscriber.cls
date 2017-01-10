public class hqInt_BatchFetchObjectSubscriber implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful
{

    public hqInt_BatchFetchObjectSubscriber(integer pbatchNo) {

    }

    public Iterable<Integer> start(Database.BatchableContext BC) {

        return null;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) 
    {
        try
        {
        	hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            integer successfullyLoadedRecordsThisBatch = obj.fetchAndInsertRecords(offsetList[0],objectUrl,apiLimitParameter,lastRunDate);
            successfullyLoadedRecords += successfullyLoadedRecordsThisBatch;
		}
        catch(exception e)
        {
            hqInt_BatchErrorLogger.logError(info.getJobId(),'\n Object : '+Accounting_Subscriber__c.SObjectType.getDescribe().getLabel()+' failed at offset with limit param '+ apiLimitParameter +' : '+ string.valueOf(offsetList[0]),e.getMessage(),e.getStackTraceString());
        } 
     }

    public void finish(Database.BatchableContext info) 
    {   

    }

    public void updateMissingRelations() {
        // this method updates relation to the domain object from subscriber
        List<Accounting_Subscriber__c> subscribers = [SELECT domain__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE domain_lookup__c = ''];
        System.debug('---Subscribers with blank domain relation---' + subscribers);

        if (subscribers.size() > 0) {
            Set<String> domainNames = new Set<String>();
            for (Accounting_Subscriber__c subscriber : subscribers) {
                domainNames.add(subscriber.domain__c);
            }
            System.debug('---domainNames---' + domainNames);

            if (domainNames.size() == 0) {
                return;
            }

            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Subscriber__c subscriber : subscribers) {
                Id domainId = mapDomainNameId.get(subscriber.domain__c);
                if (domainId != null) {
                    subscriber.domain_lookup__c = domainId;
                }
            }
    
            update subscribers;
        }
    }
}