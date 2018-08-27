public class HQSyncController {

    public String phaseOneServer { get; set;}
    public String phaseTwoServer { get; set;}
    public List<SelectOption> serverCodes { get; set;}
    public Boolean domainIsRunning { get; set;}
    public Boolean accountingRunning { get; set;}

    public String batchSubmittedDate { get; set;}
    public AsyncApexJob batchClassJob { get; set;}
    public List<JobWrapper> phase2Jobs { get; set;}

    public HQSyncController() {
        List<String> values = HQSyncUtils.getCommcareServers(true);
        this.serverCodes = new List<SelectOption>();
        for (String val : values) {
            this.serverCodes.add(new SelectOption(val, val));
        }

        this.phaseOneServer = values[0];
        this.phaseTwoServer = values[0];

        fetchDomainInstances();
        fetchAccountingInstances();
    }

    /**
     * Domains synchronization.
     */
    public void fetchDomainInstances() {
        this.domainIsRunning = false;
        ApexClass batchClass;
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        if (settings.Is_Domain_Job_Running__c == true) {
            this.domainIsRunning = true;
            this.phaseOneServer = settings.Server_Code__c;
        }

        try {
            batchClass = [SELECT Id FROM ApexClass WHERE Name='HQSyncDomainBatch' LIMIT 1];
        } catch(exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Class not found'));
        }

        batchClassJob = null;
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            this.domainIsRunning = true;
            this.batchClassJob = batchClassJobList[0];
            this.batchSubmittedDate = batchClassJobList[0].createdDate.format();
        }
    }

    public PageReference runDomainsSynchronizationJob() {
        fetchDomainInstances();
        if(!this.domainIsRunning) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            settings.Is_Domain_Job_Running__c = true;
            update settings;
            Database.executeBatch(new HQSyncDomainBatch(this.phaseOneServer, null, new List<String>()), 1);
        }

        fetchDomainInstances();
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
        objectNames.add(Accounting_Invoice__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_LineItems__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditLine__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel());

        this.accountingRunning = false;
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        this.accountingRunning = settings.Is_Job_Running__c;
        String customObject = settings.Job_Helper_Field__c;
        this.phaseTwoServer = this.accountingRunning == true ? settings.Server_Code__c : this.phaseTwoServer;

        this.batchClassJob = null;
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate, ApexClass.Id, ApexClass.Name, Status, CompletedDate
                                            FROM AsyncApexJob
                                            WHERE ApexClass.Name = 'HQSyncAccountingBatch' AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
                                            ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            this.accountingRunning = true;
            this.batchClassJob = batchClassJobList[0];
        }

        phase2Jobs = new List<JobWrapper>();

        for (String jobName : objectNames) {
            JobWrapper jobWrapper = new jobWrapper();
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
        fetchAccountingInstances();

        if (this.accountingRunning == false) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            settings.Job_Start_Date__c = Date.today();
            settings.Is_Job_Running__c = true;
            update settings;

            HQSyncUtils.runAccountingBatchJob(1, this.phaseTwoServer, new List<String>());
        }

        fetchAccountingInstances();
        return null;
    }
}