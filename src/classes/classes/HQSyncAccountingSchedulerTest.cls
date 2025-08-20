@isTest
private class HQSyncAccountingSchedulerTest {

    private class DummyContext implements SchedulableContext {
        public String getTriggerId() {
            return 'test-id';
        }
    }

    @isTest
    static void testExecute_WithSetupData() {
        Commcare_Job_Settings__c settings = new Commcare_Job_Settings__c(
            Name = 'Default',
            Is_Job_Running__c = false,
            Job_Start_Date__c = Date.today()
        );
        insert settings;

        settings = Commcare_Job_Settings__c.getOrgDefaults(); 
        settings.Is_Job_Running__c = true;
        update settings;

        HQSyncAccountingScheduler scheduler = new HQSyncAccountingScheduler();

        Test.startTest();
        scheduler.execute(new DummyContext());
        Test.stopTest();

    }
}