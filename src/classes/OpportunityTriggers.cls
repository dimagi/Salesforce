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
    	
    	Opportunity o = FogBugzUtils.fetchOpportunity(opportunityId);
    	
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
     
	 /**
	 * We use @future here in order to perform HTTP callouts from within a trigger context
	 */
    @future(callout=true)
    public static void closeFogbugzCase(String ticket_number) {
    	
    	if (ticket_number != null) {
			 
			 FogBugzAPI fbAPI = new FogBugzAPI();
			 FogBugzCase fbCase = fbAPI.getCase(ticket_number);
			 String fbCaseId = fbAPI.resolveCase(fbCase);
			 if (fbCaseId != null) {
			     fbCaseId = fbAPI.closeCase(fbCase);
			 }
			 
		}
    	
    }
    
    public static void updateCaseInFogbugz(Opportunity oppNew, Opportunity oppOld) {
    	
    	if ((oppNew.Name != oppOld.Name) || 
    	    (oppNew.StageName != oppOld.StageName) || 
    	    (oppNew.Amount != oppOld.Amount) ||
    	    (oppOld.Fogbugz_Probability__c != oppNew.Fogbugz_Probability__c)) {
    		
    		if (!System.isBatch()) {
    			
    			FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(oppNew);
    			String tags = null;
    			boolean editTags = (oppOld.Fogbugz_Probability__c != oppNew.Fogbugz_Probability__c) || (oppNew.Amount != oppOld.Amount);
    			updateCase(oppNew.Id, editTags);
    			                
    		}
    		
    	}
    }
    
    /**
     * We use @future here in order to perform HTTP callouts from within a trigger context
     */
    @future(callout=true)
    public static void updateCase(String opportunityId, boolean editTags) {
    	
    	Opportunity o = FogBugzUtils.fetchOpportunity(opportunityId);
        
        if (o != null) {
            
            FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
            FogBugzAPI fbAPI = new FogBugzAPI();
            
            if (o.Amount != null) {
                fbCase.dealSize = o.Amount.intValue();
            }
            else {
            	fbCase.dealSize = 0;
            }
            fbCase.probability = o.Fogbugz_Probability__c;            
            
            String fbCaseId = fbAPI.updateCaseTitleStageTag(fbCase, editTags);
            
        }
        else {
            System.debug(LoggingLevel.WARN, 'OpportunityTriggers::updateCase() - Could not find opportunity just created (???)');
        }
    }
}