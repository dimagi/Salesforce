/**
 * Time Card Trigger Handler class. Handles after insert, update and delete events.
 */
public class TimeCardTriggerController {

    public static String CONTRACTOR_RATE_NAME = 'Contractor Billing Rate (0% Indirects)';

    public static void handleBeforeInsert(List<Time_Card__c> newTimeCards) {
        TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();
        Set<Id> contractsIds = new Set<Id>();
        timeCardHelper.loadEmployeesSalary(newTimeCards);
        Date dateThreshold = Date.newInstance(2017, 12, 1);

        for (Time_Card__c timeCard : newTimeCards) {
            contractsIds.add(timeCard.Client__c);
            if (timeCard.Date__c >= dateThreshold) {
                Decimal emplSalary = timeCardHelper.getSalary(timeCard.Employee__c, timeCard.Date__c);
                timeCard.Time_Card_Salary__c = emplSalary;
            }

            String billingRateName = timeCardHelper.getClientBillingRate(timeCard.Client__c);
            // We don't have snapshot for older time cards. We don't want recalculate all services spend
            if (timeCard.Date__c >= dateThreshold && timeCardHelper.wasContractor(timeCard.Employee__c, timeCard) == true) {
                billingRateName = CONTRACTOR_RATE_NAME;
                timeCard.Uses_Contractor_Billing_Rate__c = true;
            }

            Decimal tmpValue = timeCardHelper.getBillingRate(billingRateName, timeCard.Date__c);
            timeCard.Billing_Rate__c = tmpValue;
        }

        TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
    }

    public static void handleAfterInsert(List<Time_Card__c> newTimeCards) {
    }

    public static void handleAfterUpdate(List<Time_Card__c> updatedTimeCards, Map<Id, Time_Card__c> beforeUpdateTimeCards) {
        // Time card Total can't be updated in fogbugz, time card must be deleted and submited again in such case insert and delte trigger will work
        if (RecursiveTriggerHelper.hasRecursiveFlag()) {
            return;
        }

        List<FTE_Tag__c> tags = new List<FTE_Tag__c>();
        List<Time_Card__c> timeCardsWithNewClient = new List<Time_Card__c>();
        Set<Id> contractsIds = new Set<Id>();

        for (Time_Card__c tc : updatedTimeCards) {
            if (tc.FTE_Only__c != true) {
                Time_Card__c oldTC = beforeUpdateTimeCards.get(tc.Id);
                if (oldTC.Client__c != null && tc.Client__c != oldTC.Client__c) {

                    contractsIds.add(oldTC.Client__c);
                    contractsIds.add(tc.Client__c);

                    if (tc.FTE_Contract__c != null) {
                        tags.add(new FTE_Tag__c(Action__c = 'Tag Deleted', Date__c = tc.Date__c, Hours__c = tc.FTE_hours__c,
                                            Employee__c = tc.Employee__c, TC_Contract__c = oldTC.Client__c,
                                            FTE_Contract__c = tc.FTE_Contract__c)); // we can't move time card tags here, it's possible that we will fatch time card with updated client
                    }

                    timeCardsWithNewClient.add(tc);
                }
            }
        }

        if (tags.size() > 0) {
            insert tags;
        }
        if (timeCardsWithNewClient.size() > 0) {
            Date dateThreshold = Date.newInstance(2017, 12, 1);
            Map<Id, String> billingRateMap = new Map<Id, String>();
            TimeCardCalculatorHelper timeCardHelper = new TimeCardCalculatorHelper();

            for (DContract__c client : [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id IN: contractsIds]) {
                billingRateMap.put(client.Id, client.Project_Billing_Rate__c);
            }

            List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
            for (Time_Card__c tcToRecalc : timeCardsWithNewClient) {
                String billingRateName = billingRateMap.get(tcToRecalc.Client__c);
                if (tcToRecalc.Uses_Contractor_Billing_Rate__c == true && tcToRecalc.Date__c >= dateThreshold) {
                    billingRateName = CONTRACTOR_RATE_NAME;
                }
                Decimal billingRate = timeCardHelper.getBillingRate(billingRateName, tcToRecalc.Date__c);

                timeCardsToUpdate.add(new Time_Card__c(Id = tcToRecalc.Id, Billing_Rate__c = billingRate,
                                                       FTE_hours__c = 0,
                                                       FTE_Contract__c = null));
                                                       // if client was updated then it means tags will be moved to other place
            }

            RecursiveTriggerHelper.setRecursiveFlag();
            update timeCardsToUpdate;
        }
        if (contractsIds.size() > 0) {
            TimeCardCalculatorUtils.markContractsToRefresh(contractsIds);
        }
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