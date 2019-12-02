/**
 * Aux functions for FogBugz stuff
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */
public without sharing class FogBugzUtils {

    private static final String FOGBUGZ_CASE_PROJECT = 'Business Development';
    private static final String FOGBUGZ_CASE_STATUS = 'Active';
    private static final Integer FOGBUGZ_CASE_PRIORITY = 3;

    public static FogBugzCase createFBCaseFromOpportunity(Opportunity o) {
        FogBugzCase fbCase = new FogBugzCase();

        // Uncomment if testing
        //fbCase.assignedTo = 'Salesforce';
        fbCase.assignedTo = o.Owner.Name;
        fbCase.title = o.Name;
        fbCase.externalBugID = o.Id;
        fbCase.project = FOGBUGZ_CASE_PROJECT;
        fbCase.area = o.StageName;
        fbCase.status = FOGBUGZ_CASE_STATUS;
        fbCase.priority = FOGBUGZ_CASE_PRIORITY;
        fbCase.caseId = o.Fogbugz_Ticket_Number__c;
        fbCase.ixPersonOpenedBy = o.Fogbugz_Opened_By__c;

        if (o.Fogbugz_Probability__c != null) {
            fbCase.probability = o.Fogbugz_Probability__c;
            fbCase.dealSize = 0;
            if (o.Amount != null) {
                fbCase.dealSize = o.Amount.intValue();
            }
        }

        return fbCase;
    }

    public static Opportunity fetchOpportunity(Id opportunityId) {
        Opportunity[] ops = [SELECT Id, Name, Owner.Name, Owner.Email, Owner.Id, StageName, Amount,
                             Fogbugz_Most_Recent_Note__c, Probability, Fogbugz_Probability__c, Fogbugz_Ticket_Number__c,
                             Fogbugz_Assigned_To__c, Fogbugz_Opened_By__c, Fogbugz_Last_Updated_Date__c, Fogbugz_elapsed_time__c, IsClosed
                             FROM Opportunity
                             WHERE Id = :opportunityId];
        return !ops.isEmpty() ? ops[0] : null;
    }

    /**
     * Returns cases that already exist as opportunities in SF, mapped by FB Id
     */
    public static Map<String, Opportunity> fetchOpportunitiesByFBId(Set<String> fbCaseIds) {
        Map<String, Opportunity> res = new Map<String, Opportunity>();

        for (Opportunity o:[SELECT Id, Name, Owner.Name, Owner.Email, Owner.Id, StageName, Amount,
                            Fogbugz_Most_Recent_Note__c, Probability, Fogbugz_Probability__c, Fogbugz_Ticket_Number__c, IsClosed,
                            Fogbugz_Assigned_To__c, Fogbugz_Opened_By__c, Fogbugz_Last_Updated_Date__c, Fogbugz_elapsed_time__c
                            FROM Opportunity
                            WHERE Fogbugz_Ticket_Number__c in :fbCaseIds]) {
            res.put(o.Fogbugz_Ticket_Number__c, o);
        }
        return res;
    }

    public static Datetime parseRFC822UTCTime(String timeString) {
        return Datetime.valueOfGmt(timeString.replace('T', ' ').removeEnd('Z'));
    }

    public static Boolean syncOpportunityFromFB(Opportunity o, String batchId) {
        return syncOpportunityFromFB(o, batchId, false);
    }

    public static Boolean syncOpportunityFromFB(Opportunity o, String batchId, Boolean checkTimes) {
        Boolean success = true;
        FogBugzAPI api = new FogBugzAPI();

        // Fetch complete details for opportunity
        FogBugzCase fbCase = api.getCase(o.Fogbugz_Ticket_Number__c);

        if (fbCase != null) {
            if (!checkTimes || o.Fogbugz_Last_Updated_Date__c == null || fbCase.lastModifiedDate == null ||
                fbCase.lastModifiedDate > o.Fogbugz_Last_Updated_Date__c) {

                if (o.Fogbugz_Opened_By__c != null) {
                    // Update externalBugId in FB for new opportunities
                    fbCase.externalBugID = o.Id;
                    String res = Test.isRunningTest() ? 'testFBId' : api.updateCase(fbCase);
                    if (res == null) {
                        System.debug(LoggingLevel.ERROR, 'FB2SFSynchronizer::execute() - Error while updating FB case #' + fbCase.caseId);
                        StatusLoggerUtils.logError(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Fogbugz Sync Error batchId : ' + batchId, 0,
                                            'FB2SFSynchronizer::execute() - Error while updating FB case #' + fbCase.caseId);
                    }
                }

                String fbArea = fbCase.area == null ? null : (fbCase.area.length() > 40 ? fbCase.area.substring(0, 40) : fbCase.area);
                if (fbArea == 'Closed - Won') { // When User will close Opp in SF then 100% is set as default, so we must
                                                     // do this also when Opp is closed in FB
                    o.Probability = 100;
                    if (o.StageName !=  fbCase.area) {
                        o.CloseDate = Date.today(); // We don't want update it again if we are using 3h time window it can be next day
                    }
                } else if (fbArea == 'Closed' || fbArea == 'Closed - No Go' || fbArea == 'Closed - Lost') {
                    o.Probability = 0;
                }

                if (!(o.IsClosed && fbCase.assignedTo == 'CLOSED') || (fbArea != null && fbArea.contains('Closed'))) { // We want avoid problem with 3 hours time frame, but we want add correct closed stage to Opp
                    o.StageName = fbArea;
                }
                o.Fogbugz_Assigned_To__c = fbCase.assignedTo;
                o.Name = fbCase.title == null ? null : (fbCase.title.length() > 120 ? fbCase.title.substring(0, 120) : fbCase.title);
                o.Fogbugz_Opened_By__c = null;
                o.Fogbugz_elapsed_time__c = fbCase.hrsElapsed;

                if (fbCase.lastModifiedDate != null) {
                    o.Fogbugz_Last_Updated_Date__c = fbCase.lastModifiedDate;
                }
                if (fbCase.latestEvent != null) {
                    o.Fogbugz_Most_Recent_Note__c = fbCase.latestEvent;
                }
                if (o.Id == null) {
                    o.CloseDate = Date.today();
                }

                Database.UpsertResult[] srList = Database.upsert(new List<Opportunity> { o }, false);
                if (!srList.get(0).isSuccess()) { // we are updating single record
                    success = false;
                    String oppErrorMessage = '';
                    for(Database.Error err : srList.get(0).getErrors()) {
                        oppErrorMessage += err.getMessage() + 'Opp Id: ' + srList.get(0).getId() + ' ';
                    }
                    StatusLoggerUtils.logError(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Fogbugz Sync Error batchId : ' + batchId, 0, o.Fogbugz_Ticket_Number__c + ' ' + oppErrorMessage);
                }
            } else {
                System.debug(LoggingLevel.INFO, 'FogBugzUtils::syncOpportunityFromFB() - Case not updated in FB, case #' + o.Fogbugz_Ticket_Number__c);
                StatusLoggerUtils.logWarning(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Fogbugz Sync batchId : ' + batchId, 0,
                                            'FogBugzUtils::syncOpportunityFromFB() - Case not updated in FB, case #' + o.Fogbugz_Ticket_Number__c);
                success = false;
            }
        } else {
            System.debug(LoggingLevel.WARN, 'FogBugzUtils::syncOpportunityFromFB() - Could not retrieve details for FB case #' + o.Fogbugz_Ticket_Number__c);
            StatusLoggerUtils.logError(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Fogbugz Sync Error batchId : ' + batchId, 0,
                                            'FogBugzUtils::syncOpportunityFromFB() - Could not retrieve details for FB case #' + o.Fogbugz_Ticket_Number__c);
            success = false;
        }

        if(success == true) {
            StatusLoggerUtils.logInfo(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Fogbugz Sync batchId : ' + batchId, 0,
                                            'Fogbugz Opp Successfully synced - FogBugz Ticket No - ' + o.Fogbugz_Ticket_Number__c);
        }
        return success;
    }

    public static Set<String> closedStages {
        get {
            if(closedStages == null) {
                closedStages = new Set<String>();
                for(OpportunityStage os : [SELECT MasterLabel FROM OpportunityStage WHERE IsClosed = true]) {
                    closedStages.add(os.MasterLabel);
                }
            }
            return closedStages;
        }
        set;
    }
}