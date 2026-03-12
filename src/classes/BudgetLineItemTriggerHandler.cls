/**
 * BudgetLineItemTriggerHandler — enforces lock rules on Budget_Line_Item__c records.
 *
 * Rules:
 *  1. Trigger guard: skip any record where Month_Key__c is null (old date-range records
 *     from the existing Flow implementation — must never be affected by this trigger).
 *  2. On insert/update: if Actuals_Locked__c = 'Yes, actuals final' on any record in
 *     the batch AND the running user does not have the Bypass_Budget_Lock custom permission,
 *     add a field-level error to block the DML.
 *  3. On insert: new records inherit locked status if the month they belong to is already
 *     locked in the budget (checked via sibling records).
 */
public class BudgetLineItemTriggerHandler {

    public static final String LOCKED_VALUE       = 'Yes, actuals final';
    public static final String BYPASS_PERMISSION  = 'Bypass_Budget_Lock';

    // ─── Trigger entry points ─────────────────────────────────────────────────

    public static void onBeforeInsert(List<Budget_Line_Item__c> newRecords) {
        List<Budget_Line_Item__c> relevant = filterRelevant(newRecords);
        if (relevant.isEmpty()) return;

        if (!hasBypassPermission()) {
            inheritLockStatus(relevant);
        }
    }

    public static void onBeforeUpdate(
        List<Budget_Line_Item__c> newRecords,
        Map<Id, Budget_Line_Item__c> oldMap
    ) {
        List<Budget_Line_Item__c> relevant = filterRelevant(newRecords);
        if (relevant.isEmpty()) return;

        if (hasBypassPermission()) return;

        blockLockedEdits(relevant, oldMap);
    }

    // ─── Lock enforcement ─────────────────────────────────────────────────────

    /**
     * Blocks any DML on records that are currently locked.
     * Checks the OLD value of Actuals_Locked__c — once locked, nothing can change.
     */
    private static void blockLockedEdits(
        List<Budget_Line_Item__c> newRecords,
        Map<Id, Budget_Line_Item__c> oldMap
    ) {
        for (Budget_Line_Item__c rec : newRecords) {
            Budget_Line_Item__c oldRec = oldMap.get(rec.Id);
            if (oldRec != null && LOCKED_VALUE.equals(oldRec.Actuals_Locked__c)) {
                rec.addError(
                    'This budget line item is locked (actuals are final) and cannot be modified. ' +
                    'Contact your administrator if a correction is needed.'
                );
            }
        }
    }

    /**
     * On insert, if the budget already has locked months, new records for those months
     * inherit the locked status automatically.
     */
    private static void inheritLockStatus(List<Budget_Line_Item__c> newRecords) {
        // Collect all Budget Ids and month keys from incoming records
        Set<Id> budgetIds = new Set<Id>();
        for (Budget_Line_Item__c rec : newRecords) {
            if (rec.Budget__c != null) budgetIds.add(rec.Budget__c);
        }
        if (budgetIds.isEmpty()) return;

        // Find all locked month keys that already exist in these budgets
        Set<String> lockedKeys = new Set<String>();
        for (Budget_Line_Item__c existing : [
            SELECT Budget__c, Month_Key__c
            FROM Budget_Line_Item__c
            WHERE Budget__c IN :budgetIds
              AND Actuals_Locked__c = :LOCKED_VALUE
              AND Month_Key__c != null
        ]) {
            lockedKeys.add(existing.Budget__c + '|' + existing.Month_Key__c);
        }

        for (Budget_Line_Item__c rec : newRecords) {
            String key = rec.Budget__c + '|' + rec.Month_Key__c;
            if (lockedKeys.contains(key)) {
                rec.Actuals_Locked__c = LOCKED_VALUE;
            }
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Trigger guard: only process records created by the new editor (Month_Key__c populated).
     * Records from the old Flow implementation have null Month_Key__c and must be left alone.
     */
    private static List<Budget_Line_Item__c> filterRelevant(
        List<Budget_Line_Item__c> records
    ) {
        List<Budget_Line_Item__c> result = new List<Budget_Line_Item__c>();
        for (Budget_Line_Item__c rec : records) {
            if (rec.Month_Key__c != null) {
                result.add(rec);
            }
        }
        return result;
    }

    private static Boolean hasBypassPermission() {
        return FeatureManagement.checkPermission(BYPASS_PERMISSION);
    }
}
