/**
 * Tests the updates of the Country_Text__c field in Opportunity with the names of the Opportunity Countries
 *
 * @author  Virginia Fernández
 * @date    04/12/2013
 */
@isTest
private class OpportunityCountryTriggerTest {

    static testMethod void newOpportunityCountryTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        insert opp;
        
        Country__c country1 = new Country__c();
        country1.Name = 'Country1';
        insert country1;
        
        Country__c country2 = new Country__c();
        country2.Name = 'Country2';
        insert country2;
        
        Test.startTest();
        
        OpportunityCountry__c oppCountry1 = new OpportunityCountry__c();
        oppCountry1.Country__c = country1.Id;
        oppCountry1.Opportunity__c = opp.Id;
        insert oppCountry1;
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country1');
        
        OpportunityCountry__c oppCountry2 = new OpportunityCountry__c();
        oppCountry2.Country__c = country2.Id;
        oppCountry2.Opportunity__c = opp.Id;
        insert oppCountry2;
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country2; Country1');
        
        Test.stopTest();
        
    }
    
    static testMethod void deleteOpportunityCountryTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        insert opp;
        
        Country__c country1 = new Country__c();
        country1.Name = 'Country1';
        insert country1;
        
        Country__c country2 = new Country__c();
        country2.Name = 'Country2';
        insert country2;
        
        OpportunityCountry__c oppCountry1 = new OpportunityCountry__c();
        oppCountry1.Country__c = country1.Id;
        oppCountry1.Opportunity__c = opp.Id;
        insert oppCountry1;
        
        OpportunityCountry__c oppCountry2 = new OpportunityCountry__c();
        oppCountry2.Country__c = country2.Id;
        oppCountry2.Opportunity__c = opp.Id;
        insert oppCountry2;
        
        Test.startTest();
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country2; Country1');
        
        delete oppCountry2;
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country1');
        
        Test.stopTest();
        
    }
    
    static testMethod void updateOpportunityCountryTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        insert opp;
        
        Country__c country1 = new Country__c();
        country1.Name = 'Country1';
        insert country1;
        
        Country__c country2 = new Country__c();
        country2.Name = 'Country2';
        insert country2;
        
        OpportunityCountry__c oppCountry1 = new OpportunityCountry__c();
        oppCountry1.Country__c = country1.Id;
        oppCountry1.Opportunity__c = opp.Id;
        insert oppCountry1;
        
        Test.startTest();
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country1');
        
        oppCountry1.Country__c = country2.Id;
        TriggerContext.runTrigger = true;
        update oppCountry1;
        
        opp = [select Id, Country_Text__c from Opportunity where id =: opp.Id];
        System.assertEquals(opp.Country_Text__c, 'Country2');
        
        Test.stopTest();
        
    }
}