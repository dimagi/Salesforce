trigger FTETimeCardTrigger on Time_Card__c (after delete, after insert) {
    Boolean enableTrigger = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Trigger__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Trigger__c : false;
    if (enableTrigger) {
        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        if (Trigger.isInsert) {
            for (Time_Card__c newTC : Trigger.new) {
                tags.add(new FTE_Tag__c(Action__c = 'Updated', Date__c = newTC.Date__c, Hours__c = newTC.Total__c,
                                        Employee__c = newTC.Employee__c, TC_Contract__c = newTC.Client__c));
            }
        } else { // after delete
            List<Time_Card__c> removedTCList = Trigger.old;
            System.debug('removedTCList ' + removedTCList);
            for (Time_Card__c removedTC : Trigger.old) {
                if (removedTC.FTE_Contract__c != null) {
                    tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = removedTC.Date__c, Hours__c = removedTC.FTE_hours__c,
                                            Employee__c = removedTC.Employee__c, TC_Contract__c = removedTC.Client__c,
                                            FTE_Contract__c = removedTC.FTE_Contract__c));
                }
                tags.add(new FTE_Tag__c(Action__c = 'Updated', Date__c = removedTC.Date__c, Hours__c = (-1) * removedTC.Total__c,
                                        Employee__c = removedTC.Employee__c, TC_Contract__c = removedTC.Client__c));
            }
        }
        if (tags.size() > 0) {
            insert tags;
        }
    }
}