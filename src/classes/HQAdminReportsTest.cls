@isTest
public class HQAdminReportsTest {

    @testSetup
    public static void addDomainsTestData() {
        List<Domain__c> newDomains = new List<Domain__c>();
        List<Internal_Properties__c> intProps = new List<Internal_Properties__c>();

        for (Integer index = 1; index <= 10; index++) {
            intProps.add(new Internal_Properties__c(
                            notes__c = 'notes_' + index,
                            can_use_data__c = Math.mod(index, 2) == 0,
                            custom_eula__c = Math.mod(index, 2) == 0,
                            commtrack_domain__c = Math.mod(index, 2) == 0,
                            using_call_center__c = Math.mod(index, 2) == 0,
                            using_adm__c = Math.mod(index, 2) == 0,
                            self_started__c = Math.mod(index, 2) == 0,
                            project_state__c = 'project_state_' + index,
                            workshop_region__c = 'workshop_region_' + index,
                            area__c = 'sector_' + index,
                            sub_area__c = 'sub_sector_' + index,
                            phone_model__c = 'phone_model_' + index,
                            project_manager__c = 'project_manager_' + index
                        ));
        }
        insert intProps;

        for (Integer index = 1; index <= 10; index++) {
            newDomains.add(new Domain__c(
                                Internal_Properties__c = intProps.get(index - 1).Id,
                                Name = 'test_domain_' + index,
                                date_created__c = DateTime.now(),
                                Deployment_Countries__c = 'country_names_' + index,
                                Deployment_region__c = 'region_names_' + index,
                                Deployment_city__c = 'city_names_' + index,
                                project_type__c = 'proj_names_' + index,
                                customer_type__c = 'cust_names_' + index,
                                cpHasApp__c = Math.mod(index, 2) == 0,
                                case_sharing__c = Math.mod(index, 2) == 0,
                                survey_management_enabled__c = Math.mod(index, 2) == 0,
                                Domain_cp_sms_ever__c = Math.mod(index, 2) == 0,
                                Domain_cp_sms_30_d__c = Math.mod(index, 2) == 0,
                                use_sql_backend__c = Math.mod(index, 2) == 0,
                                is_sms_billable__c = Math.mod(index, 2) == 0,
                                is_test__c = '' + (Math.mod(index, 2) == 0),
                                hipaa_compliant__c = Math.mod(index, 2) == 0,
                                Has_J2ME_submission_in_past_90_days__c = Math.mod(index, 2) == 0,
                                cpActiveMobileUsers__c = index,
                                cpAllMobileUsers__c = index,
                                Cp_n_users_submitted_form__c = index,
                                cpCasesIn60Days__c = index,
                                cpAllActiveCases__c = index,
                                cpAllInactiveCases__c = index,
                                cpAllCases__c = index,
                                cpAllForms__c = index,
                                cpFormsIn30Days__c = index,
                                cpFirstFormSubmissionDate__c =  DateTime.now(),
                                cp300thFormSubmission__c = DateTime.now(),
                                cpLastFormSubmissionDate__c = DateTime.now(),
                                cpAllWebUsers__c = index,
                                cpIsActive__c = Math.mod(index, 2) == 0,
                                cpAllOutgoingSms__c = index,
                                cpAllIncomingSms__c = index,
                                cpAllSms__c = index,
                                cpIncomingSmsIn30Days__c = index,
                                cpOutgoingSmsIn30Days__c = index,
                                Cp_last_update__c = DateTime.now()
                            ));
        }
        insert newDomains;
    }

    @isTest
    public static void shouldLoadFacetList() {
        FacetController fCtrl = new FacetController();

        System.assertNotEquals(null, fCtrl.dataTypeMapping);
        System.assertEquals(2, fCtrl.getFacets().get(0).facets.get(0).values.size());
        System.assertEquals(2, fCtrl.getFacets().get(0).facets.get(1).values.size());
        System.assertEquals(10, fCtrl.getFacets().get(0).facets.get(2).values.size());

        System.assertEquals(10, fCtrl.getFacets().get(2).facets.get(0).values.size());
        System.assertEquals(10, fCtrl.getFacets().get(2).facets.get(1).values.size());
        System.assertEquals(10, fCtrl.getFacets().get(2).facets.get(2).values.size());

        System.assertEquals(2, fCtrl.getFacets().get(6).facets.get(0).values.size());
        System.assertEquals(2, fCtrl.getFacets().get(6).facets.get(1).values.size());

        System.assert(String.isNotBlank(fCtrl.getFacetJSON()));
        fCtrl.setFacetJSON(null);
        System.assert(String.isNotBlank(fCtrl.getFacetJSON()));

        fCtrl.updateFacets();
        System.assert(String.isNotBlank(fCtrl.getFacetJSON()));

        QueryBuilder qb = fCtrl.getQueryBuilder();
        System.assertNotEquals(null, qb);
    }

