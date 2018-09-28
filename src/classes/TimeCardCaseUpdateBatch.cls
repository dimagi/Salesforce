/**
 * Time card sync batch job chain. TimeCardCaseUpdateBatch (Fetch updated cases from FB and update fields in time cards, like area, project , title or client).
 */
public class TimeCardCaseUpdateBatch implements Database.Batchable<FogBugzCase>, Database.AllowsCallouts, Database.Stateful {

    private DateTime startDateTime;

    public List<FogBugzCase> start(Database.BatchableContext context) {
        FogBugzAPI fogbugzApi = new FogBugzAPI();
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        this.startDateTime = DateTime.now();

        DateTime syncDateTime = batchSettings.Fogbugz_Cases_Fetch_Last_Date__c != null ? batchSettings.Fogbugz_Cases_Fetch_Last_Date__c : DateTime.now().addDays(-1);
        List<FogBugzCase> cases = fogbugzApi.getLastUpdatedCases(syncDateTime);

        if (cases != null) {
            batchSettings.Fogbugz_Cases_Fetch_Last_Date__c = this.startDateTime;
            update batchSettings;
            return cases;
        }

        if (!Test.isRunningTest()) {
            EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Cannot load updated cases from Fogbugz', 'Cannot fetch updated cases, sync date will not be updated');
        }

        return new List<FogBugzCase>();
    }

    public void execute(Database.BatchableContext context, List<FogBugzCase> scope) {
        List<Time_Card__c> tcList = new List<Time_Card__c>();
        for (FogBugzCase fbCase : scope) {
            if (fbCase.client == null || fbCase.client == '') {
                continue; // we must skip empty clients in cases - less processing, we don't have time cards for such cases
            }

            String dbCaseTitle = fbCase.caseId + ': ' + fbCase.title;
            Integer clientFBId = Integer.valueOf(fbCase.client);
            List<Time_Card__c> timeCardsToUpdate = [SELECT Id, Area__c, Case__c, Project__c, Client__c FROM Time_Card__c WHERE Case_Number__c =: fbCase.caseId AND FTE_only__c = false
                                                        AND (Area__c !=: fbCase.area OR Case__c !=: dbCaseTitle OR Project__c !=: fbCase.project
                                                            OR Client__r.FB_Id__c !=: clientFBId)];


            List<DContract__c> contracts = [SELECT Id, Name FROM DContract__c WHERE FB_Id__c =: clientFBId];
            DContract__c newContract = null;
            if (contracts.size() > 0) {
                newContract = contracts.get(0);
            }

            for (Time_Card__c tc : timeCardsToUpdate) {
                tc.Area__c = fbCase.area;
                tc.Case__c = dbCaseTitle;
                tc.Project__c = fbCase.project;
                if (newContract != null) {
                    tc.Client__c = newContract.Id;
                }
            }

            if (timeCardsToUpdate.size() > 0) {
                tcList.addAll(timeCardsToUpdate);
            }

            if (timeCardsToUpdate.size() > 0 && newContract == null && !Test.isRunningTest()) {
                EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Fogbugz Id Mismatch', 'Case Id : ' + fbCase.caseId + ', Cannot find contract with Fogbugz Id : ' + fbCase.client);
            }
        }

        if (tcList.size() > 0) {
            update tcList;
        }
    }

    public void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new TimeCardCalculator());
        }
    }
}