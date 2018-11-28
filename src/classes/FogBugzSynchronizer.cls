/**
 * Schedules FB Case - Opp sync each hour.
 */
public class FogBugzSynchronizer implements Schedulable {

    public void execute(SchedulableContext SC) {
        FogBugz_Settings__c fbSettings = FogBugz_Settings__c.getOrgDefaults();

        if (!fbSettings.Sync_Script_Running__c) {
            Database.executeBatch(new FogBugzSynchronizerBatch(fbSettings.Sync_Filter__c.intValue(), false), 1);
        }
    }
}