public class HQSyncAccountingBatch extends HQSyncBatch {

    private Integer batchNo;
    private String customObject;
    private HQSyncDataProcessor dataProcessor;

    public HQSyncAccountingBatch(Integer batchNo, String customObject, HQSyncDataProcessor dataProcessor, String serverCode, String urlSuffix, List<String> nextServers) {
        super(serverCode, null, nextServers, urlSuffix, StatusLoggerUtils.HQ_SYNC_LOGGER, customObject.replaceAll('__c', ''));
        this.customObject = customObject;
        this.batchNo = batchNo;
        this.dataProcessor = dataProcessor;

        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        settings.Server_Code__c = serverCode;
        settings.Job_Helper_Field__c = customObject;
        update settings;

        String lastRunDate = this.serverSettings.Last_Run_Date__c != null ?  this.serverSettings.Last_Run_Date__c.year() + '-' + this.serverSettings.Last_Run_Date__c.month() + '-'
                                                    + this.serverSettings.Last_Run_Date__c.day() : '1990-1-1';
        this.parameters.put('last_modified__gte', lastRunDate);
    }

    public override void finish(Database.BatchableContext info) {
        if (this.batchNo >= 16 && StatusLoggerUtils.errorsForLoggerWithoutTitle(StatusLoggerUtils.HQ_SYNC_LOGGER, 'Domain')) { // If there was an error we don't want update last sync date
            this.serverSettings.Last_Run_Date__c = Commcare_Job_Settings__c.getOrgDefaults().Job_Start_Date__c;
            update this.serverSettings;
        }

        StatusLoggerUtils.logInfo(StatusLoggerUtils.HQ_SYNC_LOGGER, this.jobName, this.addedRecords, 'Finished accounting synchronization for server - ' + this.serverName);
        if(!Test.IsRunningTest()) {
            HQSyncUtils.runAccountingBatchJob(this.batchNo + 1, this.serverName, this.servers);
        }
    }

    protected override Integer processJSON(String jsonString) {
        return dataProcessor.processJSON(jsonString, this.serverName);
    }

    protected override void handleError(Exception e, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_LOGGER, this.jobName, offset, this.serverName + ' - ' + e.getMessage());
    }
}