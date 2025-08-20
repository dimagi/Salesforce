@isTest
public class TestFogBugzSynchronization {

    private static void setupSettings() {
        FogBugz_Settings__c settings = FogBugz_Settings__c.getOrgDefaults();
        settings.Sync_Filter__c = 1;
        settings.Token__c = 'test';
        settings.Sync_Script_Running__c = false;
        settings.Default_Opportunity_Owner__c = 'do@not.exist';
        settings.FB_URL__c = 'https://manage.dimagi.com/api.asp?';
        upsert settings;
    }

    @isTest
    public static void testOpportunityToCaseWithCaseId() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Opportunity o = new Opportunity(
            Name = 'Test name',
            StageName = 'Test stage',
            CloseDate = Date.today(),
            Fogbugz_Ticket_Number__c = 'Should not change',
            Opportunity_Owner_Division__c = 'Solutions',
            Opportunity_Owner_Sub_Division__c='Inbound Sales'
        );
        insert o;
        Test.stopTest();
        Opportunity refreshed = [SELECT Id, Fogbugz_Ticket_Number__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Should not change', refreshed.Fogbugz_Ticket_Number__c, 'Opportunity already had a FogBugz id and was updated');
    }

    @isTest
    public static void testOpportunityToCaseWithoutCaseId() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Opportunity o = createTestOpportunity(null);
        Test.stopTest();

        Opportunity refreshed = [SELECT Id, Fogbugz_Ticket_Number__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(FogBugzHttpCalloutMock.TEST_FB_ID, refreshed.Fogbugz_Ticket_Number__c, 'FogBugz id was not updated on Opportunity');
    }

    @isTest
    public static void testFB2SFSyncExistentCase() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Opportunity o = createTestOpportunity(FogBugzHttpCalloutMock.TEST_FB_ID);
        Database.executeBatch(new FogBugzSynchronizerBatch(1, true), 1);
        Test.stopTest();

        Opportunity refreshed = [SELECT Id, Name, StageName, Fogbugz_Ticket_Number__c, Fogbugz_Assigned_To__c, Fogbugz_Last_Updated_Date__c, Amount,
                                        Probability, Fogbugz_Probability__c, Fogbugz_elapsed_time__c FROM Opportunity WHERE Id = :o.Id];

        System.assertEquals('Test area', refreshed.StageName, 'Opportunity stage not updated');
        System.assertEquals('Test assignee', refreshed.Fogbugz_Assigned_To__c, 'Assignee not updated');
        System.assertEquals('Test title', refreshed.Name, 'Name not updated');
        System.assertEquals(41.7327995300293, refreshed.Fogbugz_elapsed_time__c, 'Fogbugz_elapsed_time__c wasn\'t updated');
        System.assertEquals(Datetime.newInstanceGMT(2012, 1, 1, 0, 0, 0), refreshed.Fogbugz_Last_Updated_Date__c, 'FB last modified not updated');
    }

    @isTest
    public static void testFB2SFSyncNotExistentCase() {
        setupSettings();
        // We checked the update on the above test case, we'll just cover the batch job code
        // here as there's nothing we can test
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Database.executeBatch(new FogBugzSynchronizerBatch(1, true), 1);
        Test.stopTest();
    }

    @isTest
    public static void testFB2SFSyncNote() {
        setupSettings();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Opportunity o = createTestOpportunity(FogBugzHttpCalloutMock.TEST_FB_ID);

        Task t = new Task(Description = 'Test',
                          Priority = 'Normal',
                          Status = 'Test',
                          WhatId = o.Id,
                          Subject = 'Email: Test subject');
        insert t;
        Test.stopTest();
    }

    public static Opportunity createTestOpportunity(String fbCaseId) {
        setupSettings();
        Opportunity o = new Opportunity(
            Name = 'Change me',
            StageName = 'Change me',
            CloseDate = Date.today(),
            Fogbugz_Assigned_To__c = 'Change me',
            Fogbugz_Ticket_Number__c = fbCaseId,
            Opportunity_Owner_Division__c = 'Solutions',
            Opportunity_Owner_Sub_Division__c='Inbound Sales'
        );
        insert o;
        return o;
    }
}