public class RedFormReminderScheduler implements Schedulable {

    public RedFormReminderScheduler() {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RedFormReminderBatch(false));
    }
}