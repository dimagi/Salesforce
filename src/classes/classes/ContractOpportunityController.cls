public with sharing class ContractOpportunityController {

    private Id opportunityId;
    private Id contractId;

    public Contract_Opportunity__c coRelation { get; set; }

    public ContractOpportunityController(ApexPages.StandardController sc) {
        this.coRelation = (Contract_Opportunity__c) sc.getRecord();
        this.opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        this.contractId = ApexPages.currentPage().getParameters().get('contractId');
        this.coRelation.Opportunity__c = this.opportunityId;
        this.coRelation.Contract__c = this.contractId;
    }

    public PageReference saveNewRelation() {
        upsert this.coRelation;
        PageReference redirectPage = getReturnPage();
        return redirectPage;
    }

    public PageReference goBack() {
        return getReturnPage();
    }

    private PageReference getReturnPage() {
        PageReference redirectPage = null;
        if (this.opportunityId != null) {
            redirectPage = new ApexPages.StandardController(new Opportunity(Id = this.opportunityId)).view();
        } else if (this.contractId != null) {
            DContract__c contract = new DContract__c();
            redirectPage = new ApexPages.StandardController(new DContract__c(Id = this.contractId)).view();
        } else {
            return null;
        }
        redirectPage.setRedirect(true);

        return redirectPage;
    }
}