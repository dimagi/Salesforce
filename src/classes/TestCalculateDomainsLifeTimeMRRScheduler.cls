@isTest
public class TestCalculateDomainsLifeTimeMRRScheduler {

    @isTest
    static void testSchedulerExecute() {
        // Set up test data if required by your batch class
        // (optional: insert any records needed by CalculateDomainsLifeTimeMRRBatch)

        Test.startTest();
        // Schedule the job
        String cronExp = '0 0 0 1 1 ? 2026'; 
        String jobId = System.schedule('Test MRR Scheduler', cronExp, new CalculateDomainsLifeTimeMRRScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        System.assertNotEquals(null, ct);
    }
}