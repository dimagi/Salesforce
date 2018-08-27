public class HQSyncInlineFieldController {

    public Domain__c domain { get; set; }

    public HQSyncInlineFieldController(ApexPages.StandardController stdController)  {
        this.domain = (Domain__c) stdController.getRecord();
        this.domain = [SELECT Id, Deployment_Countries__c, Deployment_description__c, Internal_Properties__r.notes__c FROM Domain__c WHERE Id =: domain.Id LIMIT 1];
    }
}