/**
 * Schedules FTEGenerateEmployeesWorkCardScheduler job for calculating Domains Lifetime MRR.
 */
public without sharing class FTEGenerateEmployeesWorkCardScheduler implements Schedulable {

    public FTEGenerateEmployeesWorkCardScheduler() {}

    public void execute(SchedulableContext sc) {
       Integer fteYear = (FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year());
       Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(fteYear), 1);
    }
}