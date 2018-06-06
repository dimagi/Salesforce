public class GenericErrorMessangerScheduler implements Schedulable {

    public GenericErrorMessangerScheduler() {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GenericErrorMessangerBatch());
    }
}