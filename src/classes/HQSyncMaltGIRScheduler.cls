/**
 * Scheduler for GIR and Malt Tables data. It runs each 4th day in month. If there was errors, data will be loaded later.
 */
public class HQSyncMaltGIRScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Date currentDay = Date.today();
        Date lastMonth = Date.today().addMonths(-1).toStartOfMonth();

        if (currentDay.day() == 4) { // Run Malt Tables and GIR monthly sync
            scheduleJobs(false, lastMonth);
        } else if (currentDay.day() > 4) { // Check we had errors during sync, if we had errors we must run jobs with specific offsets
            if ([SELECT Count() FROM HQ_Sync_Error__c WHERE (Object_Type__c = 'Malt Tables' OR Object_Type__c = 'GIR') AND Date__c =: lastMonth] > 0) {
                scheduleJobs(true, lastMonth);
            }
        }
    }

    private void scheduleJobs(Boolean forErrors, Date executeDate) {
        List<String> servers = HQSyncUtils.getCommcareServers(false);
        if (servers.size() > 0) {
            String serverCode = servers.get(0);
            servers.remove(0);
            Database.executeBatch(new HQSyncMaltTablesBatch(executeDate, serverCode, servers, forErrors), 1);
        }
    }
}