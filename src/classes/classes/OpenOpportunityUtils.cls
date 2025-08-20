public with sharing class OpenOpportunityUtils {

    public static void handleBeforeInsert(Opportunity[] opportunities) {
        for (Opportunity opportunity :opportunities) {
            opportunity.Stage_Name_Updated_Date__c = Date.today();
        }
    }

    public static void handleBeforeUpdate(Opportunity[] opportunities, Map<Id, Opportunity> oldOpportunities) {
        for (Opportunity opportunity :opportunities) {
            Opportunity oldOpportunity = oldOpportunities.get(opportunity.Id);
            if (oldOpportunity.StageName != opportunity.StageName) {
                opportunity.Stage_Name_Updated_Date__c = Date.today();
                if (opportunity.Fogbugz_Assigned_To__c == 'CLOSED' && opportunity.IsClosed == false
                        && oldOpportunity.IsClosed == true) { // Opportunity was reopened
                    opportunity.Fogbugz_Assigned_To__c = 'REOPENED';
                }
            }
        }
    }
}