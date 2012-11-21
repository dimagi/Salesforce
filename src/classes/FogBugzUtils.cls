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
        
        fbCase.assignedTo = 'Salesforce';
        // @todo - Uncomment once done with testing
        // fbCase.assignedTo = o.Owner.Name;
        fbCase.title = o.Name;
        fbCase.externalBugID = o.Id;
        fbCase.project = FOGBUGZ_CASE_PROJECT;
        fbCase.area = o.StageName;
        fbCase.status = FOGBUGZ_CASE_STATUS;
        fbCase.priority = FOGBUGZ_CASE_PRIORITY;
        fbCase.caseId = o.Fogbugz_Ticket_Number__c;
        
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
                                    Description,
                                    Probability,
                                    Fogbugz_Ticket_Number__c,
                                    Fogbugz_Assigned_To__c
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
                                   Description,
                                   Probability,
                                   Fogbugz_Ticket_Number__c,
                                   Fogbugz_Assigned_To__c
                            from Opportunity
                            where Fogbugz_Ticket_Number__c in :fbCaseIds]) {
            
            res.put(o.Fogbugz_Ticket_Number__c, o);                     
        }
        
        return res;
    }

    public static Datetime parseRFC822UTCTime(String timeString) {
    	return Datetime.valueOfGmt(timeString.replace('T', ' ').removeEnd('Z'));
    }

}