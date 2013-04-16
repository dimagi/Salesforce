/**
 * Tests the close of a FogBugz case upon Opportunity deletion
 *
 * @author  Virginia Fernández
 * @date    04/16/2013
 */

@isTest
private class OpportunityTriggersTest {

    static testMethod void deleteOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = TestFogBugzAPI.TEST_FB_ID;
        insert opp;
        
        Test.startTest();
        
        delete opp;
        
        Test.stopTest();
    }
}