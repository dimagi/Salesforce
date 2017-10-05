trigger FTETimeCardTrigger on Time_Card__c (after delete, after update) {
    Boolean enableTrigger = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Trigger__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Trigger__c : false;
    if (enableTrigger) {
        if (Trigger.isUpdate) {
            for (Time_Card__c updatedTC : Trigger.new) {
                if (updatedTC.Total__c < Trigger.oldMap.get(updatedTC.Id).Total__c) {
                    //we need add how much time was removed from contract month and employee !!!
                }
            }
            //we need add how much time was removed from contract month and employee !!!
        } else { // after delete
            for (Time_Card__c removedTC : Trigger.old) {
                if (removedTC.FTE_only__c != true && removedTC.FTE_Contract__c != null) {
                    // Copy or save removed Tag !!!
                }
                //we need add how much time was removed from contract month and employee !!!
            }
            // we must check if time card contains FTE flag
        }
    }
}