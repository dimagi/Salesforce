@isTest
public class AggregateExecutionEfficiencyTest {

    @testSetup
    public static void setUpContractsData() {
        Business_Unit__c bu1 = new Business_Unit__c(Name = 'Bad');
        Business_Unit__c bu2 = new Business_Unit__c(Name = 'DLAC');
        Business_Unit__c bu3 = new Business_Unit__c(Name = 'DSI');
        insert new List<Business_Unit__c> {bu1, bu2, bu3};

        // SUM(Services_Budget__c) = 4000 + 20000 + 10000 = 34000
        // SUM(Weighted_Efficiency__c) = (4000 * 50% / 1000), (20000 * 45% / 9000), (10000 * 40% / 4000) => 2,  1, 1 => 4000 * 2 + 20000 * 1 + 10000 * 1 = 38000
        insert new DContract__c(Name = 'AEE Contract 1', Efficiency_Owner_BU__c = bu2.Id, Total_Amount_of_Contract__c = 4000, Services_Spend__c = 1000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 50);
        insert new DContract__c(Name = 'AEE Contract 2', Efficiency_Owner_BU__c = bu2.Id, Total_Amount_of_Contract__c = 20000, Services_Spend__c = 9000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 45);
        insert new DContract__c(Name = 'AEE Contract 3', Efficiency_Owner_BU__c = bu2.Id, Total_Amount_of_Contract__c = 10000, Services_Spend__c = 4000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 40);

        // SUM(Services_Budget__c) = 4000 + 40000 + 7000 = 51000
        // SUM(Weighted_Efficiency__c) = (4000 * 50% / 1000) + (40000 * 80% / 25000) + (7000 * 30% / 2500) => 2, 1.28, 0.84 => 4000 * 2 + 40000 * 1.28 + 7000 * 0.84 = 8000 + 51200 + 5880 = 65080
        insert new DContract__c(Name = 'AEE Contract 4', Efficiency_Owner_BU__c = bu3.Id, Total_Amount_of_Contract__c = 4000, Services_Spend__c = 1000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 50);
        insert new DContract__c(Name = 'AEE Contract 5', Efficiency_Owner_BU__c = bu3.Id, Total_Amount_of_Contract__c = 40000, Services_Spend__c = 25000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 80);
        insert new DContract__c(Name = 'AEE Contract 6', Efficiency_Owner_BU__c = bu3.Id, Total_Amount_of_Contract__c = 7000, Services_Spend__c = 2500, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 30);

        // To skip
        insert new DContract__c(Name = 'AEE internal 7', Efficiency_Owner_BU__c = bu3.Id, Total_Amount_of_Contract__c = 4000, Services_Spend__c = 1000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 50);
        insert new DContract__c(Name = 'AEE Contract 8', Efficiency_Owner_BU__c = bu1.Id, Total_Amount_of_Contract__c = 4000, Services_Spend__c = 1000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 50);
        insert new DContract__c(Name = 'AEE Contract 9', Efficiency_Owner_BU__c = bu1.Id, Total_Amount_of_Contract__c = 4000, Services_Spend__c = 1000, Intracompany_Sub_contract__c = 'No',
                                Percent_through_SOW_deliverables__c = 50);
    }

    @isTest
    public static void shouldGenerateSnapshots() {
        Test.startTest();
        AggregateExecutionEfficiencySnpJob.createAggregateExecutionEfficiencySnapshot();
        Test.stopTest();
        assertData();
    }

    @isTest
    public static void shouldGenerateSnapshotsScheduler() {
        Test.startTest();
        AggregateExecutionEfficiencyScheduler aeeScheduler = new AggregateExecutionEfficiencyScheduler();
        aeeScheduler.execute(null);
        Test.stopTest();
        assertData();
    }

    private static void assertData() {
        System.assertNotEquals(null, [SELECT Id FROM Aggregate_Execution_Efficiency_Snapshot__c LIMIT 1]);
        Aggregate_Execution_Efficiency_Snapshot__c snp = [SELECT Id, Date__c, DLAC__c, DSA__c, DSI__c, DWA__c, INC__c, Total_Aggregate_Execution_Efficiency__c
                                                          FROM Aggregate_Execution_Efficiency_Snapshot__c LIMIT 1];
        System.debug('snp : ' + snp);
        System.assertEquals(Date.today().addDays(-1), snp.Date__c);
        System.assertEquals(((38000.00 + 65080.00) / (34000.00 + 51000.00)) * 100.00, snp.Total_Aggregate_Execution_Efficiency__c);
        System.assertEquals((38000.00 / 34000.00) * 100.00, snp.DLAC__c);
        System.assertEquals(0, snp.DSA__c);
        System.assertEquals((65080.00 / 51000.00) * 100.00, snp.DSI__c);
        System.assertEquals(0, snp.DWA__c);
        System.assertEquals(0, snp.INC__c);
    }
}