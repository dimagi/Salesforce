@isTest
public class EmployeeSnapshotTest {

    @testSetup
    public static void addTestData() {
        insert new SFDC_Employee__c(Name = 'Empl One', Email_Address__c = '1test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Contractor', Exchange_Rate__c = 2, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Employee Two', Email_Address__c = '2test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-40), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
    }

    @isTest
    public static void shouldCreateEmployeeSnapshots() {
        Test.startTest();
        Database.executeBatch(new EmployeeSnapshotBatch());
        Test.stopTest();

        System.assertEquals(2, [SELECT Id FROM SFDC_Employee_Snapshot__c].size());
        SFDC_Employee_Snapshot__c snp1 = [SELECT Email_Address__c, Hire_Date__c, Employee_Type__c, Exchange_Rate__c, Employee_Status__c FROM SFDC_Employee_Snapshot__c WHERE Name = 'Empl One'];
        System.assertEquals('1test-email-adress@test-email.com', snp1.Email_Address__c);
        System.assertEquals(Date.today(), snp1.Hire_Date__c);
        System.assertEquals('Contractor', snp1.Employee_Type__c);
        System.assertEquals(2, snp1.Exchange_Rate__c);
        System.assertEquals('Active', snp1.Employee_Status__c);

        SFDC_Employee_Snapshot__c snp2 = [SELECT Email_Address__c, Hire_Date__c, Employee_Type__c, Exchange_Rate__c, Employee_Status__c FROM SFDC_Employee_Snapshot__c WHERE Name = 'Employee Two'];
        System.assertEquals('2test-email-adress@test-email.com', snp2.Email_Address__c);
        System.assertEquals(Date.today().addDays(-40), snp2.Hire_Date__c);
        System.assertEquals('Employee', snp2.Employee_Type__c);
        System.assertEquals(1, snp2.Exchange_Rate__c);
        System.assertEquals('Active', snp2.Employee_Status__c);
    }
}