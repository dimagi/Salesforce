public class HQSyncUpdateDomainFieldsBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Boolean upsertDomainSnapshot;
    private Map<String, Decimal> dataMap;
    private HQSyncDomainFieldUpdater fieldHelper;
    private Date snpDate;

    public HQSyncUpdateDomainFieldsBatch(Boolean upsertDomainSnapshot, HQSyncDomainFieldUpdater fieldHelper) {
        this.upsertDomainSnapshot = upsertDomainSnapshot;
        this.fieldHelper = fieldHelper;
        this.snpDate = Date.today().toStartOfMonth().addDays(-1);
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
        this.dataMap = new Map<String, Decimal> { 'Advanced' => 0, 'Community' => 0, 'Enterprise' => 0, 'Standard' => 0, 'Pro' => 0};
        return Database.getQueryLocator('SELECT Id, Name, Wam__c, Wam_TMP__c, Forms_for_Period__c, Forms_for_Period_TMP__c,'
                    + 'is_active__c, cpIsActive__c FROM Domain__c');
    }

    public void execute(Database.BatchableContext info, List<SObject> scope) {
        Map<Id, Domain_Monthly_Snapshot__c> snpMap = new Map<Id, Domain_Monthly_Snapshot__c>();
        for (Domain_Monthly_Snapshot__c snp : [SELECT Id, Wam__c, Forms_for_Period__c, Domain__c FROM Domain_Monthly_Snapshot__c
                                               WHERE Snapshot_Date__c =: snpDate AND Domain__c IN: scope]) {
            snpMap.put(snp.Domain__c, snp);
        }

        List<Domain_Monthly_Snapshot__c> updateList = new List<Domain_Monthly_Snapshot__c>();
        for (SObject domainObj : scope) {
            Domain__c domain = (Domain__c) domainObj;
            this.fieldHelper.updateSyncField(domain);
            if (snpMap.containsKey(domain.Id)) {
                Domain_Monthly_Snapshot__c snp = snpMap.get(domain.Id);
                this.fieldHelper.updateSyncField(domain, snp);
                updateList.add(snp);
            }
        }

        update scope;
        update updateList;
    }

    public void finish(Database.BatchableContext info) {
        String syncObject = this.fieldHelper.getSyncFieldName() == HQSyncUtils.GIR ? 'GIR' : 'Malt Tables';
        List<HQ_Sync_Error__c> errors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c =: syncObject];
        if (errors.size() > 0) {
            delete errors;
        }
    }
}