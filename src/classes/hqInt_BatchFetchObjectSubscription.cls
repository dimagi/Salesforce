public class hqInt_BatchFetchObjectSubscription implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful
{
	Integer apiLimitParameter = Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c);
	String lastRunDate = CommcareToSalesforceSettings__c.getInstance('LastRunDate').Value__c;
    Integer successfullyLoadedRecords = 0;
    String objectUrl = 'https://www.commcarehq.org/hq/admin/api/global/subscription/';
	public integer batchNo;
	
	public hqInt_BatchFetchObjectSubscription(integer pbatchNo)
	{
		batchNo = pbatchNo;
	}
	public Iterable<Integer> start(Database.BatchableContext BC) 
    {
        integer totalCount;
        integer totalBatches;
        
        try
        {
            hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            totalCount = obj.fetchTotalCount(0,objectUrl,10,lastRunDate);
            
        }
        catch(exception e)
        {
        	hqInt_BatchErrorLogger.logError(BC.getJobId(),'\n '+Accounting_Subscription__c.SObjectType.getDescribe().getLabel()+' Batch failed in start method',e.getMessage(),e.getStackTraceString());	
        }
        system.debug('total Count of records found --'+ totalCount);
        list <Integer> listOffset = new list <Integer>();
        
        for(integer i=0;i <= totalCount/apiLimitParameter ; i++)
          listOffset.add(i*apiLimitParameter);     

        system.debug('---listoffset---'+listoffset);       
        
        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) 
    {
        try
        {
        	hqInt_BatchFetchObjectHelperClass obj = new hqInt_BatchFetchObjectHelperClass();
            integer successfullyLoadedRecordsThisBatch = obj.fetchAndInsertRecords(offsetList[0],objectUrl,apiLimitParameter,lastRunDate);
            successfullyLoadedRecords += successfullyLoadedRecordsThisBatch;
		}
        catch(exception e)
        {
            hqInt_BatchErrorLogger.logError(info.getJobId(),'\n Object : '+Accounting_Subscription__c.SObjectType.getDescribe().getLabel()+' failed at offset with limit param '+ apiLimitParameter +' : '+ string.valueOf(offsetList[0]),e.getMessage(),e.getStackTraceString());    
        } 
     }

    public void finish(Database.BatchableContext info) 
    {
        
        String subject = 'CommCare Salesforce Job Run Report - '+Accounting_Subscription__c.SObjectType.getDescribe().getLabel()+' Object';
        String emailBody = 'Total Successfully loaded '+ Accounting_Subscription__c.SObjectType.getDescribe().getLabel() +' records = ' + successfullyLoadedRecords + '\n\n';
        
        if(!test.IsRunningTest())
        {
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(),subject,emailBody);
            hqInt_BatchFetchObjectHelperClass.runNextBatch(batchNo+1);
        }
    }
}