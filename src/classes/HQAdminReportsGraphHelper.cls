public class HQAdminReportsGraphHelper {

    private static Map<Integer, HQAdminGraphMetaData> graphMap = new Map<Integer, HQAdminGraphMetaData>
        {
            1 => new HQAdminGraphMetaData(1, 'Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> { new HQAdminGraphFieldMedaData('# domains created', 'Date created', 'Domain_date_created_date_wrapper__c'),
                                                                  new HQAdminGraphFieldMedaData('# domains first form submitted', 'First Form Submitted', 'Domain_first_form_sub_date_wrapper__c'),
                                                                  new HQAdminGraphFieldMedaData('# domains last form submitted', 'Last Form Submitted', 'Domain_last_form_sub_date_wrapper__c')},
                            new Map<String, List<String>>()),
            2 => new HQAdminGraphMetaData(2, 'Total Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>()),
            3 => new HQAdminGraphMetaData(3, 'Total Self-Started Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>> { 'Internal_Properties__r.self_started__c' => new List<String> { 'true' }}),
            4 => new HQAdminGraphMetaData(4, 'Total Domains That Use Messaging', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>()),
            5 => new HQAdminGraphMetaData(5, 'Total CommCare Supply Project Spaces', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains', 'Date created', 'Domain_date_created_date_wrapper__c')},
                            new Map<String, List<String>>()),
            6 => new HQAdminGraphMetaData(6, 'Subscriptions', 'Date',
                            new List<HQAdminGraphFieldMedaData> {new HQAdminGraphFieldMedaData('# domains on subscription', 'Date', 'current_day')},
                            new Map<String, List<String>>(), 'subscriptions')
        };

    public static HQAdminGraphMetaData getGraphMetadata(Integer graphId) {
        return graphMap.get(graphId);
    }

    public static HQAdminReportGraphDataContainer loadGraphData(Integer graphId, Date fromDate, Date toDate, String interval,
                                                                String groupField, String currentFilters, String domainName) {
        HQAdminGraphMetaData graphMeta = getGraphMetadata(graphId);
        FacetController facetCtrl = FacetController.buildFacetController(currentFilters);
        facetCtrl.domainNameSearch = domainName;
        for (String key : graphMeta.loadGraphFilters().keySet()) {
            facetCtrl.addCurrentFilters(key, graphMeta.loadGraphFilters().get(key));
        }

        if (fromDate == null || toDate == null) {
            fromDate = Date.today().addMonths(-3); // dates are fixed on ui datepicker but we must check twice to be sure everything is working
            toDate = Date.today();
        }

        if (graphMeta.graphType == 'domains') {
            return loadDomainGraph(facetCtrl, fromDate, toDate, interval, groupField);
        } else if (graphMeta.graphType == 'subscriptions') {
            return loadSubscriptionData(facetCtrl.getQueryBuilder(), fromDate, toDate, interval);
        }
        return null;
    }

    public static HQAdminReportGraphDataContainer loadDomainGraph(FacetController facetCtrl, Date fromDate, Date toDate, String interval, String groupField) {
        HQAdminReportGraphDataContainer gData = new HQAdminReportGraphDataContainer(interval, 0);
        List<DateRange> dateRanges = new List<DateRange>();
        if ((interval == 'daily' || interval == 'weekly') && fromDate.monthsBetween(toDate) > 48) { // Aggregate result max 2000 records so we want take it in batches
            Date tmpStart = fromDate;
            do {
                dateRanges.add(new DateRange(tmpStart, tmpStart.addMonths(48)));
                tmpStart = tmpStart.addMonths(48).addDays(1);
            } while (tmpStart <= toDate);
            dateRanges.get(dateRanges.size() - 1).toDate = toDate;
        } else {
            dateRanges.add(new DateRange(fromDate, toDate));
        }

        List<HQAdminReportGraphPoint> values = new List<HQAdminReportGraphPoint>();
        for (DateRange dr : dateRanges) {
            values.addAll(executeDomainQuery(facetCtrl.getQueryBuilder(), dr.fromDate, dr.toDate, interval, groupField));
        }

        List<HQAdminReportGraphPoint> effectiveValues = values;
        if (interval == 'weekly') { // we cannot group by weeks in SOQL query so we must takve care manually on this data
            Date weekStart = null;
            Integer counter = 0;
            effectiveValues = new List<HQAdminReportGraphPoint>();
            for (HQAdminReportGraphPoint dayPoint : values) {
                if (weekStart == null) {
                    weekStart = dayPoint.x;
                }
                counter += dayPoint.y;

                if (isEndOfWeek(dayPoint.x)) {
                    effectiveValues.add(new HQAdminReportGraphPoint(weekStart, counter));

                    weekStart = null;
                    counter = 0;
                }
            }
            if (weekStart != null) {
                effectiveValues.add(new HQAdminReportGraphPoint(weekStart, counter));
            }
        }

        gData.addSeries('Domains', effectiveValues);
        return gData;
    }

    public static List<HQAdminReportGraphPoint> executeDomainQuery(QueryBuilder qb, Date fromDate, Date toDate, String interval, String groupField) {
        String calendarYear = 'calendar_year(' + groupField + ')';
        String calendarMonth = 'calendar_month(' + groupField + ')';
        Integer expCounter = 0;

        qb.addAnd(groupField, fromDate, QueryBuilder.QB_GTE).addAnd(groupField, toDate, QueryBuilder.QB_LTE);
        if (interval == 'daily' || interval == 'weekly') {
            qb.addColumn(groupField).groupBy(groupField).orderBy(groupField, QueryBuilder.QB_ASC);
        } else if (interval == 'monthly') {
            expCounter = 2;
            qb.addColumn(calendarYear).addColumn(calendarMonth).groupBy(calendarYear).groupBy(calendarMonth).orderBy(calendarYear, QueryBuilder.QB_ASC).orderBy(calendarMonth, QueryBuilder.QB_ASC);
        } else {
            expCounter = 1;
            qb.addColumn(calendarYear).groupBy(calendarYear).orderBy(calendarYear, QueryBuilder.QB_ASC);
        }
        qb.addColumn('count(Id)').addAnd(groupField, (Date) null, QueryBuilder.QB_NOT_EQUAL);

        List<HQAdminReportGraphPoint> values = new List<HQAdminReportGraphPoint>();
        for (AggregateResult agRes : Database.query(qb.buildQuery())) {
            Date dateValue = null;
            if (interval == 'daily' || interval == 'weekly') {
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
                values.add(new HQAdminReportGraphPoint(dateValue, recordCount));
            }
        }
        return values;
    }

    public static HQAdminReportGraphDataContainer loadSubscriptionData(QueryBuilder qb, Date fromDate, Date toDate, String interval) {
        Set<Id> selecteDomains = new Set<Id>();
        qb.addColumn('Id');
        for (Domain__c domain : Database.query(qb.buildQuery())) {
            selecteDomains.add(domain.Id); // domains set for subscriptions
        }

        Map<String, Map<Date, Set<Id>>> dateResultMapping = new Map<String, Map<Date, Set<Id>>> { 'Community' => new Map<Date, Set<Id>>(),
                                                                                                  'Standard' => new Map<Date, Set<Id>>(),
                                                                                                  'Pro' => new Map<Date, Set<Id>>(),
                                                                                                  'Advanced' => new Map<Date, Set<Id>>(),
                                                                                                  'Enterprise' => new Map<Date, Set<Id>>(),
                                                                                                  'Reseller' => new Map<Date, Set<Id>>(),
                                                                                                  'Managed Hosting' => new Map<Date, Set<Id>>() };
        Set<String> softwarePlans = dateResultMapping.keySet();
        List<DateRange> ranges = buildDateRangeList(fromDate, toDate, interval);
        for (Accounting_Subscription__c sub : [SELECT Id, Software_Plan_Edition__c, Accounting_subscriber_domain__c, date_start__c, date_end__c
                                               FROM Accounting_Subscription__c WHERE is_hidden_to_ops__c = false AND Accounting_subscriber_domain__c IN: selecteDomains AND
                                                                                ((date_start__c >=: fromDate AND date_end__c <=: toDate) OR (date_start__c <=: fromDate AND date_end__c >=: toDate) OR
                                                                                (date_start__c <=: fromDate AND date_end__c <=: toDate) OR (date_start__c >=: fromDate AND date_end__c >=: toDate))
                                                                                AND Software_Plan_Edition__c IN: dateResultMapping.keySet()]) { // load subs
            for (DateRange dateRange : ranges) {
                if (!softwarePlans.contains(sub.Software_Plan_Edition__c)) {
                    continue;
                }
                if (dateRange.isInRange(sub.date_start__c, sub.date_end__c)) { // if in range
                    Map<Date, Set<Id>> resultHelper = dateResultMapping.get(sub.Software_Plan_Edition__c);
                    if (resultHelper.containsKey(dateRange.fromDate)) {
                        resultHelper.get(dateRange.fromDate).add(sub.Accounting_subscriber_domain__c);
                    } else {
                        resultHelper.put(dateRange.fromDate, new Set<Id> { sub.Accounting_subscriber_domain__c });
                    }
                }
            }
        }

        HQAdminReportGraphDataContainer gData = new HQAdminReportGraphDataContainer(interval, 0);
        for (String softwarePlan : dateResultMapping.keySet()) {
            List<HQAdminReportGraphPoint> values = new List<HQAdminReportGraphPoint>();
            Map<Date, Set<Id>> resultHelper = dateResultMapping.get(softwarePlan);
            for (DateRange dateRange : ranges) {//Date keyDate : resultHelper.keySet()) {
                values.add(new HQAdminReportGraphPoint(dateRange.fromDate, (resultHelper.containsKey(dateRange.fromDate) ? resultHelper.get(dateRange.fromDate).size() : 0)));
            }
            gData.addSeries(softwarePlan, values);
        }

        return gData;
    }

    public static List<DateRange> buildDateRangeList(Date startDate, Date endDate, String interval) {
        List<DateRange> rangeList = new List<DateRange>();
        Date dateHelper = startDate;
        if (interval == 'daily') {
            do {
                rangeList.add(new DateRange(dateHelper, dateHelper));
                dateHelper = dateHelper.addDays(1);
            } while (dateHelper <= endDate);
        } else if (interval == 'weekly') {
            // find first Sat
            Date dateEndHelper = startDate;
            while(!isEndOfWeek(dateEndHelper)) {
                dateEndHelper = dateEndHelper.addDays(1);
            }
            do {
                rangeList.add(new DateRange(dateHelper, dateEndHelper));
                dateHelper = dateEndHelper.addDays(1);
                dateEndHelper = dateEndHelper.addDays(7);
            } while (dateHelper <= endDate);
        } else if (interval == 'monthly') {
            do {
                rangeList.add(new DateRange(dateHelper, Date.newInstance(dateHelper.year(), dateHelper.month(), Date.daysInMonth(dateHelper.year(), dateHelper.month()))));
                dateHelper = dateHelper.addMonths(1).toStartOfMonth();
            } while (dateHelper <= endDate);
        } else if (interval == 'yearly') {
            do {
                rangeList.add(new DateRange(dateHelper, Date.newInstance(dateHelper.year(), 12, 31)));
                dateHelper = dateHelper.addYears(1);
                dateHelper = Date.newInstance(dateHelper.year(), 1, 1);
            } while (dateHelper <= endDate);
        }

        rangeList.get(rangeList.size() - 1).toDate = endDate; // fix for monthly, yearly and weekly intervals
        return rangeList;
    }

    public static Boolean isEndOfWeek(Date dateParam) {
        DateTime myDateTime = DateTime.newInstance(dateParam.year(), dateParam.month(), dateParam.day());
        String dayOfWeek = myDateTime.format('E');
        if (dayofWeek == 'Sun') {
            return true;
        }
        return false;
    }

    /**
     * Helper class for checking was subscription active in given time range
     */
    public class DateRange {

        public Date fromDate { get; set; }
        public Date toDate { get; set; }

        DateRange(Date fromDate, Date toDate) {
            this.fromDate = fromDate;
            this.toDate = toDate;
        }

        public Boolean isInRange(Date dateToCheckFrom, Date dateToCheckTo) {
            return dateToCheckFrom <= this.toDate && dateToCheckTo >= this.fromDate;
        }
    }

    /**
     * UI metadata classes for generating graphs structure
     */
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
        public String graphType { get; set; }
        public String title { get; set; }
        public String xLabel { get; set; }
        public Integer graphId { get; set; }
        public String defaultInterval { get; set; }
        public List<HQAdminGraphFieldMedaData> fieldMapping { get; set; }
        public Boolean cumulative { get; set; }

        private Map<String, List<String>> graphFilters;

        public HQAdminGraphMetaData(Integer graphId, String title, String xLabel, List<HQAdminGraphFieldMedaData> fieldMapping,
                                        Map<String, List<String>> graphFilters) {
            this(graphId, title, xLabel, fieldMapping, graphFilters, 'domains');
        }

        public HQAdminGraphMetaData(Integer graphId, String title, String xLabel, List<HQAdminGraphFieldMedaData> fieldMapping,
                                        Map<String, List<String>> graphFilters, String graphType) {
            this.title = title;
            this.xLabel = xLabel;
            this.graphId = graphId;
            this.fieldMapping = fieldMapping;
            this.graphFilters = graphFilters;
            this.graphType = graphType;
            if (this.graphType == 'domains') {
                this.defaultInterval = 'weekly';
                this.cumulative = true;
            } else {
                this.defaultInterval = 'monthly';
                this.cumulative = false;
            }
        }

        public Map<String, List<String>> loadGraphFilters() {
            return graphFilters;
        }
    }

    /**
     * NVD3 json data reprezentation
     */
    public class HQAdminReportGraphDataContainer {
        public Integer totalToFromDate { get; set; }
        public String currentInterval { get; set; }
        public List<HQAdminReportGraphSeries> graphData { get; set; }

        public HQAdminReportGraphDataContainer(String currentInterval, Integer totalToFromDate) {
            this.graphData = new List<HQAdminReportGraphSeries>();
            this.currentInterval = currentInterval;
            this.totalToFromDate = totalToFromDate;
        }

        public void addSeries(String key, List<HQAdminReportGraphPoint> values) {
            this.graphData.add(new HQAdminReportGraphSeries(key, values));
        }
    }

    public class HQAdminReportGraphSeries {
        public String key { get; set; }
        public List<HQAdminReportGraphPoint> values { get; set; }

        public HQAdminReportGraphSeries(String key, List<HQAdminReportGraphPoint> values) {
            this.key = key;
            this.values = values;
        }
    }

    public class HQAdminReportGraphPoint {
        public Date x { get; set; }
        public Integer y { get; set; }

        public HQAdminReportGraphPoint(Date selectedDate, Integer value) {
            this.x = selectedDate;
            this.y = value;
        }
    }
}