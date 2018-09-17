public class HQSyncUpdateDomainFieldsBatch implements Database.Batchable<Domain__c>, Database.Stateful{

    private Boolean runDomainSnapshot;

    public HQSyncUpdateDomainFieldsBatch(Boolean runDomainSnapshot) {
        this.runDomainSnapshot = runDomainSnapshot;
    }

    public List<Domain__c> start(Database.BatchableContext BC) {
        return [SELECT Id, Name, Wam__c, Wam_TMP__c, Forms_for_Period__c, Forms_for_Period_TMP__c FROM Domain__c];
    }

    public void execute(Database.BatchableContext info, List<Domain__c> scope) {
        for (Domain__c domain : scope) {
            domain.Wam__c = domain.Wam_TMP__c != null ? domain.Wam_TMP__c : 0;
            domain.Wam_TMP__c = 0;
            domain.Forms_for_Period__c = domain.Forms_for_Period_TMP__c != null ? domain.Forms_for_Period_TMP__c : 0;
            domain.Forms_for_Period_TMP__c = 0;
        }
        update scope;
    }

    public void finish(Database.BatchableContext info) {
        List<HQ_Sync_Error__c> errors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'Malt Tables' OR Object_Type__c = 'GIR'];
        if (errors.size() > 0) {
            delete errors;
        }

        if (this.runDomainSnapshot) {
            Date snpDate = Date.today().toStartOfMonth().addDays(-1);
            Database.executeBatch(new DomainSnapshotFromHistoryBatch(snpDate));
        }
    }
}