@isTest
private class LeadDupeBypassTest {

    // Build a Lead with the fields this org requires on Lead, plus a given email.
    private static Lead buildLead(String email) {
        return new Lead(
            FirstName = 'Test',
            LastName = 'Bypass',
            Company = 'Bypass Test Co',
            Email = email,
            LeadSource = 'Outbound',
            Status = 'Open - Not Contacted',
            Opportunity_Owner_Division__c = 'Operations',
            Opportunity_Owner_Sub_Division__c = 'Ops - OoCOO'
        );
    }

    private static LeadDupeBypass.Request req(Lead l) {
        LeadDupeBypass.Request r = new LeadDupeBypass.Request();
        r.leadToInsert = l;
        return r;
    }

    @isTest
    static void insertsLeadSuccessfully() {
        Test.startTest();
        List<LeadDupeBypass.Result> results = LeadDupeBypass.insertLeads(
            new List<LeadDupeBypass.Request>{ req(buildLead('bypass.unique@example.com')) }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'one result expected');
        System.assertEquals(true, results[0].isSuccess, 'insert should succeed');
        System.assertNotEquals(null, results[0].newLeadId, 'new Lead Id expected');
        System.assertEquals(null, results[0].errorMessage, 'no error expected');
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :results[0].newLeadId]);
    }

    @isTest
    static void bypassesDuplicateRulesOnSecondLead() {
        // Pre-existing matching Lead (same email).
        insert buildLead('bypass.dupe@example.com');

        Test.startTest();
        // Second matching Lead would normally be blocked, but the invocable inserts
        // with Database.DMLOptions.DuplicateRuleHeader.AllowSave = true.
        List<LeadDupeBypass.Result> results = LeadDupeBypass.insertLeads(
            new List<LeadDupeBypass.Request>{ req(buildLead('bypass.dupe@example.com')) }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, 'duplicate insert should be bypassed and succeed');
        System.assertNotEquals(null, results[0].newLeadId, 'new Lead Id expected after bypass');
        System.assertEquals(2, [SELECT COUNT() FROM Lead WHERE Email = 'bypass.dupe@example.com'],
            'both Leads should exist after bypass');
    }

    @isTest
    static void reportsErrorOnInvalidLead() {
        // Missing required fields (Company / divisions) -> DML fails -> error captured, not thrown.
        Lead bad = new Lead(LastName = 'NoRequiredFields');

        Test.startTest();
        List<LeadDupeBypass.Result> results = LeadDupeBypass.insertLeads(
            new List<LeadDupeBypass.Request>{ req(bad) }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess, 'invalid insert should fail');
        System.assertNotEquals(null, results[0].errorMessage, 'error message expected');
        System.assertEquals(null, results[0].newLeadId, 'no Lead Id on failure');
    }
}
