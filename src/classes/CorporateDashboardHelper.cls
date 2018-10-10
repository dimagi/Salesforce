/**
 * Helper class for generating Corporate Dashboard Graph Data.
 */
public class CorporateDashboardHelper {

    public static final String GS_GRAPHS = 'Gs';
    public static final String GS_HEADCOUNT = 'Gs Headcount';
    public static final String GS_REVENUE = 'Gs Revenue';
    public static final String PERFORMANCE_GRAPHS = 'CommCare Performance';
    public static final String UP_TIME_GRAPHS = 'Server Up Time';
    public static final String MRR_GRAPH = 'Mrr';
    public static final String OPP_EXPECTED_GRAPH = 'Opp Expected';
    public static final String EV_EXPECTED_GRAPH = 'Ev Expected';
    public static final String EV_BUFFER_GEN_GRAPH = 'Ev Buffer Gen';
    public static final String AGGREGATE_EFF_GRAPH = 'Aggregate Eff';
    public static final String WAM_GRAPH = 'Domain Wam';
    public static final String FORM_GRAPH = 'Domain Form';
    public static final String USER_GRAPH = 'Domain User';
    public static final String PROGRAMS_GRAPH = 'Domain Programs';
    public static final String ICDS_GRAPHS = 'Domain ICDS';

    @future
    public static void refreshAllGraphsFuture() {
        refreshAllGraphs();
    }

