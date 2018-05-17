trigger ProjectBillingRateUpdatedTrigger on DContract__c (after update) {

    if (!RecursiveTriggerHelper.hasRecursiveFlag()) {
        List<DContract__c> contracts = new List<DContract__c>();
        for (DContract__c con : Trigger.new) {
            DContract__c oldValue = Trigger.oldMap.get(con.Id);
            if (oldValue == null || oldValue.Project_Billing_Rate__c != con.Project_Billing_Rate__c) {
                contracts.add(new DContract__c(Id = con.Id, Project_Billing_Rate_Updated__c = true, Require_Services_Spend_Refresh__c = true));
            }
        }

        if (contracts.size() > 0) {
            Database.SaveResult[] srList = Database.update(contracts, false);
            RecursiveTriggerHelper.setRecursiveFlag();
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
        }
    }
}