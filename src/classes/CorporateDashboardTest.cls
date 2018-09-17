@isTest
public class CorporateDashboardTest {

    @testSetup
    static void setup() {
        Date currentDay = Date.today();
        Integer currentYear = currentDay.year();
        Date fiscalYearStart = Date.newInstance(currentYear, 1, 1);
        Date fiscalYearEnd = Date.newInstance(currentYear, 12, 31);
        Corporate_Dashboard_Settings__c setting = Corporate_Dashboard_Settings__c.getOrgDefaults();
        setting.Fiscal_Year_Start__c = fiscalYearStart;
        setting.Fiscal_year_End__c = fiscalYearEnd;
        setting.EV_Target__c = 2000000;
        setting.EV_Expected_Buffer_Target__c = 2000000;
        setting.Opp_Won_Target__c = 2000000;
        insert setting;
    }

    @isTest
    public static void shouldLoadGSRevenue() {
        setUpGSRevenueData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> gsRevenueGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c
                                                   FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.GS_REVENUE
                                                   ORDER BY Helper_Date__c DESC];

        System.assertEquals(11, gsRevenueGraph.get(0).Graph_Value_1__c);
        System.assertEquals(5.25, gsRevenueGraph.get(0).Graph_Value_2__c);
        System.assertEquals(15.25, gsRevenueGraph.get(0).Graph_Value_3__c);

