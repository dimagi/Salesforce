/**
 * Retrieves FogBugz cases and upserts SF opportunities
 *
 * @author  Antonio Grassi
 * @date    11/14/2012
 */
global class FogBugzSynchronizer implements Schedulable {

    public Boolean testMode = false;
    
    private static final Integer    FB_BIZ_FILTER_ID    = 287;
    // @fixme - This is the real filter, uncomment once tested
    //private static final Integer   FB_BIZ_FILTER_ID    = 114;

    global void execute(SchedulableContext SC) {
    	synchronize();
    }
    
    public void synchronize() {

        FogBugzAPI api = new FogBugzAPI();

        if (!testMode) {
            api.setCurrentFilter(FB_BIZ_FILTER_ID);
        }
        
        Map<String, FogBugzCase> fbIdToCaseMap = testMode ?
                                                 api.parseCases(TestFogBugzAPI.GET_CASES_RESPONSE) :
                                                 api.getCases();

        if (fbIdToCaseMap.size() > 0) {
	        Opportunity[] newOpportunities = new Opportunity[]{};
	        Map<String, Opportunity> existentOpportunities = fetchExistentOpportunities(fbIdToCaseMap.keySet());
	    
	        for (String caseId:fbIdToCaseMap.keySet()) {
	                
	            Opportunity o = existentOpportunities.containsKey(caseId) ?
	                            existentOpportunities.get(caseId) :
	                            new Opportunity();
	                
	            FogBugzCase fbCase = fbIdToCaseMap.get(caseId);
	                
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
	                
	            if (o.Id == null) {
	                o.CloseDate = Date.today();
	                newOpportunities.add(o);
	            }
	        }
	            
	        update existentOpportunities.values();
	            
	        if (!newOpportunities.isEmpty()) {
	            insert newOpportunities;
	            
	            // We use a batch job to update the externalBugId field in FB, as this potentially requires more than 20 callouts
	            Database.executeBatch(new FogBugzSynchronizerBatch(newOpportunities), 1);
	        }
        }
    }
    
    /**
     * Returns cases that already exist as opportunities in SF, mapped by FB Id
     */
    private Map<String, Opportunity> fetchExistentOpportunities(Set<String> fbCaseIds) {
        
        Map<String, Opportunity> res = new Map<String, Opportunity>();
        
        for (Opportunity o:[select Id,
                                   Name,
                                   Owner.Name,
                                   Owner.Id,
                                   StageName,
                                   Amount,
                                   Probability,
                                   Fogbugz_Ticket_Number__c,
                                   Fogbugz_Assigned_To__c
                            from Opportunity
                            where Fogbugz_Ticket_Number__c in :fbCaseIds]) {
            
            res.put(o.Fogbugz_Ticket_Number__c, o);                     
        }
        
        return res;
    }

}