
/**************************************************
Class Name: OpenOpportunitiesBatch
Class Description: Batch that fetches all Opportunities which to be sent by weekly email  
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando
Update Date: 2013-03-04
Additional Comments: The batch only fetches the records.
The class invokation flow would be: 
1. OpenOpportunitiesBatch gets the records
2. OpenOpportunityMailer performs the filetering based on the report criteria (logic modularised in order to remove processing logic from the batch)
3. OpenOpportunityEmailUtils class create the HTML content for the email
4. OpenOpportunityMailer receives this and send it by email   
**************************************************/
global class OpenOpportunitiesBatch implements Database.Batchable<sObject> {

    public OpenOpportunitiesBatch(){}    
    
    global Iterable<sObject> start(Database.BatchableContext bc) {
    
        Opportunity [] opportunities = new Opportunity [] {};
        
        opportunities = [SELECT 
                                Id,
                                OwnerId
                            FROM Opportunity
                            WHERE Isclosed = false];
                            
        Set<Id> usersId = new Set<Id>();
        
        for(Opportunity opp :opportunities) {        	
        	usersId.add(opp.OwnerId);
        }                                      
        
        User[] users = [SELECT Id, Email, Name FROM User WHERE Id IN :usersId];        
        return users;             
    }
    
    global void execute(Database.BatchableContext bc, User[] scope) {        	        	        	
                	        
        User user = scope[0];                	        
        Map<String, Opportunity[]> stagedOpportunities = OpenOpportunityReportController.getInstance().getOpenOpportunitiesOrderByStage(user.Id);
                        	        	        	
        OpenOpportunityMailer.sendOpenOpportunitiesBatchReport(user, new String[]{user.Email}, stagedOpportunities);
    }
    
    global void finish(Database.BatchableContext bc){}
}