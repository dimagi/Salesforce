@isTest
public class ContractSnapshotTest {

    static testMethod void shouldCreateSnapshotAfterSubmitingPRO() {
        ProjectReportOutController projectReportOutController = new ProjectReportOutController();

        projectReportOutController.pro = new Project_Report_Out__c();
        projectReportOutController.pro.PM_email__c = 'tomek.stalka@gmail.com';
        projectReportOutController.pro.Report_Out_Date__c = Date.today();

        DContract__c dcontract = addContract();

        projectReportOutController.reportContractId = dcontract.Id;
        projectReportOutController.contractIdName = new Map<Id, DContract__C> {};
        projectReportOutController.contractIdName.put(dcontract.Id, dcontract);
        projectReportOutController.status = 'Active';
        projectReportOutController.toMeetSchedule = 'Green';
        projectReportOutController.stayWithinScope = 'Green';
        projectReportOutController.currentSystemUsage = 'Green';
        projectReportOutController.partnerRelationship = 'Green';
        projectReportOutController.proTabContractPercntgethroughSOW = 30;

        projectReportOutController.save();

        List<PRO_Contract_Snapshot__c> snapshots = [SELECT Id, Name, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Expected_Buffer__c,
                                                        Expense_And_Travel_Spend__c, Services_Spend__c, Total_Calculated_Costs__c, Product_Spend__c, Net_Income_By_Deliverables_Complete__c,
                                                        Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c, Budget_Used__c
                                                        FROM PRO_Contract_Snapshot__c WHERE Contract__c =: dcontract.Id];

        System.assertEquals(1, snapshots.size());
        PRO_Contract_Snapshot__c snapshot = snapshots.get(0);

        assertSnapshotData(snapshot);
    }

    static testMethod void jobShouldCreateSnapshotForActiveProject() {
        DContract__c dcontract = addContract();

        PRO_Contract_Snapshot__c proSn1 = new PRO_Contract_Snapshot__c(Contract__c = dcontract.Id, Percent_Of_Work_Completed__c = 4, Snapshot_Date__c = Date.today().addDays(-40));
        insert proSn1;
        PRO_Contract_Snapshot__c proSn2 = new PRO_Contract_Snapshot__c(Contract__c = dcontract.Id, Percent_Of_Work_Completed__c = 11, Snapshot_Date__c = Date.today().addDays(-20));
        insert proSn2;

        PROContractSnapshotBatch proContractSnapshotBatch = new PROContractSnapshotBatch();
        Database.BatchableContext bc;
        proContractSnapshotBatch.execute(bc, proContractSnapshotBatch.start(bc));


        List<PRO_Contract_Snapshot__c> snapshots = [SELECT Id, Name, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Expected_Buffer__c,
                                                Expense_And_Travel_Spend__c, Services_Spend__c, Total_Calculated_Costs__c, Product_Spend__c, Net_Income_By_Deliverables_Complete__c,
                                                Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c, Budget_Used__c, Work_Completed_for_Period__c
                                                FROM PRO_Contract_Snapshot__c WHERE Contract__c =: dcontract.Id AND Id !=: proSn1.Id AND Id !=: proSn2.Id];

        System.assertEquals(1, snapshots.size());
        PRO_Contract_Snapshot__c snapshot = snapshots.get(0);

        assertSnapshotData(snapshot);
        System.assertEquals(19, snapshot.Work_Completed_for_Period__c);
    }

