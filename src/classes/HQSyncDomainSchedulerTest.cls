@isTest
public class HQSyncDomainSchedulerTest {
    @isTest
    static void testSchedulerExecute() {
        // Insert a valid org-default setting record to avoid MISSING_ARGUMENT error
        Commcare_Job_Settings__c settings = new Commcare_Job_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(), // required for org-default setting
            Is_Domain_Job_Running__c = false
        );
        insert settings;

        HQSyncDomainScheduler scheduler = new HQSyncDomainScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Optionally assert setting update or expected changes
        Commcare_Job_Settings__c updated = Commcare_Job_Settings__c.getOrgDefaults();
        System.assertEquals(true, updated.Is_Domain_Job_Running__c);
    }
}