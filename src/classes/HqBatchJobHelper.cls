/**
 * Helper class which is used to start and manage sync from CommCare servers.
 */
public class HqBatchJobHelper {

    public static void startBatchJobs() {
        Date startDate = Date.now();
        List<String> servers = new List<String>();

        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        settings.Job_Start_Date__c = startDate;
        settings.Is_Job_Running__c = true;
        settings.Server_Code__c = '';

        update settings;

        HqBatchJobHelper.runNextBatchJob(1, '', servers);
    }

    public static void endBatchJobs() {
        Date startDate = Date.now();

        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        //TODO update all servers settings !!!
        settings.Job_Start_Date__c = null;
        settings.Is_Job_Running__c = false;
        settings.Server_Code__c = '';
    }

    public static void runNextBatchJob(Integer batchNo, String serverCode, List<String> nextServers) {
        Boolean lastBatch = false;

        try {
            if(batchToBeRun == 1) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_feature__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_features/', nextServers), 1);
            } else if (batchToBeRun == 2) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_plan/', nextServers), 1);
            } else if (batchToBeRun == 3) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Subscriber__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscriber/', nextServers), 1);
            } else if (batchToBeRun == 4) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Featurerate__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_feature_rates/', nextServers), 1);
            } else if (batchToBeRun == 5) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_product_rate/', nextServers), 1);
            } else if (batchToBeRun == 6) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_plan_versions/', nextServers), 1);
            } else if (batchToBeRun == 7) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_payment_method/', nextServers), 1);
            } else if (batchToBeRun  == 8) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'billing_contact_info/', nextServers), 1);
            } else if (batchToBeRun == 9) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'payment_record/', nextServers), 1);
            } else if (batchToBeRun == 10) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'billing_account/', nextServers), 1);
            } else if (batchToBeRun == 11) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Subscription__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscription/', nextServers), 1);
            } else if (batchToBeRun == 12) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_Invoice__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'invoice/', nextServers), 1);
            } else if (batchToBeRun == 13) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_LineItems__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_line_items/', nextServers), 1);
            } else if (batchToBeRun == 14) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscription_and_adjustment/', nextServers), 1);
            } else if (batchToBeRun == 15) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_CreditLine__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'credit_line/', nextServers), 1);
            } else if (batchToBeRun == 16) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchNo, Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'credit_adjustment/', nextServers), 1);
            } else if (nextServers.size() > 0) {
                serverCode = nextServers.get(0);
                nextServers.delete(0);
                Database.executeBatch(new HqBatchFetchDataObjects(1, Accounting_feature__c.SObjectType.getDescribe().getLabel(), serverCode,
                                        'accounting_features/', nextServers), 1);
            } else {
                HqBatchJobHelper.endBatchJobs();
            }
        } catch (Exception e) {
            HqBatchJobHelper.endBatchJobs();
        }
    }
}