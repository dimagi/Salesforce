/**
 * Helper class which is used to start and manage synchronization from CommCare servers.
 */
public class HqBatchJobHelper {

    /**
     * Starts Domains sunchronization.
     */
    public static void startDomainJob() {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();

        if (settings.Is_Domain_Job_Running__c == true) {
            return;
        }

        settings.Is_Domain_Job_Running__c = true;
        update settings;

        List<String> servers = getCommcareServers(false);
        if (servers.size() > 0) {
            String serverCode = servers.get(0);
            servers.remove(0);
            Database.executeBatch(new HqBatchFetchDataDomains(serverCode, servers), 1);
        }
    }

    /**
     * Ends Domains synchronization.
     */
    public static void endDomainJob() {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();

        if (settings.Is_Domain_Job_Running__c == false) {
            return;
        }

        settings.Is_Domain_Job_Running__c = false;
        update settings;
    }

    /**
     * Starts Accounting objects synchronization.
     */
    public static void startBatchJobs() {
        Date startDate = Date.today();

        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        settings.Job_Start_Date__c = startDate;
        if (settings.Is_Job_Running__c == true) {
            return;
        }
        settings.Is_Job_Running__c = true;

        update settings;

        List<String> servers = getCommcareServers(false);
        if (servers.size() > 0) {
            String serverCode = servers.get(0);
            servers.remove(0);
            if(!Test.IsRunningTest()) {
                runNextBatchJob(1, serverCode, servers);
            }
        }
    }

    /**
     * Ends Accounting objects synchronization.
     */
    public static void endBatchJobs() {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        settings.Is_Job_Running__c = false;
        settings.Server_Code__c = '';
        update settings;
    }

    /**
     * Runs next batch job for Accounting objects from the given server.
     */
    public static void runNextBatchJob(Integer batchToBeRun, String serverCode, List<String> nextServers) {
        Boolean lastBatch = false;

        try {
            if(batchToBeRun == 1) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_feature__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_features/', nextServers), 1);
            } else if (batchToBeRun == 2) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_plan/', nextServers), 1);
            } else if (batchToBeRun == 3) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Subscriber__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscriber/', nextServers), 1);
            } else if (batchToBeRun == 4) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Featurerate__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_feature_rates/', nextServers), 1);
            } else if (batchToBeRun == 5) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_product_rate/', nextServers), 1);
            } else if (batchToBeRun == 6) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'software_plan_versions/', nextServers), 1);
            } else if (batchToBeRun == 7) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_payment_method/', nextServers), 1);
            } else if (batchToBeRun  == 8) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'billing_contact_info/', nextServers), 1);
            } else if (batchToBeRun == 9) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'payment_record/', nextServers), 1);
            } else if (batchToBeRun == 10) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'billing_account/', nextServers), 1);
            } else if (batchToBeRun == 11) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Subscription__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscription/', nextServers), 1);
            } else if (batchToBeRun == 12) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_Invoice__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'invoice/', nextServers), 1);
            } else if (batchToBeRun == 13) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_LineItems__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'accounting_line_items/', nextServers), 1);
            } else if (batchToBeRun == 14) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'subscription_and_adjustment/', nextServers), 1);
            } else if (batchToBeRun == 15) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_CreditLine__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'credit_line/', nextServers), 1);
            } else if (batchToBeRun == 16) {
                Database.executeBatch(new HqBatchFetchDataObjects(batchToBeRun, Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        serverCode, 'credit_adjustment/', nextServers), 1);
            } else if (nextServers.size() > 0) {
                String newServerCode = nextServers.get(0);
                nextServers.remove(0);
                Database.executeBatch(new HqBatchFetchDataObjects(1, Accounting_feature__c.SObjectType.getDescribe().getLabel(), newServerCode,
                                        'accounting_features/', nextServers), 1);
            } else {
                HqBatchJobHelper.endBatchJobs();
            }
        } catch (Exception e) {
            HqBatchJobHelper.endBatchJobs();
        }
    }

    public static List<String> getCommcareServers(Boolean skipBatchData) {
        List<String> servers = new List<String>();
        List<CommcareToSalesforceSettings__c> serverSettingsList = CommcareToSalesforceSettings__c.getAll().values();
        for (CommcareToSalesforceSettings__c serverSettings : serverSettingsList) {
            if (serverSettings.Skip_in_batch_job__c == false || skipBatchData == true) {
                servers.add(serverSettings.Name);
            }
        }
        return servers;
    }
}