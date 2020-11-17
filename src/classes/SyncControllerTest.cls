@IsTest
public class SyncControllerTest {

    @testSetup
    public static void setupSettings() {
        FogBugz_Settings__c settings = FogBugz_Settings__c.getOrgDefaults();
        settings.Sync_Filter__c = 1;
        settings.Token__c = 'test';
        settings.Sync_Script_Running__c = false;
        settings.Default_Opportunity_Owner__c = 'do@not.exist';
        settings.FB_URL__c = 'https://manage.dimagi.com/api.asp?';
        upsert settings;
    }

    @isTest
    public static void testSingleSyncRun() {
        Opportunity opp = buildOpp();
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        SyncController syncCtrl = new SyncController(sc);
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        syncCtrl.runSingleSync();
        Test.stopTest();

        System.assertNotEquals(null, syncCtrl.goBack());
        Opportunity refreshed = [SELECT Id, Name, StageName, Fogbugz_Ticket_Number__c, Fogbugz_Assigned_To__c, Fogbugz_Last_Updated_Date__c, Amount,
                                        Probability, Fogbugz_Probability__c, Fogbugz_elapsed_time__c FROM Opportunity WHERE Id =: opp.Id];
        assertCaseData(refreshed);
    }

    @isTest
    public static void testSyncRun() {
        Opportunity opp = buildOpp();
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        SyncController syncCtrl = new SyncController(sc);
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        syncCtrl.runSync();
        Test.stopTest();

        Opportunity refreshed = [SELECT Id, Name, StageName, Fogbugz_Ticket_Number__c, Fogbugz_Assigned_To__c, Fogbugz_Last_Updated_Date__c, Amount,
                                        Probability, Fogbugz_Probability__c, Fogbugz_elapsed_time__c FROM Opportunity WHERE Id =: opp.Id];
        assertCaseData(refreshed);
    }

    private static Opportunity buildOpp() {
        Opportunity opp = new Opportunity(Name = 'Change me',
                                          StageName = 'Change me',
                                          CloseDate = Date.today(),
                                          Fogbugz_Assigned_To__c = 'Change me',
                                          Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID,
                                          Opportunity_Owner_Division__c = 'Solutions',
                                          Opportunity_Owner_Sub_Division__c='Inbound Sales');
        insert opp;
        return opp;
    }

    private static void assertCaseData(Opportunity testOpp) {
        System.assertEquals('Test area', testOpp.StageName, 'Opportunity stage not updated');
        System.assertEquals('Test assignee', testOpp.Fogbugz_Assigned_To__c, 'Assignee not updated');
        System.assertEquals('Test title', testOpp.Name, 'Name not updated');
        System.assertEquals(41.7327995300293, testOpp.Fogbugz_elapsed_time__c, 'Fogbugz_elapsed_time__c wasn\'t updated');
        System.assertEquals(Datetime.newInstanceGMT(2012, 1, 1, 0, 0, 0), testOpp.Fogbugz_Last_Updated_Date__c, 'FB last modified not updated');
    }
}