@isTest
public class RedFormReminderTest {

    @testSetup
    public static void addTestData() {
        insert new SFDC_Employee__c(Name = 'Empl One', Email_Address__c = '1test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Employee Two', Email_Address__c = '2test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');

        insert new SFDC_Employee__c(Name = 'Emp Three', Email_Address__c = '3test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-2), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');

        insert new SFDC_Employee__c(Name = 'Contractor Four', Email_Address__c = '4test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Empl Five', Email_Address__c = '5test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Contr Six', Email_Address__c = '6test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');

        insert new SFDC_Employee__c(Name = 'Employee Seven', Email_Address__c = '7test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active', Red_Form_Filled_Date__c = Date.today());
        insert new SFDC_Employee__c(Name = 'Contractor Eight', Email_Address__c = '8test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active', Red_Form_Filled_Date__c = Date.today());
    }

    @isTest
    public static void shouldFilterEmployees() {
        RedFormReminderBatch batchJob = new RedFormReminderBatch(false);
        Test.startTest();
        List<SFDC_Employee__c> emplList = batchJob.start(null);
        System.assertEquals(6, emplList.size());
        batchJob.execute(null, emplList);
        batchJob.finish(null);
        Test.stopTest();
        System.assertEquals(2, batchJob.getFirstEmail().size());
        System.assertEquals(1, batchJob.getSecondEmail().size());
        System.assertEquals(3, batchJob.getGlobalEmail().size());
        System.assertEquals(0, batchJob.getQuarterEmail().size());
    }

    @isTest
    public static void shouldFilterEmployeesForQuarterEmail() {
        RedFormReminderBatch batchJob = new RedFormReminderBatch(true);
        Test.startTest();
        List<SFDC_Employee__c> emplList = batchJob.start(null);
        System.assertEquals(2, emplList.size());
        List<SFDC_Employee__c> toUpdate = new List<SFDC_Employee__c>();
        for (SFDC_Employee__c empl : [SELECT Id, Red_Form_Filled_Date__c FROM SFDC_Employee__c]) {
            empl.Red_Form_Filled_Date__c = Date.today();
            toUpdate.add(empl);
        }
        update toUpdate;
        emplList = batchJob.start(null);
        System.assertEquals(8, emplList.size());
        batchJob.execute(null, emplList);
        batchJob.finish(null);
        Test.stopTest();
        System.assertEquals(0, batchJob.getFirstEmail().size());
        System.assertEquals(0, batchJob.getSecondEmail().size());
        System.assertEquals(0, batchJob.getGlobalEmail().size());
        System.assertEquals(8, batchJob.getQuarterEmail().size());
    }
}