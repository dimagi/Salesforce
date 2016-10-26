@isTest
public class LeadQualifyProcessTest {

    public static testMethod void triggerShouldSetFailingProcessField() {
        Lead testLead1 = new Lead(FirstName = 'Tom', LastName = 'Smith', Company = 'Smith IT Company', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 8);
        insert testLead1;
        Lead testLead2 = new Lead(FirstName = 'Tom 1', LastName = 'Smith 1', Company = 'Smith IT Company 1', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 88);
        insert testLead2;
        Lead testLead3 = new Lead(FirstName = 'Tom 2', LastName = 'Smith 2 ', Company = 'Smith IT Company 2', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 6);
        insert testLead3;

        testLead1.Company = 'New Company 1';
        testLead2.Company = 'New Company 2';
        testLead3.Company = 'New Company 3';

        List<Lead> toUpdate = new List<Lead>();
        toUpdate.add(testLead1);
        toUpdate.add(testLead2);
        toUpdate.add(testLead3);

        Test.startTest();

        update toUpdate;

        Test.stopTest();

        List<Lead> leadsFromDB = [SELECT Id, Failed_Qualifying_process_at_least_once__c FROM Lead ORDER BY CreatedDate];
        System.assertEquals(true, leadsFromDB.get(0).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(true, leadsFromDB.get(1).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(false, leadsFromDB.get(2).Failed_Qualifying_process_at_least_once__c);

    }

    public static testMethod void jobShouldSetFailingProcessField() {
        Lead testLead1 = new Lead(FirstName = 'Tom', LastName = 'Smith', Company = 'Smith IT Company', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 8);
        insert testLead1;
        Lead testLead2 = new Lead(FirstName = 'Tom 1', LastName = 'Smith 1', Company = 'Smith IT Company 1', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 88);
        insert testLead2;
        Lead testLead3 = new Lead(FirstName = 'Tom 2', LastName = 'Smith 2 ', Company = 'Smith IT Company 2', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 6);
        insert testLead3;

        testLead1.Company = 'New Company 1';
        testLead2.Company = 'New Company 2';
        testLead3.Company = 'New Company 3';

        List<Lead> toUpdate = new List<Lead>();
        toUpdate.add(testLead1);
        toUpdate.add(testLead2);
        toUpdate.add(testLead3);

        Test.startTest();

        Database.executeBatch(new LeadQualifyProcessBatch(), 200);

        Test.stopTest();

        List<Lead> leadsFromDB = [SELECT Id, Failed_Qualifying_process_at_least_once__c FROM Lead ORDER BY CreatedDate];
        System.assertEquals(true, leadsFromDB.get(0).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(true, leadsFromDB.get(1).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(false, leadsFromDB.get(2).Failed_Qualifying_process_at_least_once__c);

    }

    public static testMethod void shouldUseSettings() {
        Lead_Qualifying_Process__c setting = Lead_Qualifying_Process__c.getOrgDefaults();
        setting.Threshold__c = 2;
        insert setting;

        Lead testLead1 = new Lead(FirstName = 'Tom', LastName = 'Smith', Company = 'Smith IT Company', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 8);
        insert testLead1;
        Lead testLead2 = new Lead(FirstName = 'Tom 1', LastName = 'Smith 1', Company = 'Smith IT Company 1', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 3);
        insert testLead2;
        Lead testLead3 = new Lead(FirstName = 'Tom 2', LastName = 'Smith 2 ', Company = 'Smith IT Company 2', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 1);
        insert testLead3;

        testLead1.Company = 'New Company 1';
        testLead2.Company = 'New Company 2';
        testLead3.Company = 'New Company 3';

        List<Lead> toUpdate = new List<Lead>();
        toUpdate.add(testLead1);
        toUpdate.add(testLead2);
        toUpdate.add(testLead3);

        Test.startTest();

        Database.executeBatch(new LeadQualifyProcessBatch(), 200);

        Test.stopTest();

        List<Lead> leadsFromDB = [SELECT Id, Failed_Qualifying_process_at_least_once__c FROM Lead ORDER BY CreatedDate];
        System.assertEquals(true, leadsFromDB.get(0).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(true, leadsFromDB.get(1).Failed_Qualifying_process_at_least_once__c);
        System.assertEquals(false, leadsFromDB.get(2).Failed_Qualifying_process_at_least_once__c);
    }
}