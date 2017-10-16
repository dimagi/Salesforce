public class AggregateExecutionEfficiencyScheduler implements Schedulable {

    public AggregateExecutionEfficiencyScheduler  () {}

    public void execute(SchedulableContext sc) {
       AggregateExecutionEfficiencySnpJob.createAggregateExecutionEfficiencySnapshot();
    }
}