    @isTest
    public static void shouldSaveNewFilters() {
        FacetController fCtrl = new FacetController();

        System.assertNotEquals(null, fCtrl.dataTypeMapping);
        System.assert(String.isNotBlank(fCtrl.getCurrentFilteringJSON()));

        fCtrl.setCurrentFilteringJSON('{"cpIsActive__c":["false"]}');
        System.assert(String.isNotBlank(fCtrl.getCurrentFilteringJSON()));
        QueryBuilder qb = fCtrl.getQueryBuilder();
        qb.addColumn('just_test');
        System.assertEquals('SELECT just_test FROM Domain__c WHERE cpIsActive__c = false', qb.buildQuery());

        fCtrl.domainNameSearch = 'name for test';
        fCtrl.setCurrentFilteringJSON('{"cpIsActive__c":["false"],"Deployment_region__c":["Region_2","Region_1"]}');
        System.assert(String.isNotBlank(fCtrl.getCurrentFilteringJSON()));
        qb = fCtrl.getQueryBuilder();
        qb.addColumn('just_test');
        System.assertEquals('SELECT just_test FROM Domain__c WHERE Name LIKE \'%name for test%\' AND cpIsActive__c = false AND Deployment_region__c IN (\'Region_2\',\'Region_1\')',
                                qb.buildQuery());
    }

    @isTest
    public static void shouldFilterFacets() {
        FacetController fCtrl = new FacetController();
        fCtrl.setCurrentFilteringJSON('{"cpIsActive__c":["false"]}');
        System.assert(String.isNotBlank(fCtrl.getCurrentFilteringJSON()));
        fCtrl.updateFacets();
        List<FacetController.FacetGroup> facets = fCtrl.getFacets();
        System.assertEquals(1, fCtrl.getFacets().get(0).facets.get(0).values.size());
        System.assertEquals(1, fCtrl.getFacets().get(0).facets.get(1).values.size());
        System.assertEquals(5, fCtrl.getFacets().get(0).facets.get(2).values.size());
    }

    @isTest
    public static void shouldFetchDomains() {
        HQAdminReportsController reportCtrl = new HQAdminReportsController();
        List<Domain__c> ctrlResult = reportCtrl.getDomainTableData();
        System.assertEquals(10, ctrlResult.size());
        validateTotalRow(reportCtrl, 55);
    }

    @isTest
    public static void shouldFilterDomains() {
        HQAdminReportsController reportCtrl = new HQAdminReportsController();
        List<Domain__c> ctrlResult = reportCtrl.getDomainTableData();
        System.assertEquals(10, ctrlResult.size());

        reportCtrl.facetController.setCurrentFilteringJSON('{"cpIsActive__c":["false"]}');
        reportCtrl.updateFacets();
        reportCtrl.reloadGraphData();
        ctrlResult = reportCtrl.getDomainTableData();
        System.assertEquals(5, ctrlResult.size());
        validateTotalRow(reportCtrl, 25);
    }

    private static void validateTotalRow(HQAdminReportsController reportCtrl, Integer expValue) {
        System.assertEquals(expValue, reportCtrl.totalRow.cpActiveMobileUsers__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllMobileUsers__c);
        System.assertEquals(expValue, reportCtrl.totalRow.Cp_n_users_submitted_form__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpCasesIn60Days__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllActiveCases__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllInactiveCases__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllCases__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllForms__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpFormsIn30Days__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllWebUsers__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllOutgoingSms__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllIncomingSms__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpAllSms__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpIncomingSmsIn30Days__c);
        System.assertEquals(expValue, reportCtrl.totalRow.cpOutgoingSmsIn30Days__c);
    }
}