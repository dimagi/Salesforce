/**
 * Aux functions for FogBugz stuff
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */
public with sharing class FogBugzUtils {

    private static final String     FOGBUGZ_CASE_PROJECT    = 'Business Development';
    private static final String     FOGBUGZ_CASE_STATUS     = 'Active';
    private static final Integer    FOGBUGZ_CASE_PRIORITY   = 3;

    public static FogBugzCase createFBCaseFromOpportunity(Opportunity o) {
        FogBugzCase fbCase = new FogBugzCase();
        
        // Uncomment if testing
        // fbCase.assignedTo = 'Salesforce';
        fbCase.assignedTo = o.Owner.Name;
        fbCase.title = o.Name;
        fbCase.externalBugID = o.Id;
        fbCase.project = FOGBUGZ_CASE_PROJECT;
        fbCase.area = o.StageName;
        fbCase.status = FOGBUGZ_CASE_STATUS;
        fbCase.priority = FOGBUGZ_CASE_PRIORITY;
        fbCase.caseId = o.Fogbugz_Ticket_Number__c;
        fbCase.ixPersonOpenedBy = o.Fogbugz_Opened_By__c;
        
        return fbCase;
    }

    public static Opportunity fetchOpportunity(Id opportunityId) {
        Opportunity[] ops = [select Id,
                                    Name,
                                    Owner.Name,
                                    Owner.Email,
                                    Owner.Id,
                                    StageName,
                                    Amount,
                                    Fogbugz_Most_Recent_Note__c,
                                    Probability,
                                    Fogbugz_Probability__c,
                                    Fogbugz_Ticket_Number__c,
                                    Fogbugz_Assigned_To__c,
                                    Fogbugz_Opened_By__c
                             from Opportunity
                             where Id = :opportunityId];
        
        return !ops.isEmpty() ? ops[0] : null;
    }

    /**
     * Returns cases that already exist as opportunities in SF, mapped by FB Id
     */
    public static Map<String, Opportunity> fetchOpportunitiesByFBId(Set<String> fbCaseIds) {
        
        Map<String, Opportunity> res = new Map<String, Opportunity>();
        
        for (Opportunity o:[select Id,
                                   Name,
                                   Owner.Name,
                                   Owner.Email,
                                   Owner.Id,
                                   StageName,
                                   Amount,
                                   Fogbugz_Most_Recent_Note__c,
                                   Probability,
                                   Fogbugz_Probability__c,
                                   Fogbugz_Ticket_Number__c,
                                   Fogbugz_Assigned_To__c,
                                   Fogbugz_Opened_By__c
                            from Opportunity
                            where Fogbugz_Ticket_Number__c in :fbCaseIds]) {
            
            res.put(o.Fogbugz_Ticket_Number__c, o);                     
        }
        
        return res;
    }

    public static Datetime parseRFC822UTCTime(String timeString) {
        return Datetime.valueOfGmt(timeString.replace('T', ' ').removeEnd('Z'));
    }

    public static Boolean syncOpportunityFromFB(Opportunity o) {

        Boolean success = true;
        
        FogBugzAPI api = new FogBugzAPI();
        
        // Fetch complete details for opportunity
        FogBugzCase fbCase = Test.isRunningTest() ?
                             api.parseCases(TestFogBugzAPI.GET_CASES_RESPONSE).values()[0] :
                             api.getCase(o.Fogbugz_Ticket_Number__c);
            
        if (fbCase != null) {

            if (o.Fogbugz_Opened_By__c != null) {
                // Update externalBugId in FB for new opportunities
                fbCase.externalBugID = o.Id;
                
                String res = Test.isRunningTest() ? 'testFBId' : api.updateCase(fbCase);
                
                if (res == null) {
                    System.debug(LoggingLevel.ERROR, 'FB2SFSynchronizer::execute() - Error while updating FB case #' + fbCase.caseId);
                }
            }
                
            o.StageName = fbCase.area == null ? null : (fbCase.area.length() > 40 ? fbCase.area.substring(0, 40) : fbCase.area);
            o.Fogbugz_Assigned_To__c = fbCase.assignedTo;
            // @fixme - Client field?
            // o.Fogbugz_Client__c = ???
            o.Name = fbCase.title == null ? null : (fbCase.title.length() > 120 ? fbCase.title.substring(0, 120) : fbCase.title);
            o.Amount = fbCase.dealSize;
            o.Fogbugz_Probability__c = fbCase.probability;
            o.Fogbugz_Opened_By__c = null;
    
            if (fbCase.lastModifiedDate != null) {
                o.Fogbugz_Last_Updated_Date__c = fbCase.lastModifiedDate.date();
            }
                
            if (fbCase.latestEvent != null) {
                o.Fogbugz_Most_Recent_Note__c = fbCase.latestEvent;
            }
                    
            if (o.Id == null) {
                o.CloseDate = Date.today();
            }

            upsert o;
        }
        else {
            System.debug(LoggingLevel.WARN,
                         'FogBugzSynchronizerBatch::execute() - Could not retrieve details for FB case #' + o.Fogbugz_Ticket_Number__c);
            success = false;
        }
        
        return success;
    }
}