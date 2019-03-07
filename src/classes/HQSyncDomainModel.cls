/**
 * Class contains all HQ sync API Domain models.
 */
public class HQSyncDomainModel {

    /**
     * Domain Model wrapper.
     */
    public class DomanProjectSpaceWrapper {
         public DomainModel domain_properties;
         public CalculatedProperties calculated_properties;
    }

    /**
     * Calculated properties stored in domain object.
     */
    public class CalculatedProperties {
        public Boolean cp_is_active;
        public Integer cp_n_active_cases;
        public Integer cp_n_sms_ever;
        public Integer cp_n_cases;
        public Integer cp_n_forms;
        public Integer cp_n_sms_30_d;
        public Integer cp_n_sms_60_d;
        public Integer cp_n_sms_90_d;
        public Integer cp_n_sms_in_30_d;
        public Integer cp_n_sms_in_60_d;
        public Integer cp_n_sms_in_90_d;
        public Integer cp_n_sms_out_30_d;
        public Integer cp_n_sms_out_60_d;
        public Integer cp_n_sms_out_90_d;
        public Integer cp_n_in_sms;
        public Integer cp_n_out_sms;
        public Integer cp_n_web_users;
        public Integer cp_n_cc_users;
        public Integer cp_n_active_cc_users;
        public DateTime cp_first_form;
        public DateTime cp_last_form;
        public DateTime cp_300th_form;
        public DateTime cp_last_update;
        public Integer cp_n_inactive_cases;
        public Integer cp_n_30_day_cases;
        public Integer cp_n_60_day_cases;
        public Integer cp_n_90_day_cases;
        public Integer cp_n_forms_30_d;
        public Integer cp_n_forms_60_d;
        public Integer cp_n_forms_90_d;
        public Boolean cp_has_app;
        public Integer cp_n_30_day_user_cases;
        public Integer cp_n_trivet_backends;
        public Boolean cp_use_domain_security;
        public Integer cp_n_custom_roles;
        public Boolean cp_using_locations;
        public Integer cp_n_loc_restricted_roles;
        public Integer cp_n_case_sharing_olevels;
        public Integer cp_n_case_sharing_groups;
        public Integer cp_n_repeaters;
        public Integer cp_n_case_exports;
        public Integer cp_n_deid_exports;
        public Integer cp_n_saved_exports;
        public Integer cp_n_rb_reports;
        public Integer cp_n_ucr_reports;
        public Integer cp_n_lookup_tables;
        public Boolean cp_has_project_icon;
        public Integer cp_n_apps_with_icon;
        public Integer cp_n_apps;
        public Integer cp_n_apps_with_multi_lang;
        public Integer cp_n_downloads_custom_exports;
        public Integer cp_n_viewed_ucr_reports;
        public Integer cp_n_viewed_non_ucr_reports;
        public Integer cp_n_reports_created;
        public Integer cp_n_reports_edited;
        public Integer cp_n_saved_scheduled_reports;
        public Integer cp_n_click_app_deploy;
        public Integer cp_n_saved_app_changes;
        public Integer cp_n_form_builder_entered;
        public Integer cp_n_users_submitted_form;
        public Integer cp_j2me_90_d_bool; // number in API (0 or 1), in HQ saved as Boolean
        public Integer cp_sms_30_d; // number in API (0 or 1), in HQ saved as Boolean
        public Integer cp_sms_ever; // number in API (0 or 1), in HQ saved as Boolean
    }

    /**
     * Cda data stored in domain object.
     */
    public class Cda {
        public DateTime x_date;
        public String doc_type;
        public Boolean signed;
        public String type;
        public String user_id;
        public String user_ip;
        public String version;
    }

    /**
     * Billing address data stored in domain object.
     */
    public class BillingAddress {
        public String city;
        public String country;
        public String doc_type;
        public String name;
        public String postal_code;
        public String state_province;
    }

    /**
     * HQ Deployment stored in domain object.
     */
    public class HQDeployment {
        public String city;
        public String[] countries;
        public DateTime x_date;
        public String description;
        public String Domain;
        public Boolean x_Public;
        public String region;
        public String country;
    }

