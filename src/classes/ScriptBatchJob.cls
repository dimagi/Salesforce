/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Time_Card__c>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public List<Time_Card__c> start(Database.BatchableContext context) {
        return [SELECT Id, Case_Number__c, Date__c, Employee__c, Client__c, Fogbugz_Id__c FROM Time_Card__c WHERE CreatedDate  >=: this.helperDate AND FTE_only__c != true];
    }

    public void execute(Database.BatchableContext context, List<Time_Card__c> scope) {
        for (Time_Card__c tc : scope) {
            List<Time_Card__c> tcList = [SELECT Id FROM Time_Card__c WHERE Date__c =: tc.Date__c AND Employee__c =: tc.Employee__c
                                            AND Client__c =: tc.Client__c AND Case_Number__c =: tc.Case_Number__c AND Id !=: tc.Id
                                            AND Fogbugz_Id__c = null AND FTE_only__c != true];
            if (tcList.size() > 0) {
                delete tcList;
            }
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}