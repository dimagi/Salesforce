/**
 * Batch for synchronization Domain custom object form Commcare HQ.
 */
public class HqBatchFetchDataDomains implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful {

    private hqInt_MainClass domainHelper;

    public HqBatchFetchDataDomains(String serverCode, List<String> nextServers) {
        this.serverCode = serverCode;
        this.nextServers = nextServers;
        this.serverSettings = CommcareToSalesforceSettings__c.getInstance(serverCode);
        this.successfullyLoadedRecords = 0;

        if (this.serverSettings == null) {
            throw new Exception('Cannot find settings for server with given code : ' + serverCode);
            // TODO
        }

        this.apiLimitParameter = this.serverSettings.API_Limit_Parameter__c != null ? this.serverSettings.API_Limit_Parameter__c
                            : 10;
        this.serverUrl = serverSettings.Server_URL__c;
        this.domainHelper = new hqInt_MainClass();
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
        try {
            this.domainHelper.mainMethod(offsetList[0]); // TODO
            this.successfullyLoadedRecords += apiLimitParameter;
        } catch(Exception e) {
            hqInt_BatchErrorLogger.logError(info.getJobId(), '\n failed at offset with limit param ' + this.apiLimitParameter
                            + ' : ' + String.valueOf(offsetList[0]), e.getMessage(), e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext info) {
        if(!Test.IsRunningTest()) {
            String subject = this.serverCode + ' - CommCare Salesforce Job Run Report - Domain, Internal Prop, Deployment';
            String emailBody = 'Total Successfully loaded domain records = ' + this.successfullyLoadedRecords + '\n\n';
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(), subject, emailBody);
        }
    }
}
