/**
* Weekly scheduled class to Sync Clockify data to Time Cards
**/
public class ClockifySyncScheduler implements Schedulable{
public void execute(SchedulableContext ctx) {
        Database.executeBatch(new ClockifySyncBatch(), 1);
    }
}