@isTest
private class LeadDuplicateInfoTest {

    private static LeadDuplicateInfo.Request req(Lead l) {
        LeadDuplicateInfo.Request r = new LeadDuplicateInfo.Request();
        r.lead = l;
        return r;
    }

    @isTest
    static void describesMatchingLeads() {
        insert new Lead(
            FirstName = 'Dup', LastName = 'Match', Company = 'DupCo',
            Email = 'dupinfo.test@example.com', LeadSource = 'Outbound', Status = 'Open - Not Contacted',
            Opportunity_Owner_Division__c = 'Operations', Opportunity_Owner_Sub_Division__c = 'Ops - OoCOO'
        );

        Lead candidate = new Lead(
            FirstName = 'Dup', LastName = 'Match', Company = 'DupCo', Email = 'dupinfo.test@example.com'
        );

        Test.startTest();
        List<LeadDuplicateInfo.Result> res = LeadDuplicateInfo.describe(
            new List<LeadDuplicateInfo.Request>{ req(candidate) }
        );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'one result expected');
        System.assertNotEquals(null, res[0].duplicateInfo, 'duplicateInfo should be set');
    }

    @isTest
    static void noMatchReturnsEmpty() {
        Lead candidate = new Lead(
            FirstName = 'No', LastName = 'Match', Company = 'X',
            Email = 'nomatch.unique.dupinfo@example.com'
        );

        Test.startTest();
        List<LeadDuplicateInfo.Result> res = LeadDuplicateInfo.describe(
            new List<LeadDuplicateInfo.Request>{ req(candidate) }
        );
        Test.stopTest();

        System.assertEquals('', res[0].duplicateInfo, 'no matches -> empty string');
    }
}
