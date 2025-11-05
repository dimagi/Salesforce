@isTest
public class PROEmailRemindarClearTest {

    @isTest
    static void testSchedule() {
        PRO_Email_Remindar_Settings__c settingRec = new PRO_Email_Remindar_Settings__c(
            Name = 'Test Setting'
        );
        insert settingRec;

        List<PRO_Email_Remindar_Settings__c> settingList = [
            SELECT Id, Name
            FROM PRO_Email_Remindar_Settings__c
            LIMIT 1
        ];
        System.assert(!settingList.isEmpty(), 'Settings record should exist');

        PRO_Email_Remindar_Settings__c settings = settingList[0]; 

        String cronExp = '0 0 0 1 1 ? 2026';

        Test.startTest();
        String jobId = System.schedule(
            'Test_PROEmailRemindarClearDataBatch_Scheduled',
            cronExp,
            new PROEmailRemindarClearDataBatch_Scheduled()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job Id should not be null');
        System.assert(jobId.length() > 0, 'Job Id should not be empty');
    }
}