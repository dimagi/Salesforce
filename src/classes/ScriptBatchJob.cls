/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<sObject>, Database.Stateful {

    private Date helperDate;

    /**
     * Script code for setting proper scale for time card salary calculations
     */
    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Time_Card_Salary__c != null AND Date__c <: helperDate';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        List<Time_Card__c> tcList = new List<Time_Card__c>();
        for (sObject sObj : scope) {
            Time_Card__c tc = (Time_Card__c) sObj;
            tc.Time_Card_Salary__c = tc.Time_Card_Salary__c.setScale(8);
        }
        if (tcList.size() > 0) {
            update tcList;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}