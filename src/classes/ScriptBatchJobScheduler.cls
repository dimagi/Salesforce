public class ScriptBatchJobScheduler implements Schedulable {

    public ScriptBatchJobScheduler() {
        
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ScriptBatchJob(null));
    }
}