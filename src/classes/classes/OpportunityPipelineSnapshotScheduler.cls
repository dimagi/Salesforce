public class OpportunityPipelineSnapshotScheduler implements Schedulable {

    public OpportunityPipelineSnapshotScheduler() {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(), 5);
    }
}