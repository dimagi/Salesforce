@isTest
public class EmployeeSnapshotSchedulerTest {

    @isTest
    static void testSchedulerExecute() {
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2026'; 
        String jobId = System.schedule('Test_EmployeeSnapshotScheduler', cronExp, new EmployeeSnapshotScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];
        System.assertNotEquals(null, ct);
        System.assertEquals('0 0 0 1 1 ? 2026', ct.CronExpression);
    }
}