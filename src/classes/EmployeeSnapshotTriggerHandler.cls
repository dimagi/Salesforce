/**
 * Trigger handler for Employee Snapshot custom object.
 */
public class EmployeeSnapshotTriggerHandler {

    public static void handleAfterInsert(List<SFDC_Employee_Snapshot__c> newSnapshots) {
        // notice batch size must be small, currently used only by batch job and size is controlled
        List<SFDC_Employee_Snapshot__c> updatedSalary = new List<SFDC_Employee_Snapshot__c>();
        TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();
        for (SFDC_Employee_Snapshot__c emplSnp : newSnapshots) {
            recalculateTimeCardsCost(emplSnp, timeCardHelper);
        }
    }

    public static void handleAfterUpdate(List<SFDC_Employee_Snapshot__c> updatedSnapshots, Map<Id, SFDC_Employee_Snapshot__c> oldSnapshots) {
        List<SFDC_Employee_Snapshot__c> updatedSalary = new List<SFDC_Employee_Snapshot__c>();
        TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();
        for (SFDC_Employee_Snapshot__c emplSnp : updatedSnapshots) {
            SFDC_Employee_Snapshot__c oldSnp = oldSnapshots.get(emplSnp.Id);
            if (oldSnp.Per_Week_Hours__c != emplSnp.Per_Week_Hours__c
                    || oldSnp.Salary__c != emplSnp.Salary__c
                    || oldSnp.Exchange_Rate__c != emplSnp.Exchange_Rate__c
                    || oldSnp.Employee_Type__c != emplSnp.Employee_Type__c) {
                recalculateTimeCardsCost(emplSnp, timeCardHelper);
            }
        }
    }

    public static void recalculateTimeCardsCost(SFDC_Employee_Snapshot__c emplSnp, TimeCardCalculatorHelper timeCardHelper) { // notice batch size must be small, currently used only by batch job and size is controlled
        Date endDate = emplSnp.Snapshot_Date__c;
        Date startDate = endDate.toStartOfMonth();
        Set<Id> contractIds = new Set<Id>();
        List<Time_Card__c> timeCards = [SELECT Id, Time_Card_Salary__c, Billing_Rate__c, Uses_Contractor_Billing_Rate__c,
                                        Client__r.Project_Billing_Rate__c
                                        FROM Time_Card__c WHERE Employee__c =: emplSnp.Employee_Record__c
                                        AND Date__c >=: startDate AND Date__c <=: endDate AND FTE_Only__c != true];
        System.debug('Employee Snapshot : ' + emplSnp.Name + ' ' + emplSnp.Snapshot_Date__c + ' ' + emplSnp.Employee_Type__c);
        if (timeCards.size() > 0) {
            Decimal emplSalary = TimeCardCalculatorUtils.calculateSalaryForEmplSnapshot(emplSnp);
            for (Time_Card__c tc : timeCards) {
                tc.Time_Card_Salary__c = emplSalary;

                String billingRateName = tc.Client__r.Project_Billing_Rate__c;
                if (emplSnp.Employee_Type__c == 'Contractor') {
                    billingRateName = TimeCardTriggerController.CONTRACTOR_RATE_NAME;
                    tc.Uses_Contractor_Billing_Rate__c = true;
                } else {
                    tc.Uses_Contractor_Billing_Rate__c = false;
                }
                tc.Billing_Rate__c = timeCardHelper.getBillingRate(billingRateName, tc.Date__c);

                contractIds.add(tc.Client__c);
            }

            update timeCards;
            TimeCardCalculatorUtils.markContractsToRefresh(contractIds);
        }
    }
}