/**
 * Runs batch job which creates FogBugz case from Opportunity without case Id.
 */
public class CreateFBCasesSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        if (!Test.isRunningTest()) {
        Database.executeBatch(new CreateFBCasesBatch(), 10);
        }
    }
}