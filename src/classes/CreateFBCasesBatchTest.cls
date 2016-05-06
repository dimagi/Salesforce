@isTest
private class CreateFBCasesBatchTest {

    static testMethod void shouldCreateCase() {
        FogBugzHTTPMock fakeHTTP = new FogBugzHTTPMock(TestFogBugzAPI.UPSERT_CASE_RESPONSE);
        Test.setMock(HttpCalloutMock.class, fakeHTTP);

        FogBugzAPI api = new FogBugzAPI();

        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'CreateFBCasesBatchTest';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2015, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;

        insert opp;

        Opportunity oppFromDB = [SELECT Id, Fogbugz_Ticket_Number__c FROM Opportunity WHERE Id =: opp.Id];
        System.assertEquals(null, oppFromDB.Fogbugz_Ticket_Number__c);

        Test.startTest();
        Database.executeBatch(new CreateFBCasesBatch(), 50);
        Test.stopTest();

        oppFromDB = [SELECT Id, Fogbugz_Ticket_Number__c FROM Opportunity WHERE Id =: opp.Id];
        System.assertEquals('testFBId', oppFromDB.Fogbugz_Ticket_Number__c);
    }
}