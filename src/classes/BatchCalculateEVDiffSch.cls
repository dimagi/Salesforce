/**
 * Calculates NetDiff for Closed opps in last month (Pipeline Snapshot wasn't created).
 * TODO: Rename
 */
public class BatchCalculateEVDiffSch implements Schedulable {

    public BatchCalculateEVDiffSch() {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityPipelineSnapshotBatch());
    }
}