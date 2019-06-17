/**
 * Tests for Opportunity Triggers
 */
@isTest
private class OpportunityTriggersTest {

    @isTest
    public static void shouldUpdateAccountRelationInTheDomainObjectBulk() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit;
        Account acc1 = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc1;
        Account acc2 = new Account(Name = 'Acc 2 Test', Status__c = 'Active');
        insert acc2;
        Account acc3 = new Account(Name = 'Acc 3 Test', Status__c = 'Active');
        insert acc3;
        Opportunity opp1 = new Opportunity(Name = 'opp1', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc1.Id);
        insert opp1;
        Opportunity opp2 = new Opportunity(Name = 'opp2', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc2.Id);
        insert opp2;
        Opportunity opp3 = new Opportunity(Name = 'opp3', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc3.Id);
        insert opp3;

        HQSyncDomainModel.DomainModel d1 = new HQSyncDomainModel.DomainModel();
        d1.x_id = 'sample_external_id_1';
        d1.Name = 'd1';
        d1.tags = new List<String> { ' ' };
        Domain__c domainFromDb1 = d1.createDbObject('CommCare HQ', null);
        domainFromDb1.Opportunity__c = opp1.Id;
        insert domainFromDb1;
        HQSyncDomainModel.DomainModel d2 = new HQSyncDomainModel.DomainModel();
        d2.x_id = 'sample_external_id_2';
        d2.Name = 'd2';
        d2.tags = new List<String> { ' ' };
        Domain__c domainFromDb2 = d2.createDbObject('CommCare HQ', null);
        domainFromDb2.Account__c = acc2.Id;
        domainFromDb2.Opportunity__c = opp2.Id;
        insert domainFromDb2;
        HQSyncDomainModel.DomainModel d3 = new HQSyncDomainModel.DomainModel();
        d3.x_id = 'sample_external_id_3';
        d3.Name = 'd3';
        d3.tags = new List<String> { ' ' };
        Domain__c domainFromDb3 = d3.createDbObject('CommCare HQ', null);
        domainFromDb3.Account__c = acc3.Id;
        domainFromDb3.Opportunity__c = opp3.Id;
        insert domainFromDb3;

        Test.startTest();

        List<Opportunity> opps = new List<Opportunity>();
        opp1.AccountId = acc2.Id;
        opp2.AccountId = acc3.Id;
        opp3.AccountId = null;
        opps.add(opp1);
        opps.add(opp2);
        opps.add(opp3);
        update opps;

        Test.stopTest();

        Domain__c assertDomain = [SELECT Id, Account__c FROM Domain__c WHERE Id =: domainFromDb1.Id];
        System.assertEquals(acc2.Id, assertDomain.Account__c);
        assertDomain = [SELECT Id, Account__c FROM Domain__c WHERE Id =: domainFromDb2.Id];
        System.assertEquals(acc3.Id, assertDomain.Account__c);
        assertDomain = [SELECT Id, Account__c FROM Domain__c WHERE Id =: domainFromDb3.Id];
        System.assertEquals(acc3.Id, assertDomain.Account__c);
    }

    @isTest
    public static void shouldUpdateAccountRelationInTheDomainObjectSingle() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit;
        Account acc1 = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc1;
        Account acc2 = new Account(Name = 'Acc 2 Test', Status__c = 'Active');
        insert acc2;
        Opportunity opp1 = new Opportunity(Name = 'opp1', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc1.Id);
        insert opp1;
        Opportunity opp2 = new Opportunity(Name = 'opp2', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc2.Id);
        insert opp2;

        HQSyncDomainModel.DomainModel d1 = new HQSyncDomainModel.DomainModel();
        d1.x_id = 'sample_external_id_1';
        d1.Name = 'd1';
        d1.tags = new List<String> { ' ' };
        Domain__c domainFromDb1 = d1.createDbObject('CommCare HQ', null);
        domainFromDb1.Opportunity__c = opp1.Id;
        insert domainFromDb1;

        Test.startTest();

        opp1.AccountId = acc2.Id;
        update opp1;

        Test.stopTest();

        Domain__c assertDomain = [SELECT Id, Account__c FROM Domain__c WHERE Id =: domainFromDb1.Id];
        System.assertEquals(acc2.Id, assertDomain.Account__c);
    }

    @isTest
    public static void deleteOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID;
        insert opp;

        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        delete opp;
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Opportunity].size());
    }

    @isTest
    public static void updateOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID;
        insert opp;

        Test.startTest();

        opp.Name = 'Test 2';
        update opp;
        opp.StageName = 'Stage 2 - Talking';
        update opp;

        Test.stopTest();
    }

    @isTest
    public static void updateProbabilityOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID;
        opp.Amount = 10;
        insert opp;

        Test.startTest();
        opp.Fogbugz_Probability__c = 10;
        update opp;
        Test.stopTest();
    }

    @isTest
    public static void closeOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Stage 1 - Connect';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID;
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed';
        update opp;
        opp.StageName = 'Stage 1 - Connect';
        update opp;
        Test.stopTest();
    }

    @isTest
    public static void newClosedOpportunityTest() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Closed';
        opp.CloseDate = Date.newInstance(2013, 4, 9);
        opp.Implementing_Business_Unit__c = bunit.Id;
        opp.Fogbugz_Ticket_Number__c = FogBugzHttpCalloutMock.TEST_FB_ID;

        Test.startTest();
        insert opp;
        Test.stopTest();
    }
}