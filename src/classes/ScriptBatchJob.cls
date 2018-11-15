/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Domain__c>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public List<Domain__c> start(Database.BatchableContext context) {
        return [SELECT Id, Forms_for_Period__c, Forms_for_Period_TMP__c, Wam__c, Wam_TMP__c FROM Domain__c];
    }

    public void execute(Database.BatchableContext context, List<Domain__c> scope) {
        for (Domain__c dom : scope) {
            dom.Forms_for_Period_TMP__c = dom.Forms_for_Period__c;
            dom.Wam_TMP__c = dom.Wam__c;
        }

        update scope;
    }

    public void finish(Database.BatchableContext context) {

    }
}