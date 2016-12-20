@isTest
public class HqIntegrationTests {

    @testSetup
    static void setupCustomSetting() {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        insert settings;

        CommcareToSalesforceSettings__c testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.CommCare_User_Name__c = 'CommCareUserName@gmail.com';
        testCustomSetting.CommCare_Password__c = 'CommCarePassword';
        testCustomSetting.Server_URL__c = 'https://www.commcarehq.org/hq/admin/api/global/';
        testCustomSetting.Skip_in_batch_job__c = false;
        testCustomSetting.API_Limit_Parameter__c = 10;
        testCustomSetting.Name = 'CommCare HQ';
        insert testCustomSetting;
    }

    @isTest
    static void hqIntDomainTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock('{"meta":{"limit":2,"next":"/hq/admin/api/global/project_space_metadata/?limit=2&offset=7058","offset":3,"previous":"/hq/admin/api/global/project_space_metadata/?limit=2&offset=7054","total_count":12},"objects":[{"billing_properties":{"date_end":null,"date_start":"2016-01-01","plan_version":"CommCare Advanced Edition (v2)"},"calculated_properties":{"cp_first_form":"2013-02-25T21:31:21.000000Z", "cp_300th_form": "2015-03-27T22:50:29Z","cp_has_app":true,"cp_is_active":true,"cp_j2me_90_d_bool":1,"cp_last_form":"2016-03-24T18:18:57.726780Z","cp_last_updated":"2016-03-24T22:58:24.567926Z","cp_n_30_day_cases":469,"cp_n_60_day_cases":580,"cp_n_90_day_cases":650,"cp_n_active_cases":722,"cp_n_active_cc_users":92,"cp_n_cases":15682,"cp_n_cc_users":1227,"cp_n_forms":28339,"cp_n_forms_30_d":2745,"cp_n_forms_60_d":2871,"cp_n_forms_90_d":2956,"cp_n_in_sms":0,"cp_n_inactive_cases":7794,"cp_n_j2me_30_d":2745,"cp_n_j2me_60_d":2871,"cp_n_j2me_90_d":2956,"cp_n_out_sms":0,"cp_n_sms_30_d":6,"cp_n_sms_60_d":6,"cp_n_sms_90_d":6,"cp_n_sms_ever":499,"cp_n_sms_in_30_d":0,"cp_n_sms_in_60_d":0,"cp_n_sms_in_90_d":0,"cp_n_sms_out_30_d":0,"cp_n_sms_out_60_d":0,"cp_n_sms_out_90_d":0,"cp_n_users_submitted_form":486,"cp_n_web_users":8,"cp_sms_30_d":1,"cp_sms_ever":1},"domain_properties":{"_id":"sample_external_id","_rev":"123","allow_domain_requests":false,"area":null,"attribution_notes":null,"author":null,"billable_client":null,"billing_address":{"address":[],"city":"LA","country":"USA","doc_type":"HQBillingAddress","name":"test","postal_code":"123","state_province":"TEST"},"billing_number":null,"cached_properties":{"languages":["en","luo"]},"call_center_config":{"case_owner_id":null,"case_type":null,"doc_type":"CallCenterProperties","enabled":false,"use_fixtures":true,"use_user_location_as_owner":false,"user_location_ancestor_level":0},"case_display":{"case_details":{},"doc_type":"CaseDisplaySettings","form_details":{}},"case_sharing":false,"cda":{"date":null,"doc_type":"LicenseAgreement","signed":false,"type":null,"user_id":null,"user_ip":null,"version":null},"chat_message_count_threshold":null,"city":"","cloudcare_releases":"nostars","commconnect_enabled":false,"commtrack_enabled":false,"copy_history":[],"count_messages_as_read_by_anyone":false,"country":"Uganda","cp_first_form":"2013-02-25T21:31:21.000000Z","cp_has_app":true,"cp_is_active":true,"cp_j2me_90_d_bool":1,"cp_last_form":"2016-03-24T18:18:57.726780Z","cp_last_updated":"2016-03-24T22:58:24.567926Z","cp_n_30_day_cases":469,"cp_n_60_day_cases":580,"cp_n_90_day_cases":650,"cp_n_active_cases":722,"cp_n_active_cc_users":92,"cp_n_cases":15682,"cp_n_cc_users":1227,"cp_n_forms":28339,"cp_n_forms_30_d":2745,"cp_n_forms_60_d":2871,"cp_n_forms_90_d":2956,"cp_n_in_sms":0,"cp_n_inactive_cases":7794,"cp_n_j2me_30_d":2745,"cp_n_j2me_60_d":2871,"cp_n_j2me_90_d":2956,"cp_n_out_sms":0,"cp_n_sms_30_d":6,"cp_n_sms_60_d":6,"cp_n_sms_90_d":6,"cp_n_sms_ever":499,"cp_n_sms_in_30_d":0,"cp_n_sms_in_60_d":0,"cp_n_sms_in_90_d":0,"cp_n_sms_out_30_d":0,"cp_n_sms_out_60_d":0,"cp_n_sms_out_90_d":0,"cp_n_users_submitted_form":486,"cp_n_web_users":8,"cp_sms_30_d":1,"cp_sms_ever":1,"creating_user":null,"currency_code":"USD","custom_case_username":null,"custom_chat_template":null,"customer_type":"plus","date_created":"2013-02-25T12:41:09.000000Z","default_mobile_worker_redirect":null,"default_sms_backend_id":null,"default_sms_response":null,"default_timezone":"Africa/Nairobi","deployment":{"city":"","countries":["UGANDA"],"country":"Uganda","date":"2014-06-04T00:00:00.000000Z","description":"Test desc","doc_type":"Deployment","public":false,"region":"Africa"},"description":null,"doc_type":"Domain","downloads":0,"dynamic_reports":[],"enable_registration_welcome_sms_for_case":false,"enable_registration_welcome_sms_for_mobile_worker":false,"eula":{"date":null,"doc_type":"LicenseAgreement","signed":false,"type":null,"user_id":null,"user_ip":null},"filter_surveys_from_chat":false,"full_downloads":0,"has_careplan":false,"hipaa_compliant":false,"hr_name":null,"image_path":null,"image_type":null,"internal":{"area":"Health","business_unit":"DSA","can_use_data":true,"commcare_edition":"enterprise","commconnect_domain":null,"commtrack_domain":false,"custom_eula":false,"doc_type":"InternalProperties","goal_followup_rate":null,"goal_time_period":null,"initiative":[],"notes":"Test notes ","organization_name":"World Vision","phone_model":"Nokia Test","platform":["java"],"project_manager":"sshah@dimagi.com","project_state":"transition","real_space":null,"self_started":false,"services":"plus","sf_account_id":"001b000000ItF8U","sf_contract_id":"001b000000ItF8U","sub_area":"Child Health","using_adm":false,"using_call_center":false,"workshop_region":null},"is_active":true,"is_approved":false,"is_public":false,"is_shared":false,"is_sms_billable":null,"is_snapshot":false,"is_test":"false","last_modified":"2016-03-23T20:12:45.441697Z","license":"cc","location_restriction_for_users":false,"locations_enabled":false,"migrations":{"doc_type":"DomainMigrations","has_migrated_permissions":true},"multimedia_included":true,"name":"test-1","obsolete_location_types":[],"organization":null,"ota_restore_caching":false,"phone_model":null,"project_type":"MCH","published":false,"publisher":"user","region":"","restrict_superusers":false,"restricted_sms_times":[],"secure_sessions":false,"secure_submissions":false,"send_to_duplicated_case_numbers":false,"short_description":null,"show_invalid_survey_responses_in_chat":false,"slug":null,"sms_case_registration_enabled":false,"sms_case_registration_owner_id":null,"sms_case_registration_type":null,"sms_case_registration_user_id":null,"sms_conversation_length":10,"sms_conversation_times":[],"sms_mobile_worker_registration_enabled":false,"snapshot_time":null,"sub_area":null,"subscription":"Advanced","survey_management_enabled":false,"tags":[],"title":null,"two_factor_auth":false,"use_default_sms_response":false,"usercase_enabled":false,"yt_id":null},"resource_uri":"/hq/admin/api/global/project_space_metadata/asdf233w/"},{"billing_properties":{"date_end":null,"date_start":"2016-01-01","plan_version":"CommCare Pro Edition (v2)"},"calculated_properties":{"cp_first_form":"2013-03-27T17:01:01.000000Z","cp_has_app":null,"cp_is_active":false,"cp_j2me_90_d_bool":0,"cp_last_form":"2014-10-22T14:28:14.000000Z","cp_last_updated":"2016-03-25T00:43:36.613916Z","cp_n_30_day_cases":0,"cp_n_60_day_cases":0,"cp_n_90_day_cases":0,"cp_n_active_cases":0,"cp_n_active_cc_users":0,"cp_n_cases":1457,"cp_n_cc_users":103,"cp_n_forms":1800,"cp_n_forms_30_d":0,"cp_n_forms_60_d":0,"cp_n_forms_90_d":0,"cp_n_in_sms":0,"cp_n_inactive_cases":1163,"cp_n_j2me_30_d":0,"cp_n_j2me_60_d":0,"cp_n_j2me_90_d":0,"cp_n_out_sms":0,"cp_n_sms_30_d":0,"cp_n_sms_60_d":0,"cp_n_sms_90_d":0,"cp_n_sms_ever":3,"cp_n_sms_in_30_d":0,"cp_n_sms_in_60_d":0,"cp_n_sms_in_90_d":0,"cp_n_sms_out_30_d":0,"cp_n_sms_out_60_d":0,"cp_n_sms_out_90_d":0,"cp_n_users_submitted_form":17,"cp_n_web_users":7,"cp_sms_30_d":0,"cp_sms_ever":1},"domain_properties":{"_id":"test-external-2","_rev":"30-89csss6f0","allow_domain_requests":false,"area":null,"attribution_notes":null,"author":null,"billable_client":null,"billing_address":{"address":[],"city":"London","country":"England","doc_type":"HQBillingAddress","name":"test-name-2","postal_code":"234","state_province":"CA"},"billing_number":null,"cached_properties":{"languages":["en","tog","tha"]},"call_center_config":{"case_owner_id":null,"case_type":null,"doc_type":"CallCenterProperties","enabled":false,"use_fixtures":true,"use_user_location_as_owner":false,"user_location_ancestor_level":0},"case_display":{"case_details":{},"doc_type":"CaseDisplaySettings","form_details":{}},"case_sharing":false,"cda":{"date":null,"doc_type":"LicenseAgreement","signed":false,"type":null,"user_id":null,"user_ip":null,"version":null},"chat_message_count_threshold":null,"city":"","cloudcare_releases":"nostars","commconnect_enabled":false,"commtrack_enabled":false,"copy_history":[],"count_messages_as_read_by_anyone":false,"country":"Zambia","cp_first_form":"2013-03-27T17:01:01.000000Z","cp_has_app":true,"cp_is_active":false,"cp_j2me_90_d_bool":0,"cp_last_form":"2014-10-22T14:28:14.000000Z","cp_last_updated":"2016-03-25T00:43:36.613916Z","cp_n_30_day_cases":0,"cp_n_60_day_cases":0,"cp_n_90_day_cases":0,"cp_n_active_cases":0,"cp_n_active_cc_users":0,"cp_n_cases":1457,"cp_n_cc_users":103,"cp_n_forms":1800,"cp_n_forms_30_d":0,"cp_n_forms_60_d":0,"cp_n_forms_90_d":0,"cp_n_in_sms":0,"cp_n_inactive_cases":1163,"cp_n_j2me_30_d":0,"cp_n_j2me_60_d":0,"cp_n_j2me_90_d":0,"cp_n_out_sms":0,"cp_n_sms_30_d":0,"cp_n_sms_60_d":0,"cp_n_sms_90_d":0,"cp_n_sms_ever":3,"cp_n_sms_in_30_d":0,"cp_n_sms_in_60_d":0,"cp_n_sms_in_90_d":0,"cp_n_sms_out_30_d":0,"cp_n_sms_out_60_d":0,"cp_n_sms_out_90_d":0,"cp_n_users_submitted_form":17,"cp_n_web_users":7,"cp_sms_30_d":0,"cp_sms_ever":1,"creating_user":"test@dimagi.com","currency_code":"USD","custom_case_username":null,"custom_chat_template":null,"customer_type":"plus","date_created":"2013-03-26T10:28:09.000000Z","default_mobile_worker_redirect":null,"default_sms_backend_id":"","default_sms_response":null,"default_timezone":"UTC","deployment":{"city":"sinazongwe","countries":["ZAMBIA"],"country":"Zambia","date":"2013-06-19T00:00:00.000000Z","description":"New notest for domain","doc_type":"Deployment","public":false,"region":"Africa"},"description":null,"doc_type":"Domain","downloads":0,"dynamic_reports":[],"enable_registration_welcome_sms_for_case":false,"enable_registration_welcome_sms_for_mobile_worker":false,"eula":{"date":null,"doc_type":"LicenseAgreement","signed":false,"type":null,"user_id":null,"user_ip":null},"filter_surveys_from_chat":false,"full_downloads":0,"has_careplan":false,"hipaa_compliant":false,"hr_name":null,"image_path":null,"image_type":null,"internal":{"area":"","business_unit":"DSA","can_use_data":true,"commcare_edition":"","commconnect_domain":null,"commtrack_domain":false,"custom_eula":null,"doc_type":"InternalProperties","goal_followup_rate":null,"goal_time_period":null,"initiative":[],"notes":"","organization_name":"","phone_model":"","platform":[],"project_manager":null,"project_state":"","real_space":null,"self_started":false,"services":"","sf_account_id":"","sf_contract_id":"","sub_area":null,"using_adm":null,"using_call_center":null,"workshop_region":null},"is_active":true,"is_approved":false,"is_public":false,"is_shared":false,"is_sms_billable":null,"is_snapshot":false,"is_test":"false","last_modified":"2016-03-23T20:13:14.903640Z","license":"cc","location_restriction_for_users":false,"locations_enabled":false,"migrations":{"doc_type":"DomainMigrations","has_migrated_permissions":true},"multimedia_included":true,"name":"test-2","obsolete_location_types":[],"organization":null,"ota_restore_caching":false,"phone_model":null,"project_type":"MCH","published":false,"publisher":"user","region":"","restrict_superusers":false,"restricted_sms_times":[],"secure_sessions":false,"secure_submissions":false,"send_to_duplicated_case_numbers":false,"short_description":null,"show_invalid_survey_responses_in_chat":false,"sms_case_registration_enabled":false,"sms_case_registration_owner_id":"0206df14238b0e56a11ee1237fe16476","sms_case_registration_type":"","sms_case_registration_user_id":"c6cad554c776b45f3d375c874ec92d23","sms_conversation_length":10,"sms_conversation_times":[],"sms_mobile_worker_registration_enabled":false,"snapshot_time":null,"sub_area":null,"subscription":"Pro","survey_management_enabled":false,"tags":[],"title":null,"two_factor_auth":false,"use_default_sms_response":false,"usercase_enabled":false,"yt_id":null},"resource_uri":"/hq/admin/api/global/project_space_metadata/205ds2da/"}]}'));
        HqBatchJobHelper.startDomainJob();
        Test.stopTest();

        List<Domain__c> domains = [SELECT id__c FROM Domain__c];
        System.assertEquals(2, domains.size());

        Domain__c testDomain = [SELECT id__c, cp300thFormSubmission__c, InternalProp_Business_Unit__c, Deployment_country__c, Deployment_city__c, Deployment_region__c, billing_address_country__c, billing_address_city__c,
                                    Server_Name__c FROM Domain__c WHERE id__c ='sample_external_id'];
        System.assertEquals('DSA', testDomain.InternalProp_Business_Unit__c);
        System.assertEquals('Uganda', testDomain.Deployment_country__c);
        System.assertEquals(null, testDomain.Deployment_city__c);
        System.assertEquals('Africa', testDomain.Deployment_region__c);
        System.assertEquals('USA', testDomain.billing_address_country__c);
        System.assertEquals('LA', testDomain.billing_address_city__c);
        System.assertEquals(2015, testDomain.cp300thFormSubmission__c.year());
        System.assertEquals(3, testDomain.cp300thFormSubmission__c.month());
        System.assertEquals(27, testDomain.cp300thFormSubmission__c.day());
        System.assertEquals('CommCare HQ', testDomain.Server_Name__c);

        testDomain = [SELECT id__c, InternalProp_Business_Unit__c, Deployment_country__c, Deployment_city__c, Deployment_region__c, billing_address_country__c, billing_address_city__c, Server_Name__c
                                    FROM Domain__c WHERE id__c ='test-external-2'];
        System.assertEquals('DSA', testDomain.InternalProp_Business_Unit__c);
        System.assertEquals('Zambia', testDomain.Deployment_country__c);
        System.assertEquals('sinazongwe', testDomain.Deployment_city__c);
        System.assertEquals('Africa', testDomain.Deployment_region__c);
        System.assertEquals('England', testDomain.billing_address_country__c);
        System.assertEquals('London', testDomain.billing_address_city__c);
        System.assertEquals('CommCare HQ', testDomain.Server_Name__c);

        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        System.assertEquals(false, settings.Is_Domain_Job_Running__c);
    }

    @isTest
    static void hqIntTestCalculationProperties() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        HqBatchJobHelper.startDomainJob();
        Test.stopTest();

        Domain__c testDomain = [SELECT id__c, Server_Name__c, cpAllActiveCases__c, cpAllCases__c, cpAllForms__c, cpActiveMobileUsers__c, cpAllInactiveCases__c, cpAllIncomingSms__c, cpAllMobileUsers__c, cpAllOutgoingSms__c, cpAllSms__c,
                                    cpAllSmsIn30Days__c, cpAllSmsIn60Days__c, cpAllSmsIn90Days__c, cpAllWebUsers__c, cpCasesIn30Days__c, cpCasesIn90Days__c, cpCasesIn60Days__c, cpFirstFormSubmissionDate__c,
                                    cpFormsIn30Days__c, cpFormsIn60Days__c, cpFormsIn90Days__c, cpHasApp__c, cpIncomingSmsIn30Days__c, cpIncomingSmsIn60Days__c, cpIncomingSmsIn90Days__c, cpIsActive__c,
                                    cpLastFormSubmissionDate__c, cpOutgoingSmsIn30Days__c, cpOutgoingSmsIn60Days__c, cpOutgoingSmsIn90Days__c
                                    FROM Domain__c WHERE id__c ='542f59e04ca149f9a5ae0837529fb06d'];
        System.assertEquals('542f59e04ca149f9a5ae0837529fb06d', testDomain.id__c);
        System.assertEquals(testDomain.cpAllActiveCases__c, 2);
        System.assertEquals(testDomain.cpAllCases__c, 4);
        System.assertEquals(testDomain.cpAllForms__c, 6);
        System.assertEquals(testDomain.cpAllInactiveCases__c, 8);
        System.assertEquals(testDomain.cpAllIncomingSms__c, 7);
        System.assertEquals(testDomain.cpActiveMobileUsers__c, 3);
        System.assertEquals(testDomain.cpAllMobileUsers__c, 5);
        System.assertEquals(testDomain.cpAllOutgoingSms__c, 9);
        System.assertEquals(testDomain.cpAllSms__c, 11);
        System.assertEquals(testDomain.cpAllSmsIn30Days__c, 10);
        System.assertEquals(testDomain.cpAllSmsIn60Days__c, 16);
        System.assertEquals(testDomain.cpAllSmsIn90Days__c, 17);
        System.assertEquals(testDomain.cpAllWebUsers__c, 13);
        System.assertEquals(testDomain.cpCasesIn30Days__c, 24);
        System.assertEquals(testDomain.cpCasesIn90Days__c, 25);
        System.assertEquals(testDomain.cpCasesIn60Days__c, 1);
        System.assertEquals(testDomain.cpFirstFormSubmissionDate__c.day(), 20);
        System.assertEquals(testDomain.cpFirstFormSubmissionDate__c.month(), 3);
        System.assertEquals(testDomain.cpFormsIn30Days__c, 26);
        System.assertEquals(testDomain.cpFormsIn60Days__c, 27);
        System.assertEquals(testDomain.cpFormsIn90Days__c, 28);
        System.assertEquals(testDomain.cpHasApp__c, true);
        System.assertEquals(testDomain.cpIncomingSmsIn30Days__c, 18);
        System.assertEquals(testDomain.cpIncomingSmsIn60Days__c, 19);
        System.assertEquals(testDomain.cpIncomingSmsIn90Days__c, 20);
        System.assertEquals(testDomain.cpIsActive__c, false);
        System.assertEquals(testDomain.cpLastFormSubmissionDate__c.day(), 22);
        System.assertEquals(testDomain.cpLastFormSubmissionDate__c.month(), 3);
        System.assertEquals(testDomain.cpOutgoingSmsIn30Days__c, 21);
        System.assertEquals(testDomain.cpOutgoingSmsIn60Days__c, 22);
        System.assertEquals(testDomain.cpOutgoingSmsIn90Days__c, 23);
        System.assertEquals('CommCare HQ', testDomain.Server_Name__c);
    }

    static private Decimal calculateMRRForDomain(Id domainId, Integer expectedSize) {
        Decimal sumForDomain = 0;
        List<Accounting_Subscription__c> subsForDomain1 = [SELECT Lifetime_MRR__c, accounting_software_monthly_fee__c FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c =: domainId];
        System.assertEquals(expectedSize, subsForDomain1.size());

        for (Accounting_Subscription__c s : subsForDomain1) {
            System.debug('For domain : ' + domainId + ' ' + s.Lifetime_MRR__c + ' calculated by : ' + s.accounting_software_monthly_fee__c);
            sumForDomain += s.Lifetime_MRR__c;
        }

        return sumForDomain;
    }

    static private void createSoftwarePlan(String planId) {
        hqInt_ModelClass.Accounting_SoftwarePlan plan = new hqInt_ModelClass.Accounting_SoftwarePlan();
        plan.id = planId;
        plan.name = 'sampleName' + planId;
        insert plan.createDbObject();
    }

    static private void createProductRate(String rateId) {
        hqInt_ModelClass.Accounting_SoftwareProductRate rate = new hqInt_ModelClass.Accounting_SoftwareProductRate();
        rate.id = rateId;
        rate.is_active = true;
        insert rate.createDbObject();
    }

    static private Accounting_Invoice__c buildInvoice(Integer i, Id subsciptionId, Id domainId) {
        hqInt_ModelClass.Accounting_Invoice a = new hqInt_ModelClass.Accounting_Invoice();
        a.id = 'external_id_' + i;
        a.is_hidden = false;
        a.is_hidden_to_ops = false;
        Accounting_Invoice__c aFromDB  = a.createDbObject(subsciptionId, domainId);
        insert aFromDb;
        return aFromDb;
    }

    static private Accounting_Subscription__c buildSubscription(Integer i, Id subscriberId) {
        hqInt_ModelClass.Accounting_Subscription a = new hqInt_ModelClass.Accounting_Subscription();
        a.id = 'external_id_' + i;
        a.is_active = true;
        a.do_not_invoice = true;
        a.auto_generate_credits = false;
        a.is_trial = true;
        a.is_hidden_to_ops = false;
        Accounting_Subscription__c aFromDB  = a.createDbObject(null, null, subscriberId, null);
        insert aFromDb;
        return aFromDb;
    }

    static private Accounting_Subscriber__c buildSubscriber(Integer i, Id domainId) {
        hqInt_ModelClass.Accounting_Subscriber a = new hqInt_ModelClass.Accounting_Subscriber();
        a.id = 'external_id_' + i;
        a.domain = 'domain_name_' + i;
        Accounting_Subscriber__c aFromDB  = a.createDbObject(domainId);
        insert aFromDb;
        return aFromDb;
    }

    static private Domain__c buildDomain(Integer i) {
        hqInt_Model_DomainClass d = new hqInt_Model_DomainClass();
        d.x_id = 'domain_' + i;
        d.Name = 'domain_name_' + i;
        d.tags = new List<String> { ' ' };
        Domain__c domainFromDb = d.createDbObject(null, 'CommCare HQ');
        insert domainFromDb;
        return domainFromDb;
    }
}