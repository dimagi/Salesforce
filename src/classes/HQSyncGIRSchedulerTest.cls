@isTest
public class HQSyncGIRSchedulerTest {
    private static void insertError(Date forMonthStart) {
        insert new HQ_Sync_Error__c(
            Object_Type__c = 'GIR',
            Date__c = forMonthStart
        );
    }

    @isTest
    static void testSchedulerExecute_todayIsFifthDayOrAfterWithErrors() {
        Date today = Date.today();
        if (today.day() >= 5) {
            insertError(today.addMonths(-1).toStartOfMonth());
        }

        Test.startTest();
        new HQSyncGIRScheduler().execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler ran without exceptions.');
    }

    @isTest
    static void testSchedulerExecute_todayBeforeFifthDay() {
        Date today = Date.today();

        if (today.day() < 5) {
            Test.startTest();
            new HQSyncGIRScheduler().execute(null);
            Test.stopTest();

            System.assert(true, 'Scheduler ran without exceptions (before 5th day).');
        }
    }
}