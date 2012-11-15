/**
 * This batch job updates the externalBugId of the FB cases that didn't exist
 * previously in SF as Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */
global with sharing class FogBugzSynchronizerBatch implements Database.Batchable<Opportunity>, Database.AllowsCallouts {

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
            
            // We update the externalBugId field in FB
            FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
            
            String res = Test.isRunningTest() ? 'testFBId' : api.updateCase(fbCase);
            
            if (res == null) {
                System.debug(LoggingLevel.ERROR, 'FB2SFSynchronizer::execute() - Error while updating FB case #' + fbCase.caseId);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Nothing to do here
    }
}