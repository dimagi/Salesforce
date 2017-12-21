trigger ProjectBillingRateUpdatedTrigger on DContract__c (after update) {

    List<Id> contracts = new List<Id>();
    for (DContract__c con : Trigger.new) {
        DContract__c oldValue = Trigger.oldMap.get(con.Id);
        if (oldValue == null || oldValue.Project_Billing_Rate__c != con.Project_Billing_Rate__c) {
            contracts.add(con.Id);
        }
    }

    if (contracts.size() > 0) { // after changing billing rate we must update time cards billing rates values
        Database.executeBatch(new BatchRecalculateTimeCardCost(new Set<Id>(), contracts, true), 200);
    }
}