/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 */
public class TimeCardTriggerController {

    public static void handleAfterInsert(List<Time_Card__c> newTimeCards) {
        // We must avoid situation when we exceed transaction limits (100 SOQL),
        // there is possibility that each time card will be from different month or for different employee
        TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();
        Map<Id, Set<Date>> emplSnpMap = new Map<Id, Set<Date>>();
        Map<Id, String> billingRateMap = new Map<Id, String>();
        Set<Id> contractsIds = new Set<Id>();

        for (Time_Card__c timeCard : newTimeCards) {
            contractsIds.add(timeCard.Client__c);
            Date lastMonthDate = Date.newInstance(timeCard.Date__c.year(), timeCard.Date__c.month(), Date.daysInMonth(timeCard.Date__c.year(), timeCard.Date__c.month()));
            if (emplSnpMap.containsKey(timeCard.Employee__c)) {
                Set<Date> dateSet = emplSnpMap.get(timeCard.Employee__c);
                dateSet.add(lastMonthDate);
                emplSnpMap.put(timeCard.Employee__c, dateSet);
            } else {
                emplSnpMap.put(timeCard.Employee__c, new Set<Date> { lastMonthDate });
            }
        }
        timeCardHelper.loadEmployeesSalary(emplSnpMap);

        for (DContract__c client : [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id IN: contractsIds]) {
            billingRateMap.put(client.Id, client.Project_Billing_Rate__c);
        }

        List<Time_Card__c> tcToUpdate = new List<Time_Card__c>();
        for (Time_Card__c timeCard : newTimeCards) {
            Decimal emplSalary = timeCardHelper.getSalary(timeCard.Employee__c, timeCard.Date__c);
            Decimal billingRate = timeCardHelper.getBillingRate(billingRateMap.get(timeCard.Client__c), timeCard.Date__c);
            tcToUpdate.add(new Time_Card__c(Id = timeCard.Id, Time_Card_Salary__c = emplSalary, Billing_Rate__c = billingRate));
        }

        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
        if (tcToUpdate.size() > 0) {
            update tcToUpdate;
        }
    }

    public static void handleAfterUpdate(List<Time_Card__c> updatedTimeCards, Map<Id, Time_Card__c> beforeUpdateTimeCards) {
        if (RecursiveTriggerHelper.hasRecursiveFlag()) {
            return;
        }

        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
        Set<Id> contractsIds = new Set<Id>();

        for (Time_Card__c tc : updatedTimeCards) {
            if (tc.FTE_Only__c != true) {
                Time_Card__c oldTC = beforeUpdateTimeCards.get(tc.Id);
                if (tc.Client__c != oldTC.Client__c) {

                    contractsIds.add(oldTC.Client__c);
                    contractsIds.add(tc.Client__c);
                    Time_Card__c tcToUpdate = null;

                    if (tc.FTE_Contract__c != null) {
                        tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = oldTC.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card with updated client

                        tcToUpdate = new Time_Card__c(Id = tc.Id, FTE_Contract__c = null, FTE_hours__c = 0);
                    }

                    if (tcToUpdate == null) {
                        tcToUpdate = new Time_Card__c(Id = tc.Id);
                    }
                    timeCardsToUpdate.add(tcToUpdate);
                }
            }
        }

        if (tags.size() > 0) {
            insert tags;
        }
        if (timeCardsToUpdate.size() > 0) {
            Map<Id, String> billingRateMap = new Map<Id, String>();
            TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();
            for (DContract__c client : [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id IN: contractsIds]) {
                billingRateMap.put(client.Id, client.Project_Billing_Rate__c);
            }

            for (Time_Card__c tcToRecalc : timeCardsToUpdate) {
                Decimal billingRate = timeCardHelper.getBillingRate(billingRateMap.get(tcToRecalc.Client__c), tcToRecalc.Date__c);
                tcToRecalc.Billing_Rate__c = billingRate;
            }

            RecursiveTriggerHelper.setRecursiveFlag();
            update timeCardsToUpdate;
        }
        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
    }

    public static void handleAfterDelete(List<Time_Card__c> deletedTimeCards) {
        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        Set<Id> contractsIds = new Set<Id>();
        for (Time_Card__c tc : deletedTimeCards) {
            if (tc.FTE_Only__c != true) {
                contractsIds.add(tc.Client__c);
            }
            if (tc.FTE_Contract__c != null) {
                tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = tc.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card to remove
            }
        }

        if (tags.size() > 0) {
            insert tags;
        }
        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
    }
}