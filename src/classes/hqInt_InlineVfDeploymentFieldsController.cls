public with sharing class hqInt_InlineVfDeploymentFieldsController 
{
	public Domain__c domain{get;set;}

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public hqInt_InlineVfDeploymentFieldsController(ApexPages.StandardController stdController) 
    {
        this.domain = (Domain__c)stdController.getRecord();
        domain = [SELECT id,Deployment__r.countries__c,Deployment__r.description__c,Internal_Properties__r.notes__c FROM Domain__c where id = :domain.id limit 1];
    }

    
}