@isTest
public class PROEmailRemindarBatch_ScheduledTest {
    
    @isTest
    static void testExecuteMethod() {
        
        PRO_Email_Remindar_Settings__c setting = new PRO_Email_Remindar_Settings__c(
            Name = 'Default Setting'
        );
        insert setting;

        PROEmailRemindarBatch_Scheduled scheduledJob = new PROEmailRemindarBatch_Scheduled();
        
        String cronExp = '0 0 0 1 1 ? 2050';
        
        Test.startTest();
        String jobId = System.schedule('Test PROEmailRemindarBatch Job', cronExp, scheduledJob);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}