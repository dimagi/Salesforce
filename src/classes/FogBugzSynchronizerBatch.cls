/**
 * This batch job synchronize Opps with FogBugz cases.
 */
public without sharing class FogBugzSynchronizerBatch implements Database.Batchable<Opportunity>, Database.AllowsCallouts, Database.Stateful {

    private DateTime jobStartDateTime;
    private Boolean syncSuccess;
    private String[] errorEmailAdress;
    private Integer filterId;
    private Boolean lastJob;

    public FogBugzSynchronizerBatch(Integer filterId) {
        this(filterId, false);
    }

    public FogBugzSynchronizerBatch(Integer filterId, Boolean lastJob) {
        this.filterId = filterId;
        this.lastJob = lastJob;
    }

    public Iterable<Opportunity> start(Database.BatchableContext BC) {
        FogBugz_Settings__c settings = FogBugz_Settings__c.getOrgDefaults();
        this.jobStartDateTime = Datetime.now();
        this.syncSuccess = true;
        Commcare_Job_Settings__c settingsData = Commcare_Job_Settings__c.getOrgDefaults();
        if (settingsData != null && settingsData.Error_Emails__c != null) {
            this.errorEmailAdress = settingsData.Error_Emails__c.split(',');
        }

        try {
            Opportunity[] modifiedOps = preFetchOpportunities(settings.Last_Time_Sync_Ran__c);
            return new OpportunityIterable(modifiedOps);
        } catch(exception e) {
            StatusLoggerUtils.logError(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Start method exception filter : ' + this.filterId, 0, e.getMessage());
            this.syncSuccess = false;
            return new OpportunityIterable(new Opportunity[]{});
        }
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        FogBugzAPI api = new FogBugzAPI();

        for (Opportunity o : scope) {
            if (o.Fogbugz_Opened_By__c != null) {
                Boolean ownerFound = false;
                String userMail = api.getPersonEmail(o.Fogbugz_Opened_By__c);

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
                        StatusLoggerUtils.logError(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER, 'Cannot find default owner', 0, FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c);
                        System.debug(LoggingLevel.WARN, 'FogBugzSynchronizerBatch::execute() - Cannot find default owner: ' +
                             FogBugz_Settings__c.getOrgDefaults().Default_Opportunity_Owner__c);
                    }
                }
            }

            FogBugzUtils.syncOpportunityFromFB(o, BC.getJobId());
        }
    }

    public void finish(Database.BatchableContext bc) {
        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        if (!this.lastJob) {
            this.lastJob = fbSettings.Sync_Filter_Closed__c != null ? this.lastJob : true;
        }

        if (this.lastJob) {
            fbSettings.Sync_Script_Running__c = false;
            if (this.syncSuccess) { // we can update sync date when all cases was updated
                fbSettings.Last_Time_Sync_Ran__c = this.jobStartDateTime;
            }
            update fbSettings;
        } else {
            Database.executeBatch(new FogBugzSynchronizerBatch(fbSettings.Sync_Filter_Closed__c.intValue(), true), 1);
        }

        if(!Test.isRunningTest()) {
            if (this.lastJob && DateTime.now().hour() == 9) { // send one email a day at 9:00 am
                StatusLoggerUtils.sendLog(StatusLoggerUtils.FOGBUGZ_SYNC_LOGGER);
            }
        }
    }

    private Opportunity[] preFetchOpportunities(Datetime minTime) {
        Opportunity[] allOpportunities = new Opportunity[]{};
        Opportunity[] newOpportunities = new Opportunity[]{};

        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();
        fbSettings.Sync_Script_Running__c = true;
        FogBugzAPI api = new FogBugzAPI();
        api.setCurrentFilter(this.filterId);
        Map<String, FogBugzCase> fbIdToCaseMap = api.listCases();

        // We delay a little this upsert to avoid the "uncommitted work pending" exception when performing the FB API HTTP requests
        upsert fbSettings;

        if (fbIdToCaseMap.size() > 0) {
            Map<String, Opportunity> existentOpportunities = FogBugzUtils.fetchOpportunitiesByFBId(fbIdToCaseMap.keySet());

            for (String caseId:fbIdToCaseMap.keySet()) {
                if (existentOpportunities.containsKey(caseId)) {

                    Opportunity o = existentOpportunities.get(caseId);
                    FogBugzCase c = fbIdToCaseMap.get(caseId);
                    System.debug(LoggingLevel.INFO, 'Processing existent opportunity::' + o.Id + '-' + minTime + '-' + c.lastModifiedDate);

                    // before was c.lastModifiedDate > minTime, but sometimes some cases are not returned by filter or some errors can occurs
                    // so we want check cases from last few hours to be sure all opps will be closed and updated
                    if (minTime == null || c.lastModifiedDate == null || c.lastModifiedDate > minTime.addHours(-3)) {
                        allOpportunities.add(o);
                    }
                } else {
                    FogBugzCase fbCase = fbIdToCaseMap.get(caseId);

                    if (fbCase.externalBugID != null && fbCase.externalBugID != 'null' && fbCase.externalBugID != '') {
                        // Opportunity was deleted and FB cae was closed, we want skip this situation to avoid creating opps all the time
                        System.debug(LoggingLevel.INFO, 'Opp deleted in SF skipping::' + fbCase.caseId);
                        continue;
                    } else {
                        System.debug(LoggingLevel.INFO, 'Processing new opportunity::' + minTime + '-' + fbCase.lastModifiedDate);
                    }

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