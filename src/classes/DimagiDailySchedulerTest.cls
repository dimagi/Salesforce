@isTest
public class DimagiDailySchedulerTest {
@isTest
    static void testSchedulerExecute() {
        

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2026'; 
        String jobId = System.schedule('Test DimagiDailyScheduler', cronExp, new DimagiDailyScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        System.assertNotEquals(null, ct);
    }
}