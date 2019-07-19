@isTest
public class ContractSnapshotTest {

    @isTest
    public static void shouldCreateSnapshotAfterSubmitingPRO() {
        PROComponentController componentController = new PROComponentController();
        componentController.employeeEmail = 'test.email@test.com';
        componentController.pageController = new DimagiToolsController();
        componentController.pro = new Project_Report_Out__c();
        componentController.pro.PM_email__c = 'test.email@test.com';
        componentController.pro.Report_Out_Date__c = Date.today();

        DContract__c dcontract = addContract();

        componentController.reportContractId = dcontract.Id;
        componentController.contractIdName = new Map<Id, DContract__C> {};
        componentController.contractIdName.put(dcontract.Id, dcontract);
        componentController.status = 'Active';
        componentController.toMeetSchedule = 'Green';
        componentController.stayWithinScope = 'Green';
        componentController.currentSystemUsage = 'Green';
        componentController.partnerRelationship = 'Green';
        componentController.proTabContractPercntgethroughSOW = 30;

        componentController.save();

        List<PRO_Contract_Snapshot__c> snapshots = [SELECT Id, Name, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Expected_Buffer__c,
                                                        Expense_And_Travel_Spend__c, Services_Spend__c, Total_Calculated_Costs__c, Product_Spend2__c, Net_Income_By_Deliverables_Complete__c,
                                                        Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c, Budget_Used__c
                                                        FROM PRO_Contract_Snapshot__c WHERE Contract__c =: dcontract.Id];

        System.assertEquals(1, snapshots.size());
        PRO_Contract_Snapshot__c snapshot = snapshots.get(0);

        assertSnapshotData(snapshot);
    }

