/**
 * This batch job updates the externalBugId of the FB cases that didn't exist
 * previously in SF as Opportunities
 *
 * @author  Antonio Grassi
 * @date    11/15/2012
 */
global without sharing class FogBugzSynchronizerBatch implements Database.Batchable<Opportunity>, Database.AllowsCallouts, Database.Stateful {

    public final Boolean testMode;

    private DateTime jobStartDateTime;
    private Boolean syncSuccess;
    private String[] errorEmailAdress;

    public FogBugzSynchronizerBatch(Boolean testMode) {
        this.testMode = testMode;
    }

    global Iterable<Opportunity> start(Database.BatchableContext BC) {
        FogBugz_Settings__c settings = FogBugz_Settings__c.getOrgDefaults();
        this.jobStartDateTime = Datetime.now();
        this.syncSuccess = true;
        CommcareToSalesforceSettings__c settingsData = CommcareToSalesforceSettings__c.getInstance('BatchFailureReportRecepeint');
        if (settingsData != null) {
            this.errorEmailAdress = settingsData.Value__c.split(';');
        }

        try {
            Opportunity[] modifiedOps = preFetchOpportunities(settings.Last_Time_Sync_Ran__c);
            return new OpportunityIterable(modifiedOps);
        } catch(exception e) {
            this.syncSuccess = false;
            EmailHelper.sendEmailFromException(this.errorEmailAdress, 'Fogbugz Sync - Error in start method',
                                                'Last sync date time wasn\'t updated, we catch following exception', e);
            return null;
        }
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        FogBugzAPI api = new FogBugzAPI();

        for (Opportunity o : scope) {
            if (o.Fogbugz_Opened_By__c != null) {
                Boolean ownerFound = false;
                String userMail = Test.isRunningTest() ? 'do@not.exist.com' : api.getPersonEmail(o.Fogbugz_Opened_By__c);

                if (userMail != null) {
                    User[] us = [SELECT Id FROM User WHERE Email = :userMail];
                    if (!us.isEmpty()) {
                        System.debug(LoggingLevel.INFO, 'FogBugzSynchronizerBatch::execute() - Found user ' + userMail);
                        o.OwnerId = us[0].Id;
                        ownerFound = true;
                    } else {
                        System.debug(LoggingLevel.INFO, 'FogBugzSynchronizerBatch::execute() - User ' + userMail + 'does not exist in SF');
                    }
                } else {
                    System.debug(LoggingLevel.INFO,
                         'FogBugzSynchronizerBatch::execute() - Could not retrieve user email for ' + o.Fogbugz_Opened_By__c);
                }

                if (!ownerFound) {
                    User[] us = [select Id from User where Username = :FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c];
                    if (!us.isEmpty()) {
                        o.OwnerId = us[0].Id;
                    } else {
                        System.debug(LoggingLevel.WARN, 'FogBugzSynchronizerBatch::execute() - Cannot find default owner: ' +
                             FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c);
                    }
                }
            }

            FogBugzUtils.syncOpportunityFromFB(o, BC.getJobId());
        }
    }

    private Opportunity[] preFetchOpportunities(Datetime minTime) {
        Opportunity[] allOpportunities = new Opportunity[]{};
        Opportunity[] newOpportunities = new Opportunity[]{};

        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        fbSettings.Sync_Script_Running__c = true;
        FogBugzAPI api = new FogBugzAPI();

        if (!testMode) {
            api.setCurrentFilter(fbSettings.Sync_Filter__c.intValue());
        }

        Map<String, FogBugzCase> fbIdToCaseMap = testMode ?
                                                 api.parseCases(TestFogBugzAPI.GET_CASES_RESPONSE) :
                                                 api.listCases();

        // We delay a little this upsert to avoid the "uncommitted work pending" exception when performing the FB API HTTP requests
        upsert fbSettings;
        sendEmailBeforeSyncOpps(fbIdToCaseMap);

        if (fbIdToCaseMap.size() > 0) {
            Map<String, Opportunity> existentOpportunities = FogBugzUtils.fetchOpportunitiesByFBId(fbIdToCaseMap.keySet());

            for (String caseId:fbIdToCaseMap.keySet()) {
                if (existentOpportunities.containsKey(caseId)) {

                    Opportunity o = existentOpportunities.get(caseId);
                    FogBugzCase c = fbIdToCaseMap.get(caseId);
                    System.debug(LoggingLevel.INFO, 'Processing existent opportunity::' + o.Id + '-' + minTime + '-' + c.lastModifiedDate);

                    if (minTime == null || c.lastModifiedDate == null || c.lastModifiedDate > minTime) {
                        allOpportunities.add(o);
                    }
                } else {
                    FogBugzCase fbCase = fbIdToCaseMap.get(caseId);
                    System.debug(LoggingLevel.INFO, 'Processing new opportunity::' + minTime + '-' + fbCase.lastModifiedDate);

                    Opportunity o = new Opportunity(
                        Name = 'Synchronizing',
                        StageName = 'Synchronizing',
                        Fogbugz_Ticket_Number__c = fbCase.caseId,
                        Fogbugz_Opened_By__c = fbCase.ixPersonOpenedBy,
                        CloseDate = Date.today()
                    );

                    newOpportunities.add(o);
                    allOpportunities.add(o);
                }
            }

            if (!newOpportunities.isEmpty()) {
                insert newOpportunities;
            }
        }
        return allOpportunities;
    }

    global void finish(Database.BatchableContext bc) {
        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        fbSettings.Sync_Script_Running__c = false;
        if (this.syncSuccess) { // we can update sync date when all cases was updated
            fbSettings.Last_Time_Sync_Ran__c = this.jobStartDateTime;
        }
        update fbSettings;

        if(!test.isRunningTest()) {
            hqInt_BatchErrorLogger.sendErrorEmails(BC.getJobId(), 'Fogbugz Success & Errors', 'Fogbugz Batch Run Results Logs:');
        }
    }

    /**
     * Sends email to admin, needed for reproduce bug 235623.
     */
    private void sendEmailBeforeSyncOpps(Map<String, FogBugzCase> fbIdToCaseMap) {
        if (Test.isRunningTest()) {
            return;
        }

        String emailBody = '';
        for (FogBugzCase fbCase : fbIdToCaseMap.values()) {
            emailBody += fbCase.caseId + ' ' + fbCase.title + ' ' + fbCase.lastModifiedDate + '<br/>';
        }
        EmailHelper.sendEmail(this.errorEmailAdress, 'Fogbugz Sync - Cases listed by FB filter', emailBody);
    }

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
}