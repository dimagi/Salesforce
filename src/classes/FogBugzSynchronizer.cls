/**
 * Retrieves FogBugz cases and upserts SF opportunities
 *
 * @author  Antonio Grassi
 * @date    11/14/2012
 */
global without sharing class FogBugzSynchronizer implements Schedulable {

    public Boolean testMode = false;
    
    global void execute(SchedulableContext SC) {
    	FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
    	
    	if (!fbSettings.Sync_Script_Running__c) {
            synchronize();
    	}
    }
    
    public void synchronize() {

        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        fbSettings.Sync_Script_Running__c = true;
        
        FogBugzAPI api = new FogBugzAPI();

        if (!testMode) {
            api.setCurrentFilter(fbSettings.Sync_Filter__c.intValue());
        }
        
        Map<String, FogBugzCase> fbIdToCaseMap = testMode ?
                                                 api.parseCases(TestFogBugzAPI.GET_CASES_RESPONSE) :
                                                 api.listCases();

        // We delay a little this upsert to avoid the "uncommitted work pending" exception when performing the FB API HTTP requests
        upsert fbSettings;

        if (fbIdToCaseMap.size() > 0) {
        	
	        Opportunity[] allOpportunities = new Opportunity[]{};
	        Opportunity[] newOpportunities = new Opportunity[]{};
	        
	        Map<String, Opportunity> existentOpportunities = FogBugzUtils.fetchOpportunitiesByFBId(fbIdToCaseMap.keySet());
            
	        for (String caseId:fbIdToCaseMap.keySet()) {

                Opportunity o = null;
                
                if (existentOpportunities.containsKey(caseId)) {
                	o = existentOpportunities.get(caseId);
                }
                else {
                	FogBugzCase fbCase = fbIdToCaseMap.get(caseId);
                	
                	o = new Opportunity(
                	    Name = 'Synchronizing',
                        StageName = 'Synchronizing',
                        Fogbugz_Ticket_Number__c = fbCase.caseId,
                        Fogbugz_Opened_By__c = fbCase.ixPersonOpenedBy,
                        CloseDate = Date.today()
                	);
                	
                	newOpportunities.add(o);
                }
                
                allOpportunities.add(o);

	        }

            if (!newOpportunities.isEmpty()) {
            	insert newOpportunities;
            }
            
	        if (!allOpportunities.isEmpty()) {
	            // We use a batch job to finish the synchronization, to avoid hitting the max script statements &
	            // max HTTP callouts limits
	            Database.executeBatch(new FogBugzSynchronizerBatch(allOpportunities), 1);
	        }
	        else {
	        	fbSettings.Sync_Script_Running__c = false;
	        	update fbSettings;
	        }
        }
        else {
            fbSettings.Sync_Script_Running__c = false;
            update fbSettings;
        }
    }
}