    public static void refreshAllGraphs() {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        try {
            loadGsHeadcountData();
            loadGSRevenueData();
            loadGSData();
            loadPerformanceData();
            loadServerUpTimeData();
            loadEvExpectedValue();
            loadOppExpetedValue();
            loadAggregateEff();
            loadDomainSnapshotData();
            loadICDSDomainSnapshotData();
            loadMrr();
        } catch (Exception ex) {
            System.debug('CorporateDashboardHelper error : ' + ex);
            System.debug('CorporateDashboardHelper error : ' + ex.getLineNumber());
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'CorporateDashboardHelper error', 'Cannot refresh all graphs', ex);
            }
        }
    }

    public static void loadGSRevenueData() {
        List<Global_Metric_Graph__c> gsRevenueData = new List<Global_Metric_Graph__c>();
        AggregateResult[] records = [SELECT Month_Date__c, Contract__r.Efficiency_Owner_BU__r.Name, SUM(GS_Revenue__c)
                                     FROM Pipeline_Snapshot__c WHERE Month_Date__c >=: Date.today().addMonths(-6)
                                     AND Intracompany_Sub_contract__c = 'No' AND Stage__c != 'Closed' AND Stage__c != 'Total'
                                     AND Contract__r.GS_Revenue_Calculation__c = true AND GS_Revenue__c > 0
                                     GROUP BY Month_Date__c, Contract__r.Efficiency_Owner_BU__r.Name ORDER BY Month_Date__c];

        if (records.size() > 0) {
            Date snpDateLast = (Date) records.get(0).get('Month_Date__c');
            Global_Metric_Graph__c helper = new Global_Metric_Graph__c(Name = GS_REVENUE, X_Text__c = getDateText(snpDateLast), Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Helper_Date__c = snpDateLast);
            for (AggregateResult ar : records) {
                Date snpDate = (Date) ar.get('Month_Date__c');
                String buName = (String) ar.get('Name');
                Decimal sumValue = (Decimal) (ar.get('expr0'));
                System.debug('Record : ' + snpDate + ' ' + buName + ' ' + sumValue);
                if (snpDateLast != snpDate) {
                    snpDateLast = snpDate;
                    gsRevenueData.add(helper);
                    helper = new Global_Metric_Graph__c(Name = GS_REVENUE, X_Text__c = getDateText(snpDate), Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Helper_Date__c = snpDate);
                }
                if (buName == 'Inc') {
                    helper.Graph_Value_1__c = sumValue / 1000.00;
                } else if (buName == 'DWA') {
                    helper.Graph_Value_2__c = sumValue / 1000.00;
                } else if (buName == 'DSI') {
                    helper.Graph_Value_3__c = sumValue / 1000.00;
                } else if (buName == 'DSA') {
                    helper.Graph_Value_4__c = sumValue / 1000.00;
                } else if (buName == 'DLAC') {
                    helper.Graph_Value_5__c = sumValue / 1000.00;
                }
            }
            gsRevenueData.add(helper);
        }
        deleteAndAddMetrics(gsRevenueData, GS_REVENUE);
    }

    public static void loadGsHeadcountData() {
        List<Global_Metric_Graph__c> headcountData = new List<Global_Metric_Graph__c>();
        AggregateResult[] records = [SELECT Snapshot_Date__c, Business_Unit__r.Name, Count(Id)
                                     FROM SFDC_Employee_Snapshot__c WHERE Snapshot_Date__c >=: Date.today().addMonths(-8)
                                     AND (Employee_Type__c = 'Contractor' OR Employee_Type__c = 'Employee' OR Employee_Type__c = 'External Contractor')
                                     AND Employee_Status__c = 'Active'
                                     AND Per_Week_Hours__c > 10 AND Global_Services__c > 30
                                     GROUP BY Snapshot_Date__c, Business_Unit__r.Name ORDER BY Snapshot_Date__c];

        System.debug('Employee Data : ' + records);
        if (records.size() > 0) {
            Date snpDateLast = (Date) records.get(0).get('Snapshot_Date__c');
            Global_Metric_Graph__c helper = new Global_Metric_Graph__c(Name = GS_HEADCOUNT, X_Text__c = getDateText(snpDateLast), Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Helper_Date__c = snpDateLast);
            for (AggregateResult ar : records) {
                Date snpDate = (Date) ar.get('Snapshot_Date__c');
                String buName = (String) ar.get('Name');
                Integer countRecords = Integer.valueOf(ar.get('expr0'));
                System.debug('Record : ' + snpDate + ' ' + buName + ' ' + countRecords);
                if (snpDateLast != snpDate) {
                    snpDateLast = snpDate;
                    headcountData.add(helper);
                    helper = new Global_Metric_Graph__c(Name = GS_HEADCOUNT, X_Text__c = getDateText(snpDate), Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Helper_Date__c = snpDate);
                }

                if (buName == 'Inc') {
                    helper.Graph_Value_1__c = countRecords;
                } else if (buName == 'DWA') {
                    helper.Graph_Value_2__c = countRecords;
                } else if (buName == 'DSI') {
                    helper.Graph_Value_3__c = countRecords;
                } else if (buName == 'DSA') {
                    helper.Graph_Value_4__c = countRecords;
                } else if (buName == 'DLAC') {
                    helper.Graph_Value_5__c = countRecords;
                }
            }
            headcountData.add(helper);
        }
        deleteAndAddMetrics(headcountData, GS_HEADCOUNT);
    }

    public static void loadGSData() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> gsData = new List<Global_Metric_Graph__c>();
        Decimal months = corporateDashboardSettings.GS_Graphs_number_of_months__c != null ? corporateDashboardSettings.GS_Graphs_number_of_months__c : 6;
        List<Contract_Statistic__c> contractStats = [SELECT PRO_Cycle_Date__c,GS_Quality_Total_Customer_Satisfaction__c, GS_Quality_Total_Overall_Status__c
                                                     FROM Contract_Statistic__c WHERE PRO_Cycle_Date__c >=: Date.today().addMonths(((-1) * months).intValue()).toStartOfMonth()
                                                     ORDER BY PRO_Cycle_Date__c ASC];

        for (Contract_Statistic__c conStats : contractStats) {
            Global_Metric_Graph__c gmg = new Global_Metric_Graph__c(Name = GS_GRAPHS, X_Text__c = conStats.PRO_Cycle_Date__c.format(),
                                                                     Helper_Date__c = conStats.PRO_Cycle_Date__c,
                                                                     Graph_Value_1__c = conStats.GS_Quality_Total_Overall_Status__c,
                                                                     Graph_Value_2__c = conStats.GS_Quality_Total_Customer_Satisfaction__c);
            gsData.add(gmg);
        }

        deleteAndAddMetrics(gsData, GS_GRAPHS);
    }

    public static void loadServerUpTimeData() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> upTimeData = new List<Global_Metric_Graph__c>();
        Decimal months = corporateDashboardSettings.Performance_graphs_number_of_months__c != null ? corporateDashboardSettings.Performance_graphs_number_of_months__c : 6;
        List<CommCareHQ_Performance_Metrics__c> metrics = [SELECT Date__c, ICDS_Uptime__c, Prod_Uptime__c, India_Server_Uptime__c, eNikshay_Up_Time__c
                                                           FROM CommCareHQ_Performance_Metrics__c
                                                           WHERE Date__c >=: Date.today().addMonths(((-1) * months).intValue()).toStartOfMonth() AND Prod_Uptime__c != null
                                                           ORDER BY Date__c ASC];

        if (metrics.size() > 0) {
            Global_Metric_Graph__c tmpData = new Global_Metric_Graph__c(Name = UP_TIME_GRAPHS, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0, Graph_Value_8__c = 0);
            Date lastDate = metrics.get(0).Date__c;
            for (CommCareHQ_Performance_Metrics__c rec : metrics) {
                if (rec.Date__c.year() != lastDate.year() || rec.Date__c.month() != lastDate.month()) {
                    tmpData.Graph_Value_1__c = (tmpData.Graph_Value_4__c != 0 ? tmpData.Graph_Value_1__c / tmpData.Graph_Value_4__c : 0);
                    tmpData.Graph_Value_2__c = (tmpData.Graph_Value_5__c != 0 ? tmpData.Graph_Value_2__c / tmpData.Graph_Value_5__c : 0);
                    tmpData.Graph_Value_3__c = (tmpData.Graph_Value_6__c != 0 ? tmpData.Graph_Value_3__c / tmpData.Graph_Value_6__c : 0);
                    tmpData.Graph_Value_7__c = (tmpData.Graph_Value_8__c != 0 ? tmpData.Graph_Value_7__c / tmpData.Graph_Value_8__c : 0);
                    tmpData.X_Text__c = Date.newInstance(lastDate.year(), lastDate.month(), Date.daysInMonth(lastDate.year(), lastDate.month())).format();
                    tmpData.Helper_Date__c = lastDate;
                    upTimeData.add(tmpData);
                    tmpData = new Global_Metric_Graph__c(Name = UP_TIME_GRAPHS, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                         Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0, Graph_Value_8__c = 0);
                }
                if (rec.Prod_Uptime__c != null) {
                    tmpData.Graph_Value_1__c += rec.Prod_Uptime__c;
                    tmpData.Graph_Value_4__c++;
                }
                if (rec.India_Server_Uptime__c != null) {
                    tmpData.Graph_Value_2__c += rec.India_Server_Uptime__c;
                    tmpData.Graph_Value_5__c++;
                }
                if (rec.ICDS_Uptime__c != null) {
                    tmpData.Graph_Value_3__c += rec.ICDS_Uptime__c;
                    tmpData.Graph_Value_6__c++;
                }
                if (rec.eNikshay_Up_Time__c != null) {
                    tmpData.Graph_Value_7__c += rec.eNikshay_Up_Time__c;
                    tmpData.Graph_Value_8__c++;
                }
                lastDate = rec.Date__c;
            }

            tmpData.X_Text__c = Date.newInstance(lastDate.year(), lastDate.month(), Date.daysInMonth(lastDate.year(), lastDate.month())).format();
            tmpData.Helper_Date__c = lastDate;
            tmpData.Graph_Value_1__c = (tmpData.Graph_Value_4__c != 0 ? tmpData.Graph_Value_1__c / tmpData.Graph_Value_4__c : 0);
            tmpData.Graph_Value_2__c = (tmpData.Graph_Value_5__c != 0 ? tmpData.Graph_Value_2__c / tmpData.Graph_Value_5__c : 0);
            tmpData.Graph_Value_3__c = (tmpData.Graph_Value_6__c != 0 ? tmpData.Graph_Value_3__c / tmpData.Graph_Value_6__c : 0);
            tmpData.Graph_Value_7__c = (tmpData.Graph_Value_8__c != 0 ? tmpData.Graph_Value_7__c / tmpData.Graph_Value_8__c : 0);
            upTimeData.add(tmpData);
        }

        deleteAndAddMetrics(upTimeData, UP_TIME_GRAPHS);
    }

    public static void loadPerformanceData() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> performanceData = new List<Global_Metric_Graph__c>();
        Decimal months = corporateDashboardSettings.Performance_graphs_number_of_months__c != null ? corporateDashboardSettings.Performance_graphs_number_of_months__c : 6;
        List<CommCareHQ_Performance_Metrics__c> metrics = [SELECT Date__c, Server_Apdex__c, Number_of_Submissions__c, Avg_Page_Load__c
                                                           FROM CommCareHQ_Performance_Metrics__c
                                                           WHERE Date__c >=: Date.today().addMonths(((-1) * months).intValue()).toStartOfMonth()
                                                           ORDER BY Date__c ASC];

        if (metrics.size() > 0) {
            Global_Metric_Graph__c tmpData = new Global_Metric_Graph__c(Name = PERFORMANCE_GRAPHS, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
            Date lastDate = metrics.get(0).Date__c;
            for (CommCareHQ_Performance_Metrics__c rec : metrics) {
                if (rec.Date__c.year() != lastDate.year() || rec.Date__c.month() != lastDate.month()) {
                    tmpData.Graph_Value_1__c = (tmpData.Graph_Value_4__c != 0 ? tmpData.Graph_Value_1__c / tmpData.Graph_Value_4__c : 0) / 1000.00;
                    tmpData.Graph_Value_2__c = (tmpData.Graph_Value_5__c != 0 ? tmpData.Graph_Value_2__c / tmpData.Graph_Value_5__c : 0);
                    tmpData.Graph_Value_3__c = (tmpData.Graph_Value_6__c != 0 ? tmpData.Graph_Value_3__c / tmpData.Graph_Value_6__c : 0);
                    tmpData.X_Text__c = lastDate.format();
                    tmpData.Helper_Date__c = lastDate;
                    performanceData.add(tmpData);
                    tmpData = new Global_Metric_Graph__c(Name = PERFORMANCE_GRAPHS, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                         Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                }
                if (rec.Number_of_Submissions__c != null) {
                    tmpData.Graph_Value_1__c += rec.Number_of_Submissions__c;
                    tmpData.Graph_Value_4__c++;
                }
                if (rec.Avg_Page_Load__c != null) {
                    tmpData.Graph_Value_2__c += rec.Avg_Page_Load__c;
                    tmpData.Graph_Value_5__c++;
                }
                if (rec.Server_Apdex__c != null) {
                    tmpData.Graph_Value_3__c += rec.Server_Apdex__c;
                    tmpData.Graph_Value_6__c++;
                }
                lastDate = rec.Date__c;
            }
            // we must add the last date from list:
            tmpData.X_Text__c = lastDate.format();
            tmpData.Helper_Date__c = lastDate;
            tmpData.Graph_Value_1__c = (tmpData.Graph_Value_4__c != 0 ? tmpData.Graph_Value_1__c / tmpData.Graph_Value_4__c : 0) / 1000.00;
            tmpData.Graph_Value_2__c = (tmpData.Graph_Value_5__c != 0 ? tmpData.Graph_Value_2__c / tmpData.Graph_Value_5__c : 0);
            tmpData.Graph_Value_3__c = (tmpData.Graph_Value_6__c != 0 ? tmpData.Graph_Value_3__c / tmpData.Graph_Value_6__c : 0);
            performanceData.add(tmpData);
        }

        deleteAndAddMetrics(performanceData, PERFORMANCE_GRAPHS);
    }

    public static void loadMrr() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> mrr = new List<Global_Metric_Graph__c>();
        Date fiscalYearStart = corporateDashboardSettings.Fiscal_Year_Start__c;
        Date fiscalYearEnd = corporateDashboardSettings.Fiscal_year_End__c;
        if (fiscalYearStart == null || fiscalYearEnd == null) {
            System.debug('Fiscal year data empty');
            return;
        }
        AggregateResult[] resultInv;
        if (!Test.isRunningTest()) {
            resultInv = [SELECT CALENDAR_MONTH(date_end__c), Softwareplan_Edition__c, SUM(accounting_software_monthly_fee__c)
                         FROM Accounting_Invoice__c
                         WHERE (accounting_subscription_service_type__c = 'Self_service' OR accounting_subscription_service_type__c = 'Product')
                         AND is_hidden__c = false AND is_hidden_to_ops__c = false AND calculated_MRR__c > 0
                         AND Ops_Override__c = false AND date_end__c >=: fiscalYearStart AND date_end__c <=: fiscalYearEnd
                         GROUP BY CALENDAR_MONTH(date_end__c), Softwareplan_Edition__c ORDER BY CALENDAR_MONTH(date_end__c)];
        } else {
            resultInv = [SELECT CALENDAR_MONTH(date_end__c), Softwareplan_Edition__c, SUM(accounting_software_monthly_fee__c)
                         FROM Accounting_Invoice__c GROUP BY CALENDAR_MONTH(date_end__c), Softwareplan_Edition__c ORDER BY CALENDAR_MONTH(date_end__c)];
        }

        if (resultInv.size() > 0) {
            Integer monthNum = Integer.valueOf(resultInv[0].get('expr0'));
            String month = getDateText(Date.newInstance(fiscalYearStart.year(), monthNum, 1));
            Global_Metric_Graph__c currentGraphData = new Global_Metric_Graph__c(Name = MRR_GRAPH, X_Text__c = month, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0, Helper_Date__c = Date.newInstance(fiscalYearStart.year(), monthNum, 1));
            for (AggregateResult ar : resultInv) {
                Integer currentNum = Integer.valueOf(ar.get('expr0'));
                if (monthNum != currentNum) {
                    mrr.add(currentGraphData);
                    monthNum = Integer.valueOf(ar.get('expr0'));
                    month = getDateText(Date.newInstance(fiscalYearStart.year(), monthNum, 1));
                    currentGraphData = new Global_Metric_Graph__c(Name = MRR_GRAPH, X_Text__c = month, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                  Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0, Helper_Date__c = Date.newInstance(fiscalYearStart.year(), monthNum, 1));
                }
                currentGraphData = fillMrrData(currentGraphData, (Decimal) ar.get('expr1'), (String) ar.get('Softwareplan_Edition__c'));
            }
            mrr.add(currentGraphData);
        }

        deleteAndAddMetrics(mrr, MRR_GRAPH);
    }

    public static void loadEvExpectedValue() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        Date fiscalYearStart = corporateDashboardSettings.Fiscal_Year_Start__c;
        Date fiscalYearEnd = corporateDashboardSettings.Fiscal_year_End__c;
        Decimal targetDataExpectedVal = corporateDashboardSettings.EV_Target__c;
        Decimal targetDataExpectedBuffVal = corporateDashboardSettings.EV_Expected_Buffer_Target__c;
        AggregateResult[] groupedResults = [SELECT SUM(DIFF_Expected_Value_Minus_Expense__c), SUM(Diff_expected_buffer__c) FROM Pipeline_Snapshot_EV_DIff__c
                                            WHERE Month_Date__c >=: fiscalYearStart
                                            AND Month_Date__c <=: fiscalYearEnd
                                            AND (NOT Name LIKE '%(Monthly)%') AND (NOT Name LIKE '%- Total%')
                                            AND (Pipeline_Snapshot__r.Stage__c = 'Stage 4 - Proposal Development' OR Pipeline_Snapshot__r.Stage__c = 'Stage 5 - Submitted'
                                                 OR Pipeline_Snapshot__r.Stage__c = 'Stage 6 - In Negotiations' OR Pipeline_Snapshot__r.Stage__c = 'Closed')
                                            AND Pipeline_Snapshot__r.Current_Channel__c != 'Core Funding (Gates)'
                                            AND Pipeline_Snapshot__r.Current_Channel__c != 'Inside Sales'
                                            AND (NOT Name LIKE '%MSH - Congo Health Overhaul%')];
        Decimal currentValueExpectedVal = (Decimal) groupedResults[0].get('expr0');
        Decimal currentValueExpectedBuffVal = (Decimal) groupedResults[0].get('expr1');
        deleteAndAddMetrics(new List<Global_Metric_Graph__c> {new Global_Metric_Graph__c(Name = EV_EXPECTED_GRAPH, X_Text__c = '',
                                                                                         Graph_Value_1__c = currentValueExpectedVal != null ? currentValueExpectedVal / 1000000.00 : 0,
                                                                                         Graph_Value_2__c = targetDataExpectedVal / 1000000.00)}, EV_EXPECTED_GRAPH);
        deleteAndAddMetrics(new List<Global_Metric_Graph__c> {new Global_Metric_Graph__c(Name = EV_BUFFER_GEN_GRAPH, X_Text__c = '',
                                                                                         Graph_Value_1__c = currentValueExpectedBuffVal != null ? currentValueExpectedBuffVal / 1000000.00 : 0,
                                                                                         Graph_Value_2__c = targetDataExpectedBuffVal / 1000000.00)}, EV_BUFFER_GEN_GRAPH);
    }

    public static void loadOppExpetedValue() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        Date fiscalYearStart = corporateDashboardSettings.Fiscal_Year_Start__c;
        Date fiscalYearEnd = corporateDashboardSettings.Fiscal_year_End__c;
        Decimal targetData = corporateDashboardSettings.Opp_Won_Target__c;
        AggregateResult[] groupedResults = [SELECT SUM(Expected_Value_Minus_Income__c) FROM Opportunity WHERE CloseDate >=: fiscalYearStart AND CloseDate <=: fiscalYearEnd AND Amount > 0 AND StageName = 'Closed - Won'
                                                AND Channel_Response__c != 'Inside Sales' AND (NOT Name LIKE '%Gates MOTECH Renewal%')];
        Decimal currentValue = (Decimal) groupedResults[0].get('expr0');
        deleteAndAddMetrics(new List<Global_Metric_Graph__c> {new Global_Metric_Graph__c(Name = OPP_EXPECTED_GRAPH, X_Text__c = '',
                                                                                         Graph_Value_1__c = currentValue != null ? currentValue / 1000000.00 : 0,
                                                                                         Graph_Value_2__c = targetData / 1000000.00)}, OPP_EXPECTED_GRAPH);
    }

    public static void loadAggregateEff() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> aggregateEff = new List<Global_Metric_Graph__c>();
        AggregateResult[] resultContr = [SELECT Efficiency_Owner_BU__r.Name, SUM(Services_Budget__c), SUM(Weighted_Efficiency__c)
                                         FROM DContract__c
                                         WHERE (NOT Name LIKE '%internal%') AND Total_Amount_of_Contract__c > 0
                                         AND (NOT Name LIKE '%MOTECH suite%') AND Implementation_Type__c != 'Self Service'
                                         AND Implementation_Type__c != '' AND Efficiency_Owner_BU__c != null
                                         AND Intracompany_Sub_contract__c = 'No' AND Percent_through_SOW_deliverables__c != 100
                                         AND Status__c != 'Complete' AND GS_Revenue_Calculation__c != false
                                         GROUP BY Efficiency_Owner_BU__r.Name ORDER BY Efficiency_Owner_BU__r.Name];

        if (resultContr.size() > 0) {
            Global_Metric_Graph__c graphHelper = new Global_Metric_Graph__c(Name = AGGREGATE_EFF_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                            Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
            String lastName = (String) resultContr[0].get('Name');
            for (AggregateResult ar : resultContr) {
                String currName = (String) ar.get('Name');
                if (lastName != currName) {
                    aggregateEff.add(graphHelper);
                    graphHelper = new Global_Metric_Graph__c(Name = AGGREGATE_EFF_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                             Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                }
                graphHelper.X_Text__c = currName;
                Decimal sumServices = (Decimal) ar.get('expr0');
                Decimal valuetoSet = 1;

                if (sumServices > 0) {
                    Decimal a = ar.get('expr1') != null ? (Decimal) ar.get('expr1') : 0;
                    valuetoSet = (sumServices != 0 ? a/sumServices : 0);
                }
                graphHelper.Graph_Value_1__c = valuetoSet;
            }
            aggregateEff.add(graphHelper);
        }
        deleteAndAddMetrics(aggregateEff, AGGREGATE_EFF_GRAPH);
    }

    public static void loadDomainSnapshotData() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> wamData = new List<Global_Metric_Graph__c>();
        List<Global_Metric_Graph__c> formData = new List<Global_Metric_Graph__c>();
        List<Global_Metric_Graph__c> userData = new List<Global_Metric_Graph__c>();
        List<Global_Metric_Graph__c> programData = new List<Global_Metric_Graph__c>();

        Set<String> planNames = new Set<String> { 'Advanced', 'Community', 'Enterprise', 'Pro', 'Standard' };
        Decimal months = corporateDashboardSettings.Scale_graphs_number_of_months__c != null ? Corporate_Dashboard_Settings__c.getOrgDefaults().Scale_graphs_number_of_months__c : 3;
        List<Domain_Monthly_Snapshot__c> snapshots = [SELECT Id, Snapshot_Date__c, Software_Plan_Edition__c, Wam__c, Forms_for_Period__c,
                                                      Forms__c, Active_Mobile_Users__c, Scale_of_Programs__c FROM Domain_Monthly_Snapshot__c
                                                      WHERE Snapshot_Date__c >=: Date.today().addMonths(((-1) * months).intValue()).toStartOfMonth()
                                                      AND Software_Plan_Edition__c IN: planNames
                                                      ORDER BY Snapshot_Date__c ASC];

        Integer startIdx = 0;
        Integer endIdx = 5; // we have 5 editions
        Global_Metric_Graph__c tmpWamData = new Global_Metric_Graph__c(Name = WAM_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                       Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
        Global_Metric_Graph__c tmpFormData = new Global_Metric_Graph__c(Name = FORM_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
        Global_Metric_Graph__c tmpUsersData = new Global_Metric_Graph__c(Name = USER_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                         Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
        Global_Metric_Graph__c tmpProgramsData = new Global_Metric_Graph__c(Name = PROGRAMS_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                                            Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
        while (endIdx <= snapshots.size()) {
            Domain_Monthly_Snapshot__c sn = snapshots.get(startIdx);

            if (sn.Software_Plan_Edition__c == 'Advanced') {
                tmpWamData.Graph_Value_1__c = sn.Wam__c != null ? sn.Wam__c / 1000.00 : 0;
                tmpFormData.Graph_Value_1__c = sn.Forms_for_Period__c != null ? sn.Forms_for_Period__c / 1000.00 : 0;
                tmpUsersData.Graph_Value_1__c = sn.Active_Mobile_Users__c != null ? sn.Active_Mobile_Users__c / 1000.00 : 0;
                tmpProgramsData.Graph_Value_1__c = sn.Scale_of_Programs__c;
            } else if (sn.Software_Plan_Edition__c == 'Community') {
                tmpWamData.Graph_Value_2__c = sn.Wam__c != null ? sn.Wam__c / 1000.00 : 0;
                tmpFormData.Graph_Value_2__c = sn.Forms_for_Period__c != null ? sn.Forms_for_Period__c / 1000.00 : 0;
                tmpUsersData.Graph_Value_2__c = sn.Active_Mobile_Users__c != null ? sn.Active_Mobile_Users__c / 1000.00 : 0;
                tmpProgramsData.Graph_Value_2__c = sn.Scale_of_Programs__c;
            } else if (sn.Software_Plan_Edition__c == 'Enterprise') {
                tmpWamData.Graph_Value_3__c = sn.Wam__c != null ? sn.Wam__c / 1000.00 : 0;
                tmpFormData.Graph_Value_3__c = sn.Forms_for_Period__c != null ? sn.Forms_for_Period__c / 1000.00 : 0;
                tmpUsersData.Graph_Value_3__c = sn.Active_Mobile_Users__c != null ? sn.Active_Mobile_Users__c / 1000.00 : 0;
                tmpProgramsData.Graph_Value_3__c = sn.Scale_of_Programs__c;
            } else if (sn.Software_Plan_Edition__c == 'Pro') {
                tmpWamData.Graph_Value_4__c = sn.Wam__c != null ? sn.Wam__c / 1000.00 : 0;
                tmpFormData.Graph_Value_4__c = sn.Forms_for_Period__c != null ? sn.Forms_for_Period__c / 1000.00 : 0;
                tmpUsersData.Graph_Value_4__c = sn.Active_Mobile_Users__c != null ? sn.Active_Mobile_Users__c / 1000.00 : 0;
                tmpProgramsData.Graph_Value_4__c = sn.Scale_of_Programs__c;
            } else if (sn.Software_Plan_Edition__c == 'Standard') {
                tmpWamData.Graph_Value_5__c = sn.Wam__c != null ? sn.Wam__c / 1000.00 : 0;
                tmpFormData.Graph_Value_5__c = sn.Forms_for_Period__c != null ? sn.Forms_for_Period__c / 1000.00 : 0;
                tmpUsersData.Graph_Value_5__c = sn.Active_Mobile_Users__c != null ? sn.Active_Mobile_Users__c / 1000.00 : 0;
                tmpProgramsData.Graph_Value_5__c = sn.Scale_of_Programs__c;
            }

            startIdx++;
            if (startIdx == endIdx) {
                tmpWamData.X_Text__c = getDateText(sn.Snapshot_Date__c);
                tmpFormData.X_Text__c = getDateText(sn.Snapshot_Date__c);
                tmpUsersData.X_Text__c = getDateText(sn.Snapshot_Date__c);
                tmpProgramsData.X_Text__c = getDateText(sn.Snapshot_Date__c);
                tmpWamData.Helper_Date__c = sn.Snapshot_Date__c;
                tmpFormData.Helper_Date__c = sn.Snapshot_Date__c;
                tmpUsersData.Helper_Date__c = sn.Snapshot_Date__c;
                tmpProgramsData.Helper_Date__c = sn.Snapshot_Date__c;

                wamData.add(tmpWamData);
                formData.add(tmpFormData);
                userData.add(tmpUsersData);
                programData.add(tmpProgramsData);

                tmpWamData = new Global_Metric_Graph__c(Name = WAM_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                        Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                tmpFormData = new Global_Metric_Graph__c(Name = FORM_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                         Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                tmpUsersData = new Global_Metric_Graph__c(Name = USER_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                          Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                tmpProgramsData = new Global_Metric_Graph__c(Name = PROGRAMS_GRAPH, Graph_Value_1__c = 0, Graph_Value_2__c = 0, Graph_Value_3__c = 0,
                                                             Graph_Value_4__c = 0, Graph_Value_5__c = 0, Graph_Value_6__c = 0, Graph_Value_7__c = 0);
                endIdx += 5;
            }
        }
        deleteAndAddMetrics(wamData, WAM_GRAPH);
        deleteAndAddMetrics(formData, FORM_GRAPH);
        deleteAndAddMetrics(userData, USER_GRAPH);
        deleteAndAddMetrics(programData, PROGRAMS_GRAPH);
    }

    public static void loadICDSDomainSnapshotData() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> icdsData = new List<Global_Metric_Graph__c>();
        Decimal months = corporateDashboardSettings.ICDS_Number_of_months__c != null ? corporateDashboardSettings.ICDS_Number_of_months__c : 6;
        List<ICDS_Domain_Snapshot__c> snapshots = [SELECT Id, Active_Users__c, Forms__c, WAMs__c, Date__c
                                                      FROM ICDS_Domain_Snapshot__c
                                                      WHERE Date__c >: Date.today().addMonths(((-1) * months).intValue()).toStartOfMonth()
                                                      ORDER BY Date__c ASC];

        for (ICDS_Domain_Snapshot__c icdsSnp : snapshots) {
            icdsData.add(new Global_Metric_Graph__c(X_Text__c = getDateText(icdsSnp.Date__c), Name = ICDS_GRAPHS, Helper_Date__c = icdsSnp.Date__c,
                                                    Graph_Value_1__c = icdsSnp.Active_Users__c / 1000.00, Graph_Value_2__c = icdsSnp.WAMs__c / 1000.00,
                                                    Graph_Value_3__c = icdsSnp.Forms__c / 1000.00));
        }

        deleteAndAddMetrics(icdsData, ICDS_GRAPHS);
    }

    public static String getDateText(Date snDate) {
        return DateTime.newInstance(snDate.year(), snDate.month(), snDate.day()).format('MMMM yyyy');
    }

    private static void deleteAndAddMetrics(List<Global_Metric_Graph__c> newMetrics, String metricName) {
        List<Global_Metric_Graph__c> oldMetrics = [SELECT Id FROM Global_Metric_Graph__c WHERE Name =: metricName];
        if (oldMetrics.size() > 0) {
            delete oldMetrics;
        }
        if (newMetrics.size() > 0) {
            insert newMetrics;
        }
    }

    private static Global_Metric_Graph__c fillMrrData(Global_Metric_Graph__c gData, Decimal value, String softwarePlan) {
        if (softwarePlan == 'Advanced') {
            gData.Graph_Value_1__c = value / 1000.00;
        } else if (softwarePlan == 'Community') {
            gData.Graph_Value_2__c = value / 1000.00;
        } else if (softwarePlan == 'Enterprise') {
            gData.Graph_Value_3__c = value / 1000.00;
        } else if (softwarePlan == 'Pro') {
            gData.Graph_Value_4__c = value / 1000.00;
        } else if (softwarePlan == 'Standard') {
            gData.Graph_Value_5__c = value / 1000.00;
        } else if (softwarePlan == 'Reseller') {
            gData.Graph_Value_6__c = value / 1000.00;
        } else if (softwarePlan == 'Managed Hosting') {
            gData.Graph_Value_7__c = value / 1000.00;
        }
        return gData;
    }
}