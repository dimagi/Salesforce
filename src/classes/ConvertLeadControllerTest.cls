@isTest
public class ConvertLeadControllerTest {

    @TestSetup
    static void setup() {
        insert new Business_Unit__c(Name = 'Inc');
    }

    // ── helpers ────────────────────────────────────────────────────────────────

    static Lead makeTestLead(String company) {
        return new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = company,
            Email = 'test@example.com',
            Status = 'Open - Not Contacted',
            Lead_Status_Reason__c = 'Personal Outreach',
            Opportunity_Owner_Division__c = 'CommCare',
            Opportunity_Owner_Sub_Division__c = 'CommCare Sales'
        );
    }

    // ── ConvertLeadController ──────────────────────────────────────────────────

    @isTest
    static void testConvertWithOpportunity() {
        Lead testLead = makeTestLead('OpportunityTest Co');
        insert testLead;

        Test.startTest();
        ConvertLeadController.ConvertResult result = ConvertLeadController.convertLead(
            testLead.Id,
            'With Opportunity',
            'Great fit, moving forward.',
            null,
            null,
            null,
            null,
            'OpportunityTest Co - Deal',
            '1- Working - Active Opp Development',
            false
        );
        Test.stopTest();

        System.assert(result.success, 'Conversion failed: ' + result.errorMessage);
        System.assertNotEquals(null, result.opportunityId, 'Opportunity should be created');
        System.assertNotEquals(null, result.contactId, 'Contact should be created');

        Lead updatedLead = [SELECT Status, Conversion_Outcome__c, Disposition_Notes__c, Lead_Stage_at_Exit__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Converted', updatedLead.Status);
        System.assertEquals('With Opportunity', updatedLead.Conversion_Outcome__c);
        System.assertEquals('Great fit, moving forward.', updatedLead.Disposition_Notes__c);
        System.assertEquals('Open - Not Contacted', updatedLead.Lead_Stage_at_Exit__c);

        Opportunity opp = [SELECT StageName, Probability FROM Opportunity WHERE Id = :result.opportunityId];
        System.assertEquals('Stage 4 - Proposal Development', opp.StageName);
        System.assertEquals(20, opp.Probability);

        Contact con = [SELECT Status__c, GSP_Primary_Contact__c, Last_Lead_Outcome__c,
                              Last_Lead_Context__c, Follow_up_Date__c,
                              Last_Lead_Re_engagement_Pathway__c, Last_Lead_Date__c, Lead_Cycle_Count__c
                       FROM Contact WHERE Id = :result.contactId];
        System.assertEquals('1- Working - Active Opp Development', con.Status__c);
        System.assertEquals(false, con.GSP_Primary_Contact__c);
        System.assertEquals('With Opportunity', con.Last_Lead_Outcome__c);
        System.assertEquals('Great fit, moving forward.', con.Last_Lead_Context__c);
        System.assertEquals(null, con.Follow_up_Date__c);
        System.assertEquals(null, con.Last_Lead_Re_engagement_Pathway__c);
        System.assertEquals(Date.today(), con.Last_Lead_Date__c);
        System.assertEquals(1, con.Lead_Cycle_Count__c);
    }

    @isTest
    static void testConvertContactOnlyNurture() {
        Lead testLead = makeTestLead('NurtureTest Co');
        insert testLead;

        Test.startTest();
        ConvertLeadController.ConvertResult result = ConvertLeadController.convertLead(
            testLead.Id,
            'Contact Only - Passive',
            'Good relationship, no immediate opportunity.',
            'Scheduled Follow-up',
            Date.today().addMonths(3),
            null,
            null,
            null,
            '1- Working - Active Opp Development',
            false
        );
        Test.stopTest();

        System.assert(result.success, 'Conversion failed: ' + result.errorMessage);
        System.assertEquals(null, result.opportunityId, 'No opportunity should be created');
        System.assertNotEquals(null, result.contactId, 'Contact should be created');

        Lead updatedLead = [SELECT Conversion_Outcome__c, Re_engagement_Pathway__c, Re_engage_Date__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Contact Only - Passive', updatedLead.Conversion_Outcome__c);
        System.assertEquals('Scheduled Follow-up', updatedLead.Re_engagement_Pathway__c);
        System.assertEquals(Date.today().addMonths(3), updatedLead.Re_engage_Date__c);

        Contact con = [SELECT Last_Lead_Outcome__c, Last_Lead_Context__c, Follow_up_Date__c,
                              Last_Lead_Re_engagement_Pathway__c, Last_Lead_Date__c, Lead_Cycle_Count__c
                       FROM Contact WHERE Id = :result.contactId];
        System.assertEquals('Contact Only - Passive', con.Last_Lead_Outcome__c);
        System.assertEquals('Good relationship, no immediate opportunity.', con.Last_Lead_Context__c);
        System.assertEquals(Date.today().addMonths(3), con.Follow_up_Date__c);
        System.assertEquals('Scheduled Follow-up', con.Last_Lead_Re_engagement_Pathway__c);
        System.assertEquals(Date.today(), con.Last_Lead_Date__c);
        System.assertEquals(1, con.Lead_Cycle_Count__c);
    }

    @isTest
    static void testConvertWithExistingAccount() {
        Account existingAccount = new Account(Name = 'Existing Account Corp');
        insert existingAccount;
        Lead testLead = makeTestLead('Existing Account Corp');
        insert testLead;

        Test.startTest();
        ConvertLeadController.ConvertResult result = ConvertLeadController.convertLead(
            testLead.Id,
            'With Opportunity',
            null,
            null,
            null,
            existingAccount.Id,
            null,
            'Existing Account Corp - Deal',
            '1- Working - Active Opp Development',
            false
        );
        Test.stopTest();

        System.assert(result.success, 'Conversion failed: ' + result.errorMessage);
        System.assertEquals(existingAccount.Id, result.accountId, 'Should use the existing account');
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Name = 'Existing Account Corp'], 'No duplicate account should be created');
    }

    @isTest
    static void testConvertWithExistingContact() {
        Account acc = new Account(Name = 'Contact Match Co');
        insert acc;
        Contact existingContact = new Contact(FirstName = 'Test', LastName = 'Lead', AccountId = acc.Id, Email = 'existing@example.com');
        insert existingContact;
        Lead testLead = makeTestLead('Contact Match Co');
        insert testLead;

        Test.startTest();
        ConvertLeadController.ConvertResult result = ConvertLeadController.convertLead(
            testLead.Id,
            'Contact Only - Nurture',
            null,
            'Passive',
            null,
            acc.Id,
            existingContact.Id,
            null,
            '1- Working - Active Opp Development',
            true
        );
        Test.stopTest();

        System.assert(result.success, 'Conversion failed: ' + result.errorMessage);
        System.assertEquals(existingContact.Id, result.contactId, 'Should use the existing contact');

        Contact con = [SELECT Last_Lead_Outcome__c, Last_Lead_Date__c, Lead_Cycle_Count__c, GSP_Primary_Contact__c
                       FROM Contact WHERE Id = :result.contactId];
        System.assertEquals('Contact Only - Nurture', con.Last_Lead_Outcome__c);
        System.assertEquals(Date.today(), con.Last_Lead_Date__c);
        System.assertEquals(1, con.Lead_Cycle_Count__c);
        System.assertEquals(true, con.GSP_Primary_Contact__c);
    }

    @isTest
    static void testSearchAccounts() {
        insert new Account(Name = 'Searchable Corp XYZ');

        Test.startTest();
        List<Account> results = ConvertLeadController.searchAccounts('Searchable Corp');
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Searchable Corp XYZ', results[0].Name);
    }

    @isTest
    static void testSearchContacts() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
        insert new Contact(FirstName = 'Jane', LastName = 'SearchableXYZ', AccountId = acc.Id, Email = 'jane@example.com');

        Test.startTest();
        List<Contact> nameResults = ConvertLeadController.searchContacts('SearchableXYZ');
        List<Contact> emailResults = ConvertLeadController.searchContacts('jane@example.com');
        Test.stopTest();

        System.assertEquals(1, nameResults.size());
        System.assertEquals(1, emailResults.size());
    }

    @isTest
    static void testGetLeadDetails() {
        Lead testLead = makeTestLead('Detail Co');
        insert testLead;

        Test.startTest();
        Lead result = ConvertLeadController.getLeadDetails(testLead.Id);
        Test.stopTest();

        System.assertEquals(testLead.Id, result.Id);
        System.assertEquals('Detail Co', result.Company);
    }

    // ── ArchiveLeadController ──────────────────────────────────────────────────

    @isTest
    static void testArchiveLead() {
        Lead testLead = makeTestLead('Archive Co');
        testLead.Status = 'Stage 1 - Contacted';
        testLead.Lead_Status_Reason__c = 'Personal Outreach';
        insert testLead;

        Test.startTest();
        ArchiveLeadController.archiveLead(testLead.Id, 'No Response', 'Never responded after 5 attempts.');
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Archive_Reason__c, Disposition_Notes__c, Lead_Stage_at_Exit__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Archived - Not Interested', updatedLead.Status);
        System.assertEquals('No Response', updatedLead.Archive_Reason__c);
        System.assertEquals('Never responded after 5 attempts.', updatedLead.Disposition_Notes__c);
        System.assertEquals('Stage 1 - Contacted', updatedLead.Lead_Stage_at_Exit__c);
    }

    @isTest
    static void testArchiveLeadNotAFit() {
        Lead testLead = makeTestLead('No Fit Co');
        insert testLead;

        Test.startTest();
        ArchiveLeadController.archiveLead(testLead.Id, 'Not a Fit', null);
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Archive_Reason__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Archived - Not Interested', updatedLead.Status);
        System.assertEquals('Not a Fit', updatedLead.Archive_Reason__c);
    }
}
