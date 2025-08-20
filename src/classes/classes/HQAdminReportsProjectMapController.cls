public class HQAdminReportsProjectMapController {

    public String mapAccessToken { get; set; }
    public String mapId { get; set; }
    public List<String> supportedReportsList { get; set; } // we want keep order
    public Map<String, String> supportedReports { get; set; }
    public String reportName { get; set; }

    public HQAdminReportsProjectMapController() {
        this.supportedReportsList = HQAdminReportFactory.getSupportedReportsParamters();
        this.supportedReports = HQAdminReportFactory.getSupportedReportsMap();
        this.reportName = 'projectReportMap';
        this.mapAccessToken = Admin_Reports_Settings__c.getOrgDefaults().DM_Map_Token__c;
        this.mapId = Admin_Reports_Settings__c.getOrgDefaults().DM_Map_Id__c;
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

    @RemoteAction
    public static List<HQAdminProjectData> loadTopFiveProjects(String country) {
        List<HQAdminProjectData> countryProjects = new List<HQAdminProjectData>();
        if (String.isNotBlank(country)) {
            List<Domain__c> domains = [SELECT Id, Name, organization__c, Internal_Properties__r.notes__c, Internal_Properties__r.area__c,
                                              Internal_Properties__r.sub_area__c, cpActiveMobileUsers__c, Countries_Picklist__c, Server_Name__c
                                       FROM Domain__c
                                       WHERE is_test__c = 'false' AND cpIsActive__c = true AND Countries_Picklist__c includes (:country) ORDER BY cpActiveMobileUsers__c DESC LIMIT 5];
            for (Domain__c domain : domains) {
                countryProjects.add(new HQAdminProjectData(domain.Id, domain.Name, domain.organization__c, domain.Internal_Properties__r.notes__c,
                                                           domain.Internal_Properties__r.area__c, domain.Internal_Properties__r.sub_area__c,
                                                           domain.Countries_Picklist__c, domain.cpActiveMobileUsers__c, domain.Server_Name__c));
            }
        }
        return countryProjects;
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

    public class HQAdminProjectData {

        public String sfId { get; set; }
        public String projectName { get; set; }
        public String organization { get; set; }
        public String description { get; set; }
        public String sector { get; set; }
        public String subSector { get; set; }
        public String countries { get; set; }
        public Integer users { get; set; }
        public String serverName { get; set; }

        public HQAdminProjectData(String sfId, String projectName, String organization, String description, String sector, String subSector, String countries, Decimal users, String serverName) {
            this.sfId = sfId;
            this.projectName = projectName;
            this.organization = organization;
            this.description = description;
            this.sector = sector;
            this.subSector = subSector;
            this.countries = countries;
            this.users = Integer.valueOf(users);
            this.serverName = serverName;
        }
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