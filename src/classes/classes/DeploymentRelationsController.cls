public with sharing class DeploymentRelationsController {

    private Id deploymentId;
    public SObject currentRecord { get; set;}

    public DeploymentRelationsController(ApexPages.StandardController sc) {
        this.deploymentId = ApexPages.currentPage().getParameters().get('deploymentId');

        this.currentRecord = sc.getRecord();
        this.currentRecord.put('Project__c', this.deploymentId);
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
        if (this.deploymentId != null) {
            redirectPage = new ApexPages.StandardController(new Project__c(Id = this.deploymentId)).view();
        } else {
            return null;
        }
        redirectPage.setRedirect(true);

        return redirectPage;
    }
}