public with sharing class ContractProductController {

    private Id contractId;
    public Contract_Product__c currentRecord { get; set;}

    public ContractProductController(ApexPages.StandardController sc) {
        this.contractId = ApexPages.currentPage().getParameters().get('contractId');

        this.currentRecord = (Contract_Product__c) sc.getRecord();
        this.currentRecord.Contract__c = this.contractId;
    }

    public PageReference saveNewRelation() {
        upsert this.currentRecord;
        PageReference redirectPage = getReturnPage();
        return redirectPage;
    }

    public PageReference goBack() {
        return getReturnPage();
    }

    private PageReference getReturnPage() {
        PageReference redirectPage = null;
        if (this.contractId != null) {
            redirectPage = new ApexPages.StandardController(new DContract__c(Id = this.contractId)).view();
        } else {
            return null;
        }
        redirectPage.setRedirect(true);

        return redirectPage;
    }
}