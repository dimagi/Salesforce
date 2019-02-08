public class ContractPipelineSnapshotScheduler implements Schedulable {

    public ContractPipelineSnapshotScheduler() {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ContractPipelineSnapshotBatch(), 5);
    }
}