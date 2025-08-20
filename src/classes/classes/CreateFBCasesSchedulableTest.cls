@isTest
public class CreateFBCasesSchedulableTest {
    @isTest
    static void testSchedulerExecute() {

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2026'; 
        String jobId = System.schedule('Test CreateFBCasesSchedulable', cronExp, new CreateFBCasesSchedulable());
        Test.stopTest();

        CronTrigger ct = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct);
    }
}