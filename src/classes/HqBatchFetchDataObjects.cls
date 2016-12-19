/**
 * Batch for synchronization Accounting custom objects form Commcare HQ.
 */
public class HqBatchFetchDataObjects implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    public static final String EMAIL_SUBJECT = 'CommCare Salesforce Job Run Report - ';

    public Integer batchNo;
    private String serverUrl;
    private CommcareToSalesforceSettings__c serverSettings;
    private String customObject;
    private Integer successfullyLoadedRecords;
    private String lastRunDate;
    private Integer apiLimitParameter;
    private hqInt_BatchFetchObjectHelperClass hqHelper;
    private List<String> nextServers;
    private String serverCode;

    public HqBatchFetchDataObjects(Integer batchNo, String customObject, String serverCode, String urlSuffix, List<String> nextServers) {
        this.serverCode = serverCode;
        this.nextServers = nextServers;
        this.serverSettings = CommcareToSalesforceSettings__c.getInstance(serverCode);
        this.batchNo = batchNo;
        this.customObject = customObject;
        this.successfullyLoadedRecords = 0;

        if (this.serverSettings == null) {
            throw new Exception('Cannot find settings for server with given code : ' + serverCode);
            // TODO
        }

        this.lastRunDate = this.serverSettings.Last_Run_Date__c != null ?  this.serverSettings.Last_Run_Date__c.format('yyyy-MM-dd')
                            : Date.newInstance(1990, 1, 1).format('yyyy-MM-dd');
        this.apiLimitParameter = this.serverSettings.API_Limit_Parameter__c != null ? this.serverSettings.API_Limit_Parameter__c
                            : 10;
        this.serverUrl = serverSettings.Server_URL__c + urlSuffix;
        this.hqHelper = new hqInt_BatchFetchObjectHelperClass();
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        Integer totalCount;
        Integer totalBatches;

        try {
            totalCount = this.hqHelper.fetchTotalCount(0, objectUrl, 10, lastRunDate);
        } catch(Exception e) {
            hqInt_BatchErrorLogger.logError(BC.getJobId(), '\n ' + this.customObject + ' Batch failed in start method', e.getMessage(),
                                            e.getStackTraceString());
        }

        System.debug('total Count of records found --'+ totalCount);
        List<Integer> listOffset = new List<Integer>();

        for(Integer i = 0; i <= totalCount / this.apiLimitParameter; i++) {
          listOffset.add(i * this.apiLimitParameter);
        }

        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
        try {
            Integer successfullyLoadedRecordsThisBatch = this.hqHelper.fetchAndInsertRecords(offsetList[0], this.serverUrl,
                                                                                             this.apiLimitParameter, this.lastRunDate);
            successfullyLoadedRecords += successfullyLoadedRecordsThisBatch;
        } catch(Exception e) {
            hqInt_BatchErrorLogger.logError(info.getJobId(), '\n Object : ' + this.customObject + ' failed at offset with limit param '
                    + this.apiLimitParameter +' : '+ String.valueOf(offsetList[0]), e.getMessage(), e.getStackTraceString());
        } 
     }

    public void finish(Database.BatchableContext info)  {
        if(!Test.IsRunningTest()) {
            String subject = this.serverCode + ' - ' + EMAIL_SUBJECT + this.customObject + ' Object';
            String emailBody = 'Total Successfully loaded ' + this.customObject + ' records = ' + successfullyLoadedRecords + '\n\n';
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(), subject, emailBody);
            HqBatchJobHelper.runNextBatchJob(this.batchNo + 1, this.serverCode, this.nextServers);
        }
    }
}