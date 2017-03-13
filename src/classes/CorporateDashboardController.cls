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
            Reports.reportResults results = Reports.ReportManager.runReport('00Ob00000047rxW', true);
            Reports.Dimension dim = results.getGroupingsDown();
            Map<String, Reports.AggregateColumn> columnsInfo = results.getReportExtendedMetadata().getAggregateColumnInfo();
            Reports.GroupingValue groupingVal = dim.getGroupings()[0];

            Set<String> labelIdx = new Set<String>();
            for (Reports.AggregateColumn agColumn : columnsInfo.values()) {
                labelIdx.add(agColumn.getLabel());
            }

            if (!labelIdx.contains('Avg Page Load') || !labelIdx.contains('Avg # of Submissions') || !labelIdx.contains('Avg Server Apdex')) {
                error = true;
                message = 'Cannot find Aggregates';
            }

            if (error == false) {
                for (Reports.GroupingValue gValue : dim.getGroupings()) {
                    String monthName = gValue.getLabel();
                    String factMapKey = gValue.getKey() + '!T';

                    Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
                    System.debug(monthName + ' ' + (Decimal) factDetails.getAggregates()[0].getValue() + ' ' +(Decimal) factDetails.getAggregates()[1].getValue()
                                            + ' ' + (Decimal) factDetails.getAggregates()[2].getValue());
                    this.performanceData.add(new DoubleLineChartData(monthName, (Decimal) factDetails.getAggregates()[0].getValue(), (Decimal) factDetails.getAggregates()[1].getValue(),
                                            (Decimal) factDetails.getAggregates()[2].getValue()));
                }
            }
        } catch(Exception e) {
            message = e.getMessage();
            error = true;
        }

        if (error == true) {
            System.debug('Cannot load performance data');
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot load performance data for Corporate Dashboard',
                                    'report Id : 00Ob00000047rxW   ' + message);
            }
        }

        return this.performanceData;
    }

    public class DoubleLineChartData {

        public String name { get; set; }
        public Decimal avgPageLoad { get; set; }
        public Decimal avgSubmissions { get; set; }
        public Decimal avgServerApdex { get; set; }

        public DoubleLineChartData(String name, Decimal avgPageLoad, Decimal avgSubmissions, Decimal avgServerApdex) {
            this.name = name;
            this.avgPageLoad = avgPageLoad;
            this.avgSubmissions = avgSubmissions / 1000.00;
            this.avgServerApdex = avgServerApdex;
        }
    }
}