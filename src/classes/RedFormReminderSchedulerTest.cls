@isTest
public class RedFormReminderSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
       
        String cronExp = '0 0 0 1 1 ? 2050';

        RedFormReminderScheduler scheduler = new RedFormReminderScheduler();

        Test.startTest();
        String jobId = System.schedule('Test RedFormReminder Job', cronExp, scheduler);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}