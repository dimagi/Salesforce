@isTest
public class ScriptBatchJobSchedulerTest {
  @isTest
    static void testSchedulerExecute() {
        ScriptBatchJobScheduler scheduler = new ScriptBatchJobScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}