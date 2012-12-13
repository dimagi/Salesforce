public with sharing class SyncController {

    private PageReference cancelPage = null;
    private Opportunity o;
    
    public SyncController(ApexPages.StandardSetController controller) {
    	cancelPage = controller.cancel();
    }
    
    public SyncController(ApexPages.StandardController sc) {
    	cancelPage = sc.cancel();
    	o = FogBugzUtils.fetchOpportunity(sc.getId());
    }
    
    public void runSync() {
    	FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
    	
    	if (fbSettings.Sync_Script_Running__c) {
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
	                                                   'The synchronization script is currently running'));
    	}
    	else {
	        FogBugzSynchronizer synchronizer = new FogBugzSynchronizer();
	        synchronizer.synchronize();
	        
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
	                                                   'Check the opportunities in SF to see if they were updated, ' +
	                                                   'and check FB to see if the externalBugId was set for cases created in FB'));
    	}
    }
    
    public void runSingleSync() {
    	
    	if (o.Fogbugz_Ticket_Number__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                       'Opportunity does not have a FogBugz ticket number'));
    	}
    	else {
    		Boolean success = FogBugzUtils.syncOpportunityFromFB(o);
    		
    		if (success) {
    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
                                                           'Opportunity successfully updated with current FogBugz details'));
    		}
    		else {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
	                                                       'Error while updating opportunity with current FogBugz details. Please check ' +
	                                                       'the debug logs with details'));
    		}
    	}
    }
    
    public PageReference goBack() {
    	return cancelPage;
    }
}