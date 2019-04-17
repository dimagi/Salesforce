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
                                Countries_Wrapper__c = 'country_names_' + index,
                                Countries_Picklist__c = 'country_names_' + index,
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

        Accounting_SoftwareProductRate__c productRate1 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 150, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwareProductRate__c productRate2 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 75, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwareProductRate__c productRate3 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 25, Server_Name__c = 'CommCare HQ');
        insert new List<Accounting_SoftwareProductRate__c> { productRate1, productRate2, productRate3 };

        Accounting_Softwareplan__c softwarePlan1 = new Accounting_Softwareplan__c(Name = 'softwarePlan1', edition__c = 'Community', Server_Name__c = 'CommCare HQ');
        Accounting_Softwareplan__c softwarePlan2 = new Accounting_Softwareplan__c(Name = 'softwarePlan2', edition__c = 'Standard', Server_Name__c = 'CommCare HQ');
        Accounting_Softwareplan__c softwarePlan3 = new Accounting_Softwareplan__c(Name = 'softwarePlan3', edition__c = 'Pro', Server_Name__c = 'CommCare HQ');
        insert new List<Accounting_Softwareplan__c> { softwarePlan1, softwarePlan2, softwarePlan3 };

        Accounting_SoftwarePlanVersion__c planVersion1 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate1.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan1.Id, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwarePlanVersion__c planVersion2 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate2.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan2.Id, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwarePlanVersion__c planVersion3 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate3.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan3.Id, Server_Name__c = 'CommCare HQ');
        insert new List<Accounting_SoftwarePlanVersion__c> { planVersion1, planVersion2, planVersion3 };

        Integer currentYear = Date.today().year();
        Accounting_Subscription__c subscription1 = new Accounting_Subscription__c(Created_By__c = 'Sample 1', date_start__c = Date.newInstance(currentYear, 1, 1), date_end__c = Date.newInstance(currentYear, 3 ,15), is_active__c = true,
                                                          Accounting_subscriber_domain__c = newDomains.get(0).Id, plan_version__c = planVersion1.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service', is_hidden_to_ops__c = false);
        Accounting_Subscription__c subscription2 = new Accounting_Subscription__c(Created_By__c = 'Sample 2', date_start__c = Date.newInstance(currentYear, 1, 15), date_end__c = Date.newInstance(currentYear, 2 ,15), is_active__c = true,
                                                          Accounting_subscriber_domain__c = newDomains.get(1).Id, plan_version__c = planVersion2.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Product', is_hidden_to_ops__c = false);
        Accounting_Subscription__c subscription3 = new Accounting_Subscription__c(Created_By__c = 'Sample 3', date_start__c = Date.newInstance(currentYear, 1, 1), date_end__c = Date.newInstance(currentYear, 1 ,31), is_active__c = true,
                                                          Accounting_subscriber_domain__c = newDomains.get(2).Id, plan_version__c = planVersion3.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service', is_hidden_to_ops__c = false);
        Accounting_Subscription__c subscription4 = new Accounting_Subscription__c(Created_By__c = 'Sample 4', date_start__c = Date.newInstance(currentYear, 2, 1), date_end__c = Date.newInstance(currentYear, 2 ,25), is_active__c = true,
                                                          Accounting_subscriber_domain__c = newDomains.get(3).Id, plan_version__c = planVersion1.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service', is_hidden_to_ops__c = false);
        Accounting_Subscription__c subscription5 = new Accounting_Subscription__c(Created_By__c = 'Sample 5', date_start__c = Date.newInstance(currentYear, 2, 1), date_end__c = Date.newInstance(currentYear, 3 ,31), is_active__c = true,
                                                          Accounting_subscriber_domain__c = newDomains.get(4).Id, plan_version__c = planVersion2.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Product', is_hidden_to_ops__c = false);
        insert new List<Accounting_Subscription__c> { subscription1, subscription2, subscription3, subscription4, subscription5 };
    }

    @isTest
    public static void shouldLoadFacetList() {
        FacetController fCtrl = FacetController.buildFacetController('');
        fCtrl.loadFacetValues();

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

        fCtrl.loadFacetValues();
        System.assert(String.isNotBlank(fCtrl.getFacetJSON()));

        QueryBuilder qb = fCtrl.getQueryBuilder();
        System.assertNotEquals(null, qb);
    }

    @isTest
    public static void shouldSaveNewFilters() {
        FacetController fCtrl = FacetController.buildFacetController('');
        fCtrl.loadFacetValues();

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
        FacetController fCtrl = FacetController.buildFacetController('');
        fCtrl.setCurrentFilteringJSON('{"cpIsActive__c":["false"]}');
        System.assert(String.isNotBlank(fCtrl.getCurrentFilteringJSON()));
        fCtrl.loadFacetValues();
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

        reportCtrl.facetCtrl.setCurrentFilteringJSON('{"cpIsActive__c":["false"]}');
        reportCtrl.updateFacets();
        ctrlResult = reportCtrl.getDomainTableData();
        System.assertEquals(5, ctrlResult.size());
        validateTotalRow(reportCtrl, 25);
    }

    @isTest
    public static void testPredefindedFiltersAllProjectSpaces() {
        PageReference pageRef = Page.HQAdminReports;
        pageRef.getParameters().put('report', 'allprojectSpaces');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        HQAdminReportsController reportCtrl = new HQAdminReportsController();
        System.assertEquals('{"is_test__c":["false"]}', reportCtrl.facetCtrl.getCurrentFilteringJSON());
        Test.stopTest();
    }

    @isTest
    public static void testPredefindedFiltersUsingMessaging() {
        PageReference pageRef = Page.HQAdminReports;
        pageRef.getParameters().put('report', 'usingMessaging');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        HQAdminReportsController reportCtrl = new HQAdminReportsController();
        System.assertEquals('{"Domain_cp_sms_ever__c":["true"],"is_test__c":["false"]}', reportCtrl.facetCtrl.getCurrentFilteringJSON());
        Test.stopTest();
    }

    @isTest
    public static void testPredefindedFiltersCommcareSupply() {
        PageReference pageRef = Page.HQAdminReports;
        pageRef.getParameters().put('report', 'commcareSupply');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        HQAdminReportsController reportCtrl = new HQAdminReportsController();
        System.assertEquals('{"Internal_Properties__r.commtrack_domain__c":["true"],"is_test__c":["false"]}', reportCtrl.facetCtrl.getCurrentFilteringJSON());
        Test.stopTest();
    }

    @isTest
    public static void testTopFiveProjects() {
        Domain__c domain = [SELECT Id, cpIsActive__c FROM Domain__c WHERE name = 'test_domain_5' LIMIT 1];
        domain.cpIsActive__c = true;
        update domain;

        Test.startTest();
        List<HQAdminReportsProjectMapController.HQAdminProjectData> result = HQAdminReportsProjectMapController.loadTopFiveProjects('country_names_5');
        System.assertEquals(1, result.size());
        System.assertEquals(5, result.get(0).users);
        System.assertEquals('test_domain_5', result.get(0).projectName);
        System.assertNotEquals(null, result.get(0).sfId);
        Test.stopTest();
    }

    @isTest
    public static void testFacetActionFunction() {
        List<FacetController.FacetGroup> facetGroups = HQAdminReportsController.loadReportFacets('default', '{"cpIsActive__c":["false"]}', null);
        System.assertEquals(7, facetGroups.size());
        System.assertEquals(1, facetGroups.get(0).facets.get(0).values.size());
        System.assertEquals(1, facetGroups.get(0).facets.get(1).values.size());
        System.assertEquals(5, facetGroups.get(0).facets.get(2).values.size());
    }

    @isTest
    public static void testGraphActionFunction() {
        HQAdminReportsGraphHelper.HQAdminReportGraphDataContainer graphData = HQAdminReportsController.loadGraphData(1, null, null, 'daily', 'Domain_date_created_date_wrapper__c',
                                                                                        '{"cpIsActive__c":["false"]}', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('daily', graphData.currentInterval);
        System.assertEquals(0, graphData.totalToFromDate);
        System.assertEquals(1, graphData.graphData.get(0).values.size());
        System.assertEquals(5, graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(Date.today(), graphData.graphData.get(0).values.get(0).x);

        graphData = HQAdminReportsController.loadGraphData(1, null, null, 'monthly', 'Domain_date_created_date_wrapper__c',
                                                                                        '{"cpIsActive__c":["false"]}', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('monthly', graphData.currentInterval);
        System.assertEquals(0, graphData.totalToFromDate);
        System.assertEquals(1, graphData.graphData.get(0).values.size());
        System.assertEquals(5, graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(Date.newInstance(Date.today().year(), Date.today().month(), 1), graphData.graphData.get(0).values.get(0).x);

        graphData = HQAdminReportsController.loadGraphData(3, null, null, 'yearly', 'Domain_date_created_date_wrapper__c',
                                                                                        '', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('yearly', graphData.currentInterval);
        System.assertEquals(0, graphData.totalToFromDate);
        System.assertEquals(1, graphData.graphData.get(0).values.size());
        System.assertEquals(5, graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(Date.newInstance(Date.today().year(), 1, 1), graphData.graphData.get(0).values.get(0).x);

        graphData = HQAdminReportsController.loadGraphData(3, null, null, 'weekly', 'Domain_date_created_date_wrapper__c',
                                                                                        '', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('weekly', graphData.currentInterval);
        System.assertEquals(0, graphData.totalToFromDate);
        System.assertEquals(1, graphData.graphData.get(0).values.size());
        System.assertEquals(5, graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(Date.today(), graphData.graphData.get(0).values.get(0).x);
    }

    @isTest
    public static void testEndOfTheWeekMethod() {
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 18)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 19)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 20)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 21)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 22)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 23)));
        System.assertEquals(true, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 24)));
        System.assertEquals(false, HQAdminReportsGraphHelper.isEndOfWeek(Date.newInstance(2019, 3, 25)));
    }

    @isTest
    public static void testGraphActionFunctionForSubscriptions() {
        Integer currentYear = Date.today().year();
        HQAdminReportsGraphHelper.HQAdminReportGraphDataContainer graphData = HQAdminReportsController.loadGraphData(6,
                                            '01/01/' + currentYear, '03/31/' + currentYear, 'monthly', '', '', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('monthly', graphData.currentInterval);
        System.assertEquals(3, graphData.graphData.get(0).values.size());
        System.assertEquals(1, graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(1, graphData.graphData.get(1).values.get(0).y);
        System.assertEquals(1, graphData.graphData.get(2).values.get(0).y);
        System.assertEquals(Date.newInstance(currentYear, 1, 1), graphData.graphData.get(0).values.get(0).x);
        System.assertEquals(Date.newInstance(currentYear, 2, 1), graphData.graphData.get(1).values.get(1).x);
        System.assertEquals(Date.newInstance(currentYear, 3, 1), graphData.graphData.get(2).values.get(2).x);

        graphData = HQAdminReportsController.loadGraphData(6,'01/01/' + currentYear, '03/31/' + currentYear, 'yearly', '', '', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('yearly', graphData.currentInterval);
        System.assertEquals(1, graphData.graphData.get(0).values.size());
        Map<String, Integer> expectedResultMap = new Map<String, Integer> { 'Community' => 2, 'Pro' => 1,'Standard' => 2};
        System.assertEquals(expectedResultMap.get(graphData.graphData.get(0).key), graphData.graphData.get(0).values.get(0).y);
        System.assertEquals(expectedResultMap.get(graphData.graphData.get(1).key), graphData.graphData.get(1).values.get(0).y);
        System.assertEquals(expectedResultMap.get(graphData.graphData.get(2).key), graphData.graphData.get(2).values.get(0).y);
        System.assertEquals(Date.newInstance(currentYear, 1, 1), graphData.graphData.get(0).values.get(0).x);
        System.assertEquals(Date.newInstance(currentYear, 1, 1), graphData.graphData.get(1).values.get(0).x);
        System.assertEquals(Date.newInstance(currentYear, 1, 1), graphData.graphData.get(2).values.get(0).x);

        graphData = HQAdminReportsController.loadGraphData(6, '01/01/' + currentYear, '03/31/' + currentYear, 'daily', '', '', null);
        System.assertNotEquals(null, graphData);
        System.assertEquals('daily', graphData.currentInterval);
        System.assertEquals(Date.isLeapYear(currentYear) ? 91 : 90, graphData.graphData.get(0).values.size());
    }

    @isTest
    public static void testMapController() {
        Test.startTest();
        List<Domain__c> toUpdate = new List<Domain__c>();
        for (Domain__c domain : [SELECT Name, cpIsActive__c, is_test__c, Countries_Picklist__c, Countries_Wrapper__c FROM Domain__c]) {
            domain.cpIsActive__c = true;
            domain.is_test__c = 'false';
            toUpdate.add(domain);
        }
        update toUpdate;
        HQAdminReportsProjectMapController mapCtrl = new HQAdminReportsProjectMapController();
        Test.stopTest();

        List<FacetController.FacetGroup> mapFacets = HQAdminReportsProjectMapController.loadReportMapFacets('');
        System.assertEquals(2, mapFacets.size());
        System.assertEquals(1, mapFacets.get(0).facets.size());
        System.assertEquals(2, mapFacets.get(1).facets.size());
        System.assertEquals(10, mapFacets.get(0).facets.get(0).values.size());

        HQAdminReportsProjectMapController.HQAdminMapData mapData =  HQAdminReportsProjectMapController.loadMapData('');
        System.assertEquals(10, mapData.countryMap.size());
        System.assertEquals(10, mapData.userMap.size());

        for (String country : mapData.countryMap.keySet()) {
            System.assertEquals(1, mapData.countryMap.get(country), 'Wrong count for country : ' + country);
        }
        Integer sum = 0;
        for (String country : mapData.userMap.keySet()) {
            sum += mapData.userMap.get(country);
        }
        System.assertEquals(55, sum);
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