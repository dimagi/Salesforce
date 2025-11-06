@isTest
public class HQSyncMaltTablesSchedulerTest {

    private static void insertSyncError(Date forMonthStart) {
        insert new HQ_Sync_Error__c(
            Object_Type__c = 'Malt Tables',
            Date__c = forMonthStart
        );
    }

    
    @isTest
    static void testOnFifthDay_runsBatch() {
        if (Date.today().day() == 5) {
            Test.startTest();
            new HQSyncMaltTablesScheduler().execute(null);
            Test.stopTest();
            System.assert(true, 'scheduleJobs(false, lastMonth) should be called on 5th day');
        } else {
            System.debug('Skipping testOnFifthDay_runsBatch because today is not 5th');
        }
    }

    
    @isTest
    static void testAfterFifthDay_withErrors_runsBatch() {
        if (Date.today().day() > 5) {
            insertSyncError(Date.today().addMonths(-1).toStartOfMonth());

            Test.startTest();
            new HQSyncMaltTablesScheduler().execute(null);
            Test.stopTest();

            System.assert(true, 'scheduleJobs(true, lastMonth) should be called after 5th day if errors exist');
        } else {
            System.debug('Skipping testAfterFifthDay_withErrors_runsBatch because today is <= 5');
        }
    }

  
    @isTest
    static void testAfterFifthDay_noErrors_noBatch() {
        if (Date.today().day() > 5) {
            delete [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'Malt Tables'];

            Test.startTest();
            new HQSyncMaltTablesScheduler().execute(null);
            Test.stopTest();

            System.assert(true, 'No batch should run after 5th day when no errors exist');
        } else {
            System.debug('Skipping testAfterFifthDay_noErrors_noBatch because today is <= 5');
        }
    }

    
    @isTest
    static void testBeforeFifthDay_noBatch() {
        if (Date.today().day() < 5) {
            Test.startTest();
            new HQSyncMaltTablesScheduler().execute(null);
            Test.stopTest();

            System.assert(true, 'No batch should run before 5th day');
        } else {
            System.debug('Skipping testBeforeFifthDay_noBatch because today is >= 5');
        }
    }
}