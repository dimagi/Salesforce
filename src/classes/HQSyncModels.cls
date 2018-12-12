/**
 * Class contains HQ sync API models others then Domain.
 */
public class HQSyncModels {

    public class AccountingPaymentRecordWrapper {
        public List<AccountingPaymentRecord> objects;
    }

    public class AccountingSubscriptionAdjustmentWrapper {
        public List<AccountingSubscriptionAdjustment> objects;
    }

    public class AccountingCreditLineWrapper {
        public List<AccountingCreditLine> objects;
    }

    public class AccountingCreditAdjustmentWrapper {
        public List<AccountingCreditAdjustment> objects;
    }

    /**
     * Malt Tables fetched monthly for forms for period calculation.
     */
    public class MaltTablesModel {
        public Decimal id;
        public String app_id;
        public String device_id;
        public String domain_name;
        public String email;
        public Integer experienced_threshold;
        public Boolean is_app_deleted;
        public Date month;
        public Integer num_of_forms;
        public String pam;
        public String wam;
        public Integer use_threshold;
        public String user_id;
        public String user_type;
        public String username;
    }

    /**
     * GIR fetched monthly for wam calculation.
     */
    public class GIRModel {
        public Decimal id;
        public String domain_name;
        public Integer wams_current;
    }

    /**
     * Accounting Customer Invoice fetched daily.
     */
    public class AccountingCustomerInvoice {

        public String id;
        public String account;
        public Double tax_rate;
        public Double balance;
        public Date date_due;
        public Date date_paid;
        public DateTime date_created;
        public Date date_start;
        public Date date_end;
        public Boolean is_hidden;
        public Boolean is_hidden_to_ops;
        public Double applied_credit;
        public Double subtotal;
        public String plan_versions;

        public Accounting_Invoice__c createDbObject(Id billingAccountId, Id domainId, Decimal calculatedMonthlyFee, String softPlanName, Id softPlanVersion, String serverName) {
            return new Accounting_Invoice__c(id__c = this.id, Accounting_Billing_Account__c = billingAccountId, tax_rate__c = this.tax_rate,
                            balance__c = this.balance, date_due__c = this.date_due, date_paid__c = this.date_paid, date_created__c = this.date_created,
                            date_start__c = this.date_start, date_end__c = this.date_end, is_hidden__c = this.is_hidden, Project_Space__c = domainId,
                            is_hidden_to_ops__c = this.is_hidden_to_ops, Total__c = this.subtotal, Total_Credits__c = this.applied_credit,
                            Customer_Invoice_Monthly_fee__c = calculatedMonthlyFee, Softwareplan_Edition__c = softPlanName, Accounting_Customer_PlanVersion__c = softPlanVersion,
                            Software_Plan_Version__c = plan_versions, Server_Name__c = serverName, Invoice_Type__c = HQSyncUtils.CUSTOMER_INVOICE);
        }
    }

    /**
     * Accounting Subscription Invoice fetched daily.
     */
    public class AccountingInvoice {

        public String id;
        public String subscription;
        public Double tax_rate;
        public Double balance;
        public Date date_due;
        public Date date_paid;
        public DateTime date_created;
        public Date date_received;
        public Date date_start;
        public Date date_end;
        public Boolean is_hidden;
        public Boolean is_hidden_to_ops;
        public Double applied_credit;
        public Double subtotal;

        public Accounting_Invoice__c createDbObject(Id subscriptionId, Id domainId, String softPlan, String serverName) {
            return new Accounting_Invoice__c(id__c = this.id, Accounting_Subscription__c = subscriptionId, tax_rate__c = this.tax_rate,
                            balance__c = this.balance, date_due__c = this.date_due, date_paid__c = this.date_paid, date_created__c = this.date_created,
                            date_received__c = this.date_received, date_start__c = this.date_start, date_end__c = this.date_end, is_hidden__c = this.is_hidden,
                            is_hidden_to_ops__c = this.is_hidden_to_ops, Total__c = this.subtotal, Total_Credits__c = this.applied_credit, Project_Space__c = domainId,
                            Server_Name__c = serverName, Softwareplan_Edition__c = softPlan, Invoice_Type__c = HQSyncUtils.SUBSCRIPTION_INVOICE);
        }
    }

    /**
     * Accounting Subscription fetched daily.
     */
    public class AccountingSubscription {

        public String account;
        public String plan_version;
        public String id;
        public String salesforce_contract_id;
        public Date date_start;
        public Date date_end;
        public Date date_delay_invoicing;
        public DateTime date_created;
        public Boolean is_active;
        public Boolean do_not_invoice;
        public Boolean auto_generate_credits;
        public Boolean is_trial;
        public Boolean is_hidden_to_ops;
        public Boolean skip_auto_downgrade;
        public String skip_auto_downgrade_reason;
        public String service_type;
        public String pro_bono_status;
        public String funding_source;
        public String subscriber;

