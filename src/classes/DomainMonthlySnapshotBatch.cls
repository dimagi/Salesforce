public class DomainMonthlySnapshotBatch implements Database.Batchable<Accounting_Subscription__c>, Database.Stateful {

    private Map<String, Decimal> wamMap;
    private Map<String, Decimal> formsMap;
    private Map<String, Decimal> formsForPeriodMap;
    private Map<String, Decimal> mobileUsersMap;
    private Map<String, Decimal> recordCountMap;
    private Date currentDate;
    private Boolean error;
    private BatchDefaultSettings__c settings;

    public DomainMonthlySnapshotBatch() {
        this(Date.today());
    }

    public DomainMonthlySnapshotBatch(Date currentDate) {
        this.currentDate = currentDate;
        this.wamMap = new Map<String, Decimal> { 'Reseller' => 0, 'Managed Hosting' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.formsMap = new Map<String, Decimal> { 'Reseller' => 0, 'Managed Hosting' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.mobileUsersMap = new Map<String, Decimal> { 'Reseller' => 0, 'Managed Hosting' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.recordCountMap = new Map<String, Decimal> { 'Reseller' => 0, 'Managed Hosting' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.formsForPeriodMap = new Map<String, Decimal> { 'Reseller' => 0, 'Managed Hosting' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.error = false;
        this.settings = BatchDefaultSettings__c.getOrgDefaults();
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) { // We cannot group by formula field
       return [SELECT Id, Created_By__c, Accounting_subscriber_domain__c, Software_Plan_Edition__c, Accounting_subscriber_domain__r.Wam__c, Accounting_subscriber_domain__r.cpActiveMobileUsers__c, service_type__c,
               Accounting_subscriber_domain__r.cpAllForms__c, Accounting_subscriber_domain__r.InternalProp_self_started__c FROM Accounting_Subscription__c
               WHERE is_trial__c = false AND is_active__c = true AND Accounting_subscriber_domain__c != null AND
               Accounting_subscriber_domain__r.Likely_Real__c = true AND Accounting_subscriber_domain__r.is_test__c != 'true' AND
               Accounting_subscriber_domain__r.cpIsActive__c = true];
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> scope) {
        // TO generate Domain Monthly Snapshot we are using DomainSnapshotFromHistoryBatch, we need deleted this class from production
    }

    public void finish(Database.BatchableContext context) {

    }
}