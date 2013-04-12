@isTest (seeAllData=true)
private class OpportunityProductTriggerTest {
	
	public static testmethod void OpportunityProductTrigger() {
		
		Pricebook2 standardPb = [select id, name, isActive from Pricebook2 where isStandard = true limit 1];
		
		Pricebook2 pb = new Pricebook2(Name='Test PB', isActive=true);
		insert pb;
		
		Product2 prod = new Product2(Name='Test Product', ProductCode='TEST', isActive=true);
		insert prod;
		
		PricebookEntry pbe = new PricebookEntry(Product2ID=prod.Id, Pricebook2Id=standardPb.id, UnitPrice=50, isActive=true);
		insert pbe;
		
		Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=date.today(), StageName='Stage 1 - Connecting');
		insert opp;
		
		OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=pbe.Id, Quantity=1, totalPrice=50 );
		insert oli;
		
		OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=pbe.Id, Quantity=1, totalPrice=50 );
        insert oli2;
	}	
	
}