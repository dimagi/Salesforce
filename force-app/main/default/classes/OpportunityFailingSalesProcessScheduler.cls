public class OpportunityFailingSalesProcessScheduler implements Schedulable {

    public OpportunityFailingSalesProcessScheduler  () {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new OpportunityFailingSalesProcessBatch(), 10);
    }
}