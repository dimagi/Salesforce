/**
 * Controller for refreshing Corporate Dashboard charts.
 */
public without sharing class CorporateDashboardController {

    public Boolean refreshing { get; set;}

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

    public List<DoubleLineChartData> getPerformanceData() {
        List<DoubleLineChartData> performanceData = new List<DoubleLineChartData>();
        performanceData.add(new DoubleLineChartData('Jan', 3000.0, 9.0));
        performanceData.add(new DoubleLineChartData('Feb', 4400.0, 1.5));
        performanceData.add(new DoubleLineChartData('Mar', 2500.0, 3.2));
        performanceData.add(new DoubleLineChartData('Apr', 7400.0, 2.8));
        performanceData.add(new DoubleLineChartData('May', 6500.0, 5.1));
        performanceData.add(new DoubleLineChartData('Jun', 3300.0, 4.5));
        performanceData.add(new DoubleLineChartData('Jul', 9200.0, 8.2));
        performanceData.add(new DoubleLineChartData('Aug', 8700.0, 7.3));
        performanceData.add(new DoubleLineChartData('Sep', 3400.0, 6.5));
        performanceData.add(new DoubleLineChartData('Oct', 7800.0, 6.6));
        performanceData.add(new DoubleLineChartData('Nov', 8000.0, 6.7));
        performanceData.add(new DoubleLineChartData('Dec', 1700.0, 7.0));
        return performanceData;
    }


    public List<DoubleLineChartData> getData() {
        try {
            Reports.reportResults results = Reports.ReportManager.runReport('00Ob00000047rxW', true);
            Reports.Dimension dim = results.getGroupingsDown();
            Map<String, Reports.AggregateColumn> columnsInfo = results.getReportExtendedMetadata().getAggregateColumnInfo();
            Reports.GroupingValue groupingVal = dim.getGroupings()[0];
            Integer columnNumber = 0;

            Map<String, Integer> labelIdx = new Map<String, Integer>();
            for (Reports.AggregateColumn agColumn : columnsInfo.values()) {
                labelIdx.put(agColumn.getLabel(), columnNumber);
                columnNumber++;
            }

            Integer avgPageLoadId = 0;
            Integer avgSubmissionsId = 0;
            Integer avgServerApdexId = 0;
            if (labelIdx.containsKey('Avg Page Load') && labelIdx.containsKey('Avg # of Submissions') && labelIdx.containsKey('Avg Server Apdex')) {
                Integer avgPageLoadId = labelIdx.get('Avg Page Load');
                Integer avgSubmissionsId = labelIdx.get('Avg # of Submissions');
                Integer avgServerApdexId = labelIdx.get('Avg Server Apdex');
            } else {
                break;
                //TODO send email
            }

            for (Reports.GroupingValue gValue : dim.getGroupings()) {
                String monthName = gValue.getLabel();
                String factMapKey = gValue.getKey() + '!T';

                Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
                system.debug(monthName + ' ' + (Decimal) factDetails.getAggregates()[avgPageLoadId].getValue() + ' ' +(Decimal) factDetails.getAggregates()[avgSubmissionsId].getValue(),
                                            (Decimal) factDetails.getAggregates()[avgServerApdexId].getValue());
                performanceData.add(new DoubleLineChartData(monthName, (Decimal) factDetails.getAggregates()[avgPageLoadId].getValue(), (Decimal) factDetails.getAggregates()[avgSubmissionsId].getValue(),
                                            (Decimal) factDetails.getAggregates()[avgServerApdexId].getValue()));
            }
        } catch(Exception e) {
            break;
        }
    }

    public class DoubleLineChartData {

        public String name { get; set; }
        public String name2 { get; set; }
        public Decimal valueLeftY { get; set; }
        public Decimal valueRightY { get; set; }

        public Decimal avgPageLoad { get; set; }
        public Decimal avgSubmissions { get; set; }
        public Decimal avgServerApdex { get; set; }

        public DoubleLineChartData(String name, Decimal avgPageLoad, Decimal avgSubmissions, Decimal avgServerApdex) {
            this.name = name;
            this.avgPageLoad = avgPageLoad;
            this.avgSubmissions = avgSubmissions;
            this.avgServerApdex = avgServerApdex;
        }

        public DoubleLineChartData(String name, Decimal valueLeftY, Decimal valueRightY) {
            this.name = name;
            this.valueLeftY = valueLeftY;
            this.valueRightY = valueRightY;
        }
    }
}