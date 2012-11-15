/**
 * Logic for the different triggers defined on Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/13/2012
 */
public with sharing class OpportunityTriggers {

    private static final String     NOTIFICATION_TEMPLATE   = 'New Opportunity - FogBugz integration';
    
    /**
     * We use @future here in order to perform HTTP callouts from within a trigger context
     */
    @future(callout=true)
    public static void createInFogbugz(Id opportunityId) {
    	
    	Opportunity o = fetchOpportunity(opportunityId);
    	
    	if (o != null) {
    		
	        FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
	        FogBugzAPI fbAPI = new FogBugzAPI();
	        
	        String fbCaseId = Test.isRunningTest() ? TestFogBugzAPI.TEST_FB_ID : fbAPI.createCase(fbCase);
	        
	        if (fbCaseId != null) {
	            o.Fogbugz_Ticket_Number__c = fbCaseId;
	            update o;
	            
	            EmailTemplate[] template = [select Id from EmailTemplate where Name = :NOTIFICATION_TEMPLATE];
	            
	            if (!template.isEmpty()) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                    mail.setTemplateId(template[0].Id);
                    mail.setWhatId(o.Id);
                    mail.setTargetObjectId(o.Owner.Id);
                
                    Messaging.sendEmail(new Messaging.Email[] { mail }, false);
	            	
	            }
                else {
                	System.debug(LoggingLevel.WARN, 'OpportunityTriggers::createInFogbugz() - Notification mail template not found');
                }
	        }
	        else {
	            System.debug(LoggingLevel.ERROR, 'OpportunityTriggers::createInFogbugz() - Error while creating case');
	        }
    	}
    	else {
    		System.debug(LoggingLevel.WARN, 'OpportunityTriggers::createInFogbugz() - Could not find opportunity just created (???)');
    	}
    }

    private static Opportunity fetchOpportunity(Id opportunityId) {
        Opportunity[] ops = [select Id,
                                    Name,
                                    Owner.Name,
                                    Owner.Id,
                                    StageName,
                                    Fogbugz_Ticket_Number__c
                             from Opportunity
                             where Id = :opportunityId];
    	
    	return !ops.isEmpty() ? ops[0] : null;
    }
}