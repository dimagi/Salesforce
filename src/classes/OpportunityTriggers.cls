/**
 * Logic for the different triggers defined on Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/13/2012
 */
public with sharing class OpportunityTriggers {

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
                                    Owner.Email,
                                    Owner.Id,
                                    StageName,
                                    Fogbugz_Ticket_Number__c
                             from Opportunity
                             where Id = :opportunityId];
    	
    	return !ops.isEmpty() ? ops[0] : null;
    }
}