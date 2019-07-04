@isTest
public class EmployeeArchiveTest {

    @isTest
    public static void shouldReturnArchivedHistory() {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;
        List<Employee_History_Archive__c> archList = new List<Employee_History_Archive__c>();
        archList.add(new Employee_History_Archive__c(History_Field_Name__c = 'Created', History_Old_Value__c = null, History_New_Value__c = null,
                                                 History_Created_Date__c = DateTime.now().addHours(-2), History_User_Id__c = '', Employee_Id__c = employeeObj.Id));
        archList.add(new Employee_History_Archive__c(History_Field_Name__c = 'Salary__c', History_Old_Value__c = null, History_New_Value__c = '120000',
                                                 History_Created_Date__c = DateTime.now().addHours(-1), History_User_Id__c = '', Employee_Id__c = employeeObj.Id));
        archList.add(new Employee_History_Archive__c(History_Field_Name__c = 'Salary__c', History_Old_Value__c = '120000', History_New_Value__c = null,
                                                 History_Created_Date__c = DateTime.now(), History_User_Id__c = '', Employee_Id__c = employeeObj.Id));
        insert archList;
        ApexPages.StandardController sc = new ApexPages.standardController(employeeObj);
        PageReference emplPage = sc.view();
        Test.setCurrentPageReference(emplPage);

        EmployeeHistoryArchiveController ctrl = new EmployeeHistoryArchiveController(sc);

        Test.startTest();
        System.assertEquals(3, ctrl.getEmployeeArchivedHistory().size());
        Test.stopTest();
    }

    @isTest
    public static void employeeArchiveManagerTest() {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;
        SFDC_Employee__c employeeObj2 = new SFDC_Employee__c(Name = 'Sample Employee 2', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj2;

        Test.startTest();
        EmployeeArchiveManager.archiveNewHistoryData();
        Test.stopTest();
        // We cannot mock history data in test,
        // We also can't create object because we will get field not writable exception
        // The only way to test it is creating history wrapper and mock it instead a query
        // We will test what is possible
        System.assertEquals(0, [SELECT Id FROM Employee_History_Archive__c].size());

        DateTime currentTime = DateTime.now();
        insert EmployeeArchiveManager.buildArchiveRecord(employeeObj.Id, 'Test_Field__c', employeeObj2.Id, false,
                                                         24000.99, 21000.00,  currentTime.addHours(-1), null);
        insert EmployeeArchiveManager.buildArchiveRecord(employeeObj2.Id, 'Test_Field_2__c', employeeObj.Id, false,
                                                         'SimpleName', null, currentTime.addHours(-2), null);
 
        System.assertEquals(2, [SELECT Id FROM Employee_History_Archive__c].size());
        List<Employee_History_Archive__c> records = [SELECT Employee_Id__c, History_Field_Name__c, History_Id__c, History_User_Id__c,
                                                     History_Is_Deleted__c, History_New_Value__c, History_Old_Value__c, History_Created_Date__c
                                                     FROM Employee_History_Archive__c ORDER BY History_Created_Date__c DESC];
        assertRecord(records.get(0), employeeObj.Id, 'Test_Field__c', employeeObj2.Id, null, false, '24000.99', '21000.00', currentTime.addHours(-1));
        assertRecord(records.get(1), employeeObj2.Id, 'Test_Field_2__c', employeeObj.Id, null, false, 'SimpleName', null, currentTime.addHours(-2));
    }

    private static void assertRecord(Employee_History_Archive__c record, Id expectedEmployee, String expectedField, Id expectedId,
                                     Id expectedUser, Boolean expectedIsDeleted, String expectedNew, String expectedOld,
                                     DateTime expectedDateTime) {
        System.assertEquals(expectedEmployee, record.Employee_Id__c);
        System.assertEquals(expectedField, record.History_Field_Name__c);
        System.assertEquals(expectedId, record.History_Id__c);
        System.assertEquals(expectedUser, record.History_User_Id__c);
        System.assertEquals(expectedIsDeleted, record.History_Is_Deleted__c);
        System.assertEquals(expectedNew, record.History_New_Value__c);
        System.assertEquals(expectedOld, record.History_Old_Value__c);
        System.assertEquals(expectedDateTime, record.History_Created_Date__c);
    }
}