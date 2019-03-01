public class HQAdminReportsController {

    private static final List<String> reportColumns = new List<String> {'Name', 'date_created__c', 'Deployment_Countries__c', 'Server_Name__c', 'is_test__c', 'hipaa_compliant__c', 'Internal_Properties__r.notes__c',
                                                                        'InternalProp_project_state__c', 'InternalProp_using_adm__c', 'InternalProp_using_call_center__c', 'InternalProp_area__c', 'InternalProp_sub_area__c',
                                                                        'InternalProp_Business_Unit__c', 'InternalProp_self_started__c', 'InternalProp_commtrack_domain__c', 'InternalProp_custom_eula__c',
                                                                        'InternalProp_organization_name__c', 'Has_J2ME_submission_in_past_90_days__c', 'cpActiveMobileUsers__c', 'cpAllMobileUsers__c', 'Cp_n_users_submitted_form__c',
                                                                        'cpCasesIn60Days__c', 'cpAllActiveCases__c', 'cpAllInactiveCases__c', 'cpAllCases__c', 'cpAllForms__c', 'cpFormsIn30Days__c', 'cpFirstFormSubmissionDate__c',
                                                                        'cp300thFormSubmission__c', 'cpLastFormSubmissionDate__c', 'cpAllWebUsers__c', 'cpIsActive__c', 'cpAllOutgoingSms__c', 'cpAllIncomingSms__c',
                                                                        'cpAllSms__c', 'cpIncomingSmsIn30Days__c', 'cpOutgoingSmsIn30Days__c', 'Cp_last_update__c'};

    public List<String> supportedReportsList { get; set; } // we want keep order
    public Map<String, String> supportedReports { get; set; }
    public String reportName { get; set; }
    public Boolean sortDir { get; set; }
    public Domain__c totalRow { get; set; }
    public Pagination tablePagination { get; set; }
    public Integer totalRowCount { get; set; }
    public FacetController facetCtrl { get; set; }
    public List<HQAdminReportsGraphHelper.HQAdminGraphMetaData> graphMetaDataList { get; set; }
    public String sortField { get;
        set {
            if (sortField != value) {
                this.sortDir = false;
            }
            sortField = value;
         }
    }

    private Boolean facetsWasUpadated;

    public HQAdminReportsController() {
        this.supportedReportsList = HQAdminReportFactory.getSupportedReportsParamters();
        this.supportedReports = HQAdminReportFactory.getSupportedReportsMap();

        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        this.reportName = pageParams.get('report');
        if (String.isBlank(this.reportName) || !supportedReports.containsKey(this.reportName)) {
            this.reportName = 'spaceList';
        }
        this.graphMetaDataList = HQAdminReportFactory.getGraphsMetadata(this.reportName);
        this.facetCtrl = HQAdminReportFactory.getFacetController(this.reportName);

        this.tablePagination = new Pagination();
        this.sortDir = false;
        this.sortField = null;
        this.totalRow = new Domain__c(Name = 'Total');
        this.facetsWasUpadated = true; // For first time opening we want calculate totals
        this.totalRowCount = 0;
    }

    public List<Domain__c> getDomainTableData() {
        QueryBuilder qb = this.facetCtrl.getQueryBuilder();
        qb.selectFrom('Domain__c').addColumns(HQAdminReportsController.reportColumns).setLimit(this.tablePagination.pageSize).setOffset(this.tablePagination.getOffsetValue());
        if (String.isNotBlank(this.sortField)) {
            qb.orderBy(this.sortField, (this.sortDir == false ? QueryBuilder.QB_ASC : QueryBuilder.QB_DESC), this.sortDir);
        }
        List<Domain__c> result = Database.query(qb.buildQuery());

        if (this.facetsWasUpadated) {
            calculateTableTotalRow();
            this.tablePagination.resetPageNumber();
            this.facetsWasUpadated = false;
        }
        this.tablePagination.handleResulSize(this.totalRowCount); // refresh hasNext etc.
        return result;
    }

    public void setGraphDataJSON(String value) {}

    public String getGraphDataJSON() {
        String jsonResponse;
        return JSON.serialize(this.graphMetaDataList);
    }

    public void sortColumn() {
        this.sortDir = !this.sortDir;
    }

    public PageReference updateFacets() {
        this.facetsWasUpadated = true;
        return null;
    }

    @RemoteAction
    public static List<FacetController.FacetGroup> loadReportFacets(String reportName, String jsonFilters, String domainName) {
        FacetController facetCtrl = FacetController.buildFacetController(jsonFilters);
        facetCtrl.domainNameSearch = domainName;
        facetCtrl.loadFacetValues();
        return facetCtrl.getFacets();
    }

    @RemoteAction
    public static HQAdminReportsGraphHelper.HQAdminReportGraphDataContainer loadGraphData(Integer graphId, String fromDate, String toDate, String interval,
                                                                                        String groupField, String currentFilters, String domainName) {
        Date parsedFrom = String.isNotBlank(fromDate) ? Date.parse(fromDate) : null;
        Date parsedTo = String.isNotBlank(toDate) ? Date.parse(toDate) : null;
        return HQAdminReportsGraphHelper.loadGraphData(graphId, parsedFrom, parsedTo, interval, groupField, currentFilters, domainName);
    }

    private void calculateTableTotalRow() {
        QueryBuilder qbCount = this.facetCtrl.getQueryBuilder();
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
}