@isTest
private class FogBugzSynchronizerTest {
    
    @isTest
    static void testSchedulerRunsBatch() {
        // Insert org defaults
        FogBugz_Settings__c fbSettings = new FogBugz_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Sync_Script_Running__c = false,
            Sync_Filter__c = 10
        );
        insert fbSettings;
        
        // Create a cron expression 1 min in the future
        Datetime dt = System.now().addMinutes(1);
        String cronExp = String.format(
            '0 {0} {1} {2} {3} ? {4}', 
            new List<String>{
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
        
        Test.startTest();
        System.schedule('FogBugzSyncJobTest', cronExp, new FogBugzSynchronizer());
        Test.stopTest(); // Forces the schedulable + batch to run
    }
    
    @isTest
    static void testSchedulerSkipsWhenRunning() {
        // Insert org defaults with script already running
        FogBugz_Settings__c fbSettings = new FogBugz_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Sync_Script_Running__c = true,
            Sync_Filter__c = 20
        );
        insert fbSettings;
        
        // Valid cron (future time)
        Datetime dt = System.now().addMinutes(1);
        String cronExp = String.format(
            '0 {0} {1} {2} {3} ? {4}', 
            new List<String>{
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
        
        Test.startTest();
        System.schedule('FogBugzSyncJobTestSkip', cronExp, new FogBugzSynchronizer());
        Test.stopTest();
        
        // No batch should run since Sync_Script_Running__c = true
        System.assertEquals(
            0, 
            [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex'], 
            'Batch should not be queued when Sync_Script_Running__c = true'
        );
    }
}