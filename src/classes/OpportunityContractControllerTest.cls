/**************************************************
Class Name: OpportunityContractControllerTest
Class Description: Class for Contract creating from an Opportunity Testing and Coverage
Author: Virginia Fernández (vfernandez@adooxen.com)
Update Date: 2013-04-09
Additional Comments: 
**************************************************/
@isTest(SeeAllData=true)
private class OpportunityContractControllerTest {

    static testMethod void testNewContract() {
    	Opportunity opp = new Opportunity();
    	opp.Name = 'Test';
    	opp.StageName = 'Stage 1 - Connect';
    	opp.CloseDate = Date.newInstance(2013, 4, 9);
    	insert opp;
    	
    	Country__c country = new Country__c();
    	country.Name = 'Test';
    	insert country;
    	
    	OpportunityCountry__c oppcountry = new OpportunityCountry__c();
    	oppcountry.Country__c = country.id;
    	oppcountry.Opportunity__c = opp.id;
    	insert oppcountry;
    	
    	Product2 product = new Product2();
    	product.Name = 'Product';
    	insert product;
    	
    	Pricebook2 pb = [select id from PriceBook2 where isStandard = true limit 1];
    	
    	PricebookEntry pricebook = new PricebookEntry();
    	pricebook.Product2Id = product.id;
    	pricebook.UnitPrice = 1;
    	pricebook.Pricebook2Id = pb.Id;
    	pricebook.IsActive = true;
    	insert pricebook;
    	
    	OpportunityLineItem lineItem = new OpportunityLineItem();
    	lineItem.OpportunityId = opp.id;
    	lineItem.PricebookEntryId = pricebook.id;
    	lineItem.Quantity = 1;
    	lineItem.TotalPrice = 1;
    	insert lineItem;
    	
    	
    	ApexPages.StandardController sc = new ApexPages.standardController(opp);
    	PageReference oppPage = sc.view();
        Test.setCurrentPageReference(oppPage);
    	
        OpportunityContractController opportunityContract = new OpportunityContractController(sc);
        Test.startTest();
        
        PageReference contrPage = opportunityContract.createContract();
        
        System.debug(contrPage.getContent());
        Test.stopTest();
    }
}