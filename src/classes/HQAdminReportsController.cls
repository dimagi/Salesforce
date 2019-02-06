public class HQAdminReportsController {

    private static final List<String> reportColumns = new List<String> {'Name', 'date_created__c', 'Deployment_Countries__c', 'is_test__c', 'hipaa_compliant__c', 'Internal_Properties__r.notes__c',
                                                                        'InternalProp_project_state__c', 'InternalProp_using_adm__c', 'InternalProp_using_call_center__c', 'InternalProp_area__c', 'InternalProp_sub_area__c',
                                                                        'InternalProp_Business_Unit__c', 'InternalProp_self_started__c', 'InternalProp_commtrack_domain__c', 'InternalProp_custom_eula__c',
                                                                        'InternalProp_organization_name__c', 'Has_J2ME_submission_in_past_90_days__c', 'cpActiveMobileUsers__c', 'cpAllMobileUsers__c', 'Cp_n_users_submitted_form__c',
                                                                        'cpCasesIn60Days__c', 'cpAllActiveCases__c', 'cpAllInactiveCases__c', 'cpAllCases__c', 'cpAllForms__c', 'cpFormsIn30Days__c', 'cpFirstFormSubmissionDate__c',
                                                                        'cp300thFormSubmission__c', 'cpLastFormSubmissionDate__c', 'cpAllWebUsers__c', 'cpIsActive__c', 'cpAllOutgoingSms__c', 'cpAllIncomingSms__c',
                                                                        'cpAllSms__c', 'cpIncomingSmsIn30Days__c', 'cpOutgoingSmsIn30Days__c', 'Cp_last_update__c'};

    // Table order and pagination
    public String sortField { get;
        set {
            if (sortField != value) {
                this.sortDir = false;
            }
            sortField = value;
         }
    }
    public Boolean sortDir { get; set; }
    public Domain__c totalRow { get; set; }
    public Pagination tablePagination { get; set; }
    public Integer totalRowCount { get; set; }
    public FacetController facetController { get; set; }

    // graph
    public String graphField { get; set; }
    public String graphInterval { get; set; }
    public Date graphFrom { get; set; }
    public Date graphTo { get; set; }
    private HQAdminReportGraphContainer gData;


    private Boolean facetsWasUpadated;

    public HQAdminReportsController() {
        this.tablePagination = new Pagination();
        this.sortDir = false;
        this.sortField = 'Name';
        this.totalRow = new Domain__c(Name = 'Total');
        this.facetsWasUpadated = true; // For first time opening we want calculate totals
        this.totalRowCount = 0;
        this.facetController = new facetController();

        this.graphFrom = Date.today().addMonths(-3);
        this.graphTo = Date.today();
        this.graphField = 'Domain_date_created_date_wrapper__c';
        this.graphInterval = 'daily';
    }

    public List<Domain__c> getDomainTableData() {
        QueryBuilder qb = this.facetController.getQueryBuilder();
        qb.selectFrom('Domain__c').addColumns(HQAdminReportsController.reportColumns).setLimit(this.tablePagination.pageSize).setOffset(this.tablePagination.getOffsetValue());
        qb.orderBy(this.sortField, (this.sortDir == false ? QueryBuilder.QB_ASC : QueryBuilder.QB_DESC), this.sortDir);
        List<Domain__c> result = Database.query(qb.buildQuery());

        if (this.facetsWasUpadated) {
            calculateTableTotalRow();
            reloadGraphData();
            this.facetsWasUpadated = false;
        }
        this.tablePagination.handleResulSize(this.totalRowCount);
        return result;
    }

    public void reloadGraphData() {
        fixDates();
        QueryBuilder qb = this.facetController.getQueryBuilder();
        qb.addAnd(this.graphField, this.graphFrom, QueryBuilder.QB_GTE).addAnd(this.graphField, this.graphTo, QueryBuilder.QB_LTE);

        String calendarYear = 'calendar_year(' + this.graphField + ')';
        String calendarMonth = 'calendar_month(' + this.graphField + ')';
        Integer expCounter = 0;
        if (this.graphInterval == 'daily') {
            qb.addColumn(this.graphField).groupBy(this.graphField).orderBy(this.graphField, QueryBuilder.QB_ASC);
        } else if (this.graphInterval == 'monthly') {
            expCounter = 2;
            qb.addColumn(calendarYear).addColumn(calendarMonth).groupBy(calendarYear).groupBy(calendarMonth).orderBy(calendarYear, QueryBuilder.QB_ASC).orderBy(calendarMonth, QueryBuilder.QB_ASC);
        } else {
            expCounter = 1;
            qb.addColumn(calendarYear).groupBy(calendarYear).orderBy(calendarYear, QueryBuilder.QB_ASC);
        }
        qb.addColumn('count(Id)').addAnd(this.graphField, (Date) null, QueryBuilder.QB_NOT_EQUAL);

        this.gData = new HQAdminReportGraphContainer();
        this.gData.graphData = new List<HQAdminReportGraph>();
        this.gData.currentInterval = this.graphInterval;
        this.gData.totalToFromDate = 0; // TODO : probably later
        for (AggregateResult agRes : Database.query(qb.buildQuery())) {
            Date dateValue = null;
            if (this.graphInterval == 'daily') {
                dateValue = (Date) (agRes.get(this.graphField) != null ? agRes.get(this.graphField) : null);
            } else if (this.graphInterval == 'monthly') {
                Integer year = ((Decimal) (agRes.get('expr0'))).intValue();
                Integer month = ((Decimal) (agRes.get('expr1'))).intValue();
                dateValue = Date.newInstance(year, month, 1);
            } else {
                Integer year = ((Decimal) (agRes.get('expr0'))).intValue();
                dateValue = Date.newInstance(year, 1, 1);
            }

            Integer recordCount = ((Decimal) (agRes.get('expr' + expCounter))).intValue();
            if (dateValue != null) {
                this.gData.graphData.add(new HQAdminReportGraph(dateValue, recordCount));
            }
        }
    }

    public void setGraphDataJSON(String value) {}

    public String getGraphDataJSON() {
        String jsonResponse;
        return JSON.serialize(this.gData);
    }

    public void sortColumn() {
        this.sortDir = !this.sortDir;
    }

    public PageReference updateFacets() {
        this.facetsWasUpadated = true;
        return this.facetController.updateFacets();
    }

    private void fixDates() {
        if (this.graphFrom == null && this.graphTo == null) {
            this.graphFrom = Date.today().addMonths(-3);
            this.graphTo = Date.today();
        } else if (this.graphFrom == null && this.graphTo != null) {
            this.graphFrom = this.graphTo.addMonths(-3);
        } else if (this.graphFrom != null && this.graphTo == null) {
            this.graphTo = this.graphFrom.addMonths(3);
        } else if (this.graphTo < this.graphFrom) {
            Date helper = this.graphTo;
            this.graphTo = this.graphFrom;
            this.graphFrom = helper;
        }
    }

    private void calculateTableTotalRow() {
        QueryBuilder qbCount = this.facetController.getQueryBuilder();
        qbCount.addColumn('count(Id)').addColumn('sum(cpActiveMobileUsers__c)').addColumn('sum(cpAllMobileUsers__c)');
        qbCount.addColumn('sum(Cp_n_users_submitted_form__c)').addColumn('sum(cpCasesIn60Days__c)').addColumn('sum(cpAllActiveCases__c)');
        qbCount.addColumn('sum(cpAllInactiveCases__c)').addColumn('sum(cpAllCases__c)').addColumn('sum(cpAllForms__c)');
        qbCount.addColumn('sum(cpFormsIn30Days__c)').addColumn('sum(cpAllWebUsers__c)').addColumn('sum(cpAllOutgoingSms__c)');
        qbCount.addColumn('sum(cpAllIncomingSms__c)').addColumn('sum(cpAllSms__c)').addColumn('sum(cpIncomingSmsIn30Days__c)');
        qbCount.addColumn('sum(cpOutgoingSmsIn30Days__c)');

        for (AggregateResult agRes : Database.query(qbCount.buildQuery())) {
            this.totalRowCount = ((Decimal) (agRes.get('expr0'))).intValue();
            this.totalRow.cpActiveMobileUsers__c = getExpressionValueSafe(agRes, 'expr1'); //(Decimal) (agRes.get('expr1');
            this.totalRow.cpAllMobileUsers__c = getExpressionValueSafe(agRes, 'expr2');
            this.totalRow.Cp_n_users_submitted_form__c = getExpressionValueSafe(agRes, 'expr3');
            this.totalRow.cpCasesIn60Days__c = getExpressionValueSafe(agRes, 'expr4');
            this.totalRow.cpAllActiveCases__c = getExpressionValueSafe(agRes, 'expr5');
            this.totalRow.cpAllInactiveCases__c = getExpressionValueSafe(agRes, 'expr6');
            this.totalRow.cpAllCases__c = getExpressionValueSafe(agRes, 'expr7');
            this.totalRow.cpAllForms__c = getExpressionValueSafe(agRes, 'expr8');
            this.totalRow.cpFormsIn30Days__c = getExpressionValueSafe(agRes, 'expr9');
            this.totalRow.cpAllWebUsers__c = getExpressionValueSafe(agRes, 'expr10');
            this.totalRow.cpAllOutgoingSms__c = getExpressionValueSafe(agRes, 'expr11');
            this.totalRow.cpAllIncomingSms__c = getExpressionValueSafe(agRes, 'expr12');
            this.totalRow.cpAllSms__c = getExpressionValueSafe(agRes, 'expr13');
            this.totalRow.cpIncomingSmsIn30Days__c = getExpressionValueSafe(agRes, 'expr14');
            this.totalRow.cpOutgoingSmsIn30Days__c = getExpressionValueSafe(agRes, 'expr15');
        }
    }

    private Integer getExpressionValueSafe(AggregateResult aggregateResult, String expressionName) {
        Object obj = aggregateResult.get(expressionName);
        return obj != null ?((Decimal) obj).intValue() : 0;
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