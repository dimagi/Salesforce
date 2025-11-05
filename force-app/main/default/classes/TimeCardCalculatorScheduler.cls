/**
 * Schedules TimeCardCalculator // 4/25/2022 removed the TimeCardCaseUpdateBatch from the schedule
 */
public class TimeCardCalculatorScheduler implements Schedulable {

    public TimeCardCalculatorScheduler () {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TimeCardCalculator());
    }
}