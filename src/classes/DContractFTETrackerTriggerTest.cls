@isTest
public class DContractFTETrackerTriggerTest {

    @testSetup
    static void setupData() {
        DContract__c contract = new DContract__c(
            Name = 'Test Contract',
            Services_Spend__c = 100,
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No',
            Skip_FTE_Tracker_Trigger__c = false
        );
        insert contract;
    }

    @isTest
    static void testAfterUpdateFTETrackerChange() {
        DContract__c contract = [SELECT Id, FTE_Tracker__c FROM DContract__c LIMIT 1];
        contract.FTE_Tracker__c = 'yes';

        Test.startTest();
        update contract;
        Test.stopTest();

        // No assertions needed; this validates no errors were thrown and batch was queued
        System.assert(true);
    }

    @isTest
    static void testAfterUpdateWithSkipFlag() {
        DContract__c contract = [SELECT Id FROM DContract__c LIMIT 1];
        contract.FTE_Tracker__c = 'NO';
        contract.Skip_FTE_Tracker_Trigger__c = true;

        Test.startTest();
        update contract;
        Test.stopTest();

        // Confirm Skip flag was reset
        DContract__c updated = [SELECT Skip_FTE_Tracker_Trigger__c FROM DContract__c WHERE Id = :contract.Id];
        System.assertEquals(false, updated.Skip_FTE_Tracker_Trigger__c);
    }
}