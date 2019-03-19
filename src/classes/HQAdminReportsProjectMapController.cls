public class HQAdminReportsProjectMapController {

    public String mapAccessToken { get; set; }
    public List<String> supportedReportsList { get; set; } // we want keep order
    public Map<String, String> supportedReports { get; set; }
    public String reportName { get; set; }

    public HQAdminReportsProjectMapController() {
        this.supportedReportsList = HQAdminReportFactory.getSupportedReportsParamters();
        this.supportedReports = HQAdminReportFactory.getSupportedReportsMap();
        this.reportName = 'projectReportMap';
        this.mapAccessToken = Admin_Reports_Settings__c.getOrgDefaults().DM_Map_Token__c;
    }

    @RemoteAction
    public static List<FacetController.FacetGroup> loadReportMapFacets(String jsonFilters) {
        FacetController facetCtrl = FacetController.buildMapFacetController(jsonFilters);
        facetCtrl.addCurrentFilter('cpIsActive__c', 'true');
        facetCtrl.addCurrentFilter('is_test__c', 'false');
        facetCtrl.loadFacetValues();
        return facetCtrl.getFacets();
    }

    @RemoteAction
    public static HQAdminMapData loadMapData(String currentFilters) {
        FacetController facetCtrl = FacetController.buildMapFacetController(currentFilters);
        return loadCountryData(facetCtrl);
    }

    private static HQAdminMapData loadCountryData(FacetController facetCtrl) {
        Map<String, Integer> countryMap = new Map<String, Integer>();
        Map<String, Integer> userMap = new Map<String, Integer>();

        facetCtrl.addCurrentFilter('cpIsActive__c', 'true');
        facetCtrl.addCurrentFilter('is_test__c', 'false');
        QueryBuilder qb = facetCtrl.getQueryBuilder();
        qb.addColumn('Countries_Wrapper__c').addColumn('Count(Id)').addColumn('Sum(cpActiveMobileUsers__c)').groupBy('Countries_Wrapper__c');
        for (AggregateResult agRes : Database.query(qb.buildQuery())) {
            List<String> nameValues;
            String name = (String) agRes.get('Countries_Wrapper__c');
            if (!String.isBlank(name) && name.contains(',')) {
                name = name.replaceAll(', ', ';');
                nameValues = name.split(',');
            } else {
                nameValues = new List<String> { name };
            }

            for (String val : nameValues) {
                val = val != null ? val.replaceAll(';', ', ') : val;
                Integer oldValue = countryMap.containsKey(val) ? countryMap.get(val) : 0;
                Integer countVal = ((Decimal) (agRes.get('expr0'))).intValue();
                countryMap.put(val, oldValue + countVal);

                oldValue = userMap.containsKey(val) ? userMap.get(val) : 0;
                countVal = ((Decimal) (agRes.get('expr1'))).intValue();
                userMap.put(val, oldValue + countVal);
            }
        }
        qb = facetCtrl.getQueryBuilder().addColumn('Count()');
        Integer activeCount = (Integer) Database.countQuery(qb.buildQuery());
        return new HQAdminMapData(countryMap, userMap, activeCount, qb.buildQuery());
    }

    public class HQAdminMapData {

        public Map<String, Integer> countryMap { get; set; }
        public Map<String, Integer> userMap { get; set; }
        public Integer totalActiveProjects { get; set; }
        public String testResponse { get; set; }

        public HQAdminMapData(Map<String, Integer> countryMap, Map<String, Integer> userMap, Integer totalActiveProjects, String testResponse) {
            this.countryMap = countryMap;
            this.userMap = userMap;
            this.totalActiveProjects = totalActiveProjects;
            this.testResponse = testResponse;
        }
    }
}