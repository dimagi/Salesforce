/**
 * Creates FogBugz cases for each Opportunity without case Id.
 */
public class CreateFBCasesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public CreateFBCasesBatch() {}

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Name, StageName, Fogbugz_Opened_By__c, Fogbugz_Probability__c, Amount, Owner.Name, IsClosed, Fogbugz_Ticket_Number__c'
                                            + ' FROM Opportunity WHERE IsClosed = false AND Fogbugz_Ticket_Number__c = \'\'');
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> opps = new List<Opportunity>();
        FogBugzAPI fbAPI = new FogBugzAPI();
        System.debug('CreateFBCasesBatch scope: ' + scope.size());
        for (sObject so : scope) {
            Opportunity o = (Opportunity) so;
            FogBugzCase fbCase = FogBugzUtils.createFBCaseFromOpportunity(o);
            System.debug('CreateFBCasesBatch caseId before update: ' + fbCase);
            String fbCaseId = fbAPI.createCase(fbCase, o.IsClosed);
            if (fbCaseId != null) {
                o.Fogbugz_Ticket_Number__c = fbCaseId;
                opps.add(o);
                System.debug('CreateFBCasesBatch caseId after update: ' + fbCaseId);
                StatusLoggerUtils.logInfo(StatusLoggerUtils.CASE_CREATE_LOGGER, o.Id + ' ' + o.Name, 0, 'Creating case for Opportunity.');
            } else {
               StatusLoggerUtils.logError(StatusLoggerUtils.CASE_CREATE_LOGGER, o.Id + ' ' + o.Name, 0, 'Error while creating case for Opportunity.');
               System.debug(LoggingLevel.ERROR, 'CreateFBCasesBatch - Error while creating case');
            }
        }
        if (opps.size() > 0) {
            update opps;
        }
     }

    public void finish(Database.BatchableContext info) {
        StatusLoggerUtils.sendLog(StatusLoggerUtils.CASE_CREATE_LOGGER);
    }
}