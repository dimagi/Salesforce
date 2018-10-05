/**
 * Schedules TimeCardCaseUpdateBatch and then TimeCardCalculator
 */
public class TimeCardCalculatorScheduler implements Schedulable {

    public TimeCardCalculatorScheduler () {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TimeCardCaseUpdateBatch(), 1);
    }
}