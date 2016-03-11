public with sharing class hqInt_MainClassBatch implements Database.Batchable<Integer>,Database.AllowsCallouts,Database.Stateful
{

    Integer apiLimitParameter = Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c);
    Integer successfullyLoadedRecords = 0;

    public Iterable<Integer> start(Database.BatchableContext BC) 
    {
        integer totalCount;
        integer totalBatches;

        try
        {
            hqInt_MainClass obj = new hqInt_MainClass();
            HTTPResponse res = obj.requestMethod(1,0);
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) 
    		{
            	if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total_count') 
                {
                    parser.nextToken();
                    totalCount = parser.getIntegerValue();
                    break;
                }
            }

        }
        catch(exception e)
        {
            if(e.getMessage().contains('Read timed out'))
            {
                hqInt_BatchErrorLogger.logError(BC.getJobId(),' hqInt_MainClassBatch Batch failed in start method',e.getMessage(),e.getStackTraceString());
                return null;
            }
        }

        list <Integer> listOffset = new list <Integer>();
        
        for(integer i=0;i <= totalCount/apiLimitParameter ; i++)
          listOffset.add(i*apiLimitParameter);     

        if(test.isRunningTest())  
        {
            listOffset = new list <integer>{0};
        }

        system.debug('---listoffset---'+listoffset);       
        
        return listOffset;
    }

    public void execute(Database.BatchableContext info, List<Integer> offsetList) 
    {
        
        try
        {
        	hqInt_MainClass obj = new hqInt_MainClass();
            obj.mainMethod(offsetList[0]);
            successfullyLoadedRecords += apiLimitParameter;
		}
        catch(exception e)
        {
            hqInt_BatchErrorLogger.logError(info.getJobId(),'\n failed at offset with limit param '+ apiLimitParameter +' : '+ string.valueOf(offsetList[0]),e.getMessage(),e.getStackTraceString());
        } 
        
    }

    public void finish(Database.BatchableContext info) 
    {
        
        String subject = 'CommCare Salesforce Job Run Report - Domain,Internal Prop, Deployment';
        String emailBody = 'Total Successfully loaded domain records = ' + successfullyLoadedRecords + '\n\n';
        
        if(info != null)
            hqInt_BatchErrorLogger.sendErrorEmails(info.getJobId(),subject,emailBody);
    }
}