@isTest
public class LogsDeletingBatchScheduleTest {
@isTest
    static void testSchedulerExecute() {
        LogsDeletingBatchSchedule scheduler = new LogsDeletingBatchSchedule();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}