    /**
     * Internal Properties stored in domain object.
     */
    public class InternalProperties {
        public String area;
        public Boolean can_use_data;
        public String commcare_edition;
        public Boolean commtrack_domain;
        public Boolean custom_eula;
        public double goal_followup_rate;
        public Integer goal_time_period;
        public String[] initiative;
        public String[] platform;
        public String notes;
        public String organization_name;
        public String phone_model;
        public String project_manager;
        public String project_state;
        public Boolean self_started;
        public String services;
        public String sf_account_id;
        public String sf_contract_id;
        public String sub_area;
        public Boolean using_adm;
        public Boolean using_call_center;
        public String workshop_region;
        public String business_unit;

        public Internal_Properties__c createDbObject(String serverName) {
            Internal_Properties__c internalPropertiesObj = new Internal_Properties__c();
            internalPropertiesObj.area__c = this.area;
            internalPropertiesObj.can_use_data__c = this.can_use_data == null ? false : this.can_use_data;
            internalPropertiesObj.commcare_edition__c = this.commcare_edition;
            internalPropertiesObj.commtrack_domain__c = this.commtrack_domain == null ? false : this.commtrack_domain;
            internalPropertiesObj.custom_eula__c = this.custom_eula == null ? false : this.custom_eula;
            internalPropertiesObj.goal_followup_rate__c = this.goal_followup_rate;
            internalPropertiesObj.goal_time_period__c = this.goal_time_period;
            internalPropertiesObj.initiative__c = String.join(this.initiative, ',');
            internalPropertiesObj.platform__c = String.join(this.platform, ',');
            internalPropertiesObj.notes__c = this.notes;
            internalPropertiesObj.organization_name__c = this.organization_name;
            internalPropertiesObj.phone_model__c = this.phone_model;
            internalPropertiesObj.project_manager__c = this.project_manager;
            internalPropertiesObj.project_state__c = this.project_state;
            internalPropertiesObj.self_started__c = this.self_started == null ? false : this.self_started;
            internalPropertiesObj.services__c = this.services;
            internalPropertiesObj.sf_account_id__c = this.sf_account_id;
            internalPropertiesObj.sf_contract_id__c = this.sf_contract_id;
            internalPropertiesObj.sub_area__c = this.sub_area;
            internalPropertiesObj.using_adm__c = this.using_adm == null ? false : this.using_adm;
            internalPropertiesObj.using_call_center__c = this.using_call_center == null ? false : this.using_call_center;
            internalPropertiesObj.workshop_region__c = this.workshop_region;
            internalPropertiesObj.InternalProp_Business_Unit__c = this.business_unit;
            internalPropertiesObj.Server_Name__c = serverName;

            return internalPropertiesObj;
        }
    }

    /**
     * HQ Domain model, sync daily.
     */
    public class DomainModel {

