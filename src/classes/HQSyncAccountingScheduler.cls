/**
 * Schedules Commcare Accounting synchronization from many servers.
 */
public class HQSyncAccountingScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        HQSyncUtils.startAccountingJobs();
    }
}