@isTest
private class CreateFBCasesSchedulableTest {

    @isTest
    static void testScheduleExecutesBatch() {
        // Create a cron expression 1 minute in the future
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
        // Schedule the job → this will invoke execute() and run the batch
        System.schedule('Test_CreateFBCasesSchedulable', cronExp, new CreateFBCasesSchedulable());
        Test.stopTest();

        // Assert scheduled job exists
        CronTrigger ct = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test_CreateFBCasesSchedulable'
            LIMIT 1
        ];
        System.assertEquals('Test_CreateFBCasesSchedulable', ct.CronJobDetail.Name);

        // Optional: check a batch job was queued
        Integer batchCount = [
            SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex'
        ];
        System.assert(batchCount > 0, 'Expected batch job to be queued');
    }
}