        public Boolean case_sharing;
        public Boolean commconnect_enabled;
        public Boolean commtrack_enabled;
        public Boolean count_messages_as_read_by_anyone;
        public Boolean filter_surveys_from_chat;
        public Boolean has_careplan;
        public Boolean has_custom_logo;
        public Boolean is_active;
        public Boolean is_approved;
        public Boolean is_public;
        public Boolean is_shared;
        public Boolean is_snapshot;
        public Boolean location_restriction_for_users;
        public Boolean locations_enabled;
        public Boolean multimedia_included;
        public Boolean published;
        public Boolean restrict_superusers;
        public Boolean secure_submissions;
        public Boolean send_to_duplicated_case_numbers;
        public Boolean survey_management_enabled;
        public Boolean show_invalid_survey_responses_in_chat;
        public Boolean sms_case_registration_enabled;
        public Boolean sms_mobile_worker_registration_enabled;
        public Boolean supports_multiple_locations_per_user;
        public Boolean use_cloudcare_releases;
        public Boolean use_default_sms_response;
        public DateTime date_created;
        public DateTime launch_date;
        public DateTime snapshot_time;
        public Integer chat_message_count_threshold;
        public Integer downloads;
        public Integer full_downloads;
        public Integer sms_conversation_length;
        public Integer total_downloads;
        public Integer download_count;
        public String default_sms_response;
        public String x_id; //modified
        public String area;
        public String attribution_notes;
        public String author;
        public String cloudcare_releases;
        public String creating_user;
        public String custom_case_username;
        public String custom_chat_template;
        public String customer_type;
        public String default_mobile_worker_redirect;
        public String default_sms_backend_id;
        public String default_timezone;
        public String description;
        public String hr_name;
        public String is_test;
        public String license;
        public String Name;
        public String name_of_publisher;
        public String organization;
        public String phone_model;
        public String project_type;
        public String publisher;
        public String short_description;
        public String sms_case_registration_owner_id;
        public String sms_case_registration_type;
        public String sms_case_registration_user_id;
        public String sub_area;
        public String title;
        public String billable_client;
        public String billing_number;
        public String currency_code;
        public Boolean is_sms_billable;
        public Boolean hipaa_compliant;
        public Boolean use_sql_backend;
        public String domain_type;
        public String[] tags;
        public HQDeployment deployment;
        public InternalProperties internal;
        public BillingAddress billing_address;
        public Cda cda;