    static testMethod void shouldCalculateForPeriodInPipelineSnapshot() {
        DContract__c dcontract1 = new DContract__c(Name = 'Sample Test 1', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000);
        DContract__c dcontract2 = new DContract__c(Name = 'Sample Test 2', Services_Spend__c = 155, Total_Amount_of_Contract__c = 5500);
        DContract__c dcontract3 = new DContract__c(Name = 'Sample Test 3', Services_Spend__c = 23, Total_Amount_of_Contract__c = 222);
        insert dcontract1;
        insert dcontract2;
        insert dcontract3;

        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addDays(-10), Contract__c = dcontract1.Id, Services_Spend__c = 10);
        Pipeline_Snapshot__c ps2 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract1.Id, Services_Spend__c = 76);
        Pipeline_Snapshot__c ps3 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract3.Id, Services_Spend__c = 100);
        Pipeline_Snapshot__c ps4 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addDays(-50), Contract__c = dcontract2.Id, Services_Spend__c = 1);
        Pipeline_Snapshot__c ps5 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today().addDays(-30), Contract__c = dcontract2.Id, Services_Spend__c = 8);
        Pipeline_Snapshot__c ps6 = new Pipeline_Snapshot__c(Source_Type__c = 'Contract', Month_Date__c = Date.today(), Contract__c = dcontract2.Id, Services_Spend__c = 11);
        insert ps1;
        insert ps2;
        insert ps3;
        insert ps4;
        insert ps5;
        insert ps6;
        Test.setCreatedDate(ps1.Id, DateTime.now().addDays(-6));
        Test.setCreatedDate(ps4.Id, DateTime.now().addDays(-6));
        Test.setCreatedDate(ps5.Id, DateTime.now().addDays(-6));

        Test.startTest();
        Database.executeBatch(new ForPeriodCalcSnapshotBatch(false), 50);
        Test.stopTest();

        Pipeline_Snapshot__c psFromDB = [SELECT Id, Services_Spend_for_Period__c FROM Pipeline_Snapshot__c WHERE Id =: ps2.Id];
        System.assertEquals(66, psFromDB.Services_Spend_for_Period__c);
        psFromDB = [SELECT Id, Services_Spend_for_Period__c FROM Pipeline_Snapshot__c WHERE Id =: ps4.Id];
        System.assertEquals(null, psFromDB.Services_Spend_for_Period__c);
        psFromDB = [SELECT Id, Services_Spend_for_Period__c FROM Pipeline_Snapshot__c WHERE Id =: ps6.Id];
        System.assertEquals(3, psFromDB.Services_Spend_for_Period__c);
    }

    static testMethod void shouldCalculateGSRevenue() {
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

        Test.startTest();
        Database.executeBatch(new GSRevenueCalculationBatch([SELECT Id FROM Business_Unit__c]));
        Test.stopTest();

        DContract__c conFromDB = [SELECT Id, GS_Revenue__c FROM DContract__c WHERE Id =: dcontract1.Id LIMIT 1];
        System.assertEquals(2910, conFromDB.GS_Revenue__c);
        conFromDB = [SELECT Id, GS_Revenue__c FROM DContract__c WHERE Id =: dcontract2.Id LIMIT 1];
        System.assertEquals(2910, conFromDB.GS_Revenue__c);
        conFromDB = [SELECT Id, GS_Revenue__c FROM DContract__c WHERE Id =: dcontract3.Id LIMIT 1];
        System.assertEquals(2910, conFromDB.GS_Revenue__c);
        conFromDB = [SELECT Id, GS_Revenue__c FROM DContract__c WHERE Id =: dcontract4.Id LIMIT 1];
        System.assertEquals(2910, conFromDB.GS_Revenue__c);
    }

    static private void assertSnapshotData(PRO_Contract_Snapshot__c snapshot) {
        System.assertEquals('Sample Test Name', snapshot.Name);
        System.assertEquals(30, snapshot.Percent_Of_Work_Completed__c);
        System.assertEquals(35, snapshot.Percent_Services_Budget_For_GS__c);
        System.assertEquals(50, snapshot.Expected_Buffer__c);
        System.assertEquals(5000, snapshot.Expense_And_Travel_Spend__c);
        System.assertEquals(2500, snapshot.Services_Spend__c);
        System.assertEquals(6000, snapshot.Total_Calculated_Costs__c);
        System.assertEquals(1000, snapshot.Product_Spend__c);
        System.assertEquals(-2400, snapshot.Net_Income_By_Deliverables_Complete__c);
        System.assertEquals(60, snapshot.Execution_Efficiency__c);
        System.assertEquals(-28, snapshot.Buffer_By_Deliverables_Complete__c);
        System.assertEquals(58, snapshot.Budget_Used__c);
    }

    static private DContract__c addContract() {
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