/**
 * Batch for synchronization Domain custom object form Commcare HQ.
 */
public class HqBatchFetchDataDomains implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    private HqDomainProcessHelper domainHelper;
    private CommcareToSalesforceSettings__c serverSettings;
    private Integer successfullyLoadedRecords;
    private Integer apiLimitParameter;
    private List<String> nextServers;
    private String serverCode;

    public HqBatchFetchDataDomains(String serverCode, List<String> nextServers) {
        this.serverCode = serverCode;
        this.nextServers = nextServers;
        this.serverSettings = CommcareToSalesforceSettings__c.getInstance(serverCode);
        this.successfullyLoadedRecords = 0;

        if (this.serverSettings == null) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
            EmailHelper.sendEmail(settings.Error_Emails__c.split(','), 'Commcare sync Error', 'Cannot find server settings with name : ' + this.serverCode);
            HqBatchJobHelper.endDomainJob();
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Cannot find settings for server with given code : ' + serverCode);
            throw ex;
        }

        this.apiLimitParameter = this.serverSettings.API_Limit_Parameter__c != null ? Integer.valueOf(this.serverSettings.API_Limit_Parameter__c)
                            : 10;
        this.domainHelper = new HqDomainProcessHelper(this.serverSettings);
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        Integer totalCount = this.domainHelper.getTotalCount();
        List <Integer> listOffset = new List <Integer>();
        for(Integer i = 0;i <= totalCount / apiLimitParameter; i++) {
            listOffset.add(i * apiLimitParameter);
        }
        if(Test.isRunningTest()) {
            listOffset = new List<Integer>{0};
        }

        System.debug('listOffset: ' + listOffset);

        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
        try {
            this.successfullyLoadedRecords += this.domainHelper.processDomains(offsetList[0]);
        } catch(Exception e) {
            System.debug('Failed at offset with limit param ' + this.apiLimitParameter);
            System.debug(e.getMessage());
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

        if (nextServers.size() > 0) {
            String nextServer = nextServers.get(0);
            nextServers.remove(0);
            Database.executeBatch(new HqBatchFetchDataDomains(nextServer, nextServers), 1);
        } else {
            HqBatchJobHelper.endDomainJob();
        }
    }
}