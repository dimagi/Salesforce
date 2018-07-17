/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Pipeline_Snapshot_EV_DIff__c>, Database.Stateful {

    private Date helperDate;

    /**
     * Script code for removing wrong EV Diffs.
     */
    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public List<Pipeline_Snapshot_EV_DIff__c> start(Database.BatchableContext context) {
        return [SELECT Id FROM Pipeline_Snapshot_EV_DIff__c WHERE Pipeline_Snapshot__r.Stage__c = 'Core run rate'];
    }

    public void execute(Database.BatchableContext context, List<Pipeline_Snapshot_EV_DIff__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext context) {
    }
}