        public Accounting_Subscription__c createDbObject(Id billingAccountId, Id softPlanVerId, Id subscriberId, Id domainId, String serverName) {
            Accounting_Subscription__c accountingSubscriptionObj = new Accounting_Subscription__c();
            accountingSubscriptionObj.id__c = this.id;
            accountingSubscriptionObj.salesforce_contract_id__c = this.salesforce_contract_id;
            accountingSubscriptionObj.date_start__c = this.date_start;
            accountingSubscriptionObj.date_end__c = this.date_end;
            accountingSubscriptionObj.date_delay_invoicing__c = this.date_delay_invoicing;
            accountingSubscriptionObj.date_created__c = this.date_created;
            accountingSubscriptionObj.is_active__c = this.is_active;
            accountingSubscriptionObj.do_not_invoice__c = this.do_not_invoice;
            accountingSubscriptionObj.auto_generate_credits__c = this.auto_generate_credits;
            accountingSubscriptionObj.is_trial__c = this.is_trial;
            accountingSubscriptionObj.is_hidden_to_ops__c = this.is_hidden_to_ops;
            accountingSubscriptionObj.service_type__c = this.service_type;
            accountingSubscriptionObj.pro_bono_status__c = this.pro_bono_status;
            accountingSubscriptionObj.funding_source__c = this.funding_source;
            accountingSubscriptionObj.skip_auto_downgrade__c = this.skip_auto_downgrade == null ? false : this.skip_auto_downgrade;
            accountingSubscriptionObj.Justify_why_Skip_Auto_Downgrade__c = this.skip_auto_downgrade_reason != null ?
                                            this.skip_auto_downgrade_reason.length() > 255 ? this.skip_auto_downgrade_reason.substring(0, 255) : this.skip_auto_downgrade_reason : null;
            accountingSubscriptionObj.account__c = billingAccountId;
            accountingSubscriptionObj.plan_version__c = softPlanVerId;
            accountingSubscriptionObj.Accounting_Subscriber__c = subscriberId;
            accountingSubscriptionObj.Accounting_subscriber_domain__c = domainId;
            accountingSubscriptionObj.Server_Name__c = serverName;

            return accountingSubscriptionObj;
        }
    }

    /**
     * Accounting Subscriber fetched daily.
     */
    public class AccountingSubscriber {

        public string id;
        public string domain;
        public string organization;

        public Accounting_Subscriber__c createDbObject(Id domainId, String serverName) {
            Accounting_Subscriber__c accountingSubscriberObj = new Accounting_Subscriber__c();
            accountingSubscriberObj.id__c = this.id;
            if (this.domain != null && this.domain.length() > 80) {
                accountingSubscriberObj.domain__c = this.domain.subString(0, 80);
            } else {
                accountingSubscriberObj.domain__c = this.domain;
            }
            accountingSubscriberObj.organization__c = this.organization;
            accountingSubscriberObj.domain_lookup__c = domainId;
            accountingSubscriberObj.Server_Name__c = serverName;
            system.debug('--domainid--' + domainid);

            return accountingSubscriberObj;
        }
    }

    /**
     * Accounting Billing Account fetched daily.
     */
    public class AccountingBillingAccount  {

        public String id;
        public String name;
        public String salesforce_account_id;
        public String created_by;
        public DateTime date_created;
        public Boolean is_auto_invoiceable;
        public String account_type;
        public String created_by_domain;
        public DateTime date_confirmed_extra_charges;
        public Boolean is_active;
        public String dimagi_contact;
        public String entry_point;
        public String last_payment_method;
        public String pre_or_post_pay;

        public Accounting_BillingAccount__c createDbObject(id billingContactId, String serverName) {
            Accounting_BillingAccount__c accountingBillingAccount = new Accounting_BillingAccount__c();
            accountingBillingAccount.id__c = this.id;
            if (this.name != null && this.name.length() > 80) {
                accountingBillingAccount.name = this.name.subString(0, 80);
            } else {
                accountingBillingAccount.name = this.name;
            }
            accountingBillingAccount.salesforce_account_id__c = this.salesforce_account_id;
            accountingBillingAccount.created_by__c = this.created_by;
            accountingBillingAccount.date_created__c = this.date_created;
            accountingBillingAccount.is_auto_invoiceable__c = this.is_auto_invoiceable;
            accountingBillingAccount.account_type__c = this.account_type;
            accountingBillingAccount.created_by_domain__c = this.created_by_domain;
            accountingBillingAccount.date_confirmed_extra_charges__c = this.date_confirmed_extra_charges;
            accountingBillingAccount.is_active__c = this.is_active;
            accountingBillingAccount.dimagi_contact__c = this.dimagi_contact;
            accountingBillingAccount.entry_point__c = this.entry_point;
            accountingBillingAccount.BillingContact__c = billingContactId;
            accountingBillingAccount.last_payment_method__c = this.last_payment_method;
            accountingBillingAccount.pre_or_post_pay__c = this.pre_or_post_pay;
            accountingBillingAccount.Server_Name__c = serverName;

            return accountingBillingAccount;
        }
    }

