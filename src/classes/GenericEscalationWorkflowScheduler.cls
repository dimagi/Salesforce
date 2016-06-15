/**
 * Schedules job for Generic Escalation Workflow.
 */
global class GenericEscalationWorkflowScheduler implements Schedulable {

    public GenericEscalationWorkflowScheduler () {}

    global void execute(SchedulableContext sc) {
       Database.executeBatch(new GenericEscalationWorkflowBatch(), 5);
    }

}