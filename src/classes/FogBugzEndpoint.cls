/**
 * Handles requests sent by FogBugz to the Force.com site
 *
 * @author  Antonio Grassi
 * @date    11/20/2012
 */
public with sharing class FogBugzEndpoint {

    private final static String SF_TOKEN = 'Yiquee9TEpho4fihahwuS4qu';
    
    public void processRequest() {

        Map<String, String> params = System.currentPageReference().getParameters();
        
        if (params.containsKey('token') && params.get('token').equals(SF_TOKEN)) {
        	
        	if (params.containsKey('caseId')) {
        		
        		FogBugzAPI api = new FogBugzAPI();
        		FogBugzCase fbCase = api.getCase(params.get('caseId'));
        		
        		if (fbCase != null) {
        			Map<String, Opportunity> ops = FogBugzUtils.fetchOpportunitiesByFBId(new Set<String>{params.get('caseId')});
        			
        			Opportunity o = ops.size() > 0 ? ops.values()[0] : new Opportunity();
        			
	                o.StageName = fbCase.area;
	                o.Fogbugz_Assigned_To__c = fbCase.assignedTo;
	                // @fixme - Client field?
	                // o.Fogbugz_Client__c = ???
	                o.Fogbugz_Ticket_Number__c = fbCase.caseId;
	                o.Name = fbCase.title;
	                o.Amount = fbCase.dealSize;
	                o.Probability = fbCase.probability;
	    
	                if (fbCase.lastModifiedDate != null) {
	                    o.Fogbugz_Last_Updated_Date__c = fbCase.lastModifiedDate.date();
	                }
	                
	                if (fbCase.latestEvent != null) {
	                    o.Description = fbCase.latestEvent;
	                }

                    Boolean newOp = o.Id == null;
                    
	                if (o.Id == null) {
	                    o.CloseDate = Date.today();
	                }
        			
        			upsert o;
        			
        			if (newOp) {
        				updateFBExternalId(o.Id);
        			}
        		}
        		else {
        			System.debug(LoggingLevel.WARN, 'FogBugzEndpoint::processRequest() - Could not retrieve case ' + params.get('caseId'));
        		}
        	}
        	else {
        		System.debug(LoggingLevel.WARN, 'FogBugzEndpoint::processRequest() - Missing case Id parameter');
        	}
        }
        else {
        	System.debug(LoggingLevel.WARN, 'FogBugzEndpoint::processRequest() - Missing or missmatching token parameter');
        }
    }
    
    @future(callout=true)
    public static void updateFBExternalId(Id opId) {
    	
    	Opportunity o = FogBugzUtils.fetchOpportunity(opId);
    	
    	if (o != null) {

            FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
            
            FogBugzAPI api = new FogBugzAPI();
            String res = api.updateCase(fbCase);
            
            if (res == null) {
                System.debug(LoggingLevel.ERROR, 'FogBugzEndpoint::updateFBExternalId() - Error while updating FB case #' + fbCase.caseId);
            }
    	}
    }
}