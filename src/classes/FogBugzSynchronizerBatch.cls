/**
 * This batch job updates the externalBugId of the FB cases that didn't exist
 * previously in SF as Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */
global without sharing class FogBugzSynchronizerBatch implements Database.Batchable<Opportunity>, Database.AllowsCallouts {

    /**
     * We define a custom iterator to traverse the new opportunities
     */
    public class OpportunityIterator implements Iterator<Opportunity> {
    
        Opportunity[] opportunities;
        Integer i = 0;
        
        public OpportunityIterator(Opportunity[] opportunities) {
            this.opportunities = opportunities;
            
        }
        
        public Boolean hasNext() {
            return i < opportunities.size();
        }
        
        public Opportunity next() {
            return opportunities[i++];
        }
    }
    
    public class OpportunityIterable implements Iterable<Opportunity> {
        
        Opportunity[] opportunities;
        
        public OpportunityIterable(Opportunity[] opportunities) {
            this.opportunities = opportunities;
        }
        public Iterator<Opportunity> iterator() {
            return new OpportunityIterator(opportunities);
        }
    }
    
    /**
     * The batch job code starts here
     */

    final Opportunity[] newOpportunities;
    
    public FogBugzSynchronizerBatch(Opportunity[] newOpportunities) {
        this.newOpportunities = newOpportunities;
    }
    
    global Iterable<Opportunity> start(Database.BatchableContext BC) {
        return new OpportunityIterable(newOpportunities);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        FogBugzAPI api = new FogBugzAPI();
        
        for (Opportunity o:scope) {

            // Determine SF owner for new opportunities             
            if (o.Fogbugz_Opened_By__c != null) {

                Boolean ownerFound = false;
                String userMail = Test.isRunningTest() ? 'do@not.exist.com' : api.getPersonEmail(o.Fogbugz_Opened_By__c);
                            
                if (userMail != null) {
                    
                    User[] us = [select Id from User where Email = :userMail];
                    
                    if (!us.isEmpty()) {
                        System.debug(LoggingLevel.INFO, 'FogBugzSynchronizerBatch::execute() - Found user ' + userMail);
                        o.OwnerId = us[0].Id;
                        ownerFound = true;
                    }
                    else {
                        System.debug(LoggingLevel.INFO, 'FogBugzSynchronizerBatch::execute() - User ' + userMail + 'does not exist in SF');
                    }
                }
                else {
                    System.debug(LoggingLevel.INFO,
                                 'FogBugzSynchronizerBatch::execute() - Could not retrieve user email for ' + o.Fogbugz_Opened_By__c);
                }
                
                if (!ownerFound) {
                        
                    User[] us = [select Id from User where Username = :FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c];
                        
                    if (!us.isEmpty()) {
                        o.OwnerId = us[0].Id;
                    }
                    else {
                        System.debug(LoggingLevel.WARN, 'FogBugzSynchronizerBatch::execute() - Cannot find default owner: ' +
                                     FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c);
                    }
                }
            }
            
            // Now we fetch the latest case details from FB into the oppty
            FogBugzUtils.syncOpportunityFromFB(o);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        fbSettings.Sync_Script_Running__c = false;
        update fbSettings;
    }
}