    /**
     * Accounting Software Plan fetched daily.
     */
    public class AccountingSoftwarePlan {

        public String id;
        public String name;
        public String description;
        public String visibility;
        public String edition;

        public Accounting_Softwareplan__c createDbObject(String serverName) {

            Accounting_Softwareplan__c accountingSoftwarePlanObj = new Accounting_Softwareplan__c();
            accountingSoftwarePlanObj.id__c = this.id;
            accountingSoftwarePlanObj.name = this.name;
            accountingSoftwarePlanObj.description__c = this.description;
            accountingSoftwarePlanObj.edition__c = this.edition;
            accountingSoftwarePlanObj.visibility__c = this.visibility;
            accountingSoftwarePlanObj.Server_Name__c = serverName;

            return accountingSoftwarePlanObj;
        }
    }

    public class AccountingSoftwareProductRate {

        public String id;
        public Boolean is_active;
        public Double monthly_fee;

        public Accounting_SoftwareProductRate__c createDbObject(String serverName) {
            Accounting_SoftwareProductRate__c softwareProductRate = new Accounting_SoftwareProductRate__c();
            softwareProductRate.id__c = this.id;
            softwareProductRate.is_active__c = this.is_active;
            softwareProductRate.monthly_fee__c = this.monthly_fee;
            softwareProductRate.Server_Name__c = serverName;

            return softwareProductRate;
        }
    }

    /**
     * Accounting Software Plan Version fetched daily.
     */
    public class AccountingSoftwarePlanVersion {

        public String id;
        public String plan;
        public DateTime date_created;
        public Boolean is_active;
        public String[] feature_rates;
        public String[] product_rates;

        public Accounting_SoftwarePlanVersion__c createDbObject(Id planId, Id productRate, String serverName) {
            Accounting_SoftwarePlanVersion__c accountingSoftwarePlanVersionObj = new Accounting_SoftwarePlanVersion__c();
            accountingSoftwarePlanVersionObj.id__c = this.id;
            accountingSoftwarePlanVersionObj.Accounting_SoftwarePlan__c = planId;
            accountingSoftwarePlanVersionObj.date_created__c = this.date_created;
            accountingSoftwarePlanVersionObj.is_active__c = this.is_active;
            accountingSoftwarePlanVersionObj.FeatureRates__c = String.join(feature_rates,',');
            accountingSoftwarePlanVersionObj.Software_Product_Rate__c = productRate;
            accountingSoftwarePlanVersionObj.Server_Name__c = serverName;

            return accountingSoftwarePlanVersionObj;
        }
    }

    /**
     * Accounting Feature Rate fetched daily.
     */
    public class AccountingFeatureRate {

        public String id;
        public String feature;
        public Double monthly_fee;
        public Integer monthly_limit;
        public Double per_excess_fee;
        public DateTime date_created;
        public Boolean is_active;

