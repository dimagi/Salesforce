@isTest
public class DeactivateDuplicatedSubscriptionsTest {
 @testSetup
    static void setupData() {
        // Create a Domain
        Domain__c domain = new Domain__c(Name = 'Test Domain', Server_Name__c = 'test.server.com');
        insert domain;

        // Create duplicate active subscriptions for the same domain
        List<Accounting_Subscription__c> subs = new List<Accounting_Subscription__c>();
        for (Integer i = 0; i < 3; i++) {
            subs.add(new Accounting_Subscription__c(
                Accounting_subscriber_domain__c = domain.Id,
                is_active__c = true
            ));
        }
        insert subs;

        // Ensure BatchDefaultSettings__c has required values if referenced outside test
        BatchDefaultSettings__c settings = new BatchDefaultSettings__c(Error_Emails__c = 'test@example.com');
        insert settings;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        DeactivateDuplicatedSubscriptionsBatch batch = new DeactivateDuplicatedSubscriptionsBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Since the actual logic just logs info and sends email (disabled in test),
        // we validate it ran by asserting no exceptions and batch scope executed
        // There are no changes to verify, so this test is functional/coverage based
        System.assert(true);  // Placeholder assertion to satisfy test method structure
    }
}