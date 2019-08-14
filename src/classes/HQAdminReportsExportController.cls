public class HQAdminReportsExportController {

    public static final List<String> exportColumns = new List<String> {'Name', 'hr_name__c', 'date_created__c', 'Deployment_Countries__c', 'Server_Name__c', 'is_test__c', 'hipaa_compliant__c', 'Internal_Properties__r.notes__c',
                                                                       'Internal_Properties__r.project_state__c', 'InternalProp_using_adm__c', 'InternalProp_using_call_center__c', 'Internal_Properties__r.area__c',
                                                                       'Internal_Properties__r.sub_area__c', 'InternalProp_Business_Unit__c', 'InternalProp_self_started__c', 'InternalProp_commtrack_domain__c', 'InternalProp_custom_eula__c',
                                                                       'Internal_Properties__r.organization_name__c', 'Has_J2ME_submission_in_past_90_days__c', 'cpActiveMobileUsers__c', 'cpAllMobileUsers__c', 'Cp_n_users_submitted_form__c',
                                                                       'cpCasesIn60Days__c', 'cpAllActiveCases__c', 'cpAllInactiveCases__c', 'cpAllCases__c', 'cpAllForms__c', 'cpFormsIn30Days__c', 'cpFirstFormSubmissionDate__c',
                                                                       'cp300thFormSubmission__c', 'cpLastFormSubmissionDate__c', 'cpAllWebUsers__c', 'cpIsActive__c', 'cpAllOutgoingSms__c', 'cpAllIncomingSms__c',
                                                                       'cpAllSms__c', 'cpIncomingSmsIn30Days__c', 'cpOutgoingSmsIn30Days__c', 'Cp_last_update__c'};

    public String fileName { get; set; }
    public List<String> loadedFilters { get; set; }
    public DateTime generationDate {
            get {
                return DateTime.now();
            }
            set; }

    private QueryBuilder qb;
    private HQ_Admin_Report_CSV_Files__c exportFacet;

    public HQAdminReportsExportController() {
        this.fileName = 'empty';
        String facetId = ApexPages.currentPage().getParameters().get('facetId');
        if (String.isNotBlank(facetId)) {
            List<HQ_Admin_Report_CSV_Files__c> exportDataList = [SELECT Id, Name, Facet_Filters_JSON__c, Domain_Name__c, Order_Field__c, Order_Direction__c
                                                                 FROM HQ_Admin_Report_CSV_Files__c WHERE Id =: facetId];
            if (exportDataList.size() > 0) {
                this.exportFacet = exportDataList.get(0);
                String tmpName = HQAdminReportFactory.supportedReportsMap.get(this.exportFacet.Name);
                this.fileName = (String.isNotBlank(tmpName) ? tmpName.toLowerCase().replaceAll(' ', '_') : (String.isNotBlank(this.exportFacet.Name) ? this.exportFacet.Name.toLowerCase().replaceAll(' ', '_') : 'hq_admin_report'));
                this.fileName += '_' + Date.today().month() + '_' + Date.today().day() + '_' + Date.today().year();
                fetchExportData();
            } else {
                throwAnError(facetId);
            }
        } else {
            throwAnError(facetId);
        }
    }

    public List<Domain__c> getDomainRecords() {
        List<Domain__c> domains = Database.query(this.qb.buildQuery());
        for (Domain__c domain : domains) {
            domain.hr_name__c = escapedCsv(domain.hr_name__c);
            domain.Deployment_Countries__c = escapedCsv(domain.Deployment_Countries__c);
            if (domain.Internal_Properties__c == null) {
                domain.Internal_Properties__r = new Internal_Properties__c();
            }
            domain.Internal_Properties__r.organization_name__c = escapedCsv(domain.Internal_Properties__r.organization_name__c);
            domain.Internal_Properties__r.project_state__c = escapedCsv(domain.Internal_Properties__r.project_state__c);
            domain.Internal_Properties__r.area__c = escapedCsv(domain.Internal_Properties__r.area__c);
            domain.Internal_Properties__r.sub_area__c = escapedCsv(domain.Internal_Properties__r.sub_area__c);
            domain.Internal_Properties__r.notes__c = escapedCsv(domain.Internal_Properties__r.notes__c);
        }
        return domains;
    }

    public String escapedCsv(String input) {
        String output = input != null ? input.escapeCsv() : '""';
        if (!output.startsWith('"') && !output.endsWith('"')) {
            output = '"' + output + '"';
        }
        return output;
    }

    /**
     * Future method used to delete old export records (HQ_Admin_Report_CSV_Files__c).
     * It is used by Domain synch scheduler to avoid additional shceduled jobs and classes.
     * We don't want used additional resources because salesforce have limitations.
     */
    @future
    public static void deleteOldExports() {
        List<HQ_Admin_Report_CSV_Files__c> toDelete = [SELECT Id FROM HQ_Admin_Report_CSV_Files__c WHERE CreatedDate <: DateTime.now().addMinutes(-5)];
        if (toDelete.size() > 0) {
            delete toDelete;
        }
    }

    private void fetchExportData() {
        FacetController facetCtrl = FacetController.buildFacetController(this.exportFacet.Facet_Filters_JSON__c);
        facetCtrl.domainNameSearch = this.exportFacet.Domain_Name__c;
        this.loadedFilters = facetCtrl.getCurrentFiltersForExport();

        this.qb = facetCtrl.getQueryBuilder();
        this.qb.selectFrom('Domain__c').addColumns(exportColumns).addColumn('Internal_Properties__c').setLimit(10000);

        if (String.isNotBlank(this.exportFacet.Order_Field__c)) {
            this.qb.orderBy(this.exportFacet.Order_Field__c, (this.exportFacet.Order_Direction__c == false ? QueryBuilder.QB_ASC : QueryBuilder.QB_DESC), this.exportFacet.Order_Direction__c);
            if (this.exportFacet.Order_Field__c != 'Name') {
                this.qb.orderBy('Name', QueryBuilder.QB_ASC);
            }
        }
    }

    private void throwAnError(String facetId) {
        CalloutException ex = new CalloutException();
        ex.setMessage('Incorrect facet Id: ' + facetId);
        throw ex;
    }
}