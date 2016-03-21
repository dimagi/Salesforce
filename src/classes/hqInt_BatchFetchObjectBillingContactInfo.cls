public class hqInt_BatchFetchObjectBillingContactInfo implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful {

    private Integer apiLimitParameter = Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c);
    private String lastRunDate = CommcareToSalesforceSettings__c.getInstance('LastRunDate').Value__c;
    private Integer successfullyLoadedRecords = 0;
    private String objectUrl = 'https://www.commcarehq.org/hq/admin/api/global/billing_contact_info/';
    private String jobRunDate;

    public Date processStartDate;
    public integer batchNo;

    public hqInt_BatchFetchObjectBillingContactInfo(Integer pbatchNo) {
        this.batchNo = pbatchNo;
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        Integer totalCount;
        Integer totalBatches;
        try {
            hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            totalCount = obj.fetchTotalCount(0, objectUrl, 10, lastRunDate);
        } catch(exception e) {
            hqInt_BatchErrorLogger.logError(BC.getJobId(), '\n ' + Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel()
                                                + ' Batch failed in start method', e.getMessage(), e.getStackTraceString());
        }

        System.debug('total Count of records found --' + totalCount);
        List<Integer> listOffset = new List<Integer>();

        for(integer i=0;i <= totalCount/apiLimitParameter; i++) {
          listOffset.add(i * apiLimitParameter);
        }

        System.debug('---listoffset---' + listoffset);

         if(test.isRunningTest()) {
            listOffset = new list <integer>{0};
         }
 
        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
        try {
            hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            Integer successfullyLoadedRecordsThisBatch = obj.fetchAndInsertRecords(offsetList[0], objectUrl, apiLimitParameter, lastRunDate);
            successfullyLoadedRecords += successfullyLoadedRecordsThisBatch;
        } catch(Exception e) {
            System.debug('Error has occured' + e.getMessage());
            hqInt_BatchErrorLogger.logError(info.getJobId(), '\n Object : ' + Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel()
                                                + ' failed at offset with limit param ' +  apiLimitParameter + ' : ' +  String.valueOf(offsetList[0]),
                                                e.getMessage(), e.getStackTraceString());
        } 
     }

    public void finish(Database.BatchableContext info) {
        String subject = 'CommCare Salesforce Job Run Report - ' + Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel()
                            + ' Object';
        String emailBody = 'Total Successfully loaded ' + Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel() + ' records = '
                            + successfullyLoadedRecords + '\n\n';

        if(!test.isRunningTest()) {
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(), subject, emailBody);
            hqInt_BatchFetchObjectHelperClass.runNextBatch(batchNo + 1);
        }
    }
}