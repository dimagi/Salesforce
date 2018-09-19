public class DomainMonthlySnapshotBatch implements Database.Batchable<Accounting_Subscription__c>, Database.Stateful {

    private Map<String, Decimal> formsMap;
    private Map<String, Decimal> mobileUsersMap;
    private Map<String, Decimal> recordCountMap;
    private Date currentDate;
    private Boolean error;
    private Boolean additionalFilters;
    private BatchDefaultSettings__c settings;

    private Set<String> domainsToSkip;

    public DomainMonthlySnapshotBatch() {
        this(Date.today());
    }

        public DomainMonthlySnapshotBatch(Date currentDate) {
        this(currentDate, false);
    }

    public DomainMonthlySnapshotBatch(Date currentDate, Boolean additionalFilters) {
        this.additionalFilters = additionalFilters;
        this.domainsToSkip = new Set<String>();
        this.currentDate = currentDate;
        this.formsMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.mobileUsersMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.recordCountMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.error = false;
        this.settings = BatchDefaultSettings__c.getOrgDefaults();
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) { // We cannot group by formula field
        if (!this.additionalFilters) {
            return [SELECT Id, Created_By__c, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name, Accounting_subscriber_domain__r.Server_Name__c,
               Software_Plan_Edition__c, Accounting_subscriber_domain__r.Wam__c, Accounting_subscriber_domain__r.cpActiveMobileUsers__c, service_type__c,
               Accounting_subscriber_domain__r.cpAllForms__c, Accounting_subscriber_domain__r.InternalProp_self_started__c FROM Accounting_Subscription__c
               WHERE is_trial__c = false AND is_active__c = true AND Accounting_subscriber_domain__c != null AND
               Accounting_subscriber_domain__r.Likely_Real__c = true AND Accounting_subscriber_domain__r.is_test__c != 'true' AND
               Accounting_subscriber_domain__r.cpIsActive__c = true];
       }
       return [SELECT Id, Created_By__c, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name, Accounting_subscriber_domain__r.Server_Name__c,
           Software_Plan_Edition__c, Accounting_subscriber_domain__r.Wam__c, Accounting_subscriber_domain__r.cpActiveMobileUsers__c, service_type__c,
           Accounting_subscriber_domain__r.cpAllForms__c, Accounting_subscriber_domain__r.InternalProp_self_started__c FROM Accounting_Subscription__c
           WHERE is_trial__c = false AND is_active__c = true AND Accounting_subscriber_domain__c != null AND
           Accounting_subscriber_domain__r.Likely_Real__c = true AND Accounting_subscriber_domain__r.is_test__c != 'true' AND
           Accounting_subscriber_domain__r.cpIsActive__c = true AND Accounting_subscriber_domain__r.InternalProp_self_started__c = true AND
           (service_type__c = 'Self_service' OR service_type__c = 'Product')];
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> scope) {
        try {
            for (Accounting_Subscription__c sub : scope) {
                String softwarePlan = sub.Software_Plan_Edition__c;
                if (softwarePlan == null || softwarePlan == '' || softwarePlan == '-' || softwarePlan == 'Reseller' || softwarePlan == 'Managed Hosting'
                        || domainsToSkip.contains(sub.Accounting_subscriber_domain__r.Server_Name__c + '-' + sub.Accounting_subscriber_domain__r.Name)) {
                     continue; // we want skip empty plan or incorrect plan or duplicated domains
                }

                this.formsMap.put(softwarePlan, formsMap.get(softwarePlan) + (sub.Accounting_subscriber_domain__r.cpAllForms__c != null ? sub.Accounting_subscriber_domain__r.cpAllForms__c : 0));
                this.mobileUsersMap.put(softwarePlan, mobileUsersMap.get(softwarePlan) + (sub.Accounting_subscriber_domain__r.cpActiveMobileUsers__c != null ? sub.Accounting_subscriber_domain__r.cpActiveMobileUsers__c : 0));
                this.recordCountMap.put(softwarePlan, recordCountMap.get(softwarePlan) + 1);

                this.domainsToSkip.add(sub.Accounting_subscriber_domain__r.Server_Name__c + '-' + sub.Accounting_subscriber_domain__r.Name);
                // we want avoid duplicated data if for example domain will have incorrect 2 active subscription
            }
        } catch (Exception e) {
            this.error = true;
            System.debug('Exception : ' + e.getMessage());
            StatusLoggerUtils.logError(StatusLoggerUtils.DOMAIN_SNP_LOGGER, 'Cannot calculate domain snapshot records', 0, e.getMessage());
        }
    }

    public void finish(Database.BatchableContext context) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.DOMAIN_SNP_LOGGER, 'Domain Snapshot', 0, 'Finished Domain Snapshot Job');

        try {
            if (this.error == false) {
                List<Domain_Monthly_Snapshot__c> snapshots = new List<Domain_Monthly_Snapshot__c>();
                for (String key : recordCountMap.keySet()) {
                    Domain_Monthly_Snapshot__c snapshot = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = key, Snapshot_Date__c = this.currentDate, Forms__c = this.formsMap.get(key),
                                                                Wam__c = 0, Forms_for_Period__c = 0, Active_Mobile_Users__c = this.mobileUsersMap.get(key),
                                                                Scale_of_Programs__c = this.recordCountMap.get(key)); // Wams nad Forms for period are calculated later by HQSync
                    snapshots.add(snapshot);
                }
                insert snapshots;
            }
        } catch (Exception e) {
            StatusLoggerUtils.logError(StatusLoggerUtils.DOMAIN_SNP_LOGGER, 'Cannot save domain snapshot records', 0, e.getMessage());
        }

        if (!Test.isRunningTest()) {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.DOMAIN_SNP_LOGGER,  BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
     }
}