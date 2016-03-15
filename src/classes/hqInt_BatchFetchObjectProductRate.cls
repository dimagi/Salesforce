public class hqInt_BatchFetchObjectProductRate implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    private Integer apiLimitParameter = Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c);
    private String lastRunDate = CommcareToSalesforceSettings__c.getInstance('LastRunDate').Value__c;
    private Integer successfullyLoadedRecords = 0;
    private String objectUrl = 'https://www.commcarehq.org/hq/admin/api/global/software_product_rate/';
    public Integer batchNo;

    public hqInt_BatchFetchObjectProductRate(integer pbatchNo) {
        batchNo = pbatchNo;
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        Integer totalCount;
        Integer totalBatches;

        try {
            hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            totalCount = obj.fetchTotalCount(0, objectUrl, 10, lastRunDate);
        } catch(exception e) {
            hqInt_BatchErrorLogger.logError(BC.getJobId(), '\n ' + Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel() + ' Batch failed in start method', e.getMessage(), e.getStackTraceString());
        }

        System.debug('total Count of records found --' + totalCount);
        List<Integer> listOffset = new List<Integer>();

        for (Integer i = 0; i <= totalCount / apiLimitParameter; i++) {
          listOffset.add(i * apiLimitParameter);
        }

        System.debug('---listoffset---' + listoffset);

        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) {
        try {
            hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            integer successfullyLoadedRecordsThisBatch = obj.fetchAndInsertRecords(offsetList[0],objectUrl, apiLimitParameter, lastRunDate);
            successfullyLoadedRecords += successfullyLoadedRecordsThisBatch;
        } catch(exception e) {
           System.debug('--info--'+info);
           System.debug('--offsetList--'+offsetList);

            if(info !=null && offsetlist !=null) {
                hqInt_BatchErrorLogger.logError(info.getJobId(), '\n Object : ' + Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel() + ' failed at offset with limit param '
                    + apiLimitParameter + ' : ' + string.valueOf(offsetList[0]), e.getMessage(), e.getStackTraceString());
            }
        }
     }

    public void finish(Database.BatchableContext info) {
        String subject = 'CommCare Salesforce Job Run Report - '+ Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel()+' Object';
        String emailBody = 'Total Successfully loaded '+ Accounting_SoftwareProductRate__c.SObjectType.getDescribe().getLabel()+' records = ' + successfullyLoadedRecords + '\n\n';

        if(!test.isRunningTest()) {
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(),subject,emailBody);
            hqInt_BatchFetchObjectHelperClass.runNextBatch(batchNo+1);
        }
    }
}