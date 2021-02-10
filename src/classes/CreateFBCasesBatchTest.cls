@isTest
public class CreateFBCasesBatchTest {

    @isTest
    public static void shouldCreateCase() {
        setUpTestData();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Opportunity oppFromDB = [SELECT Id, Name, StageName, Fogbugz_Opened_By__c, Fogbugz_Probability__c, Amount, Owner.Name,
                                        IsClosed, Fogbugz_Ticket_Number__c FROM Opportunity LIMIT 1];
        System.assertEquals(null, oppFromDB.Fogbugz_Ticket_Number__c);

        Database.BatchableContext bc;
        List<Opportunity> scope = new List<Opportunity>();
        scope.add(oppFromDB);
        (new CreateFBCasesBatch().execute(bc, scope));
        Test.stopTest();

        Opportunity oppFromDBAfterUpdate = [SELECT Id, Fogbugz_Ticket_Number__c FROM Opportunity LIMIT 1];
        System.assertEquals('testFBId', oppFromDBAfterUpdate.Fogbugz_Ticket_Number__c);
    }

    private static void setUpTestData() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'CreateFBCasesBatchTest';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2015, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Opportunity_Owner_Division__c = 'Solutions';
        opp.Opportunity_Owner_Sub_Division__c='Inbound Sales';

        insert opp;
    }
}