    @isTest
    public static void jobShouldCreateSnapshotForActiveProject() {
        DContract__c dcontract = addContract();

        PRO_Contract_Snapshot__c proSn1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract.Id, Percent_Of_Work_Completed__c = 4, Snapshot_Date__c = Date.today().addDays(-40));
        insert proSn1;
        PRO_Contract_Snapshot__c proSn2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract.Id, Percent_Of_Work_Completed__c = 11, Snapshot_Date__c = Date.today().addDays(-20));
        insert proSn2;

        PROContractSnapshotBatch proContractSnapshotBatch = new PROContractSnapshotBatch();
        Database.BatchableContext bc;
        proContractSnapshotBatch.execute(bc, proContractSnapshotBatch.start(bc));


        List<PRO_Contract_Snapshot__c> snapshots = [SELECT Id, Name, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Expected_Buffer__c,
                                                Expense_And_Travel_Spend__c, Services_Spend__c, Total_Calculated_Costs__c, Product_Spend2__c, Net_Income_By_Deliverables_Complete__c,
                                                Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c, Budget_Used__c, Work_Completed_for_Period__c
                                                FROM PRO_Contract_Snapshot__c WHERE Contract__c =: dcontract.Id AND Id !=: proSn1.Id AND Id !=: proSn2.Id];

        System.assertEquals(1, snapshots.size());
        PRO_Contract_Snapshot__c snapshot = snapshots.get(0);

        assertSnapshotData(snapshot);
        System.assertEquals(19, snapshot.Work_Completed_for_Period__c);
    }

    @isTest
    public static void shouldCreatePipelineSnapshots() {
        Account acc1 = new Account(Name = 'Test');
        insert acc1;
        DContract__c dcontract1 = new DContract__c(
            Name = 'Sample Test 1', Status__c = 'Active', ALL_TIME_Income__c = 10000, Total_Amount_of_Contract__c = 14000, Percent_through_SOW_deliverables__c = 80,
            Account__c = acc1.Id, Total_Amount_REMAINING__c = 4000, Contract_Expense_BUDGET__c = 2000, Total_Direct_Costs_Expenses__c = 1000,
            Contract_End_Date__c = Date.today().addMonths(4), Date_of_Contract_Execution__c = Date.today().addMonths(4), Contract_Start_Date__c = Date.today().addMonths(-2),
            Country_Text__c = 'Country sample text', Expected_Buffer__c = 50, Direct_Costs_Total_Expenses__c = 1000, Funder_Account__c = acc1.Id, of_Services_budget_for_GS__c = 50,
            Intracompany_Sub_contract__c = 'No', Product_Text__c = 'Simple product text', Services_Spend__c = 2000);
        DContract__c dcontract2 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 2', Services_Spend__c = 155, Total_Amount_of_Contract__c = 5500);
        DContract__c dcontract3 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 3', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        DContract__c dcontract4 = new DContract__c(Date_of_Contract_Execution__c = Date.today(), Status__c = 'Complete', Name = 'Sample Test 4', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract1.Id, Services_Spend__c = 10);
        Pipeline_Snapshot__c ps2 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract2.Id, Services_Spend__c = 76);
        Pipeline_Snapshot__c ps3 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract3.Id, Services_Spend__c = 100);
        Pipeline_Snapshot__c ps4 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract1.Id, Services_Spend__c = 1);
        Pipeline_Snapshot__c ps5 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract2.Id, Services_Spend__c = 8);
        Pipeline_Snapshot__c ps6 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract3.Id, Services_Spend__c = 11);
        Pipeline_Snapshot__c ps7 = new Pipeline_Snapshot__c(Source_Type__c = 'Opportunity', Month_Date__c = Date.today(), Contract__c = dcontract3.Id, Services_Spend__c = 100);
        insert new List<Pipeline_Snapshot__c> { ps1, ps2, ps3, ps4, ps5, ps6, ps7 };

        System.assertEquals(7, [SELECT Id FROM Pipeline_Snapshot__c].size());
        Test.startTest();
        Database.executeBatch(new ContractPipelineSnapshotBatch(), 50);
        Test.stopTest();
        System.assertEquals(8, [SELECT Id FROM Pipeline_Snapshot__c].size()); // 1 Clsoed
        System.assertEquals(0, [SELECT Id FROM Pipeline_Snapshot__c WHERE Id IN: new List<Id> { ps1.Id, ps2.Id, ps3.Id }].size());
        System.assertEquals(4, [SELECT Id FROM Pipeline_Snapshot__c WHERE Id IN: new List<Id> { ps4.Id, ps5.Id, ps6.Id, ps7.Id }].size());

        System.assertEquals(1, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Closed' AND Month_Date__c =: Date.today()].size());
        System.assertEquals(0, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Total' AND Month_Date__c =: Date.today()].size());
        System.assertEquals(3, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Outstanding Contracted' AND Month_Date__c =: Date.today()].size());

        Pipeline_Snapshot__c test = [SELECT Id, Invoiced__c, Billing_Deficit__c, Billing_efficiency__c, Duration_months__c, GS_Net_Income_to_Date__c, Total_Calculated_Costs__c,
                                     Work_Completed__c, Contract_Total_Non_Expense_Income_Rmg__c, GS_Services_Completed__c, GS_Execution_Budget__c
                                     FROM Pipeline_Snapshot__c WHERE Month_Date__c =: Date.today() AND Contract__c =: dcontract1.Id AND Stage__c = 'Outstanding Contracted'];
        System.assertEquals(71.43, test.Invoiced__c);
        System.assertEquals(428.57, test.Billing_Deficit__c);
        System.assertEquals(89.29, test.Billing_efficiency__c);
        System.assertEquals(6, test.Duration_months__c);
        System.assertEquals(80, test.Work_Completed__c);
        System.assertEquals(3000, test.Contract_Total_Non_Expense_Income_Rmg__c);
        System.assertEquals(3000, test.GS_Execution_Budget__c);
        System.assertEquals(400, test.GS_Net_Income_to_Date__c);
        System.assertEquals(2400, test.GS_Services_Completed__c);
        System.assertEquals(2000, test.Total_Calculated_Costs__c);
    }

    @isTest
    public static void shouldCalculateForPeriodInPipelineSnapshot() {
        Account acc1 = new Account(Name = 'Test');
        insert acc1;
        DContract__c dcontract1 = new DContract__c(
            Name = 'Sample Test 1', Status__c = 'Active', ALL_TIME_Income__c = 10000, Total_Amount_of_Contract__c = 14000, Percent_through_SOW_deliverables__c = 80,
            Account__c = acc1.Id, Total_Amount_REMAINING__c = 4000, Contract_Expense_BUDGET__c = 2000, Total_Direct_Costs_Expenses__c = 1000,
            Contract_End_Date__c = Date.today().addMonths(4), Date_of_Contract_Execution__c = Date.today().addMonths(4), Contract_Start_Date__c = Date.today().addMonths(-2),
            Country_Text__c = 'Country sample text', Expected_Buffer__c = 50, Direct_Costs_Total_Expenses__c = 1000, Funder_Account__c = acc1.Id, of_Services_budget_for_GS__c = 50,
            Intracompany_Sub_contract__c = 'No', Product_Text__c = 'Simple product text', Services_Spend__c = 2000);
        DContract__c dcontract2 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 2', Services_Spend__c = 155, Total_Amount_of_Contract__c = 5500);
        DContract__c dcontract3 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 3', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        DContract__c dcontract4 = new DContract__c(Date_of_Contract_Execution__c = Date.today(), Status__c = 'Complete', Name = 'Sample Test 4', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract1.Id, Services_Spend__c = 10);
        Pipeline_Snapshot__c ps2 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract2.Id, Services_Spend__c = 76);
        Pipeline_Snapshot__c ps3 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract3.Id, Services_Spend__c = 100);
        Pipeline_Snapshot__c ps4 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract1.Id, Services_Spend__c = 1, Work_Completed__c = 50);
        Pipeline_Snapshot__c ps5 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract2.Id, Services_Spend__c = 8);
        Pipeline_Snapshot__c ps6 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addMonths(-1), Contract__c = dcontract3.Id, Services_Spend__c = 11);
        Pipeline_Snapshot__c ps7 = new Pipeline_Snapshot__c(Source_Type__c = 'Opportunity', Month_Date__c = Date.today(), Contract__c = dcontract3.Id, Services_Spend__c = 100);
        insert new List<Pipeline_Snapshot__c> { ps1, ps2, ps3, ps4, ps5, ps6, ps7 };

        System.assertEquals(7, [SELECT Id FROM Pipeline_Snapshot__c].size());
        Test.startTest();
        Database.executeBatch(new ContractPipelineSnapshotBatch(), 50);
        Test.stopTest();
        System.assertEquals(8, [SELECT Id FROM Pipeline_Snapshot__c].size()); // +1 Clsoed
        System.assertEquals(0, [SELECT Id FROM Pipeline_Snapshot__c WHERE Id IN: new List<Id> { ps1.Id, ps2.Id, ps3.Id }].size());
        System.assertEquals(4, [SELECT Id FROM Pipeline_Snapshot__c WHERE Id IN: new List<Id> { ps4.Id, ps5.Id, ps6.Id, ps7.Id }].size());

        System.assertEquals(1, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Closed' AND Month_Date__c =: Date.today()].size());
        System.assertEquals(0, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Total' AND Month_Date__c =: Date.today()].size());
        System.assertEquals(3, [SELECT Id FROM Pipeline_Snapshot__c WHERE Stage__c = 'Outstanding Contracted' AND Month_Date__c =: Date.today()].size());
        Pipeline_Snapshot__c test = [SELECT Id, Services_Spend_for_Period__c, Work_Completed_for_Period__c
                                     FROM Pipeline_Snapshot__c WHERE Month_Date__c =: Date.today() AND Contract__c =: dcontract1.Id AND Stage__c = 'Outstanding Contracted'];
        System.assertEquals(1999, test.Services_Spend_for_Period__c);
        System.assertEquals(30, test.Work_Completed_for_Period__c);
    }

    @isTest
    public static void testContractPipelineSnapshotsController() {
        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        Date testDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);

        DContract__c dcontract1 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 1', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 2', Services_Spend__c = 155, Total_Amount_of_Contract__c = 5500);
        DContract__c dcontract3 = new DContract__c(Status__c = 'Active', Name = 'Sample Test 3', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        DContract__c dcontract4 = new DContract__c(Date_of_Contract_Execution__c = testDate, Status__c = 'Complete', Name = 'Sample Test 4', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate, Contract__c = dcontract1.Id, Services_Spend__c = 10);
        Pipeline_Snapshot__c ps2 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate, Contract__c = dcontract2.Id, Services_Spend__c = 76);
        Pipeline_Snapshot__c ps3 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate, Contract__c = dcontract3.Id, Services_Spend__c = 100);
        Pipeline_Snapshot__c ps4 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate.addMonths(-1), Contract__c = dcontract1.Id, Services_Spend__c = 1);
        Pipeline_Snapshot__c ps5 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate.addMonths(-1), Contract__c = dcontract2.Id, Services_Spend__c = 8);
        Pipeline_Snapshot__c ps6 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = testDate.addMonths(-1), Contract__c = dcontract3.Id, Services_Spend__c = 11);
        Pipeline_Snapshot__c ps7 = new Pipeline_Snapshot__c(Source_Type__c = 'Opportunity', Month_Date__c = testDate, Contract__c = dcontract3.Id, Services_Spend__c = 100);
        insert new List<Pipeline_Snapshot__c> { ps1, ps2, ps3, ps4, ps5, ps6, ps7 };

        Test.startTest();
        ContractPipelineSnapshotController ctrl = new ContractPipelineSnapshotController();
        ctrl.initPipelineSnapshot();
        System.assertEquals(testDate, ctrl.lastMonthSnapshotDate);
        System.assertEquals(3, ctrl.currentPSCount);

        List<Pipeline_Snapshot__c> testResult = ctrl.getSnpList();
        System.assertEquals(3, testResult.size());
        System.assertEquals(3, ctrl.pagination.resultSize);
        System.assertEquals(10, ctrl.pagination.pageSize);
        System.assertEquals(1, ctrl.pagination.pageNumber);
        System.assertEquals(false, ctrl.pagination.hasNext);
        System.assertEquals(false, ctrl.pagination.hasPrevious);
        ctrl.runPipelineSnapshotJob();
        Test.stopTest();
        ctrl = new ContractPipelineSnapshotController();
        ctrl.initPipelineSnapshot();
        System.assertEquals(4, ctrl.currentPSCount); // 3 + 1 closed
    }

    @isTest
    public static void shouldCalculateGSRevenue() {
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;

        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 10, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 1000); // 5
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 20, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 2000); // 30
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 30, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 3000); // 22
        DContract__c dcontract4 = new DContract__c(Name = 'Sample Test 4', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 40, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 4000); // 40
        insert dcontract1;
        insert dcontract2;
        insert dcontract3;
        insert dcontract4;

        PRO_Contract_Snapshot__c proS1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                Work_Completed_for_Period__c = 5, GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 9));
        PRO_Contract_Snapshot__c proS2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                Work_Completed_for_Period__c = 5, GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS3 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                Work_Completed_for_Period__c = 5, GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS4 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                Work_Completed_for_Period__c = 5, GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 9));
        PRO_Contract_Snapshot__c proS5 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 444, Customer_Satisfaction_of_services__c = 223,
                                                                Work_Completed_for_Period__c = 3, GS_Execution_Budget__c = 1367, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS6 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 678, Customer_Satisfaction_of_services__c = 900,
                                                                Work_Completed_for_Period__c = 7, GS_Execution_Budget__c = 1333, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS7 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                Work_Completed_for_Period__c = 7, GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS8 = new PRO_Contract_Snapshot__c(Contract__c = dcontract4.Id, GS_Project_Services_Budget_Handoff_Cp__c = 1000, Project_Quality_Overall_Status__c = 543, Customer_Satisfaction_of_services__c = 776,
                                                                Work_Completed_for_Period__c = 15, GS_Execution_Budget__c = 4567, Snapshot_Date__c = Date.newInstance(2017, 2, 23));

        insert proS1;
        insert proS2;
        insert proS3;
        insert proS4;
        insert proS5;
        insert proS6;
        insert proS7;
        insert proS8;

        Test.startTest();
        Database.executeBatch(new GSOverallCalculationBatch(Date.newInstance(2017, 3, 8)));
        Test.stopTest();

        Contract_Statistic__c proDromDB = [SELECT Id, Inc_GS_Revenue__c FROM Contract_Statistic__c LIMIT 1];
        Decimal value = proDromDB.Inc_GS_Revenue__c;
        System.assertEquals(300.00, value.setScale(2));
    }

    @isTest
    public static void shouldCalculateGSQualitySituation1() {
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;
        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 10, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 20, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 2000);
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 30, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 3000);
        DContract__c dcontract4 = new DContract__c(Name = 'Sample Test 4', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 40, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 4000);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        PRO_Contract_Snapshot__c proS1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 9));
        PRO_Contract_Snapshot__c proS2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS3 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS4 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 9));
        PRO_Contract_Snapshot__c proS5 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 444, Customer_Satisfaction_of_services__c = 223,
                                                                GS_Execution_Budget__c = 1367, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS6 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 678, Customer_Satisfaction_of_services__c = 900,
                                                                GS_Execution_Budget__c = 1333, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS7 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS8 = new PRO_Contract_Snapshot__c(Contract__c = dcontract4.Id, Project_Quality_Overall_Status__c = 543, Customer_Satisfaction_of_services__c = 776,
                                                                GS_Execution_Budget__c = 4567, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        insert new List<PRO_Contract_Snapshot__c> { proS1, proS2, proS3, proS4, proS5, proS6, proS7, proS8 };

        Project_Report_Out__c pro1 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS1.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 9));
        Project_Report_Out__c pro2 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS2.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));
        Project_Report_Out__c pro3 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS3.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));

        Project_Report_Out__c pro4 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS4.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 9));
        Project_Report_Out__c pro5 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS5.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));

        Project_Report_Out__c pro6 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS6.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));
        Project_Report_Out__c pro7 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS7.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));

        Project_Report_Out__c pro8 = new Project_Report_Out__c(Contract__c = dcontract4.Id, Contract_Snapshot__c = proS8.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));

        insert new List<Project_Report_Out__c> { pro1, pro2, pro3, pro4, pro5, pro6, pro7, pro8 };

        Test.startTest();
        Database.executeBatch(new GSOverallCalculationBatch(Date.newInstance(2017, 3, 8)));
        Test.stopTest();

        Contract_Statistic__c proDromDB = [SELECT Id, Inc_GS_Customer_Sat__c, Inc_GS_Overall_Status__c FROM Contract_Statistic__c LIMIT 1];
        Decimal value = proDromDB.Inc_GS_Overall_Status__c;
        System.assertEquals(24.98, value.setScale(2));
        value = proDromDB.Inc_GS_Customer_Sat__c;
        System.assertEquals(25.99, value.setScale(2));
        // Expected Value = (400 + 444 + 678 + 543) / (1000 + 1367 + 1333 + 4567) = 2065 / 8267 = 24,97
        // Expected Value (Customer) = (250 + 223 + 900 + 776) / (1000 + 1367 + 1333 + 4567) = 2149 / 8267 = 25,99
    }

    @isTest
    public static void shouldCalculateGSQualitySituation2() {
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;
        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 10, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 20, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 2000);
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 30, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 3000);
        DContract__c dcontract4 = new DContract__c(Name = 'Sample Test 4', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 40, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 4000);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        PRO_Contract_Snapshot__c proS1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS3 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        PRO_Contract_Snapshot__c proS4 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 2, 23));
        PRO_Contract_Snapshot__c proS5 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 444, Customer_Satisfaction_of_services__c = 223,
                                                                GS_Execution_Budget__c = 1367, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS6 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 678, Customer_Satisfaction_of_services__c = 900,
                                                                GS_Execution_Budget__c = 1333, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS7 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        PRO_Contract_Snapshot__c proS8 = new PRO_Contract_Snapshot__c(Contract__c = dcontract4.Id, Project_Quality_Overall_Status__c = 543, Customer_Satisfaction_of_services__c = 776,
                                                                GS_Execution_Budget__c = 4567, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        insert new List<PRO_Contract_Snapshot__c> { proS1, proS2, proS3, proS4, proS5, proS6, proS7, proS8 };

        Project_Report_Out__c pro1 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS1.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));
        Project_Report_Out__c pro2 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS2.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));
        Project_Report_Out__c pro3 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS3.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));

        Project_Report_Out__c pro4 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS4.Id, Report_Out_Date__c = Date.newInstance(2017, 2, 23));
        Project_Report_Out__c pro5 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS5.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));

        Project_Report_Out__c pro6 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS6.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));
        Project_Report_Out__c pro7 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS7.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));

        Project_Report_Out__c pro8 = new Project_Report_Out__c(Contract__c = dcontract4.Id, Contract_Snapshot__c = proS8.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));
        insert new List<Project_Report_Out__c> { pro1, pro2, pro3, pro4, pro5, pro6, pro7, pro8 };

        Test.startTest();
        Database.executeBatch(new GSOverallCalculationBatch(Date.newInstance(2017, 3, 22)));
        Test.stopTest();

        Contract_Statistic__c proDromDB = [SELECT Id, Inc_GS_Customer_Sat__c, Inc_GS_Overall_Status__c FROM Contract_Statistic__c LIMIT 1];
        Decimal value = proDromDB.Inc_GS_Overall_Status__c;
        System.assertEquals(24.98, value.setScale(2));
        value = proDromDB.Inc_GS_Customer_Sat__c;
        System.assertEquals(25.99, value.setScale(2));
        // Expected Value = (400 + 444 + 678 + 543) / (1000 + 1367 + 1333 + 4567) = 2065 / 8267 = 24,97
        // Expected Value (Customer) = (250 + 223 + 900 + 776) / (1000 + 1367 + 1333 + 4567) = 2149 / 8267 = 25,99
    }

    @isTest
    public static void shouldCalculateGSQualitySituation3() {
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;
        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 10, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 20, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 2000);
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 30, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 3000);
        DContract__c dcontract4 = new DContract__c(Name = 'Sample Test 4', Prime_Contracting_Business_Unit__c = bu.Id, Percent_through_SOW_deliverables__c = 40, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 4000);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        PRO_Contract_Snapshot__c proS1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        PRO_Contract_Snapshot__c proS3 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 4, 13));
        PRO_Contract_Snapshot__c proS4 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 3, 9));
        PRO_Contract_Snapshot__c proS5 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 444, Customer_Satisfaction_of_services__c = 223,
                                                                GS_Execution_Budget__c = 1367, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        PRO_Contract_Snapshot__c proS6 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 678, Customer_Satisfaction_of_services__c = 900,
                                                                GS_Execution_Budget__c = 1333, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        PRO_Contract_Snapshot__c proS7 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 250,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 4, 13));
        PRO_Contract_Snapshot__c proS8 = new PRO_Contract_Snapshot__c(Contract__c = dcontract4.Id, Project_Quality_Overall_Status__c = 543, Customer_Satisfaction_of_services__c = 776,
                                                                GS_Execution_Budget__c = 4567, Snapshot_Date__c = Date.newInstance(2017, 3, 23));
        insert new List<PRO_Contract_Snapshot__c> { proS1, proS2, proS3, proS4, proS5, proS6, proS7, proS8 };

        Project_Report_Out__c pro1 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS1.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));
        Project_Report_Out__c pro2 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS2.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));
        Project_Report_Out__c pro3 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS3.Id, Report_Out_Date__c = Date.newInstance(2017, 4, 13));

        Project_Report_Out__c pro4 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS4.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 9));
        Project_Report_Out__c pro5 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS5.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));

        Project_Report_Out__c pro6 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS6.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));
        Project_Report_Out__c pro7 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS7.Id, Report_Out_Date__c = Date.newInstance(2017, 4, 13));

        Project_Report_Out__c pro8 = new Project_Report_Out__c(Contract__c = dcontract4.Id, Contract_Snapshot__c = proS8.Id, Report_Out_Date__c = Date.newInstance(2017, 3, 23));
        insert new List<Project_Report_Out__c> { pro1, pro2, pro3, pro4, pro5, pro6, pro7, pro8 };

        Test.startTest();
        Database.executeBatch(new GSOverallCalculationBatch(Date.newInstance(2017, 3, 27)));
        Test.stopTest();

        Contract_Statistic__c proDromDB = [SELECT Id, Inc_GS_Customer_Sat__c, Inc_GS_Overall_Status__c FROM Contract_Statistic__c LIMIT 1];
        Decimal value = proDromDB.Inc_GS_Overall_Status__c;
        System.assertEquals(24.98, value.setScale(2));
        value = proDromDB.Inc_GS_Customer_Sat__c;
        System.assertEquals(25.99, value.setScale(2));
        // Expected Value = (400 + 444 + 678 + 543) / (1000 + 1367 + 1333 + 4567) = 2065 / 8267 = 24,97
        // Expected Value (Customer) = (250 + 223 + 900 + 776) / (1000 + 1367 + 1333 + 4567) = 2149 / 8267 = 25,99
    }

    @isTest
    public static void shouldCalculateGSQualityTotal() {
        Business_Unit__c bu1 = new Business_Unit__c(Name = 'Inc');
        insert bu1;
        Business_Unit__c bu2 = new Business_Unit__c(Name = 'DSI');
        insert bu2;
        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Prime_Contracting_Business_Unit__c = bu1.Id, Percent_through_SOW_deliverables__c = 10, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Prime_Contracting_Business_Unit__c = bu1.Id, Percent_through_SOW_deliverables__c = 20, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 2000);
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Prime_Contracting_Business_Unit__c = bu2.Id, Percent_through_SOW_deliverables__c = 30, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 3000);
        DContract__c dcontract4 = new DContract__c(Name = 'Sample Test 4', Prime_Contracting_Business_Unit__c = bu2.Id, Percent_through_SOW_deliverables__c = 40, Expected_Buffer__c = 0,
                                                   Contract_Expense_BUDGET__c = 0, of_Services_budget_for_GS__c = 100, Total_Amount_of_Contract__c = 4000);
        insert new List<DContract__c> { dcontract1, dcontract2, dcontract3, dcontract4 };

        PRO_Contract_Snapshot__c proS1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract1.Id, Project_Quality_Overall_Status__c = 200, Customer_Satisfaction_of_services__c = 100,
                                                                GS_Execution_Budget__c = 500, Snapshot_Date__c = Date.newInstance(2017, 1, 26));
        PRO_Contract_Snapshot__c proS2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract2.Id, Project_Quality_Overall_Status__c = 400, Customer_Satisfaction_of_services__c = 200,
                                                                GS_Execution_Budget__c = 900, Snapshot_Date__c = Date.newInstance(2017, 1, 26));
        PRO_Contract_Snapshot__c proS3 = new PRO_Contract_Snapshot__c(Contract__c = dcontract3.Id, Project_Quality_Overall_Status__c = 600, Customer_Satisfaction_of_services__c = 300,
                                                                GS_Execution_Budget__c = 1000, Snapshot_Date__c = Date.newInstance(2017, 1, 26));
        PRO_Contract_Snapshot__c proS4 = new PRO_Contract_Snapshot__c(Contract__c = dcontract4.Id, Project_Quality_Overall_Status__c = 800, Customer_Satisfaction_of_services__c = 400,
                                                                GS_Execution_Budget__c = 1500, Snapshot_Date__c = Date.newInstance(2017, 1, 26));
        insert new List<PRO_Contract_Snapshot__c> { proS1, proS2, proS3, proS4 };

        Project_Report_Out__c pro1 = new Project_Report_Out__c(Contract__c = dcontract1.Id, Contract_Snapshot__c = proS1.Id, Report_Out_Date__c = Date.newInstance(2017, 1, 26));
        Project_Report_Out__c pro2 = new Project_Report_Out__c(Contract__c = dcontract2.Id, Contract_Snapshot__c = proS2.Id, Report_Out_Date__c = Date.newInstance(2017, 1, 26));
        Project_Report_Out__c pro3 = new Project_Report_Out__c(Contract__c = dcontract3.Id, Contract_Snapshot__c = proS3.Id, Report_Out_Date__c = Date.newInstance(2017, 1, 26));
        Project_Report_Out__c pro4 = new Project_Report_Out__c(Contract__c = dcontract4.Id, Contract_Snapshot__c = proS4.Id, Report_Out_Date__c = Date.newInstance(2017, 1, 26));
        insert new List<Project_Report_Out__c> { pro1, pro2, pro3, pro4 };

        Test.startTest();
        Database.executeBatch(new GSOverallCalculationBatch(Date.newInstance(2017, 2, 8)));
        Test.stopTest();

        Contract_Statistic__c proDromDB = [SELECT Id, GS_Quality_Total_Overall_Status__c, GS_Quality_Total_Customer_Satisfaction__c FROM Contract_Statistic__c LIMIT 1];
        Decimal value = proDromDB.GS_Quality_Total_Overall_Status__c;
        System.debug('GS_Quality_Total_Overall_Status__c' + proDromDB.GS_Quality_Total_Overall_Status__c);
        System.assertEquals(51.28, value.setScale(2));
        value = proDromDB.GS_Quality_Total_Customer_Satisfaction__c;
        System.assertEquals(25.64, value.setScale(2));
        // Expected Value = (200 + 400 + 600 + 800) / (500 + 900 + 1000 + 1500) = 2000 / 3900 = 51,28
        // Expected Value (Customer) = (100 + 200 + 300 + 400) / (500 + 900 + 1000 + 1500) = 1000 / 3900 = 25,64
    }

    private static void assertSnapshotData(PRO_Contract_Snapshot__c snapshot) {
        System.assertEquals('Sample Test Name', snapshot.Name);
        System.assertEquals(30, snapshot.Percent_Of_Work_Completed__c);
        System.assertEquals(35, snapshot.Percent_Services_Budget_For_GS__c);
        System.assertEquals(50, snapshot.Expected_Buffer__c);
        System.assertEquals(5000, snapshot.Expense_And_Travel_Spend__c);
        System.assertEquals(2500, snapshot.Services_Spend__c);
        System.assertEquals(6000, snapshot.Total_Calculated_Costs__c);
        System.assertEquals(1000, snapshot.Product_Spend2__c);
        System.assertEquals(-2400, snapshot.Net_Income_By_Deliverables_Complete__c);
        System.assertEquals(60, snapshot.Execution_Efficiency__c);
        System.assertEquals(-28, snapshot.Buffer_By_Deliverables_Complete__c);
        System.assertEquals(58, snapshot.Budget_Used__c);
    }

    private static DContract__c addContract() {
        DContract__c dcontract = new DContract__c();

        dcontract.Name = 'Sample Test Name';
        dcontract.Percent_through_SOW_deliverables__c = 30;
        dcontract.of_Services_budget_for_GS__c = 35;
        dcontract.Expected_Buffer__c = 50;
        dcontract.Direct_Costs_Total_Expenses__c = 5000;
        dcontract.Services_Spend__c = 2500;
        dcontract.Contract_Expense_BUDGET__c = 2000;
        dcontract.Total_Amount_of_Contract__c = 12000;
        dcontract.Product_Income_Budget__c = 4000;
        dcontract.Contract_Start_Date__c = Date.today().addDays(-1);
        dcontract.Contract_End_Date__c = Date.today().addDays(3);
        dcontract.Direct_Costs_Sub_contract_Expenses__c = 300;
        dcontract.Direct_Costs_Travel_Expenses__c = 125;
        dcontract.Total_Direct_Costs__c = 3700;
        dcontract.Internal_Sub_contract_Spend__c = 200;

        dcontract.Status__c = 'Active';
        dcontract.Requires_Report_Out__c = 'No';

        insert dcontract;
        return dcontract;
    }
}