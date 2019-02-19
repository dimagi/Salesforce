public class HQAdminReportsGraphHelper {

    private static Map<Integer, HQAdminGraphMetaData> graphMap = new Map<Integer, HQAdminGraphMetaData>
        {
            1 => new HQAdminReportsGraphHelper.HQAdminGraphMetaData(1, 'Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> { new HQAdminGraphFieldMedaData('# domains created', 'Date created', 'Domain_date_created_date_wrapper__c'),
                                                                  new HQAdminGraphFieldMedaData('# domains first form submitted', 'First Form Submitted', 'Domain_first_form_sub_date_wrapper__c'),
                                                                  new HQAdminGraphFieldMedaData('# domains last form submitted', 'Last Form Submitted', 'Domain_last_form_sub_date_wrapper__c')},
                            new Map<String, List<String>>()),
            2 => new HQAdminReportsGraphHelper.HQAdminGraphMetaData(2, 'Total Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>()),
            3 => new HQAdminReportsGraphHelper.HQAdminGraphMetaData(3, 'Total Self-Started Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>> { 'Internal_Properties__r.self_started__c' => new List<String> { 'true' }}),
            4 => new HQAdminReportsGraphHelper.HQAdminGraphMetaData(4, 'Total Domains That Use Messaging', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>()),
            5 => new HQAdminReportsGraphHelper.HQAdminGraphMetaData(5, 'Total CommCare Supply Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>())
        };

    public static HQAdminGraphMetaData getGraphMetadata(Integer graphId) {
        return graphMap.get(graphId);
    }

    public static HQAdminReportGraphContainer loadGraphData(Integer graphId, Date fromDate, Date toDate, String interval,
                                                                String groupField, String currentFilters, String domainName) {
        HQAdminGraphMetaData graphMeta = getGraphMetadata(graphId);
        FacetController facetCtrl = FacetController.buildFacetController(currentFilters);
        facetCtrl.domainNameSearch = domainName;
        for (String key : graphMeta.loadGraphFilters().keySet()) {
            facetCtrl.addCurrentFilters(key, graphMeta.loadGraphFilters().get(key));
        }
        QueryBuilder qb = facetCtrl.getQueryBuilder();

        if (fromDate == null || toDate == null) {
            fromDate = Date.today().addMonths(-3); // dates are fixed on ui datepicker but we must check twice to be sure everything is working
            toDate = Date.today();
        }

        qb.addAnd(groupField, fromDate, QueryBuilder.QB_GTE).addAnd(groupField, toDate, QueryBuilder.QB_LTE);

        String calendarYear = 'calendar_year(' + groupField + ')';
        String calendarMonth = 'calendar_month(' + groupField + ')';
        Integer expCounter = 0;
        if (interval == 'daily') {
            qb.addColumn(groupField).groupBy(groupField).orderBy(groupField, QueryBuilder.QB_ASC);
        } else if (interval == 'monthly') {
            expCounter = 2;
            qb.addColumn(calendarYear).addColumn(calendarMonth).groupBy(calendarYear).groupBy(calendarMonth).orderBy(calendarYear, QueryBuilder.QB_ASC).orderBy(calendarMonth, QueryBuilder.QB_ASC);
        } else {
            expCounter = 1;
            qb.addColumn(calendarYear).groupBy(calendarYear).orderBy(calendarYear, QueryBuilder.QB_ASC);
        }
        qb.addColumn('count(Id)').addAnd(groupField, (Date) null, QueryBuilder.QB_NOT_EQUAL);

        HQAdminReportGraphContainer gData = new HQAdminReportGraphContainer();
        gData.graphData = new List<HQAdminReportGraph>();
        gData.currentInterval = interval;
        gData.totalToFromDate = 0;
        for (AggregateResult agRes : Database.query(qb.buildQuery())) {
            Date dateValue = null;
            if (interval == 'daily') {
                dateValue = (Date) (agRes.get(groupField) != null ? agRes.get(groupField) : null);
            } else if (interval == 'monthly') {
                Integer year = ((Decimal) (agRes.get('expr0'))).intValue();
                Integer month = ((Decimal) (agRes.get('expr1'))).intValue();
                dateValue = Date.newInstance(year, month, 1);
            } else {
                Integer year = ((Decimal) (agRes.get('expr0'))).intValue();
                dateValue = Date.newInstance(year, 1, 1);
            }

            Integer recordCount = ((Decimal) (agRes.get('expr' + expCounter))).intValue();
            if (dateValue != null) {
                gData.graphData.add(new HQAdminReportGraph(dateValue, recordCount));
            }
        }
        return gData;
    }

    public class HQAdminGraphFieldMedaData {
        public String yLabel { get; set; }
        public String fieldLabel { get; set; }
        public String fieldName { get; set; }

        public HQAdminGraphFieldMedaData(String label, String fieldLabel, String fieldName) {
            this.yLabel = label;
            this.fieldLabel = fieldLabel;
            this.fieldName = fieldName;
        }
    }

    public class HQAdminGraphMetaData {
        public String title { get; set; }
        public String xLabel { get; set; }
        public Integer graphId { get; set; }
        public List<HQAdminGraphFieldMedaData> fieldMapping { get; set; }

        private Map<String, List<String>> graphFilters;

        public HQAdminGraphMetaData(Integer graphId, String title, String xLabel, List<HQAdminGraphFieldMedaData> fieldMapping,
                                        Map<String, List<String>> graphFilters) {
            this.title = title;
            this.xLabel = xLabel;
            this.graphId = graphId;
            this.fieldMapping = fieldMapping;
            this.graphFilters = graphFilters;
        }

        public Map<String, List<String>> loadGraphFilters() {
            return graphFilters;
        }
    }

    public class HQAdminReportGraphContainer {
        public Integer totalToFromDate { get; set; }
        public String currentInterval { get; set; }
        public List<HQAdminReportGraph> graphData { get; set; }
    }

    public class HQAdminReportGraph {

        public Date x { get; set; }
        public Integer y { get; set; }

        public HQAdminReportGraph(Date selectedDate, Integer value) {
            this.x = selectedDate;
            this.y = value;
        }
    }
}