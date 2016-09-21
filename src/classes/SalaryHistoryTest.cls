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

    static testMethod void shouldCalculateCorrectSalary() {
        Test.startTest();

        System.assertEquals(11.50, SalaryHistoryHelper.calculateSalary(20000, 2));
        System.assertEquals(22.99, SalaryHistoryHelper.calculateSalary(40000, 2));
        System.assertEquals(15.33, SalaryHistoryHelper.calculateSalary(40000, 3));
        System.assertEquals(34.48, SalaryHistoryHelper.calculateSalary(60000, 2));
        System.assertEquals(22.25, SalaryHistoryHelper.calculateSalary(60000, 3.1));
        System.assertEquals(71.96, SalaryHistoryHelper.calculateSalary(457000, 7.3));

        Test.stopTest();
    }

    static testMethod void testIntegrationWithCalculationBatchJob() {
        // 3 Employess, 3 contracts, one is subcontract
        Test.startTest();

        SFDC_Employee__c employee_1 = new SFDC_Employee__c(Name = 'emp_6', Salary__c = 60000, Exchange_Rate__c = 1);
        insert employee_1;
        SFDC_Employee__c employee_2 = new SFDC_Employee__c(Name = 'emp_7', Salary__c = 45000, Exchange_Rate__c = 2,
                                                         Effective_Salary_Date__c = Date.newInstance(2013, 1, 1),
                                                         Effective_Exchange_Rate_Date__c = Date.newInstance(2011, 1, 1));
        insert employee_2;
        SFDC_Employee__c employee_3 = new SFDC_Employee__c(Name = 'emp_8', Salary__c = 200000, Exchange_Rate__c = 2,
                                                         Effective_Salary_Date__c = Date.newInstance(2010, 1, 1),
                                                         Effective_Exchange_Rate_Date__c = Date.newInstance(2013, 6, 1));
        insert employee_3;

        DContract__c parent_1 = new DContract__c(Name = 'Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent_1;
        DContract__c child = new DContract__c(Name = 'Sample Child', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent_1.Id);
        insert child;
        DContract__c parent_2 = new DContract__c(Name = 'Sample Parent 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent_2;

        // Employee 1:
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(20000, 2) = 11.50
        Time_Card__c tc_1_employee_1 = new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2010, 12, 30), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        insert tc_1_employee_1;
        // Salary = 3 * SalaryHistoryHelper.calculateSalary(20000, 2) = 3 * 11.50 = 34,5
        Time_Card__c tc_2_employee_1 = new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2010, 11, 1), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        insert tc_2_employee_1;
        // Salary = 6 * SalaryHistoryHelper.calculateSalary(40000, 2) = 6 * 22.99 = 137,94
        Time_Card__c tc_3_employee_1 = new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2011, 1, 1), Employee__c = employee_1.Id, Client__c = child.Id);
        insert tc_3_employee_1;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(40000, 3) = 7 * 15.33 = 107,31
        Time_Card__c tc_4_employee_1 = new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2011, 5, 22), Employee__c = employee_1.Id, Client__c = parent_2.Id);
        insert tc_4_employee_1;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(20000, 2) = 8 * 34.48 = 275,84
        Time_Card__c tc_5_employee_1 = new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2016, 3, 3), Employee__c = employee_1.Id, Client__c = parent_2.Id);
        insert tc_5_employee_1;
        // child = 137.94, parent_1 46 = 183.94 , parent_2 = 275,84 + 107,31 = 383.15

        // Employee 2:
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(45000, 2) = 25.86
        Time_Card__c tc_1_employee_2 = new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2010, 12, 30), Employee__c = employee_2.Id, Client__c = parent_1.Id);
        insert tc_1_employee_2;
        // Salary = 3 * SalaryHistoryHelper.calculateSalary(45000, 2) = 3 * 25.86 = 77,58
        Time_Card__c tc_2_employee_2 = new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2010, 11, 1), Employee__c = employee_2.Id, Client__c = parent_1.Id);
        insert tc_2_employee_2;
        // Salary = 6 * SalaryHistoryHelper.calculateSalary(45000, 2) = 6 * 25.86 = 155,16
        Time_Card__c tc_3_employee_2 = new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2011, 1, 1), Employee__c = employee_2.Id, Client__c = parent_1.Id);
        insert tc_3_employee_2;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(45000, 2) = 7 * 25.86 = 181,02
        Time_Card__c tc_4_employee_2 = new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2011, 5, 22), Employee__c = employee_2.Id, Client__c = parent_1.Id);
        insert tc_4_employee_2;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(45000, 2) = 8 * 25.86 = 206,88
        Time_Card__c tc_5_employee_2 = new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2016, 3, 3), Employee__c = employee_2.Id, Client__c = parent_2.Id);
        insert tc_5_employee_2;
        // child = 0, parent_1 = 439.62 , parent_2 = 206,88

        // Employee 3:
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(200000, 4) = 57.48
        Time_Card__c tc_1_employee_3 = new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2010, 12, 30), Employee__c = employee_3.Id, Client__c = child.Id);
        insert tc_1_employee_3;
        // Salary = 3 * SalaryHistoryHelper.calculateSalary(200000, 4) = 3 * 57.48 = 172.44
        Time_Card__c tc_2_employee_3 = new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2010, 11, 1), Employee__c = employee_3.Id, Client__c = child.Id);
        insert tc_2_employee_3;
        // Salary = 6 * SalaryHistoryHelper.calculateSalary(200000, 2) = 6 * 114.95 = 689.7
        Time_Card__c tc_3_employee_3 = new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2013, 6, 1), Employee__c = employee_3.Id, Client__c = child.Id);
        insert tc_3_employee_3;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(200000, 2) = 7 * 114.95 = 804.65
        Time_Card__c tc_4_employee_3 = new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2015, 5, 22), Employee__c = employee_3.Id, Client__c = parent_1.Id);
        insert tc_4_employee_3;
        // Salary = 1 * SalaryHistoryHelper.calculateSalary(200000, 4) = 8 * 57.48 = 459.84
        Time_Card__c tc_5_employee_3 = new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2013, 5, 30), Employee__c = employee_3.Id, Client__c = parent_2.Id);
        insert tc_5_employee_3;
        // child = 919.62, parent_1 = 804.65 + 919.62 CH , parent_2 = 459.84

        // TOTAL : child = 1057.56, parent_1 = 46 + 439.62 + 804.65 + 1057.56 CH = 2347.83 , parent_2 = 383.15 + 206,88 + 459.84 = 1049.87

        BatchCalculateTotalHoursOfTimeCard batch1 = new BatchCalculateTotalHoursOfTimeCard();
        Database.QueryLocatorIterator iter = batch1.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }
        System.debug('testData : ' + testData);
        batch1.execute(null, testData);
        System.debug('testData : ' + testData);
        System.debug('batch1.getServicesSpendMap() : ' + batch1.getServicesSpendMap());
        BatchUpdateContractServicesSpend batch2 = new BatchUpdateContractServicesSpend(batch1.getServicesSpendMap());
        batch2.execute(null, batch2.start(null));

        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent_1.Id];
        System.assertEquals(2347.83, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child.Id];
        System.assertEquals(1057.56, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent_2.Id];
        System.assertEquals(1049.87, dcontractFromDB.Services_Spend__c);
    }
}