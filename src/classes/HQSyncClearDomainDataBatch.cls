/**
 * Class for removing data from Domain tmp fields.
 */
public class HQSyncClearDomainDataBatch implements Database.Batchable<SObject>, Database.Stateful {

    public HQSyncClearDomainDataBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Forms_for_Period_TMP__c, Wam_TMP__c FROM Domain__c');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        for (SObject oDomain : scope) {
            Domain__c domain = (Domain__c) oDomain;
            domain.Forms_for_Period_TMP__c = 0;
            domain.Wam_TMP__c = 0;
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
    }
}