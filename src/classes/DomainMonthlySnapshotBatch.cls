public class DomainMonthlySnapshotBatch implements Database.Batchable<Accounting_Subscription__c>, Database.Stateful {

    private Map<String, Decimal> wamMap;
    private Map<String, Decimal> formsMap;
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
        this.wamMap = new Map<String, Decimal> { 'Empty' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.formsMap = new Map<String, Decimal> { 'Empty' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.mobileUsersMap = new Map<String, Decimal> { 'Empty' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.recordCountMap = new Map<String, Decimal> { 'Empty' => 0, 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.error = false;
        this.settings = BatchDefaultSettings__c.getOrgDefaults();
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) { // We cannot group by formula field
       return [SELECT Id, Software_Plan_Edition__c, Accounting_subscriber_domain__r.Wam__c, Accounting_subscriber_domain__r.cpActiveMobileUsers__c, service_type__c,
               Accounting_subscriber_domain__r.cpAllForms__c, Accounting_subscriber_domain__r.InternalProp_self_started__c FROM Accounting_Subscription__c
               WHERE is_trial__c = false AND is_active__c = true AND Accounting_subscriber_domain__c != null AND
               Accounting_subscriber_domain__r.Likely_Real__c = true AND Accounting_subscriber_domain__r.is_test__c != 'true' AND
               Accounting_subscriber_domain__r.cpIsActive__c = true];
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> scope) {
        try {
            for (Accounting_Subscription__c sub : scope) {
                String softwarePlan = sub.Software_Plan_Edition__c;
                if (softwarePlan == '' || softwarePlan == null || softwarePlan == '-') {
                    softwarePlan = 'Empty';
                }

                this.wamMap.put(softwarePlan, wamMap.get(softwarePlan) + (sub.Accounting_subscriber_domain__r.Wam__c != null ? sub.Accounting_subscriber_domain__r.Wam__c : 0));
                this.formsMap.put(softwarePlan, formsMap.get(softwarePlan) + (sub.Accounting_subscriber_domain__r.cpAllForms__c != null ? sub.Accounting_subscriber_domain__r.cpAllForms__c : 0));
                this.mobileUsersMap.put(softwarePlan, mobileUsersMap.get(softwarePlan) + (sub.Accounting_subscriber_domain__r.cpActiveMobileUsers__c != null ? sub.Accounting_subscriber_domain__r.cpActiveMobileUsers__c : 0));
                if ((sub.service_type__c == 'Self_service' || sub.service_type__c == 'Product') && sub.Accounting_subscriber_domain__r.InternalProp_self_started__c == true) {
                    this.recordCountMap.put(softwarePlan, recordCountMap.get(softwarePlan) + 1);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(this.settings.Error_Emails__c.split(','), 'Cannot calculate monthy Domain Snapshots',
                                    'Error : ', e);
            }
            this.error = true;
            //throw e; // we want stop calculations and fix problems
        }
    }

    public void finish(Database.BatchableContext context) {
        try {
            if (error == false) {
                List<Domain_Monthly_Snapshot__c> snapshots = new List<Domain_Monthly_Snapshot__c>();
                for (String key : recordCountMap.keySet()) {
                    Domain_Monthly_Snapshot__c snapshot = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = key, Snapshot_Date__c = this.currentDate,
                                                                Wam__c = wamMap.get(key), Forms__c = formsMap.get(key), Active_Mobile_Users__c = mobileUsersMap.get(key),
                                                                Scale_of_Programs__c = recordCountMap.get(key));
                    snapshots.add(snapshot);
                }
                insert snapshots;
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(this.settings.Error_Emails__c.split(','), 'Cannot calculate monthy Domain Snapshots',
                                    'Error : ', e);
            }
        }
    }
}