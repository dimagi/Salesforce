/**
 * Controller for refreshing Corporate Dashboard charts.
 */
public without sharing class CorporateDashboardController {

    public Boolean refreshing { get; set;}
    public List<LineChartData> performanceData { get; set;}
    public List<LineChartData> upTimeData { get; set;}
    public String randomParam {get; set;}

    public CorporateDashboardController() {
        this.randomParam = '' + DateTime.now().getTime();
        this.refreshing = false;
    }

    public PageReference refreshDashboard() {
        if (this.refreshing == false) {
            this.refreshing = true;
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setMethod('PUT');
            req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v36.0/analytics/dashboards/01Zb0000000gCws');

            Http http = new Http();
            HttpResponse res = http.send(req);
        }

        return null;
    }

    public void resetRefreshFlag() {
        this.refreshing = false;
    }

    public void resizeWindow() {
        // we need this empty method to rerender apex charts on view
    }

    public List<LineChartData> getData() {
        if (this.performanceData != null) {
            return this.performanceData;
        }
        this.performanceData = new List<LineChartData>();
        Boolean error = false;
        String message = '';
        try {
            List<CommCareHQ_Performance_Metrics__c> metrics = [SELECT Date__c, Server_Apdex__c, Number_of_Submissions__c, Avg_Page_Load__c
                                                           FROM CommCareHQ_Performance_Metrics__c
                                                           WHERE Date__c >=: Date.today().addMonths(-12).toStartOfMonth()
                                                           ORDER BY Date__c ASC];

            if (metrics.size() > 0) {
                LineChartData tmpData = new LineChartData('', 0, 0, 0, 0);
                Date lastDate = metrics.get(0).Date__c;
                for (CommCareHQ_Performance_Metrics__c rec : metrics) {
                    if (rec.Date__c.year() != lastDate.year() || rec.Date__c.month() != lastDate.month()) {
                        tmpData.graphValue2 = (tmpData.recordCount1 != 0 ? tmpData.graphValue2 / tmpData.recordCount1 : 0) / 1000.00;
                        tmpData.graphValue1 = (tmpData.recordCount2 != 0 ? tmpData.graphValue1 / tmpData.recordCount2 : 0);
                        tmpData.graphValue3 = (tmpData.recordCount3 != 0 ? tmpData.graphValue3 / tmpData.recordCount3 : 0);
                        tmpData.name = getDateText(lastDate);
                        this.performanceData.add(tmpData);
                        tmpData = new LineChartData('', 0, 0, 0, 0);
                    }

                    if (rec.Number_of_Submissions__c != null) {
                        tmpData.graphValue2 += rec.Number_of_Submissions__c;
                        tmpData.recordCount1++;
                    }
                    if (rec.Avg_Page_Load__c != null) {
                        tmpData.graphValue1 += rec.Avg_Page_Load__c;
                        tmpData.recordCount2++;
                    }
                    if (rec.Server_Apdex__c != null) {
                        tmpData.graphValue3 += rec.Server_Apdex__c;
                        tmpData.recordCount3++;
                    }
                    lastDate = rec.Date__c;
                }
                // we must add the last date from list:
                tmpData.name = getDateText(lastDate);
                tmpData.graphValue2 = (tmpData.recordCount1 != 0 ? tmpData.graphValue2 / tmpData.recordCount1 : 0) / 1000.00;
                tmpData.graphValue1 = (tmpData.recordCount2 != 0 ? tmpData.graphValue1 / tmpData.recordCount2 : 0);
                tmpData.graphValue3 = (tmpData.recordCount3 != 0 ? tmpData.graphValue3 / tmpData.recordCount3 : 0);
                this.performanceData.add(tmpData);
            }
        } catch(Exception e) {
            message = e.getMessage();
            error = true;
        }

        if (error == true) {
            System.debug('Cannot load performance data');
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot load performance data for Corporate Dashboard', message);
            }
        }

        return this.performanceData;
    }

    public List<LineChartData> getUpData() {
        if (this.upTimeData != null) {
            return this.upTimeData;
        }
        this.upTimeData = new List<LineChartData>();
        Boolean error = false;
        String message = '';
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'part 1'));
        try {
            List<CommCareHQ_Performance_Metrics__c> metrics = [SELECT Date__c, ICDS_Uptime__c, Prod_Uptime__c, India_Server_Uptime__c, eNikshay_Up_Time__c
                                                           FROM CommCareHQ_Performance_Metrics__c
                                                           WHERE Date__c >=: Date.today().addMonths(-12).toStartOfMonth() AND Prod_Uptime__c != null
                                                           ORDER BY Date__c ASC];
            if (metrics.size() > 0) {
                LineChartData tmpData = new LineChartData('', 0, 0, 0, 0);
                Date lastDate = metrics.get(0).Date__c;
                for (CommCareHQ_Performance_Metrics__c rec : metrics) {
                    if (rec.Date__c.year() != lastDate.year() || rec.Date__c.month() != lastDate.month()) {
                        tmpData.graphValue2 = (tmpData.recordCount1 != 0 ? tmpData.graphValue2 / tmpData.recordCount1 : 0);
                        tmpData.graphValue1 = (tmpData.recordCount2 != 0 ? tmpData.graphValue1 / tmpData.recordCount2 : 0);
                        tmpData.graphValue3 = (tmpData.recordCount3 != 0 ? tmpData.graphValue3 / tmpData.recordCount3 : 0);
                        tmpData.graphValue4 = (tmpData.recordCount4 != 0 ? tmpData.graphValue4 / tmpData.recordCount4 : 0);
                        tmpData.name = getDateText(lastDate);
                        this.upTimeData.add(tmpData);
                        tmpData = new LineChartData('', 0, 0, 0, 0);
                    }

                    if (rec.India_Server_Uptime__c != null) {
                        tmpData.graphValue2 += rec.India_Server_Uptime__c;
                        tmpData.recordCount1++;
                    }
                    if (rec.Prod_Uptime__c != null) {
                        tmpData.graphValue1 += rec.Prod_Uptime__c;
                        tmpData.recordCount2++;
                    }
                    if (rec.ICDS_Uptime__c != null) {
                        tmpData.graphValue3 += rec.ICDS_Uptime__c;
                        tmpData.recordCount3++;
                    }
                    if (rec.eNikshay_Up_Time__c != null) {
                        tmpData.graphValue4 += rec.eNikshay_Up_Time__c;
                        tmpData.recordCount4++;
                    }
                    lastDate = rec.Date__c;
                }
                // we must add the last date from list:
                tmpData.name = getDateText(lastDate);
                tmpData.graphValue2 = (tmpData.recordCount1 != 0 ? tmpData.graphValue2 / tmpData.recordCount1 : 0);
                tmpData.graphValue1 = (tmpData.recordCount2 != 0 ? tmpData.graphValue1 / tmpData.recordCount2 : 0);
                tmpData.graphValue3 = (tmpData.recordCount3 != 0 ? tmpData.graphValue3 / tmpData.recordCount3 : 0);
                tmpData.graphValue4 = (tmpData.recordCount4 != 0 ? tmpData.graphValue4 / tmpData.recordCount4 : 0);
                this.upTimeData.add(tmpData);
            }
        } catch(Exception e) {
            message = e.getMessage();
            error = true;
        }

        if (error == true) {
            System.debug('Cannot load up time data');
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot load up time data for Corporate Dashboard', message);
            }
        }
        return this.upTimeData;
    }

    public String getDateText(Date snDate) {
        return DateTime.newInstance(snDate.year(), snDate.month(), snDate.day()).format('MMMM yyyy');
    }

    public class LineChartData {

        public String name { get; set; }
        public Decimal graphValue1 { get; set; }
        public Decimal graphValue2 { get; set; }
        public Decimal graphValue3 { get; set; }
        public Decimal graphValue4 { get; set; }
        public Decimal recordCount1 { get; set;}
        public Decimal recordCount2 { get; set;}
        public Decimal recordCount3 { get; set;}
        public Decimal recordCount4 { get; set;}

        public LineChartData() {
        }

        public LineChartData(String name, Decimal graphValue1, Decimal graphValue2, Decimal graphValue3, Decimal graphValue4) {
            this.name = name;
            this.graphValue1 = graphValue1;
            this.graphValue2 = graphValue2 / 1000.00;
            this.graphValue3 = graphValue3;
            this.graphValue4 = graphValue4;
            this.recordCount1 = 0;
            this.recordCount2 = 0;
            this.recordCount3 = 0;
            this.recordCount4 = 0;
        }
    }
}