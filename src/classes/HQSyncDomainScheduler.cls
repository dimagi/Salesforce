/**
 * Schedules Commcare Domains synchronization from many servers.
 */
 public class HQSyncDomainScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        HQSyncUtils.startDomainJob();
    }
}