        public Accounting_Featurerate__c createDbObject(String featureId, String serverName) {
            Accounting_Featurerate__c obj = new Accounting_Featurerate__c();
            obj.id__c = id;
            obj.date_created__c = date_created;
            obj.feature__c = featureId;
            obj.is_active__c = is_active;
            obj.monthly_fee__c = monthly_fee;
            obj.monthly_limit__c = monthly_limit;
            obj.per_excess_fee__c = per_excess_fee;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Feature fetched daily.
     */
    public class AccountingFeature {

        public String id;
        public String name;
        public String feature_type;

        public accounting_feature__c createDbObject(String serverName) {
            Accounting_feature__c obj = new Accounting_feature__c();
            obj.id__c = id;
            obj.name = name;
            obj.feature_type__c = feature_type;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Billing Contact Info fetched daily.
     */
    public class AccountingBillingContactInfo {

        public string account;
        public string first_name;
        public string last_name;
        public string emails;
        public string phone_number;
        public string company_name;
        public string first_line;
        public string second_line;
        public string city;
        public string state_province_region;
        public string postal_code;
        public string country;

        public Accounting_BillingContactInfo__c createDbObject(String serverName) {
            Accounting_BillingContactInfo__c obj = new Accounting_BillingContactInfo__c();
            obj.city__c = city;
            obj.company_name__c = company_name;
            obj.country__c = country;
            obj.emails__c = emails;
            obj.first_line__c = first_line;
            obj.first_name__c = first_name;
            obj.last_name__c = last_name;
            obj.phone_number__c = phone_number;
            obj.postal_code__c = postal_code;
            obj.second_line__c = second_line;
            obj.state_province_region__c = state_province_region;
            obj.accountid__c = account;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Line Item fetched daily.
     */
    public class AccountingLineItem {

        public String id;
        public String customer_invoice;
        public String invoice;
        public String feature_rate;
        public String base_description;
        public Double base_cost;
        public String unit_description;
        public Double unit_cost;
        public Integer quantity;
        public Double subtotal;
        public Double applied_credit;

        public Accounting_LineItems__c createDbObject(String invoiceId, String featurerateId, String serverName) {
            Accounting_LineItems__c obj = new Accounting_LineItems__c();
            obj.id__c = id;
            obj.invoice__c = invoiceId;
            obj.Accounting_FeatureRate__c = featurerateId;
            obj.base_description__c = base_description;

            obj.base_cost__c = base_cost;
            obj.unit_description__c = unit_description;
            obj.unit_cost__c = unit_cost;
            obj.quantity__c = quantity;

            obj.subtotal__c = subtotal;
            obj.applied_credit__c = applied_credit;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Line Item fetched daily.
     */
    public class AccountingPaymentRecord {

        public string id;
        public string payment_method;
        public DateTime date_created;
        public string transaction_id;
        public Double amount;

        public Accounting_Paymentrecord__c createDbObject(Id sfIdPaymentMethod, String serverName) {
            Accounting_Paymentrecord__c obj = new Accounting_Paymentrecord__c();
            obj.id__c = id;
            obj.payment_method__c = sfIdPaymentMethod;
            obj.amount__c = amount;
            obj.date_created__c = date_created;
            obj.transaction_id__c = transaction_id;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Payment Method fetched daily.
     */
    public class AccountingPaymentMethod {

        public string id;
        public string account;
        public string method_type;
        public string customer_id;
        public DateTime date_created;
        public string billing_admin;

        public Accounting_PaymentMethod__c createDbObject(Id sfIdBillAcc, Id sfIdBillAccAdmin, String serverName) {
            Accounting_PaymentMethod__c obj = new Accounting_PaymentMethod__c();
            obj.id__c = id;
            obj.account__c = sfIdBillAcc;
            obj.billing_admin__c = sfIdBillAccAdmin;
            obj.customer_id__c = customer_id;

            obj.date_created__c = date_created;
            obj.method_type__c = method_type;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Subscription Adjustment fetched daily.
     */
    public class AccountingSubscriptionAdjustment {

        public String id;
        public String subscription;
        public String reason;
        public String method;
        public DateTime date_created;

        public Accounting_SubscriptionAdjustment__c createDbObject(String subscriptionId, String serverName) {
            Accounting_SubscriptionAdjustment__c obj = new Accounting_SubscriptionAdjustment__c();
            obj.id__c = id;
            obj.subscription__c = subscriptionId;
            obj.reason__c = reason;
            obj.method__c = method;
            obj.date_created__c = date_created;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Credit Adjustment fetched daily.
     */
    public class AccountingCreditAdjustment {

        public String id;
        public String credit_line;
        public String reason;
        public String note;

        public double amount;
        public String line_item;
        public String invoice;
        public DateTime date_created;

        public String web_user;
        public String payment_record;
        public String related_credit;

        public Accounting_CreditAdjustment__c createDbObject(String creditLineSfId, String invoiceSfId, String lineItemSfId, String paymentRecSfId,
                                                                String relatedCreditLineSfId, String serverName) {
            Accounting_CreditAdjustment__c obj = new Accounting_CreditAdjustment__c();
            obj.amount__c = amount;
            obj.credit_line__c = creditLineSfId;
            obj.date_created__c = date_created;
            obj.id__c = id;

            obj.invoice_id__c = invoiceSfId;
            obj.line_item_id__c = lineItemSfId;
            obj.note__c = note;
            obj.payment_record_id__c = paymentRecSfId;

            obj.reason__c = reason;
            obj.related_credit_id__c = relatedCreditLineSfId;
            obj.web_user__c = web_user;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }

    /**
     * Accounting Credit Line fetched daily.
     */
    public class AccountingCreditLine {

        public String id;
        public String account;
        public String subscription;
        public DateTime date_created;

        public double balance;
        public String product_type;
        public String feature_type;
        public Boolean is_active;

        public Accounting_CreditLine__c createDbObject(String billingAccSfId, String subscriptionSfId, String serverName) {
            Accounting_CreditLine__c obj = new Accounting_CreditLine__c();
            obj.id__c = id;
            obj.account__c = billingAccSfId;
            obj.balance__c = balance;
            obj.date_created__c = date_created;

            obj.feature_type__c = feature_type;
            obj.is_active__c = is_active;
            obj.product_type__c = product_type;
            obj.Subscription__c = subscriptionSfId;
            obj.Server_Name__c = serverName;

            return obj;
        }
    }
}