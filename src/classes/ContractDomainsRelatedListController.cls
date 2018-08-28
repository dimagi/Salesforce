public class ContractDomainsRelatedListController {

    public Accounting_Subscriber__c domainWrapper { get; set; }
    public DContract__c dContract { get; set; }

    public ContractDomainsRelatedListController() {
        String conId = ApexPages.currentPage().getParameters().get('contractId');
        if (conId != null) {
            this.dContract = [SELECT Id, Name FROM DContract__c WHERE Id =: conId LIMIT 1];
        }
        domainWrapper = new Accounting_Subscriber__c();
    }

    public PageReference save() {
        if (domainWrapper.domain_lookup__c == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Select domain to assign'));
            return null;
        }

        Domain__c selectedDomain = [SELECT Id, Name, Contract__c FROM Domain__c WHERE Id =: domainWrapper.domain_lookup__c];
        if (selectedDomain.Contract__c == dContract.Id) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Domain already connected with contract'));
            return null;
        }

        selectedDomain.Contract__c = dContract.Id;
        update selectedDomain;

        return new ApexPages.StandardController(dContract).view();
    }

    public PageReference cancel() {
        return new ApexPages.StandardController(dContract).view();
    }
}