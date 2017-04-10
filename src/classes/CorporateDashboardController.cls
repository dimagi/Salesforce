/**
 * Controller for refreshing Corporate Dashboard charts.
 */
public without sharing class CorporateDashboardController {

    public Boolean refreshing { get; set;}
    public List<DoubleLineChartData> performanceData { get; set;}

    public CorporateDashboardController() {
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

    public List<DoubleLineChartData> getData() {
        this.performanceData = new List<DoubleLineChartData>();
        Boolean error = false;
        String message = '';
        try {
            List<CommCareHQ_Performance_Metrics__c> metrics = [SELECT Date__c, Server_Apdex__c, Number_of_Submissions__c, Avg_Page_Load__c
                                                           FROM CommCareHQ_Performance_Metrics__c
                                                           WHERE Date__c >=: Date.today().addMonths(-12).toStartOfMonth()
                                                           ORDER BY Date__c ASC];

            if (metrics.size() > 0) {
                DoubleLineChartData tmpData = new DoubleLineChartData('', 0, 0, 0);
                Date lastDate = metrics.get(0).Date__c;
                for (CommCareHQ_Performance_Metrics__c rec : metrics) {
                    if (rec.Date__c.year() != lastDate.year() || rec.Date__c.month() != lastDate.month()) {
                        tmpData.avgSubmissions = (tmpData.avgSubmissions / (tmpData.recordCount != 0 ? tmpData.recordCount : 1)) / 1000.00;
                        tmpData.avgPageLoad = tmpData.avgPageLoad / (tmpData.recordCount != 0 ? tmpData.recordCount : 1);
                        tmpData.avgServerApdex = tmpData.avgServerApdex / (tmpData.recordCount != 0 ? tmpData.recordCount : 1);
                        tmpData.name = getDateText(lastDate);
                        this.performanceData.add(tmpData);
                        tmpData = new DoubleLineChartData('', 0, 0, 0);
                    }
                    tmpData.avgSubmissions += rec.Number_of_Submissions__c != null ? rec.Number_of_Submissions__c : 0;
                    tmpData.avgPageLoad += rec.Avg_Page_Load__c != null ? rec.Avg_Page_Load__c : 0;
                    tmpData.avgServerApdex += rec.Server_Apdex__c != null ? rec.Server_Apdex__c : 0;
                    tmpData.recordCount++;
                    lastDate = rec.Date__c;
                }
                // we must add the last date from list:
                tmpData.name = getDateText(lastDate);
                tmpData.avgSubmissions = (tmpData.avgSubmissions / (tmpData.recordCount != 0 ? tmpData.recordCount : 1)) / 1000.00;
                tmpData.avgPageLoad = tmpData.avgPageLoad / (tmpData.recordCount != 0 ? tmpData.recordCount : 1);
                tmpData.avgServerApdex = tmpData.avgServerApdex / (tmpData.recordCount != 0 ? tmpData.recordCount : 1);
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

    public String getDateText(Date snDate) {
        return DateTime.newInstance(snDate.year(), snDate.month(), snDate.day()).format('MMMM yyyy');
    }

    public class DoubleLineChartData {

        public String name { get; set; }
        public Decimal avgPageLoad { get; set; }
        public Decimal avgSubmissions { get; set; }
        public Decimal avgServerApdex { get; set; }
        public Decimal recordCount { get; set;}

        public DoubleLineChartData() {
        }

        public DoubleLineChartData(String name, Decimal avgPageLoad, Decimal avgSubmissions, Decimal avgServerApdex) {
            this.name = name;
            this.avgPageLoad = avgPageLoad;
            this.avgSubmissions = avgSubmissions / 1000.00;
            this.avgServerApdex = avgServerApdex;
            this.recordCount = 0;
        }
    }
}