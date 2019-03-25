public class HQSyncUpdateDomainFieldsBatch implements Database.Batchable<SObject>, Database.Stateful{

    private Boolean upsertDomainSnapshot;
    private Map<String, Decimal> wamMap;
    private Map<String, Decimal> formsForPeriodMap;

    public HQSyncUpdateDomainFieldsBatch(Boolean upsertDomainSnapshot) {
        this.upsertDomainSnapshot = upsertDomainSnapshot;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        this.wamMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        this.formsForPeriodMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        return Database.getQueryLocator('SELECT Id, Name, Wam__c, Wam_TMP__c, Forms_for_Period__c, Forms_for_Period_TMP__c,'
                    + 'is_active__c, cpIsActive__c FROM Domain__c');
    }

    public void execute(Database.BatchableContext info, List<SObject> scope) {
        Map<Id, Domain__c> wamAndFormsDomains = new Map<Id, Domain__c>();
        for (SObject domainObj : scope) {
            Domain__c domain = (Domain__c) domainObj;
            domain.Wam__c = domain.Wam_TMP__c != null ? domain.Wam_TMP__c : 0;
            domain.Wam_TMP__c = 0;
            domain.Forms_for_Period__c = domain.Forms_for_Period_TMP__c != null ? domain.Forms_for_Period_TMP__c : 0;
            domain.Forms_for_Period_TMP__c = 0;

            if (domain.is_active__c == true && domain.cpIsActive__c == true) {
                wamAndFormsDomains.put(domain.Id, domain);
            }
        }

        update scope;

        for (Accounting_Subscription__c sub : [SELECT Id, Accounting_subscriber_domain__c, Software_Plan_Edition__c FROM Accounting_Subscription__c
               WHERE Accounting_subscriber_domain__c IN: wamAndFormsDomains.keySet() AND is_active__c = true AND Software_Plan_Edition__c IN: this.wamMap.keySet()]) {

            Domain__C domain = wamAndFormsDomains.get(sub.Accounting_subscriber_domain__c);
            this.wamMap.put(sub.Software_Plan_Edition__c, this.wamMap.get(sub.Software_Plan_Edition__c)
                    + (domain.Wam__c != null ? domain.Wam__c : 0));
            this.formsForPeriodMap.put(sub.Software_Plan_Edition__c, this.formsForPeriodMap.get(sub.Software_Plan_Edition__c)
                    + (domain.Forms_for_Period__c != null ? domain.Forms_for_Period__c : 0));
        }
    }

    public void finish(Database.BatchableContext info) {
        List<HQ_Sync_Error__c> errors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'Malt Tables' OR Object_Type__c = 'GIR'];
        if (errors.size() > 0) {
            delete errors;
        }

        if (this.upsertDomainSnapshot) {
            Date snpDate = Date.today().toStartOfMonth().addDays(-1);
            for (String key : this.wamMap.keySet()) {
                List<Domain_Monthly_Snapshot__c> snpList = [SELECT Id, Wam__c, Forms_for_Period__c FROM Domain_Monthly_Snapshot__c WHERE Snapshot_Date__c =: snpDate AND Software_Plan_Edition__c =: key];
                Domain_Monthly_Snapshot__c snapshot = new Domain_Monthly_Snapshot__c(Software_Plan_Edition__c = key, Snapshot_Date__c = snpDate);
                if (snpList.size() > 0) {
                    snapshot = snpList.get(0);
                }
                snapshot.Wam__c = this.wamMap.get(key);
                snapshot.Forms_for_Period__c = this.formsForPeriodMap.get(key);
                upsert snapshot;
            }
        }
    }
}