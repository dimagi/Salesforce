/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Stage__c, Month_Date__c, Opportunity__c, Submitted_this_month__c FROM Pipeline_Snapshot__c WHERE Source_Type__c = \'Opportunity\' AND Month_Date__c =: helperDate');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Pipeline_Snapshot__c> toUpdate = new List<Pipeline_Snapshot__c>();
        for (SObject objRec : scope) {
            Pipeline_Snapshot__c ps = (Pipeline_Snapshot__c) objRec;
            ps.Submitted_this_month__c = OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps);
            toUpdate.add(ps);
        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}