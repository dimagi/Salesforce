@isTest
public class RedFormReminderTest {

    @testSetup
    public static void addTestData() {
        // TODO add test data and update asserts
    }

    @isTest
    public static void shouldFilterEmployees() {
        RedFormReminderBatch batchJob = new RedFormReminderBatch(false);
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        System.assertEquals(0, batchJob.getFirstEmail().size());
        System.assertEquals(0, batchJob.getSecondEmail().size());
        System.assertEquals(0, batchJob.getGlobalEmail().size());
        System.assertEquals(0, batchJob.getQuarterEmail().size());
    }

    @isTest
    public static void shouldFilterEmployeesForQuarterEmail() {
        RedFormReminderBatch batchJob = new RedFormReminderBatch(true);
        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
        System.assertEquals(0, batchJob.getFirstEmail().size());
        System.assertEquals(0, batchJob.getSecondEmail().size());
        System.assertEquals(0, batchJob.getGlobalEmail().size());
        System.assertEquals(0, batchJob.getQuarterEmail().size());
    }
}