@isTest
public class ContactDirectoryTest {

    @isTest
    public static void ProjectReportOutControllerTest() {
        insert new SFDC_Employee__c(Name = 'Empl One', Email_Address__c = '1test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Employee Two', Email_Address__c = '2test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Emp Three', Email_Address__c = '3test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-2), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Contractor Four', Email_Address__c = '4test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Empl Five', Email_Address__c = '5test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Contr Six', Email_Address__c = '6test-email-adress@test-email.com', Hire_Date__c = Date.today().addDays(-7), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Employee Seven', Email_Address__c = '7test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Employee', Exchange_Rate__c = 1, Employee_Status__c = 'Active');
        insert new SFDC_Employee__c(Name = 'Contractor Eight', Email_Address__c = '8test-email-adress@test-email.com', Hire_Date__c = Date.today(), Employee_Type__c = 'Contractor', Exchange_Rate__c = 1, Employee_Status__c = 'Terminated');

        insert new DContract__c(Name = 'Test One', Status__c = 'Complete');
        insert new DContract__c(Name = 'Test Two', Status__c = 'Complete');
        insert new DContract__c(Name = 'Test Three Values');
        insert new DContract__c(Name = 'Test Four');
        insert new DContract__c(Name = 'Test Five Value');
        insert new DContract__c(Name = 'Test Six');
        insert new DContract__c(Name = 'Seven Contr');
        insert new DContract__c(Name = 'Eight Con');
        insert new DContract__c(Name = 'Test Contract Draft 1', Status__c = 'Draft');
        insert new DContract__c(Name = 'Test Draft', Status__c = 'Draft');

        PageReference pageRef = Page.ContactDirectory;
        pageRef.getParameters().put('code', 'simpleCode');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        ContactDirectoryController ctrl = new ContactDirectoryController();
        PageReference testRedirect = ctrl.initAction();
        System.assertNotEquals(null, testRedirect);

        ctrl.loadPageData();
        System.assertEquals(7, ctrl.empList.size());
        System.assertEquals(8, ctrl.contractList.size());

        ctrl.empSearchName = 'Emp';
        ctrl.searchEmp();
        System.assertEquals(5, ctrl.empList.size());

        ctrl.empSearchName = 'Four';
        ctrl.searchEmp();
        System.assertEquals(1, ctrl.empList.size());

        ctrl.contractSearchName = 'Test';
        ctrl.searchContract();
        System.assertEquals(6, ctrl.contractList.size());

        ctrl.contractSearchName = 'Val';
        ctrl.searchContract();
        System.assertEquals(2, ctrl.contractList.size());
        Test.stopTest();
    }
}