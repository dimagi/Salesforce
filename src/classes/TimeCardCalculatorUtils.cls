public class TimeCardCalculatorUtils {

    public static Decimal calculateSalaryForEmplSnapshot(SFDC_Employee_Snapshot__c emplSnp) {
        Decimal salary = (((emplSnp.Salary__c != null ? emplSnp.Salary__c : 0)
                            / (emplSnp.Exchange_Rate__c != null && emplSnp.Exchange_Rate__c != 0 ? emplSnp.Exchange_Rate__c : 1.0))
                            / (260.0 * ((emplSnp.Per_Week_Hours__c != null && emplSnp.Per_Week_Hours__c != 0 ? emplSnp.Per_Week_Hours__c : 40.0) / 40.0)))
                            / 8.0;
        return salary.setScale(8);
    }

    public static void markContractsToRefresh(Set<Id> contractIds) {
        List<DContract__c> contractsToRefresh = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id IN: contractIds AND Require_Services_Spend_Refresh__c = false];
        for (DContract__c dContract : contractsToRefresh) {
            dContract.Require_Services_Spend_Refresh__c = true;
        }
        if (contractsToRefresh.size() > 0) {
            Database.SaveResult[] srList = Database.update(contractsToRefresh, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
        }
    }
}