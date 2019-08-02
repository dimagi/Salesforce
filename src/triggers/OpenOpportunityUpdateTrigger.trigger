trigger OpenOpportunityUpdateTrigger on Opportunity (before insert, before update) {
    if (trigger.isInsert) {
        OpenOpportunityUtils.handleBeforeInsert(trigger.new);
    } else if (trigger.isUpdate) {
        OpenOpportunityUtils.handleBeforeUpdate(trigger.new, trigger.oldMap);
    }
}