        public Domain__c createDbObject(String serverName, CalculatedProperties calculatedProperties) {
            Domain__c domainObj = new Domain__c();
            domainObj.case_sharing__c = this.case_sharing == null ? false : this.case_sharing;
            domainObj.commconnect_enabled__c = this.commconnect_enabled == null ? false : this.commconnect_enabled;
            domainObj.commtrack_enabled__c = this.commtrack_enabled == null ? false : this.commtrack_enabled;
            domainObj.count_messages_as_read_by_anyone__c = this.count_messages_as_read_by_anyone == null ? false : this.count_messages_as_read_by_anyone;
            domainObj.default_sms_response__c = this.default_sms_response;
            domainObj.filter_surveys_from_chat__c = this.filter_surveys_from_chat == null ? false : this.filter_surveys_from_chat;
            domainObj.has_careplan__c = this.has_careplan == null ? false : this.has_careplan;
            domainObj.has_custom_logo__c = this.has_custom_logo == null ? false:this.has_custom_logo;
            domainObj.is_active__c = this.is_active == null ? false:this.is_active;
            domainObj.is_approved__c = this.is_approved == null ? false:this.is_approved;
            domainObj.is_public__c = this.is_public == null ? false : this.is_public;
            domainObj.is_shared__c = this.is_shared == null ? false : this.is_shared;
            domainObj.is_snapshot__c = this.is_snapshot == null ? false : this.is_snapshot;
            domainObj.location_restriction_for_users__c = this.location_restriction_for_users == null ? false : this.location_restriction_for_users;
            domainObj.locations_enabled__c = this.locations_enabled == null ? false : this.locations_enabled;
            domainObj.multimedia_included__c = this.multimedia_included == null ? false : this.multimedia_included;
            domainObj.published__c = this.published == null ? false : this.published;
            domainObj.restrict_superusers__c = this.restrict_superusers == null ? false : this.restrict_superusers;
            domainObj.secure_submissions__c = this.secure_submissions == null ? false : this.secure_submissions;
            domainObj.send_to_duplicated_case_numbers__c = this.send_to_duplicated_case_numbers == null ? false : this.send_to_duplicated_case_numbers;
            domainObj.survey_management_enabled__c = this.survey_management_enabled == null ? false : this.survey_management_enabled;
            domainObj.show_invalid_survey_responses_in_chat__c = this.show_invalid_survey_responses_in_chat == null ? false : this.show_invalid_survey_responses_in_chat;
            domainObj.sms_case_registration_enabled__c = this.sms_case_registration_enabled == null ? false : this.sms_case_registration_enabled;
            domainObj.sms_mobile_worker_registration_enabled__c = this.sms_mobile_worker_registration_enabled == null ? false : this.sms_mobile_worker_registration_enabled;
            domainObj.supports_multiple_locations_per_user__c = this.supports_multiple_locations_per_user == null ? false : this.supports_multiple_locations_per_user;
            domainObj.use_cloudcare_releases__c = this.use_cloudcare_releases == null ? false : this.use_cloudcare_releases;
            domainObj.use_default_sms_response__c = this.use_default_sms_response == null ? false : this.use_default_sms_response;
            domainObj.use_sql_backend__c = this.use_sql_backend == null ? false : this.use_sql_backend;
            domainObj.date_created__c = this.date_created;
            domainObj.launch_date__c = this.launch_date;
            domainObj.snapshot_time__c = this.snapshot_time;
            domainObj.chat_message_count_threshold__c = this.chat_message_count_threshold;
            domainObj.download_count__c = this.download_count;
            domainObj.downloads__c = this.downloads;
            domainObj.full_downloads__c = this.full_downloads;
            domainObj.sms_conversation_length__c = this.sms_conversation_length;
            domainObj.total_downloads__c = this.total_downloads;
            domainObj.id__c = this.x_id;

            domainObj.attribution_notes__c = this.attribution_notes;
            domainObj.author__c = this.author;
            domainObj.cloudcare_releases__c = this.cloudcare_releases;
            domainObj.creating_user__c = this.creating_user;
            domainObj.custom_case_username__c = this.custom_case_username;
            domainObj.custom_chat_template__c = this.custom_chat_template;
            domainObj.customer_type__c = this.customer_type;
            domainObj.default_mobile_worker_redirect__c = this.default_mobile_worker_redirect;
            domainObj.default_sms_backend_id__c = this.default_sms_backend_id;
            domainObj.default_timezone__c = this.default_timezone;
            domainObj.description__c = this.description;

            domainObj.hr_name__c = this.hr_name;
            domainObj.is_test__c = this.is_test;
            domainObj.license__c = this.license;
            if (this.Name != null && this.Name.length() > 80) {
                domainObj.Name = this.Name.subString(0, 80);
            } else {
                domainObj.Name = this.Name;
            }
            domainObj.name_of_publisher__c = this.name_of_publisher;
            domainObj.organization__c = this.organization;

            domainObj.project_type__c = this.project_type;
            domainObj.publisher__c = this.publisher;
            domainObj.short_description__c = this.short_description;
            domainObj.sms_case_registration_owner_id__c = this.sms_case_registration_owner_id;
            domainObj.sms_case_registration_type__c = this.sms_case_registration_type;
            domainObj.sms_case_registration_user_id__c = this.sms_case_registration_user_id;

            domainObj.title__c = this.title;
            domainobj.tags__c = String.join(this.tags,',');
            domainObj.billable_client__c = this.billable_client;
            domainObj.billing_number__c = this.billing_number;

            if (this.deployment != null && this.deployment.countries != null) {
                domainObj.Countries_Picklist__c = String.join(this.deployment.countries, ';');
                domainObj.Deployment_Countries__c = String.join(this.deployment.countries, ',');
                domainObj.Deployment_city__c = this.deployment.city;
                domainObj.Deployment_date__c = this.deployment.x_date;
                domainObj.Deployment_description__c = this.deployment.description;
                domainObj.Deployment_public__c = this.deployment.x_Public;
                domainObj.Deployment_region__c = this.deployment.region;
                domainObj.Deployment_country__c = this.deployment.country;
            }

            // 2 options: 1 - field is and can be true or false, 2 - there is no field so we put false
            if (this.hipaa_compliant != null) {
                domainObj.hipaa_compliant__c = this.hipaa_compliant;
            } else {
                domainObj.hipaa_compliant__c = false;
            }

            if(this.billing_address != null) {
                domainObj.billing_address_city__c = this.billing_address.city;
                domainObj.billing_address_country__c = this.billing_address.country;
                domainObj.billing_address_doc_type__c = this.billing_address.doc_type;
                domainObj.billing_address_name__c = this.billing_address.name;
                domainObj.billing_address_postal_code__c = this.billing_address.postal_code;
                domainObj.billing_address_state_province__c = this.billing_address.state_province;
            }

            if(this.cda != null) {
                domainObj.cda_date__c = this.cda.x_date;
                domainObj.cda_doc_type__c = this.cda.doc_type;
                domainObj.cda_signed__c = this.cda.signed == null?false: this.cda.signed;
                domainObj.cda_type__c = this.cda.type;
                domainObj.cda_user_id__c = this.cda.user_id;
                domainObj.cda_user_ip__c = this.cda.user_ip;
                domainObj.cda_version__c = this.cda.version;
                domainObj.currency_code__c = this.currency_code;
                domainObj.is_sms_billable__c = this.is_sms_billable==null?false:this.is_sms_billable;
            }

            if (calculatedProperties != null) {
                domainObj.cpIsActive__c = calculatedProperties.cp_is_active == null ? false : calculatedProperties.cp_is_active;
                domainObj.cpAllActiveCases__c = calculatedProperties.cp_n_active_cases;
                domainObj.cpAllSms__c = calculatedProperties.cp_n_sms_ever;
                domainObj.cpAllCases__c = calculatedProperties.cp_n_cases;
                domainObj.cpAllForms__c = calculatedProperties.cp_n_forms;
                domainObj.cpAllSmsIn30Days__c = calculatedProperties.cp_n_sms_30_d;
                domainObj.cpAllSmsIn60Days__c = calculatedProperties.cp_n_sms_60_d;
                domainObj.cpAllSmsIn90Days__c = calculatedProperties.cp_n_sms_90_d;
                domainObj.cpIncomingSmsIn30Days__c = calculatedProperties.cp_n_sms_in_30_d;
                domainObj.cpIncomingSmsIn60Days__c = calculatedProperties.cp_n_sms_in_60_d;
                domainObj.cpIncomingSmsIn90Days__c = calculatedProperties.cp_n_sms_in_90_d;
                domainObj.cpOutgoingSmsIn30Days__c = calculatedProperties.cp_n_sms_out_30_d;
                domainObj.cpOutgoingSmsIn60Days__c = calculatedProperties.cp_n_sms_out_60_d;
                domainObj.cpOutgoingSmsIn90Days__c = calculatedProperties.cp_n_sms_out_90_d;
                domainObj.cpAllIncomingSms__c = calculatedProperties.cp_n_in_sms;
                domainObj.cpAllOutgoingSms__c = calculatedProperties.cp_n_out_sms;
                domainObj.cpAllWebUsers__c = calculatedProperties.cp_n_web_users;
                domainObj.cpAllMobileUsers__c = calculatedProperties.cp_n_cc_users;
                domainObj.cpActiveMobileUsers__c = calculatedProperties.cp_n_active_cc_users;
                domainObj.cpFirstFormSubmissionDate__c = calculatedProperties.cp_first_form;
                domainObj.cpLastFormSubmissionDate__c = calculatedProperties.cp_last_form;
                domainObj.cp300thFormSubmission__c = calculatedProperties.cp_300th_form;
                domainObj.cpAllInactiveCases__c = calculatedProperties.cp_n_inactive_cases;
                domainObj.cpCasesIn30Days__c = calculatedProperties.cp_n_30_day_cases;
                domainObj.cpCasesIn60Days__c = calculatedProperties.cp_n_60_day_cases;
                domainObj.cpCasesIn90Days__c = calculatedProperties.cp_n_90_day_cases;
                domainObj.cpFormsIn30Days__c = calculatedProperties.cp_n_forms_30_d;
                domainObj.cpFormsIn60Days__c = calculatedProperties.cp_n_forms_60_d;
                domainObj.cpFormsIn90Days__c = calculatedProperties.cp_n_forms_90_d;
                domainObj.cpHasApp__c = calculatedProperties.cp_has_app == null ? false : calculatedProperties.cp_has_app;

                domainObj.Domain_cp_n_30_day_user_cases__c = calculatedProperties.cp_n_30_day_user_cases;
                domainObj.Domain_cp_n_trivet_backends__c = calculatedProperties.cp_n_trivet_backends;
                domainObj.Domain_cp_use_domain_security__c = calculatedProperties.cp_use_domain_security == null ? false : calculatedProperties.cp_use_domain_security;
                domainObj.Domain_cp_n_custom_roles__c = calculatedProperties.cp_n_custom_roles;
                domainObj.Domain_cp_using_locations__c = calculatedProperties.cp_using_locations == null ? false : calculatedProperties.cp_using_locations;
                domainObj.Domain_cp_n_loc_restricted_roles__c = calculatedProperties.cp_n_loc_restricted_roles;
                domainObj.Domain_cp_n_case_sharing_olevels__c = calculatedProperties.cp_n_case_sharing_olevels;
                domainObj.Domain_cp_n_case_sharing_groups__c = calculatedProperties.cp_n_case_sharing_groups;
                domainObj.Domain_cp_n_repeaters__c = calculatedProperties.cp_n_repeaters;
                domainObj.Domain_cp_n_case_exports__c = calculatedProperties.cp_n_case_exports;
                domainObj.Domain_cp_n_deid_exports__c = calculatedProperties.cp_n_deid_exports;
                domainObj.Domain_cp_n_saved_exports__c = calculatedProperties.cp_n_saved_exports;
                domainObj.Domain_cp_n_rb_reports__c = calculatedProperties.cp_n_rb_reports;
                domainObj.Domain_cp_n_ucr_reports__c = calculatedProperties.cp_n_ucr_reports;
                domainObj.Domain_cp_n_lookup_tables__c = calculatedProperties.cp_n_lookup_tables;
                domainObj.Domain_cp_has_project_icon__c = calculatedProperties.cp_has_project_icon == null ? false : calculatedProperties.cp_has_project_icon;
                domainObj.Domain_cp_n_apps_with_icon__c = calculatedProperties.cp_n_apps_with_icon;
                domainObj.Domain_cp_n_apps__c = calculatedProperties.cp_n_apps;
                domainObj.Domain_cp_n_apps_with_multi_lang__c = calculatedProperties.cp_n_apps_with_multi_lang;

                domainObj.Domain_cp_n_downloads_custom_exports__c = calculatedProperties.cp_n_downloads_custom_exports;
                domainObj.Domain_cp_n_viewed_ucr_reports__c = calculatedProperties.cp_n_viewed_ucr_reports;
                domainObj.Domain_cp_n_viewed_non_ucr_reports__c = calculatedProperties.cp_n_viewed_non_ucr_reports;
                domainObj.Domain_cp_n_reports_created__c = calculatedProperties.cp_n_reports_created;
                domainObj.Domain_cp_n_reports_edited__c = calculatedProperties.cp_n_reports_edited;
                domainObj.Domain_cp_n_saved_scheduled_reports__c = calculatedProperties.cp_n_saved_scheduled_reports;
                domainObj.Domain_cp_n_click_app_deploy__c = calculatedProperties.cp_n_click_app_deploy;
                domainObj.Domain_cp_n_saved_app_changes__c = calculatedProperties.cp_n_saved_app_changes;
                domainObj.Domain_cp_n_form_builder_entered__c = calculatedProperties.cp_n_form_builder_entered;

                domainObj.Cp_last_update__c = calculatedProperties.cp_last_update;
                domainObj.Cp_n_users_submitted_form__c = calculatedProperties.cp_n_users_submitted_form;
                domainObj.Has_J2ME_submission_in_past_90_days__c = calculatedProperties.cp_j2me_90_d_bool == null || calculatedProperties.cp_j2me_90_d_bool == 0 ? false : true;
                domainObj.Domain_cp_sms_30_d__c = calculatedProperties.cp_sms_30_d == null || calculatedProperties.cp_sms_30_d == 0 ? false : true;
                domainObj.Domain_cp_sms_ever__c = calculatedProperties.cp_sms_ever == null || calculatedProperties.cp_sms_ever == 0 ? false : true;
            }
            domainObj.Server_Name__c = serverName;

            return domainobj;
        }
    }
}