        System.assertEquals(1, gsRevenueGraph.get(1).Graph_Value_1__c);
        System.assertEquals(5.2, gsRevenueGraph.get(1).Graph_Value_2__c);
        System.assertEquals(6.25, gsRevenueGraph.get(1).Graph_Value_3__c);

    }

    @isTest
    public static void shouldLoadICDSGraphs() {
        Date currentDate = Date.today();
        insert new ICDS_Domain_Snapshot__c(Active_Users__c = 45000, Forms__c = 13000000, WAMs__c = 345000, Date__c = currentDate.addMonths(-2));
        insert new ICDS_Domain_Snapshot__c(Active_Users__c = 55000, Forms__c = 14000000, WAMs__c = 365000, Date__c = currentDate.addMonths(-1));
        insert new ICDS_Domain_Snapshot__c(Active_Users__c = 65000, Forms__c = 15000000, WAMs__c = 385000, Date__c = currentDate);

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> icdsGraphs = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c
                                                   FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.ICDS_GRAPHS
                                                   ORDER BY Helper_Date__c];
        System.assertEquals(45, icdsGraphs.get(0).Graph_Value_1__c);
        System.assertEquals(365, icdsGraphs.get(1).Graph_Value_2__c);
        System.assertEquals(15000, icdsGraphs.get(2).Graph_Value_3__c);
    }

    @isTest
    public static void shouldLoadDomainSnapshotGraphs() {
        setUpMonthlySnapshotData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> userGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c
                                                  FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.USER_GRAPH ORDER BY Helper_Date__c];
        List<Global_Metric_Graph__c> formGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c
                                                  FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.FORM_GRAPH ORDER BY Helper_Date__c];
        List<Global_Metric_Graph__c> wamGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c
                                                  FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.WAM_GRAPH ORDER BY Helper_Date__c];
        List<Global_Metric_Graph__c> programsGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c, Graph_Value_5__c
                                                  FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.PROGRAMS_GRAPH ORDER BY Helper_Date__c];

        System.assertEquals(3, userGraph.size());
        System.assertEquals(3, formGraph.size());
        System.assertEquals(3, wamGraph.size());
        System.assertEquals(3, programsGraph.size());

        System.assertEquals(17, userGraph.get(0).Graph_Value_5__c);
        System.assertEquals(13, userGraph.get(0).Graph_Value_4__c);
        System.assertEquals(12, wamGraph.get(0).Graph_Value_3__c);
        System.assertEquals(11, wamGraph.get(0).Graph_Value_2__c);
        System.assertEquals(66, formGraph.get(0).Graph_Value_1__c);
        System.assertEquals(33, programsGraph.get(0).Graph_Value_1__c);
    }

    @isTest
    public static void shouldLoadGSGraphs() {
        setUpGSData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> gsGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c
                                                FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.GS_GRAPHS
                                                ORDER BY Helper_Date__c];
        System.assertEquals(3, gsGraph.size());
        System.assertEquals(86, gsGraph.get(0).Graph_Value_1__c);
        System.assertEquals(77, gsGraph.get(0).Graph_Value_2__c);
        System.assertEquals(66, gsGraph.get(1).Graph_Value_1__c);
        System.assertEquals(88, gsGraph.get(2).Graph_Value_2__c);
    }

    @isTest
    public static void shouldLoadPerformanceGraphs() {
        setUpPerformanceData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> performanceGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c
                                                         FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.PERFORMANCE_GRAPHS
                                                         ORDER BY Helper_Date__c];
        System.assertEquals(2, performanceGraph.size());
        System.assertEquals(30, performanceGraph.get(0).Graph_Value_1__c);
        System.assertEquals(7, performanceGraph.get(0).Graph_Value_2__c);
        System.assertEquals(9, performanceGraph.get(0).Graph_Value_3__c);
        System.assertEquals(17.5, performanceGraph.get(1).Graph_Value_1__c);
        System.assertEquals(5, performanceGraph.get(1).Graph_Value_2__c);
        System.assertEquals(8, performanceGraph.get(1).Graph_Value_3__c);
    }

    @isTest
    public static void shouldLoadUpTimeGraph() {
        setUpUpTimeData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> performanceGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c
                                                         FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.UP_TIME_GRAPHS
                                                         ORDER BY Helper_Date__c];
        System.assertEquals(3, performanceGraph.size());
        System.assertEquals(92, performanceGraph.get(0).Graph_Value_1__c);
        System.assertEquals(95, performanceGraph.get(0).Graph_Value_2__c);
        System.assertEquals(55, performanceGraph.get(0).Graph_Value_3__c);
        System.assertEquals(100, performanceGraph.get(1).Graph_Value_1__c);
        System.assertEquals(98, performanceGraph.get(1).Graph_Value_2__c);
        System.assertEquals(75, performanceGraph.get(1).Graph_Value_3__c);
        System.assertEquals(99, performanceGraph.get(2).Graph_Value_1__c);
        System.assertEquals(99, performanceGraph.get(2).Graph_Value_2__c);
        System.assertEquals(75, performanceGraph.get(2).Graph_Value_3__c);
    }

    @isTest
    public static void shouldLoadMrrGraph() {
        setUpMrrData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> mrrGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c,
                                                         Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c
                                                         FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.MRR_GRAPH
                                                         ORDER BY Helper_Date__c];
        System.assertEquals(2, mrrGraph.size());
        System.assertEquals(0, mrrGraph.get(0).Graph_Value_4__c);
        System.assertEquals(0, mrrGraph.get(1).Graph_Value_4__c);
    }

    @isTest
    public static void shouldLoadHiresGraph() {
        setHiresData();

        Test.startTest();
        CorporateDashboardHelper.refreshAllGraphs();
        Test.stopTest();

        List<Global_Metric_Graph__c> headcountGraph = [SELECT X_Text__c, Graph_Value_1__c, Graph_Value_2__c, Graph_Value_3__c, Graph_Value_4__c,
                                                         Graph_Value_5__c, Graph_Value_6__c, Graph_Value_7__c, Helper_Date__c
                                                         FROM Global_Metric_Graph__c WHERE Name =: CorporateDashboardHelper.GS_HEADCOUNT
                                                         ORDER BY Helper_Date__c];
        System.assertEquals(2, headcountGraph.size());
        System.assertEquals(2, headcountGraph.get(0).Graph_Value_1__c);
        System.assertEquals(1, headcountGraph.get(0).Graph_Value_2__c);
        System.assertEquals(1, headcountGraph.get(0).Graph_Value_3__c);

        System.assertEquals(3, headcountGraph.get(1).Graph_Value_1__c);
        System.assertEquals(1, headcountGraph.get(1).Graph_Value_2__c);
        System.assertEquals(2, headcountGraph.get(1).Graph_Value_3__c);
    }

    private static void setUpGSRevenueData() {
        //Inc : current month - 10000 * 50% + 6000 * 100% = 11000 / 1000 = 11
        //Inc : previous month - 10000 * 10% + 6000 * 0% = 1000 / 1000 = 1
        //DWA : current month - 100000 * 5% + 2500 * 10% = 5250 / 1000 = 5,25
        //DWA : previous month - 100000 * 5% + 2500 * 8% = 5200 / 1000 = 5,2
        //DSI : current month - 40000 * 25% + 15000 * 35% = 15250 / 1000 = 15,25
        //DSI : previous month - 40000 * 10% + 15000 * 15% = 6250 / 1000 = 6,25
        Business_Unit__c bizUnit1 = new Business_Unit__c(Name = 'Inc');
        Business_Unit__c bizUnit2 = new Business_Unit__c(Name = 'DWA');
        Business_Unit__c bizUnit3 = new Business_Unit__c(Name = 'DSI');
        insert bizUnit1;
        insert bizUnit2;
        insert bizUnit3;

        DContract__c contract1 = new DContract__c(Name = 'Test 1', Efficiency_Owner_BU__c = bizUnit1.Id, GS_Revenue_Calculation__c = true);
        DContract__c contract2 = new DContract__c(Name = 'Test 2', Efficiency_Owner_BU__c = bizUnit1.Id, GS_Revenue_Calculation__c = true);
        DContract__c contract3 = new DContract__c(Name = 'Test 3', Efficiency_Owner_BU__c = bizUnit2.Id, GS_Revenue_Calculation__c = true);
        DContract__c contract4 = new DContract__c(Name = 'Test 4', Efficiency_Owner_BU__c = bizUnit2.Id, GS_Revenue_Calculation__c = true);
        DContract__c contract5 = new DContract__c(Name = 'Test 5', Efficiency_Owner_BU__c = bizUnit3.Id, GS_Revenue_Calculation__c = true);
        DContract__c contract6 = new DContract__c(Name = 'Test 6', Efficiency_Owner_BU__c = bizUnit3.Id, GS_Revenue_Calculation__c = true);
        insert contract1;
        insert contract2;
        insert contract3;
        insert contract4;
        insert contract5;
        insert contract6;

        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract1.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 10000, Work_Completed_for_Period__c = 50);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract2.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 6000, Work_Completed_for_Period__c = 100);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract3.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 100000, Work_Completed_for_Period__c = 5);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract4.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 2500, Work_Completed_for_Period__c = 10);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract5.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 40000, Work_Completed_for_Period__c = 25);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today(), Contract__c = contract6.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 15000, Work_Completed_for_Period__c = 35);

        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract1.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 10000, Work_Completed_for_Period__c = 10);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract2.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 6000, Work_Completed_for_Period__c = 0);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract3.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 100000, Work_Completed_for_Period__c = 5);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract4.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 2500, Work_Completed_for_Period__c = 8);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract5.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 40000, Work_Completed_for_Period__c = 10);
        insert new Pipeline_Snapshot__c(Month_Date__c = Date.today().addMonths(-1), Contract__c = contract6.Id,
                                        Stage__c = 'Outstanding Contracted', Intracompany_Sub_contract__c = 'No',
                                        GS_Project_Services_Budget_Handoff_Cp__c = 15000, Work_Completed_for_Period__c = 15);
    }

    private static void setHiresData() {
        Business_Unit__c bizUnit1 = new Business_Unit__c(Name = 'Inc');
        Business_Unit__c bizUnit2 = new Business_Unit__c(Name = 'DWA');
        Business_Unit__c bizUnit3 = new Business_Unit__c(Name = 'DSI');
        insert bizUnit1;
        insert bizUnit2;
        insert bizUnit3;

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_1', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit1.Id,
                                                Exchange_Rate__c = 1);
        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_1', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today().addMonths(-1), Business_Unit__c = bizUnit1.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_2', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit2.Id,
                                                Exchange_Rate__c = 1);
        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_2', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today().addMonths(-1), Business_Unit__c = bizUnit2.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_3', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit3.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_4', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today().addMonths(-1), Business_Unit__c = bizUnit3.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_5', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit3.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_6', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit1.Id,
                                                Exchange_Rate__c = 1);
        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_6', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today().addMonths(-1), Business_Unit__c = bizUnit1.Id,
                                                Exchange_Rate__c = 1);

        insert new SFDC_Employee_Snapshot__c(Name = 'emp_snp_7', Employee_Status__c = 'Active', Employee_Type__c = 'Employee', Sub_Unit__c = 'Global Services',
                                                Per_Week_Hours__c = 11, Global_Services__c = 31, Snapshot_Date__c = Date.today(), Business_Unit__c = bizUnit1.Id,
                                                Exchange_Rate__c = 1);
    }

    private static void setUpMrrData() {
        Date currentDay = Date.today();
        Accounting_Subscription__c sub = new Accounting_Subscription__c(service_type__c = 'Self_service');
        insert sub;
        Accounting_Invoice__c inv1 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay, Softwareplan_Edition__c = 'Pro');
        Accounting_Invoice__c inv2 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay, Softwareplan_Edition__c = 'Pro');
        Accounting_Invoice__c inv3 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay, Softwareplan_Edition__c = 'Pro');
        Accounting_Invoice__c inv4 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay.addMonths(-1), Softwareplan_Edition__c = 'Pro');
        Accounting_Invoice__c inv5 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay.addMonths(-1), Softwareplan_Edition__c = 'Pro');
        Accounting_Invoice__c inv6 = new Accounting_Invoice__c(Accounting_Subscription__c = sub.Id,
                                                               is_hidden__c = false, Ops_Override__c = false,
                                                               is_hidden_to_ops__c = false,
                                                               date_end__c = currentDay.addMonths(-1), Softwareplan_Edition__c = 'Pro');
        insert inv1;
        insert inv2;
        insert inv3;
        insert inv4;
        insert inv5;
        insert inv6;
    }

    private static void setUpPerformanceData() {
        Date currentDay = Date.today();
        CommCareHQ_Performance_Metrics__c performance1 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-1),
                                                                                               Server_Apdex__c = null,
                                                                                               Number_of_Submissions__c = 30000,
                                                                                               Avg_Page_Load__c = 3);
        CommCareHQ_Performance_Metrics__c performance2 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-1),
                                                                                               Server_Apdex__c = 9,
                                                                                               Number_of_Submissions__c = 5000,
                                                                                               Avg_Page_Load__c = null);
        CommCareHQ_Performance_Metrics__c performance3 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-1),
                                                                                               Server_Apdex__c = 7,
                                                                                               Number_of_Submissions__c = null,
                                                                                               Avg_Page_Load__c = 7);
        CommCareHQ_Performance_Metrics__c performance4 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-2),
                                                                                               Server_Apdex__c = null,
                                                                                               Number_of_Submissions__c = 30000,
                                                                                               Avg_Page_Load__c = 7);
        CommCareHQ_Performance_Metrics__c performance5 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-2),
                                                                                               Server_Apdex__c = 9,
                                                                                               Number_of_Submissions__c = 30000,
                                                                                               Avg_Page_Load__c = null);
        CommCareHQ_Performance_Metrics__c performance6 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-2),
                                                                                               Server_Apdex__c = 9,
                                                                                               Number_of_Submissions__c = null,
                                                                                               Avg_Page_Load__c = 7);
        insert performance1;
        insert performance2;
        insert performance3;
        insert performance4;
        insert performance5;
        insert performance6;
    }

    private static void setUpUpTimeData() {
        Date currentDay = Date.today();
        CommCareHQ_Performance_Metrics__c performance1 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-3),
                                                                                               ICDS_Uptime__c = 55,
                                                                                               India_Server_Uptime__c = 95,
                                                                                               Prod_Uptime__c = 92);
        CommCareHQ_Performance_Metrics__c performance2 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-2),
                                                                                               ICDS_Uptime__c = 75,
                                                                                               India_Server_Uptime__c = 98,
                                                                                               Prod_Uptime__c = 100);
        CommCareHQ_Performance_Metrics__c performance3 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-1),
                                                                                               ICDS_Uptime__c = 50,
                                                                                               India_Server_Uptime__c = 99,
                                                                                               Prod_Uptime__c = 99);
        CommCareHQ_Performance_Metrics__c performance4 = new CommCareHQ_Performance_Metrics__c(Date__c = currentDay.addMonths(-1),
                                                                                               ICDS_Uptime__c = 100,
                                                                                               India_Server_Uptime__c = 99,
                                                                                               Prod_Uptime__c = 99);

        insert performance1;
        insert performance2;
        insert performance3;
        insert performance4;
    }

    private static void setUpGSData() {
        Date currentDay = Date.today();
        Contract_Statistic__c cs1 = new Contract_Statistic__c(PRO_Cycle_Date__c = currentDay.addMonths(-1),
                                                              GS_Quality_Total_Customer_Satisfaction__c = 88,
                                                              GS_Quality_Total_Overall_Status__c = 78);
        Contract_Statistic__c cs2 = new Contract_Statistic__c(PRO_Cycle_Date__c = currentDay.addMonths(-2),
                                                              GS_Quality_Total_Customer_Satisfaction__c = 90,
                                                              GS_Quality_Total_Overall_Status__c = 66);
        Contract_Statistic__c cs3 = new Contract_Statistic__c(PRO_Cycle_Date__c = currentDay.addMonths(-3),
                                                              GS_Quality_Total_Customer_Satisfaction__c = 77,
                                                              GS_Quality_Total_Overall_Status__c = 86);
        insert cs1;
        insert cs2;
        insert cs3;
    }

    private static void setUpMonthlySnapshotData() {
        Date currentDay = Date.today();
        Integer currentYear = currentDay.year();
        Integer currentMonth = currentDay.month();
        Domain_Monthly_Snapshot__c sn1 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Standard', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 11, Snapshot_Date__c = currentDay.addMonths(-1));
        Domain_Monthly_Snapshot__c sn2 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Standard', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 22, Snapshot_Date__c = currentDay.addMonths(-2));
        Domain_Monthly_Snapshot__c sn3 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Standard', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 17000,
                                                                        Scale_of_Programs__c = 33, Snapshot_Date__c = currentDay.addMonths(-3));
        Domain_Monthly_Snapshot__c sn4 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Pro', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 44, Snapshot_Date__c = currentDay.addMonths(-1));
        Domain_Monthly_Snapshot__c sn5 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Pro', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 55, Snapshot_Date__c = currentDay.addMonths(-2));
        Domain_Monthly_Snapshot__c sn6 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Pro', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 13000,
                                                                        Scale_of_Programs__c = 66, Snapshot_Date__c = currentDay.addMonths(-3));
        Domain_Monthly_Snapshot__c sn7 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Enterprise', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 77, Snapshot_Date__c = currentDay.addMonths(-1));
        Domain_Monthly_Snapshot__c sn8 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Enterprise', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 88, Snapshot_Date__c = currentDay.addMonths(-2));
        Domain_Monthly_Snapshot__c sn9 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Enterprise', Wam__c = 12000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 99, Snapshot_Date__c = currentDay.addMonths(-3));
        Domain_Monthly_Snapshot__c sn10 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Community', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 88, Snapshot_Date__c = currentDay.addMonths(-1));
        Domain_Monthly_Snapshot__c sn11 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Community', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 77, Snapshot_Date__c = currentDay.addMonths(-2));
        Domain_Monthly_Snapshot__c sn12 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Community', Wam__c = 11000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 66, Snapshot_Date__c = currentDay.addMonths(-3));
        Domain_Monthly_Snapshot__c sn13 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Advanced', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 55, Snapshot_Date__c = currentDay.addMonths(-1));
        Domain_Monthly_Snapshot__c sn14 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Advanced', Wam__c = 1000, Forms_for_Period__c = 50000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 44, Snapshot_Date__c = currentDay.addMonths(-2));
        Domain_Monthly_Snapshot__c sn15 = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = 'Advanced', Wam__c = 1000, Forms_for_Period__c = 66000, Active_Mobile_Users__c = 1300,
                                                                        Scale_of_Programs__c = 33, Snapshot_Date__c = currentDay.addMonths(-3));
        insert sn1;
        insert sn2;
        insert sn3;
        insert sn4;
        insert sn5;
        insert sn6;
        insert sn7;
        insert sn8;
        insert sn9;
        insert sn10;
        insert sn11;
        insert sn12;
        insert sn13;
        insert sn14;
        insert sn15;
    }
}