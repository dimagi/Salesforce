/**
 * Schedules Commcare Domains synchronization from many servers.
 */
 public class HQSyncDomainScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        deleteDuplicatedDomainSnapshot();
        HQSyncUtils.startDomainJob();
    }

    public static void deleteDuplicatedDomainSnapshot() {
        Date currentDate = Date.today();
        Date lastMonth = Date.today().toStartOfMonth().addDays(-1);
        HQSyncUtils.deleteDuplicatedDomainSnapshot(lastMonth);
    }
}