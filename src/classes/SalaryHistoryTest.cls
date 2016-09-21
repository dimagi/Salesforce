@isTest
public class SalaryHistoryTest {

    /**
     * 1 date record and 3 history (first with empty OldValue)
     */
    static testMethod void shouldFetchHistoryForEmp1() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_1', Salary__c = 30000);

        List<SalaryHistoryRecord> historyList = salaryHelper.getHistoryForEmployee(employee, 'Salary__c', 'Effective_Salary_Date__c');

        System.assertEquals(3, historyList.size());
        System.assertEquals(10000, historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());
        System.assertEquals(20000, historyList.get(1).getValue());
        System.assertEquals(Date.newInstance(2015, 4, 14), historyList.get(1).getValueDate());
        System.assertEquals(30000, historyList.get(2).getValue());
        System.assertEquals(Date.newInstance(2015, 6, 1), historyList.get(2).getValueDate());

        Test.stopTest();
    }

    /**
     * Empty list
     */
    static testMethod void shouldFetchHistoryForEmp2() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_2', Salary__c = 150000);

        List<SalaryHistoryRecord> historyList = salaryHelper.getHistoryForEmployee(employee, 'Salary__c', 'Effective_Salary_Date__c');

        System.assertEquals(1, historyList.size());
        System.assertEquals(150000, historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());

        Test.stopTest();
    }

    /**
     * 0 date record and 3 history (first with filled OldValue)
     */
    static testMethod void shouldFetchHistoryForEmp3() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_3', Salary__c = 150000);

        List<SalaryHistoryRecord> historyList = salaryHelper.getHistoryForEmployee(employee, 'Salary__c', 'Effective_Salary_Date__c');

        System.assertEquals(4, historyList.size());
        System.assertEquals(50000, historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());
        System.assertEquals(60000, historyList.get(1).getValue());
        System.assertEquals(Date.newInstance(2014, 1, 1), historyList.get(1).getValueDate());
        System.assertEquals(70000, historyList.get(2).getValue());
        System.assertEquals(Date.newInstance(2015, 1, 1), historyList.get(2).getValueDate());
        System.assertEquals(80000, historyList.get(3).getValue());
        System.assertEquals(Date.newInstance(2016, 9, 10), historyList.get(3).getValueDate());

        Test.stopTest();
    }

    /**
     * 2 date record and 2 history
     */
    static testMethod void shouldFetchHistoryForEmp4() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_4', Salary__c = 150000);

        List<SalaryHistoryRecord> historyList = salaryHelper.getHistoryForEmployee(employee, 'Salary__c', 'Effective_Salary_Date__c');

        System.assertEquals(2, historyList.size());
        System.assertEquals(17000, historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());
        System.assertEquals(34000, historyList.get(1).getValue());
        System.assertEquals(Date.newInstance(2015, 1, 1), historyList.get(1).getValueDate());

        Test.stopTest();
    }

    static testMethod void shouldMergeListsEmp6() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_6', Salary__c = 60000);

        List<SalaryHistoryRecord> historyList = salaryHelper.mergeSalaryHistory(employee);

        System.assertEquals(5, historyList.size());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(20000, 2), historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(40000, 2), historyList.get(1).getValue());
        System.assertEquals(Date.newInstance(2011, 1, 1), historyList.get(1).getValueDate());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(40000, 3), historyList.get(2).getValue());
        System.assertEquals(Date.newInstance(2011, 2, 14), historyList.get(2).getValueDate());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(60000, 3), historyList.get(3).getValue());
        System.assertEquals(Date.newInstance(2011, 11, 1), historyList.get(3).getValueDate());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(60000, 2), historyList.get(4).getValue());
        System.assertEquals(Date.newInstance(2012, 1, 1), historyList.get(4).getValueDate());

        Test.stopTest();
    }

    static testMethod void shouldMergeListsEmp7() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_7', Salary__c = 45000, Exchange_Rate__c = 2,
                                                         Effective_Salary_Date__c = Date.newInstance(2013, 1, 1),
                                                         Effective_Exchange_Rate_Date__c = Date.newInstance(2011, 1, 1));

        List<SalaryHistoryRecord> historyList = salaryHelper.mergeSalaryHistory(employee);

        System.assertEquals(1, historyList.size());
        System.assertEquals(SalaryHistoryHelper.calculateSalary(45000, 2), historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());

        Test.stopTest();
    }

    static testMethod void shouldMergeListsEmp8() {
        Test.startTest();

        SalaryHistoryHelper salaryHelper = new SalaryHistoryHelper();
        SFDC_Employee__c employee = new SFDC_Employee__c(Name = 'emp_8', Salary__c = 200000, Exchange_Rate__c = 2,
                                                         Effective_Salary_Date__c = Date.newInstance(2010, 1, 1),
                                                         Effective_Exchange_Rate_Date__c = Date.newInstance(2013, 6, 1));

        List<SalaryHistoryRecord> historyList = salaryHelper.mergeSalaryHistory(employee);

        System.assertEquals(2, historyList.size());
        System.assertEquals(SalaryHistoryHelper.calculateSalary(200000, 4), historyList.get(0).getValue());
        System.assertEquals(Date.newInstance(1900, 1, 1), historyList.get(0).getValueDate());

        System.assertEquals(SalaryHistoryHelper.calculateSalary(200000, 2), historyList.get(1).getValue());
        System.assertEquals(Date.newInstance(2013, 6, 1), historyList.get(1).getValueDate());

        Test.stopTest();
    }
}