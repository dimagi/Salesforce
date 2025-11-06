@IsTest
private class testEmailController_Test {
    
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        return u;
    }
    
    private static Opportunity createTestOpportunity(Account acc) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting', // use a valid early stage
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Opportunity_Owner_Division__c = 'Global Solutions',          
            Opportunity_Owner_Sub_Division__c = 'Ops - BizOps'
        );
        insert opp;
        return opp;
    }
    
    private static void createSettingsForUser(User u) {
        // Create org default settings record
        Open_Opportunity_Settings__c setting = new Open_Opportunity_Settings__c(
            Biz_Dev_Daily_Report_Emails__c = u.Email,
             Default_Email_Recipient__c = u.Email 
        );
        insert setting;
    }

    @IsTest
    static void testWithStandardController() {
        User u = createTestUser();
        
        // Create account and opportunity so OpenOpportunityReportController can find it
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        createTestOpportunity(acc);
        
        createSettingsForUser(u);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        testEmailController ctrl = new testEmailController(sc);
        ctrl.testEmail(); // should execute email logic
        PageReference ref = ctrl.goBack();
        Test.stopTest();
        
        System.assertNotEquals(null, ref, 'goBack() should return a PageReference');
    }
    
    @IsTest
    static void testWithStandardSetController() {
        User u = createTestUser();
        
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;
        createTestOpportunity(acc);
        
        createSettingsForUser(u);
        
        List<Account> accList = [SELECT Id FROM Account WHERE Id = :acc.Id];
        
        Test.startTest();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(accList);
        testEmailController ctrl = new testEmailController(ssc);
        ctrl.testEmail();
        PageReference ref = ctrl.goBack();
        Test.stopTest();
        
        System.assertNotEquals(null, ref, 'goBack() should return a PageReference');
    }
}