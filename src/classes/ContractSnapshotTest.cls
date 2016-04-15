@isTest(SeeAllData=true)
public class ContractSnapshotTest {

    static testMethod void shouldCreateSnapshotAfterSubmitingPRO() {
        ProjectReportOutController projectReportOutController = new ProjectReportOutController();

        projectReportOutController.pro = new Project_Report_Out__c();
        projectReportOutController.pro.PM_email__c = 'tomek.stalka@gmail.com';
        projectReportOutController.pro.Report_Out_Date__c = Date.today();

        DContract__c dcontract = addContract();

        projectReportOutController.contractId = dcontract.Id;
        projectReportOutController.contractIdName = new Map<Id, DContract__C> {};
        projectReportOutController.contractIdName.put(dcontract.Id, dcontract);
        projectReportOutController.status = 'Active';
        projectReportOutController.ToMeetSchedule = 'Green';
        projectReportOutController.StayWithinScope = 'Green';
        projectReportOutController.CurrentSystemUsage = 'Green';
        projectReportOutController.PartnerRelationship = 'Green';
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

        PROContractSnapshotBatch proContractSnapshotBatch = new PROContractSnapshotBatch();
        Database.BatchableContext bc;
        proContractSnapshotBatch.execute(bc, proContractSnapshotBatch.start(bc));


        List<PRO_Contract_Snapshot__c> snapshots = [SELECT Id, Name, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Expected_Buffer__c,
                                                Expense_And_Travel_Spend__c, Services_Spend__c, Total_Calculated_Costs__c, Product_Spend__c, Net_Income_By_Deliverables_Complete__c,
                                                Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c, Budget_Used__c
                                                FROM PRO_Contract_Snapshot__c WHERE Contract__c =: dcontract.Id];

        System.assertEquals(1, snapshots.size());
        PRO_Contract_Snapshot__c snapshot = snapshots.get(0);

        assertSnapshotData(snapshot);
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