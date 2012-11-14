/**
 * Creates a FogBugz case upon Opportunity creation
 *
 * @todo    Handle bulk insertions
 *
 * @author  Antonio Grassi
 * @date    11/13/2012
 */

trigger OpportunityToCase on Opportunity (after insert) {

    if (Trigger.new[0].Fogbugz_Ticket_Number__c == null) {
    	OpportunityTriggers.createInFogbugz(Trigger.new[0].Id);
    }
}