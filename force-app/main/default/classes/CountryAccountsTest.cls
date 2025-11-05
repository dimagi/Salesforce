@isTest
private class CountryAccountsTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>{
            new Account(
                Name = 'Test Account 1',
                Phone = '1234567890',
                Country__c = 'a00b0000001AP19AAG'
            ),
            new Account(
                Name = 'Test Account 2',
                Phone = '0987654321',
                Country__c = 'a00b0000001AOvdAAG'
            ),
            new Account(
                Name = 'Inactive Account',
                Phone = '5555555555',
                Country__c = 'a00b0000001AP2BAAW'
            )
        };
        insert testAccounts;
    }
    
    
    @isTest
    static void testEmptyResults() {
        // Delete all accounts to test empty scenario
        delete [SELECT Id FROM Account];
        
        // Instantiate controller
        CountryAccounts controller = new CountryAccounts(null);
        
        // Call the method
        Test.startTest();
        List<Account> results = controller.getOpenAccounts();
        Test.stopTest();
        
        // Verify empty list is returned
        System.assertEquals(0, results.size(), 'Should return empty list when no accounts exist');
    }
    
    @isTest
    static void testWithSharingEnforcement() {
        // Create a user with standard profile to test sharing
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@countryaccounts.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = stdProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@countryaccounts.test'
        );
        insert testUser;
        
        System.runAs(testUser) {
            // Instantiate controller
            CountryAccounts controller = new CountryAccounts(null);
            
            // Call the method
            Test.startTest();
            List<Account> results = controller.getOpenAccounts();
            Test.stopTest();
            
            // Verify user can see the accounts (sharing is enforced)
            System.assertEquals(3, results.size(), 'Standard user should see all accounts with sharing');
        }
    }
}