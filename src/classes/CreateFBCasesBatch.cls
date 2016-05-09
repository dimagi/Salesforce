/**
 * Creates FogBugz cases for each Opportunity without case Id.
 */
global class CreateFBCasesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name, StageName, Fogbugz_Opened_By__c, Fogbugz_Probability__c, Amount, Owner.Name, IsClosed, Fogbugz_Ticket_Number__c FROM Opportunity WHERE IsClosed = false AND Fogbugz_Ticket_Number__c = \'\'');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        FogBugzAPI fbAPI = new FogBugzAPI();
        System.debug('CreateFBCasesBatch scope: ' + scope.size());
        for (sObject so : scope) {
            Opportunity o = (Opportunity) so;
            FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
            System.debug('CreateFBCasesBatch caseId before update: ' + fbCase);
            String fbCaseId = fbAPI.createCase(fbCase, o.IsClosed);            
            if (fbCaseId != null) {
                o.Fogbugz_Ticket_Number__c = fbCaseId;
                update o;
                System.debug('CreateFBCasesBatch caseId after update: ' + fbCaseId);
            } else {
                System.debug(LoggingLevel.ERROR, 'CreateFBCasesBatch - Error while creating case');
            }
        }
     }

    global void finish(Database.BatchableContext info) {

    }
}