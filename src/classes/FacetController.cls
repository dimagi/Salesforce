public class FacetController {

    private List<FacetGroup> facets;
    private Map<String, List<String>> currentFilters;
    public Map<String, String> dataTypeMapping { get; set;}
    public String domainNameSearch { get; set; }
    public Map<String, String> predefindedNotEqualFilters { get; set; }
    public Map<String, String> displayNameMapping { get; set; }


    public QueryBuilder getQueryBuilder() {
        return getQueryBuilder(new QueryBuilder('Domain__c'));
    }

    public QueryBuilder getQueryBuilder(QueryBuilder qb) {
        if (String.isNotBlank(this.domainNameSearch)) {
            qb.addLike('Name', this.domainNameSearch);
        }
        for (String fieldName : this.currentFilters.keySet()) {
            List<String> qValues = this.currentFilters.get(fieldName);
            qb.addAnd(fieldName, qValues, this.dataTypeMapping.get(fieldName));
        }
        for (String field : predefindedNotEqualFilters.keySet()) {
            qb.addAnd(field, predefindedNotEqualFilters.get(field), QueryBuilder.QB_TEXT_TYPE, QueryBuilder.QB_NOT_EQUAL);
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

    public void addCurrentFilters(String fieldName, List<String> values) {
        for (String value : values) {
            addCurrentFilter(fieldName, value);
        }
    }

    public void addCurrentFilter(String fieldName, String value) {
        if (this.currentFilters.containsKey(fieldName)) {
            List<String> currentValues = this.currentFilters.get(fieldName);
            if (!currentValues.contains(value)) {
                currentValues.add(value);
                this.currentFilters.put(fieldName, currentValues);
            }
        } else {
            this.currentFilters.put(fieldName, new List<String> { value });
        }
    }

    public void setCurrentFilteringJSON(String jsonData) {
        this.currentFilters = (Map<String, List<String>>) JSON.deserialize(jsonData, Map<String, List<String>>.class);
    }

    public String getCurrentFilteringJSON() {
        return JSON.serialize(this.currentFilters);
    }

    public String getFacetJSON() {
        return JSON.serialize(this.facets);
    }

    public List<FacetGroup> getFacets() {
        return this.facets;
    }

    public List<String> getCurrentFiltersForExport() {
        List<String> filtersResult = new List<String>();
        for (String fieldKey : this.currentFilters.keySet()) {
            String valuesHelper = '';
            for (String fieldValue : this.currentFilters.get(fieldKey)) {
                valuesHelper += ',"' + fieldValue + '"';
            }
            filtersResult.add('"' + this.displayNameMapping.get(fieldKey) + ' : "' + valuesHelper);
        }
        return filtersResult;
    }

    private void reloadFacetValues(Facet facet, String dbQuery) {
        List<FacetValue> result;
        String effectiveName = facet.getFacetQueryField();
        if (effectiveName.contains('.')) {
            effectiveName = effectiveName.split('\\.')[1];
        }

        if (facet.getDataType() != 'Multiselect') {
            result = getFacetValues(facet, String.format(dbQuery, new List<String> {facet.getFacetQueryField()}), facet.getFacetQueryField(), effectiveName);
        } else {
            result = getFacetValuesForMultiselect(String.format(dbQuery, new List<String> {facet.getFacetQueryField()}), facet.getFacetQueryField(), effectiveName);
        }

        facet.values = result;
    }

    private List<FacetValue> getFacetValues(Facet facet, String query, String fieldName, String effectiveName) {
        List<FacetValue> result = new List<FacetValue>();
        for (AggregateResult agRes : Database.query(query)) {
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
        return result;
    }

    private List<FacetValue> getFacetValuesForMultiselect(String query, String fieldName, String effectiveName) {
        List<FacetValue> result = new List<FacetValue>();
        Map<String, Integer> mappingHelper = new Map<String, Integer>();
        for (AggregateResult agRes : Database.query(query)) {
            List<String> nameValues;
            String name = (String) agRes.get(effectiveName);
            if (!String.isBlank(name) && name.contains(',')) {
                name = name.replaceAll(', ', ';');
                nameValues = name.split(',');
            } else {
                nameValues = new List<String> { name };
            }

            for (String val : nameValues) {
                val = val != null ? val.replaceAll(';', ', ') : val;
                Integer oldValue = mappingHelper.containsKey(val) ? mappingHelper.get(val) : 0;
                Integer countVal = ((Decimal) (agRes.get('expr0'))).intValue();
                mappingHelper.put(val, oldValue + countVal);
            }
        }

        for (String key : mappingHelper.keySet()) {
             result.add(new FacetValue(key, mappingHelper.get(key)));
        }

        return result;
    }

    private static Facet createFacet(String name, String dataType, String fieldName, FacetController facetCtrl) {
        return createFacet(name, dataType, fieldName, fieldName, facetCtrl);
    }

    private static Facet createFacet(String name, String dataType, String fieldName, String queryFieldName, FacetController facetCtrl) {
        Facet facet = new Facet(name, dataType, fieldName, queryFieldName);
        facetCtrl.dataTypeMapping.put(fieldName, dataType);
        facetCtrl.displayNameMapping.put(fieldName, name);
        return facet;
    }

    /**
     * Factory methods.
     */
    private FacetController() {
        this.facets = new List<FacetGroup>(); // we generate filters for page, we hardcoded them to spped it up, we don't want fetch everything from database we have a lot things to calculate
        this.dataTypeMapping = new Map<String, String>();
        this.currentFilters = new Map<String, List<String>>();
        this.predefindedNotEqualFilters = new  Map<String, String>();
        this.displayNameMapping = new Map<String, String>();
    }

    public static FacetController buildFacetController(String jsonFilters) {
        FacetController fController = new FacetController();
        if (String.isNotBlank(jsonFilters)) {
            fController.setCurrentFilteringJSON(jsonFilters);
        }

        // Activity
        FacetGroup facetGroup = new FacetGroup('Activity');
        facetGroup.addFacet(createFacet('Test Project', 'Text', 'is_test__c', fController));
        facetGroup.addFacet(createFacet('Active', 'Checkbox', 'cpIsActive__c', fController));
        facetGroup.addFacet(createFacet('Scale', 'Text', 'Internal_Properties__r.project_state__c', fController));
        fController.getFacets().add(facetGroup);
        // Location
        facetGroup = new FacetGroup('Location');
        facetGroup.addFacet(createFacet('Country', 'Multiselect', 'Countries_Picklist__c', 'Countries_Wrapper__c', fController));
        facetGroup.addFacet(createFacet('Region', 'Text', 'Deployment_region__c', fController));
        facetGroup.addFacet(createFacet('City', 'Text', 'Deployment_city__c', fController));
        facetGroup.addFacet(createFacet('Workshop Region', 'Text', 'Internal_Properties__r.workshop_region__c', fController));
        fController.getFacets().add(facetGroup);
        // Type
        facetGroup = new FacetGroup('Type');
        facetGroup.addFacet(createFacet('Sector', 'Text', 'Internal_Properties__r.area__c', fController));
        facetGroup.addFacet(createFacet('Sub-Sector', 'Text', 'Internal_Properties__r.sub_area__c', fController));
        facetGroup.addFacet(createFacet('Phone Model', 'Text', 'Internal_Properties__r.phone_model__c', fController));
        facetGroup.addFacet(createFacet('Project Manager', 'Text', 'Internal_Properties__r.project_manager__c', fController));
        fController.getFacets().add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Self Starters');
        facetGroup.addFacet(createFacet('Self Started', 'Checkbox', 'Internal_Properties__r.self_started__c', fController));
        facetGroup.addFacet(createFacet('Has App', 'Checkbox', 'cpHasApp__c', fController));
        fController.getFacets().add(facetGroup);
        // Advanced Features
        facetGroup = new FacetGroup('Advanced Features');
        facetGroup.addFacet(createFacet('Case Sharing', 'Checkbox', 'case_sharing__c', fController));
        facetGroup.addFacet(createFacet('ADM', 'Checkbox', 'Internal_Properties__r.using_adm__c', fController));
        facetGroup.addFacet(createFacet('Call Center', 'Checkbox', 'Internal_Properties__r.using_call_center__c', fController));
        facetGroup.addFacet(createFacet('CommCare Supply', 'Checkbox', 'Internal_Properties__r.commtrack_domain__c', fController));
        facetGroup.addFacet(createFacet('Survey Management', 'Checkbox', 'survey_management_enabled__c', fController));
        facetGroup.addFacet(createFacet('Used Messaging Ever', 'Checkbox', 'Domain_cp_sms_ever__c', fController));
        facetGroup.addFacet(createFacet('Used Messaging Last 30 days', 'Checkbox', 'Domain_cp_sms_30_d__c', fController));
        facetGroup.addFacet(createFacet('User \'scale\' backend', 'Checkbox', 'use_sql_backend__c', fController));
        fController.getFacets().add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Plans');
        facetGroup.addFacet(createFacet('Project Type', 'Text', 'project_type__c', fController));
        facetGroup.addFacet(createFacet('Customer Type', 'Text', 'customer_type__c', fController));
        facetGroup.addFacet(createFacet('Initiative', 'Text', 'Internal_Properties__r.initiative__c', fController));
        facetGroup.addFacet(createFacet('SMS Billable', 'Checkbox', 'is_sms_billable__c', fController));
        fController.getFacets().add(facetGroup);
        // Self Starters
        facetGroup = new FacetGroup('Eula');
        facetGroup.addFacet(createFacet('Public Data', 'Checkbox', 'Internal_Properties__r.can_use_data__c', fController));
        facetGroup.addFacet(createFacet('Custom Eula', 'Checkbox', 'Internal_Properties__r.custom_eula__c', fController));
        fController.getFacets().add(facetGroup);

        return fController;
    }

    public static FacetController buildMapFacetController(String jsonFilters) {
        FacetController fController = new FacetController();
        if (String.isNotBlank(jsonFilters)) {
            fController.setCurrentFilteringJSON(jsonFilters);
        }
        fController.predefindedNotEqualFilters.put('Countries_Picklist__c', null);

        // Location
        FacetGroup facetGroup = new FacetGroup('Location');
        facetGroup.addFacet(createFacet('Country', 'Multiselect', 'Countries_Picklist__c', 'Countries_Wrapper__c', fController));
        fController.getFacets().add(facetGroup);

        // Type
        facetGroup = new FacetGroup('Type');
        facetGroup.addFacet(createFacet('Sector', 'Text', 'Internal_Properties__r.area__c', fController));
        facetGroup.addFacet(createFacet('Sub-Sector', 'Text', 'Internal_Properties__r.sub_area__c', fController));
        fController.getFacets().add(facetGroup);

        fController.dataTypeMapping.put('is_test__c', 'Text');
        fController.dataTypeMapping.put('cpIsActive__c', 'Checkbox');

        return fController;
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
        private final String facetQueryField;

        public Facet(String name, String dataType, String fieldName) {
            this(name, dataType, fieldName, fieldName);
        }

        public Facet(String name, String dataType, String fieldName, String facetQueryField) {
            this.name = name;
            this.dataType = dataType;
            this.fieldName = fieldName;
            this.facetQueryField = facetQueryField;
        }

        public String getFacetQueryField() {
            return this.facetQueryField;
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