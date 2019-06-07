public class HQAdminReportsExportController {

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
        return Database.query(this.qb.buildQuery());
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
        this.qb.selectFrom('Domain__c').addColumns(HQAdminReportsController.reportColumns).setLimit(10000);

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