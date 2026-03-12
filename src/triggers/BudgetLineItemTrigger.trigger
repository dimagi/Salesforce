/**
 * BudgetLineItemTrigger — thin trigger, all logic delegated to BudgetLineItemTriggerHandler.
 *
 * Trigger guard in handler: records where Month_Key__c is null are skipped entirely,
 * so existing date-range records from the old Flow implementation are never touched.
 */
trigger BudgetLineItemTrigger on Budget_Line_Item__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            BudgetLineItemTriggerHandler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            BudgetLineItemTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
