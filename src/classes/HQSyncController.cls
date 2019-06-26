/**
 * Controller for sync Visualforce page. Page is used to schedule Phase One and Phase Two synchronization from different servers.
 */
public class HQSyncController {

    public Date syncPhaseTwoDate { get; set; }
    public Boolean syncRunningPhaseOne { get; set; }
    public Boolean syncRunningPhaseTwo { get; set; }

    public String phaseOneServer { get; set;}
    public String phaseTwoServer { get; set;}
    public List<SelectOption> serverCodes { get; set;}

    public JobWrapper phaseOneJob { get; set;}
    public List<JobWrapper> phase2Jobs { get; set;}
    public Integer initialTab { get; set; }

    public HQSyncController() {
        List<String> values = HQSyncUtils.getCommcareServers(true);
        this.serverCodes = new List<SelectOption>();
        for (String val : values) {
            this.serverCodes.add(new SelectOption(val, val));
        }

        this.phaseOneServer = values[0];
        this.phaseTwoServer = values[0];

        this.syncPhaseTwoDate = Date.today().addDays(-2);
        loadServerSuccessfulDate();

        loadSynchronizationStatus();

        this.initialTab = 1;
        if (this.syncRunningPhaseTwo == true) {
            this.initialTab = 2;
        }
    }

    public void loadSynchronizationStatus() {
        fetchDomainInstances();
        fetchAccountingInstances();
    }

    /**
     * Domains synchronization.
     */
    public void fetchDomainInstances() {
        this.syncRunningPhaseOne = false;
        ApexClass batchClass;
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        if (settings.Is_Domain_Job_Running__c == true) {
            this.syncRunningPhaseOne = true;
            this.phaseOneServer = settings.Server_Code__c;
        }

        try {
            batchClass = [SELECT Id FROM ApexClass WHERE Name='HQSyncDomainBatch' LIMIT 1];
        } catch(exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Class not found'));
        }

        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, CreatedDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if (batchClassJobList != null && batchClassJobList.size() > 0) {
            this.syncRunningPhaseOne = true;
            this.phaseOneJob = new JobWrapper();
            this.phaseOneJob.jobItemsProcessed = batchClassJobList[0].JobItemsProcessed;
            this.phaseOneJob.totalJobItems = batchClassJobList[0].TotalJobItems;
            this.phaseOneJob.createdDate = batchClassJobList[0].CreatedDate;
            this.phaseOneJob.isRunning = true;
        }
    }

    public PageReference runDomainsSynchronizationJob() {
        this.initialTab = 1;
        loadSynchronizationStatus();
        if(this.syncRunningPhaseTwo == false && this.syncRunningPhaseOne == false) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            settings.Is_Domain_Job_Running__c = true;
            update settings;
            Database.executeBatch(new HQSyncDomainBatch(this.phaseOneServer, null, new List<String>()), 1);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot run synchronization job. Running instance was found already.'));
        }

        loadSynchronizationStatus();
        return null;
    }

    /**
     * Accounting synchronization.
     */
    public void fetchAccountingInstances() {
        List <String> objectNames = new List <String>();
        objectNames.add(accounting_feature__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_BillingAccountAdmin__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Subscriber__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Featurerate__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Subscription__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_Invoice__c.SObjectType.getDescribe().getLabel() + ' ' + HQSyncUtils.SUBSCRIPTION_INVOICE + ' Invoice');
        objectNames.add(Accounting_Invoice__c.SObjectType.getDescribe().getLabel() + ' ' + HQSyncUtils.CUSTOMER_INVOICE + ' Invoice');
        objectNames.add(Accounting_LineItems__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditLine__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel());

        this.syncRunningPhaseTwo = false;
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        this.syncRunningPhaseTwo = settings.Is_Job_Running__c;
        String customObject = settings.Job_Helper_Field__c;
        this.phaseTwoServer = this.syncRunningPhaseTwo == true ? settings.Server_Code__c : this.phaseTwoServer;

        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, CreatedDate, ApexClass.Id, ApexClass.Name, Status, CompletedDate
                                            FROM AsyncApexJob
                                            WHERE ApexClass.Name = 'HQSyncAccountingBatch' AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
                                            ORDER BY createdDate DESC LIMIT 1];
        AsyncApexJob batchClassJob = null;
        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            this.syncRunningPhaseTwo = true;
            batchClassJob = batchClassJobList[0];
        }

        phase2Jobs = new List<JobWrapper>();

        for (String jobName : objectNames) {
            JobWrapper jobWrapper = new JobWrapper();
            jobWrapper.jobName = jobName;
            phase2Jobs.add(jobWrapper);
        }

        JobWrapper jobWrapper;
        for (JobWrapper job : phase2Jobs) {
            if (job.jobName == customObject) {
                jobWrapper = job;
                break;
            }
        }

        if (jobWrapper != null && batchClassJob != null) {
            jobWrapper.jobItemsProcessed = batchClassJob.JobItemsProcessed;
            jobWrapper.totalJobItems = batchClassJob.TotalJobItems;
            jobWrapper.isRunning = true;
        }
    }

    public PageReference runAccountingJob() {
        this.initialTab = 2;
        loadSynchronizationStatus();

        if (this.syncRunningPhaseTwo == false && this.syncRunningPhaseOne == false) {
            saveServerSuccessfulDate();
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            settings.Job_Start_Date__c = Date.today();
            settings.Is_Job_Running__c = true;
            update settings;

            HQSyncUtils.runAccountingBatchJob(1, this.phaseTwoServer, new List<String>());
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot run synchronization job. Running instance was found already.'));
        }

        loadSynchronizationStatus();
        return null;
    }

    public void saveServerSuccessfulDate() {
        this.syncPhaseTwoDate = Date.today().addDays(-2);
        CommcareToSalesforceSettings__c serverSettings = CommcareToSalesforceSettings__c.getInstance(this.phaseTwoServer);
        if (serverSettings != null) {
            if (this.syncPhaseTwoDate != null
                    && ((serverSettings.Last_Run_Date__c != null && this.syncPhaseTwoDate <= serverSettings.Last_Run_Date__c)
                    || (serverSettings.Last_Run_Date__c == null))) {
                this.syncPhaseTwoDate = serverSettings.Last_Run_Date__c;
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load server settings.'));
        }
    }

    public void loadServerSuccessfulDate() {
        this.syncPhaseTwoDate = Date.today().addDays(-2);
        CommcareToSalesforceSettings__c serverSettings = CommcareToSalesforceSettings__c.getInstance(this.phaseTwoServer);
        if (serverSettings != null) {
            if (serverSettings.Last_Run_Date__c != null) {
                this.syncPhaseTwoDate = serverSettings.Last_Run_Date__c;
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load server settings.'));
        }
    }
}