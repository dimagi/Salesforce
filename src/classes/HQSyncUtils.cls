public class HQSyncUtils {

    public static final String LIMIT_PARAM = 'limit';
    public static final String OFFSET_PARAM = 'offset';
    public static final String FORMAT_PARAM = 'format';
    public static final String JSON_PARAM = 'json';
    public static final String ADDED_PARAM = 'format';
    public static final String FETCHED_PARAM = 'json';
    public static final String OBJECTS_PARAM = 'objects';

    public static final String DOMAIN_SUFFIX = 'project_space_metadata';
    public static final String MALT_SUFFIX = 'malt_tables';
    public static final String GIR_SUFFIX = 'gir_tables';

    /**
     * Replace reserved Apex words from given JSON file.
     */
    public static String replaceReservedWords(String myString) {
       myString = myString.replaceAll('"_id":', '"x_id":');
       myString = myString.replaceAll('"public":', '"x_Public":');
       myString = myString.replaceAll('"date":', '"x_date":');
       return myString;
    }

    /**
     * Generates offset list from total count and request size.
     */
    public static List<Integer> buildsOffsetList(Integer totalCount, Integer size) {
        List <Integer> listOffset = new List <Integer>();
        for(Integer i = 0; i <= totalCount / size; i++) {
            listOffset.add(i * size);
        }

        if(Test.isRunningTest()) {
            listOffset = new List<Integer> {0};
        }

        return listOffset;
    }

    /**
     * Creates JSON parser for reading objects(it's skip metafrom JSON begining) part from HQ API.
     */
    public static JSONParser createParser(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == OBJECTS_PARAM) {
                break;
            }
        }

        return parser;
    }

    /**
     * Returns Commcare servers list added to the SF settings.
     */
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

    /**
     * Starts Domains synchronization. It blocks UI for manual run.
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
            Database.executeBatch(new HQSyncDomainBatch(serverCode, null, servers), 1);
        }
    }

    /**
     * Ends Domains synchronization.
     */
    public static void endDomainJob() {
        if (!Test.isRunningTest()) {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.HQ_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();

        if (settings.Is_Domain_Job_Running__c == false) {
            return;
        }

        settings.Is_Domain_Job_Running__c = false;
        update settings;
    }

    /**
     * Starts Accounting objects synchronization. It blocks UI for manual run.
     */
    public static void startAccountingJobs() {
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
                runAccountingBatchJob(1, serverCode, servers);
            }
        }
    }

    /**
     * Ends Accounting objects synchronization.
     */
    public static void endAccountingJobs() {
        if (!Test.isRunningTest()) {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.HQ_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        settings.Is_Job_Running__c = false;
        settings.Server_Code__c = '';
        update settings;
    }

    /**
     * Runs accounting batch job with proper endpoint(currently we have 16 endpoints and 2 servers) and server list.
     */
    public static void runAccountingBatchJob(Integer batchToBeRun, String serverCode, List<String> nextServers) {
        Boolean lastBatch = false;

        try {
            if(batchToBeRun == 1) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_feature__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncFeatureProcessor(), serverCode, 'accounting_features/', nextServers), 1);
            } else if (batchToBeRun == 2) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSoftwarePlanProcessor(),serverCode, 'software_plan/', nextServers), 1);
            } else if (batchToBeRun == 3) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Subscriber__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSubscriberProcessor(), serverCode, 'subscriber/', nextServers), 1);
            } else if (batchToBeRun == 4) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Featurerate__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncFeatureRateProcessor(), serverCode, 'accounting_feature_rates/', nextServers), 1);
            } else if (batchToBeRun == 5) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSoftwareProductRateProcessor(), serverCode, 'software_product_rate/', nextServers), 1);
            } else if (batchToBeRun == 6) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSoftwarePlanVersionProcessor(), serverCode, 'software_plan_versions/', nextServers), 1);
            } else if (batchToBeRun == 7) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncPaymentMethodProcessor(), serverCode, 'accounting_payment_method/', nextServers), 1);
            } else if (batchToBeRun  == 8) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncBillingContactInfoProcessor(), serverCode, 'billing_contact_info/', nextServers), 1);
            } else if (batchToBeRun == 9) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncPaymentRecordProcessor(), serverCode, 'payment_record/', nextServers), 1);
            } else if (batchToBeRun == 10) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncBillingAccountProcessor(), serverCode, 'billing_account/', nextServers), 1);
            } else if (batchToBeRun == 11) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Subscription__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSubscriptionProcessor(), serverCode, 'subscription/', nextServers), 1);
            } else if (batchToBeRun == 12) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_Invoice__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncInvoiceProcessor(), serverCode, 'invoice/', nextServers), 1);
            } else if (batchToBeRun == 13) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_LineItems__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncLineItemProcessor(), serverCode, 'accounting_line_items/', nextServers), 1);
            } else if (batchToBeRun == 14) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncSubscriptionAdjustmentProcessor(), serverCode, 'subscription_and_adjustment/', nextServers), 1);
            } else if (batchToBeRun == 15) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_CreditLine__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncCreditLineProcessor(), serverCode, 'credit_line/', nextServers), 1);
            } else if (batchToBeRun == 16) {
                Database.executeBatch(new HQSyncAccountingBatch(batchToBeRun, Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel(),
                                        new HQSyncProcessors.HQSyncCreditAdjustmentProcessor(), serverCode, 'credit_adjustment/', nextServers), 1);
            } else if (nextServers.size() > 0) {
                updateMissingRelations(serverCode);
                String newServerCode = nextServers.get(0);
                nextServers.remove(0);
                Database.executeBatch(new HQSyncAccountingBatch(1, Accounting_feature__c.SObjectType.getDescribe().getLabel(), new HQSyncProcessors.HQSyncFeatureProcessor(),
                                           newServerCode, 'accounting_features/', nextServers), 1);
            } else {
                endAccountingJobs();
                Database.executeBatch(new CalculateDomainsLifeTimeMRRBatch(), 100);
            }
        } catch (Exception e) {
            endAccountingJobs();
            BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
            EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'Cannot run Accounting HQ batch job', '', e);
        }
    }

    /**
     * Updates missing relations, caused by some sync errors. For example domain sync had error and new domain wasn't added to the DB, but subscriber was added and relation is empty.
     */
    public static void updateMissingRelations(String serverName) {
        try {
            updateMissingSubscriberDomain(serverName);
            updateMissingSpaceLink(serverName);
            updateMissingSubscriptionDomain(serverName);
        } catch (Exception ex) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            System.debug('Error: ' + ex);
            EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'Commcare sync Error', 'Cannot update missing relations: ' + serverName, ex);
        }
    }

    /**
     * Updates missing space link in invoice object.
     */
    public static void updateMissingSpaceLink(String serverName) {
        List<Accounting_Invoice__c> accountingInvoice = [SELECT id__c, Accounting_Subscription__r.Accounting_Subscriber__r.domain__c, Project_Space__c
                                                         FROM Accounting_Invoice__c WHERE Project_Space__c = '' AND Server_Name__c =: serverName];
        List<Accounting_Invoice__c> accountingInvoiceToUpdate = new List<Accounting_Invoice__c>();
        System.debug('---Accounting Invoice with blank domain relation link---' + accountingInvoice);
        if (accountingInvoice.size() == 0) {
            return;
        }

        Set<String> domainNames = new Set<String>();
        for(Accounting_Invoice__c ac : accountingInvoice) {
            if (ac.Accounting_Subscription__r != null && ac.Accounting_Subscription__r.Accounting_Subscriber__r != null) {
                domainNames.add(ac.Accounting_Subscription__r.Accounting_Subscriber__r.domain__c);
                accountingInvoiceToUpdate.add(ac);
            }
        }

        System.debug('---domainNames---' + domainNames);

        if (domainNames.size() > 0) {
            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames AND Server_Name__c =: serverName]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Invoice__c ac : accountingInvoiceToUpdate) {
                Id domainId = mapDomainNameId.get(ac.Accounting_Subscription__r.Accounting_Subscriber__r.domain__c);
                if (domainId != null) {
                    ac.Project_Space__c = domainId;
                }
            }

            update accountingInvoiceToUpdate;
        }
    }


    /**
     * Updates missing domain relation in subscriber object.
     */
    public static void updateMissingSubscriberDomain(String serverName) {
        List<Accounting_Subscriber__c> subscribers = [SELECT domain__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE domain_lookup__c = '' AND Server_Name__c =: serverName];
        System.debug('---Subscribers with blank domain relation---' + subscribers);

        if (subscribers.size() > 0) {
            Set<String> domainNames = new Set<String>();
            for (Accounting_Subscriber__c subscriber : subscribers) {
                domainNames.add(subscriber.domain__c);
            }
            System.debug('---domainNames---' + domainNames);

            if (domainNames.size() == 0) {
                return;
            }

            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames AND Server_Name__c =: serverName]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Subscriber__c subscriber : subscribers) {
                Id domainId = mapDomainNameId.get(subscriber.domain__c);
                if (domainId != null) {
                    subscriber.domain_lookup__c = domainId;
                }
            }

            update subscribers;
        }
    }

    /**
     * Updates missing domain relation in subscription object.
     */
    public static void updateMissingSubscriptionDomain(String serverName) {
        List<Accounting_Subscription__c> subscriptions = [SELECT Id, Name, Accounting_subscriber_domain__c, Accounting_Subscriber__r.domain__c FROM Accounting_Subscription__c
                                                          WHERE Accounting_subscriber_domain__c = '' AND Accounting_Subscriber__r.domain__c != '' AND Server_Name__c =: serverName];
        System.debug('---subscriptions with blank domain relation---' + subscriptions);

        if (subscriptions.size() > 0) {
            Set<String> domainNames = new Set<String>();
            for (Accounting_Subscription__c subscription : subscriptions) {
                domainNames.add(subscription.Accounting_Subscriber__r.domain__c);
            }
            System.debug('---domainNames---' + domainNames);

            if (domainNames.size() == 0) {
                return;
            }

            Map <String, Id> mapDomainNameId = new Map<String, Id>();
            for(Domain__c domain : [SELECT Id, Name FROM Domain__c WHERE Name in: domainNames AND Server_Name__c =: serverName]) {
                mapDomainNameId.put(domain.Name, domain.Id);
            }

            for (Accounting_Subscription__c subscription : subscriptions) {
                Id domainId = mapDomainNameId.get(subscription.Accounting_Subscriber__r.domain__c);
                if (domainId != null) {
                    subscription.Accounting_subscriber_domain__c = domainId;
                }
            }

            update subscriptions;
        }
    }

    public static List<Integer> getErrorOffsetList(String objectType, String serverName, Date monthDate) {
        List<HQ_Sync_Error__c> totalErrors = [SELECT Offset__c FROM HQ_Sync_Error__c WHERE Object_Type__c =: objectType AND Server_Name__c =: serverName AND Date__c =: monthDate AND Offset__c = -1];
        if (totalErrors.size() > 0) { // if there is and error with offset -1 it means that total count fetch failed
            delete totalErrors;
            return null;
        }

        List<Integer> offsetList = new List<Integer>();
        List<HQ_Sync_Error__c> compressedData = [SELECT Offset__c FROM HQ_Sync_Error__c WHERE Object_Type__c =: objectType AND Server_Name__c =: serverName AND Date__c =: monthDate];
        for (HQ_Sync_Error__c hqData : compressedData) {
            offsetList.add((hqData.Offset__c != null ? hqData.Offset__c.intValue() : 0));
        }
        return offsetList;
    }
}