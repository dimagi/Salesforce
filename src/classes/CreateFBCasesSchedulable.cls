/**
 * Runs batch job which creates FogBugz case from Opportunity without case Id.
 */
public class CreateFBCasesSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CreateFBCasesBatch(), 10);
    }
}