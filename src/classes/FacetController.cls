public class FacetController {

    private List<FacetGroup> facets;
    private Map<String, List<String>> currentFilters;
    public Map<String, String> dataTypeMapping { get; set;}
    public String domainNameSearch { get; set; }

    public FacetController() {
        this.facets = new List<FacetGroup>(); // we generate filters for page, we hardcoded them to spped it up, we don't want fetch everything from database we have a lot things to calculate
        this.currentFilters = new Map<String, List<String>>();
        this.dataTypeMapping = new Map<String, String>();
        // Activity
        FacetGroup facetGroup = new FacetGroup('Activity');
        facetGroup.addFacet(createFacet('Test Project', 'Text', 'is_test__c'));
        facetGroup.addFacet(createFacet('Active', 'Checkbox', 'cpIsActive__c'));
        facetGroup.addFacet(createFacet('Scale', 'Text', 'Internal_Properties__r.project_state__c'));
        this.facets.add(facetGroup);
        // Location
        facetGroup = new FacetGroup('Location');
        //facetGroup.addFacet(createFacet('Country', 'Text', 'Deployment_Countries__c'));
        facetGroup.addFacet(createFacet('Region', 'Text', 'Deployment_region__c'));
        facetGroup.addFacet(createFacet('City', 'Text', 'Deployment_city__c'));
        facetGroup.addFacet(createFacet('Workshop Region', 'Text', 'Internal_Properties__r.workshop_region__c'));
        this.facets.add(facetGroup);
        // Type
        facetGroup = new FacetGroup('Type');
        facetGroup.addFacet(createFacet('Sector', 'Text', 'Internal_Properties__r.area__c'));
        facetGroup.addFacet(createFacet('Sub-Sector', 'Text', 'Internal_Properties__r.sub_area__c'));
        facetGroup.addFacet(createFacet('Phone Model', 'Text', 'Internal_Properties__r.phone_model__c'));
        facetGroup.addFacet(createFacet('Project Manager', 'Text', 'Internal_Properties__r.project_manager__c'));
        this.facets.add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Self Starters');
        facetGroup.addFacet(createFacet('Self Started', 'Checkbox', 'Internal_Properties__r.self_started__c'));
        facetGroup.addFacet(createFacet('Has App', 'Checkbox', 'cpHasApp__c'));
        this.facets.add(facetGroup);
        // Advanced Features
        facetGroup = new FacetGroup('Advanced Features');
        facetGroup.addFacet(createFacet('Case Sharing', 'Checkbox', 'case_sharing__c'));
        facetGroup.addFacet(createFacet('ADM', 'Checkbox', 'Internal_Properties__r.using_adm__c'));
        facetGroup.addFacet(createFacet('Call Center', 'Checkbox', 'Internal_Properties__r.using_call_center__c'));
        facetGroup.addFacet(createFacet('CommCare Supply', 'Checkbox', 'Internal_Properties__r.commtrack_domain__c'));
        facetGroup.addFacet(createFacet('Survey Management', 'Checkbox', 'survey_management_enabled__c'));
        facetGroup.addFacet(createFacet('Used Messaging Ever', 'Checkbox', 'Domain_cp_sms_ever__c'));
        facetGroup.addFacet(createFacet('Used Messaging Last 30 days', 'Checkbox', 'Domain_cp_sms_30_d__c'));
        facetGroup.addFacet(createFacet('User \'scale\' backend', 'Checkbox', 'use_sql_backend__c'));
        this.facets.add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Plans');
        facetGroup.addFacet(createFacet('Project Type', 'Text', 'project_type__c'));
        facetGroup.addFacet(createFacet('Customer Type', 'Text', 'customer_type__c'));
        facetGroup.addFacet(createFacet('Initiative', 'Text', 'Internal_Properties__r.initiative__c'));
        facetGroup.addFacet(createFacet('SMS Billable', 'Checkbox', 'is_sms_billable__c'));
        this.facets.add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Eula');
        facetGroup.addFacet(createFacet('Public Data', 'Checkbox', 'Internal_Properties__r.can_use_data__c'));
        facetGroup.addFacet(createFacet('Custom Eula', 'Checkbox', 'Internal_Properties__r.custom_eula__c'));
        this.facets.add(facetGroup);
        loadFacetValues();
    }

    public QueryBuilder getQueryBuilder() {
        QueryBuilder qb = new QueryBuilder('Domain__c');
        if (String.isNotBlank(this.domainNameSearch)) {
            qb.addLike('Name', this.domainNameSearch);
        }
        for (String fieldName : this.currentFilters.keySet()) {
            List<String> qValues = this.currentFilters.get(fieldName);
            qb.addAnd(fieldName, qValues, this.dataTypeMapping.get(fieldName));
        }
        return qb;
    }

    public void loadFacetValues() {
        QueryBuilder qb = getQueryBuilder();
        qb.addColumn('{0}').addColumn('Count(Id)').groupBy('{0}');
        String finalFacetQuery = qb.buildQueryForFormat();
        for (FacetGroup fGroup : this.facets) {
            for (Facet facet : fGroup.facets) {
                reloadFacetValues(facet, finalFacetQuery);
            }
        }
    }

    public PageREference updateFacets() {
        loadFacetValues();
        return null;
    }

    private void reloadFacetValues(Facet facet, String dbQuery) {
        List<FacetValue> result = new List<FacetValue>();
        String effectiveName = facet.getFieldName();
        if (effectiveName.contains('.')) {
            effectiveName = effectiveName.split('\\.')[1];
        }

        for (AggregateResult agRes : Database.query(String.format(dbQuery, new List<String> {facet.getFieldName()}))) {
            String name;

            if (facet.getDataType() == 'Text') {
                name = (String) agRes.get(effectiveName);
            } else {
                Boolean tmpBool = (Boolean) agRes.get(effectiveName);
                name = tmpBool != null ? String.valueOf(tmpBool) : 'null';
            }

            Integer countVal = ((Decimal) (agRes.get('expr0'))).intValue();
            result.add(new FacetValue(name, countVal));
        }
 
        facet.values = result;
    }

    private Facet createFacet(String name, String dataType, String fieldName) {
        Facet facet = new Facet(name, dataType, fieldName);
        this.dataTypeMapping.put(fieldName, dataType);
        return facet;
    }

    public void setCurrentFilteringJSON(String jsonData) {
        this.currentFilters = (Map<String, List<String>>) JSON.deserialize(jsonData, Map<String, List<String>>.class);
    }

    public String getCurrentFilteringJSON() {
        return JSON.serialize(this.currentFilters);
    }

    public void setFacetJSON(String jsonData) {
        // we don't want update facets from UI
    }

    public String getFacetJSON() {
        return JSON.serialize(this.facets);
    }

    /**
     * Classes for facets UI represntation.
     */
    public class FacetGroup {
        public String name { get; set; }
        public List<Facet> facets { get; set; }

        public FacetGroup(String name) {
            this.name = name;
            this.facets = new List<Facet>();
        }

        public void addFacet(Facet newFacet) {
            this.facets.add(newFacet);
        }
    }

    public class Facet {
        public String name { get; set; }
        public List<FacetValue> values { get; set; }

        private final String dataType;
        private final String fieldName;

        public Facet(String name, String dataType, String fieldName) {
            this.name = name;
            this.dataType = dataType;
            this.fieldName = fieldName;
        }

        public String getFieldName() {
            return this.fieldName;
        }

        public String getDataType() {
            return this.dataType;
        }
    }

    public class FacetValue {
        public String value { get; set; }
        public Integer valCount { get; set; }

        public FacetValue(String value, Integer valCount) {
            this.value = value;
            this.valCount = valCount;
        }
    }
}