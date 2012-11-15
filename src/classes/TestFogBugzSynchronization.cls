/**
 * Tests for the FogBugz sync high level cases
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */

@isTest
public class TestFogBugzSynchronization {

    static testMethod void testOpportunityToCaseWithCaseId() {

        Opportunity o = new Opportunity(
            Name = 'Test name',
            StageName = 'Test stage',
            CloseDate = Date.today(),
            Fogbugz_Ticket_Number__c = 'Should not change'
        );
        
        insert o;
        
        Opportunity refreshed = [select Id,
                                        Fogbugz_Ticket_Number__c
                                 from Opportunity
                                 where Id = :o.Id];

        System.assertEquals('Should not change', refreshed.Fogbugz_Ticket_Number__c, 'Opportunity already had a FogBugz id and was updated');
    }

    static testMethod void testOpportunityToCaseWithoutCaseId() {

        Test.startTest();

        Opportunity o = new Opportunity(
            Name = 'Test name',
            StageName = 'Test stage',
            CloseDate = Date.today()
        );
        
        insert o;
        Test.stopTest();
        
        Opportunity refreshed = [select Id,
                                        Fogbugz_Ticket_Number__c
                                 from Opportunity
                                 where Id = :o.Id];

        System.assertEquals(TestFogBugzAPI.TEST_FB_ID, refreshed.Fogbugz_Ticket_Number__c, 'FogBugz id was not updated on Opportunity');
    }
    
    static testMethod void testFB2SFSyncExistentCase() {
    	
        Opportunity o = new Opportunity(
            Name = 'Change me',
            StageName = 'Change me',
            CloseDate = Date.today(),
            Fogbugz_Assigned_To__c = 'Change me',
            Fogbugz_Ticket_Number__c = TestFogBugzAPI.TEST_FB_ID
        );
        
        insert o;
        
        FogBugzSynchronizer synchronizer = new FogBugzSynchronizer();
        synchronizer.testMode = true;
        synchronizer.synchronize();
        
        Opportunity refreshed = [select Id,
                                        Name,
                                        StageName,
                                        Fogbugz_Ticket_Number__c,
                                        Fogbugz_Assigned_To__c,
                                        Fogbugz_Last_Updated_Date__c,
                                        Amount,
                                        Probability
                                 from Opportunity
                                 where Id = :o.Id];
                                 
        System.assertEquals('Test area', refreshed.StageName, 'Opportunity stage not updated');
        System.assertEquals('Test assignee', refreshed.Fogbugz_Assigned_To__c, 'Assignee not updated');
        System.assertEquals('Test title', refreshed.Name, 'Name not updated');
        System.assertEquals(1, refreshed.Amount, 'Amount not updated');
        System.assertEquals(1, refreshed.Probability, 'Probability not updated');
        System.assertEquals(Datetime.newInstanceGMT(2012, 1, 1, 0, 0, 0), refreshed.Fogbugz_Last_Updated_Date__c, 'FB last modified not updated');
    }
    
    static testMethod void testFB2SFSyncNotExistentCase() {
    	// We checked the update on the above test case, we'll just cover the batch job code
    	// here as there's nothing we can test
    	
    	Test.startTest();
    	FogBugzHTTPMock fakeHTTP = new FogBugzHTTPMock(TestFogBugzAPI.GET_CASES_RESPONSE);
        Test.setMock(HttpCalloutMock.class, fakeHTTP);
    	
    	FogBugzSynchronizer synchronizer = new FogBugzSynchronizer();
    	synchronizer.synchronize();
    	Test.stopTest();
    }
}