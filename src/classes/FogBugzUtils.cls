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
    
    public static Datetime parseRFC822UTCTime(String timeString) {
    	return Datetime.valueOfGmt(timeString.replace('T', ' ').removeEnd('Z'));
    }

}