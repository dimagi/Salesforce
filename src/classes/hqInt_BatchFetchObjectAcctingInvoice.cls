public class hqInt_BatchFetchObjectAcctingInvoice implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful {

    public integer batchNo;

    public hqInt_BatchFetchObjectAcctingInvoice(integer pbatchNo) {
        batchNo = pbatchNo;
    }

    public Iterable<Integer> start(Database.BatchableContext BC)  {
        return null;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList)  {

     }

    public void finish(Database.BatchableContext info) {

    }

    public void updateMissingRelations() {
        // this method updates relation to the domain object from accounting invoice
        List<Accounting_Invoice__c> accountingInvoice = [SELECT id__c, Accounting_Subscription__r.Accounting_Subscriber__r.domain__c, Project_Space__c
                                                         FROM Accounting_Invoice__c WHERE Project_Space__c = ''];
        List<Accounting_Invoice__c> accountingInvoiceToUpdate = new List<Accounting_Invoice__c>();
        System.debug('---Accounting Invoice with blank domain relation link---' + accountingInvoice);
        if (accountingInvoice.size() == 0) {
        	return;
        }
        
        Set<String> domainNames = new Set<String>();
        for(Accounting_Invoice__c ac : accountingInvoice) {
            if (ac.Accounting_Subscription__r != null && ac.Accounting_Subscription__r.Accounting_Subscriber__r != null) {
                domainNames.add(ac.Accounting_Subscription__r.Accounting_Subscriber__r.domain__c);
                accountingInvoiceToUpdate.add(ac);
            }
        }
        
        System.debug('---domainNames---' + domainNames);

        if (domainNames.size() > 0) {
            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Invoice__c ac : accountingInvoiceToUpdate) {
            	Id domainId = mapDomainNameId.get(ac.Accounting_Subscription__r.Accounting_Subscriber__r.domain__c);
                if (domainId != null) {
                    ac.Project_Space__c = domainId;
                }
            }

            update accountingInvoiceToUpdate;
        }
    } 
}