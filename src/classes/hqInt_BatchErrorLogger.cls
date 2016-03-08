public class hqInt_BatchErrorLogger 
{
	public static void sendErrorEmails(String batchId, String subject, String body)
	{
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
        String[] toAddresses = CommcareToSalesforceSettings__c.getInstance('BatchFailureReportRecepeint').Value__c.split(';');

        // Sets the paramaters of the email
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        String emailBody = '';
        if(String.isNotBlank(body))
        	emailBody = body;
		
		Boolean topRowInserted = false;
        emailBody += '<br/><br/><br/><table border="1">';
        
        for(Batch_Error_Logs__c batchErrorLog : [SELECT id,Details__c,Error_Message__c,Stack_Trace_String__c FROM Batch_Error_Logs__c WHERE Batch_Id__c = :batchId])
        {
        	if(!topRowInserted)
        	{
        		emailBody += '<tr style="font-weight:bold"><td>Batch Id</td><td>Details</td><td>Error Message</td><td>Stack Trace</td></tr>';
        		topRowInserted = true;	
        	}
        	
        	emailBody += '<tr>';
        	emailBody += '<td>'+ batchId + '</td>';
        	emailBody += '<td>'+ batchErrorLog.Details__c + '</td>';  
        	emailBody += '<td>'+ batchErrorLog.Error_Message__c + '</td>';
        	emailBody += '<td>'+ batchErrorLog.Stack_Trace_String__c + '</td>';
        	emailBody += '</tr>';
        }
        emailBody += '</table>';
        email.setHtmlBody(emailBody);   
        // Sends the email
        Messaging.SendEmailResult [] r = 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
	}

    public static void logError(string batchId,String details,String errorMsg,String stackTraceString)
    {
        Batch_Error_Logs__c batchError = new Batch_Error_Logs__c();
        batchError.Batch_Id__c = batchId;
        batchError.Details__c= details;
        batchError.Error_Message__c = errorMsg;
        batchError.Stack_Trace_String__c = stackTraceString;
        insert batchError;    
    }
    
    public static Boolean checkErrorsLogged(String batchId)
    {
    	 if([select count() from Batch_Error_Logs__c WHERE id = :batchId] > 0)
    	 {
    	 	return true;
    	 }
    	 else
    	 {
    	 	return false;
    	 }
    }
}