/**
 * Class for adjusting hours when we will have negative values in a month after moving hours.
 */
public without sharing class FTERemoveNegativeHoursBatch implements Database.Batchable<FTEEmployeeMonthUpdated>, Database.Stateful {

    public List<FTEEmployeeMonthUpdated> start(Database.BatchableContext BC) {
        AggregateResult[] groupedResults = [SELECT CALENDAR_MONTH(Date__c), CALENDAR_YEAR(Date__c), Employee__c, TC_Contract__c, SUM(Hours__c)
                                            FROM FTE_Tag__c
                                            WHERE Action__c = 'Updated'
                                            GROUP BY CALENDAR_MONTH(Date__c), CALENDAR_YEAR(Date__c), Employee__c, TC_Contract__c
                                            HAVING SUM(Hours__c) < 0
                                            ORDER BY Employee__c]; // Only monthly negative updates

        List<FTEEmployeeMonthUpdated> records = new List<FTEEmployeeMonthUpdated>();
        for (AggregateResult result : groupedResults) {
            Id employeeId = (Id) result.get('Employee__c');
            Id clientId = (Id) result.get('TC_Contract__c');
            Integer month = (Integer) result.get('expr0');
            Integer year = (Integer) result.get('expr1');
            Decimal hours = (Decimal) result.get('expr2');

            records.add(new FTEEmployeeMonthUpdated(employeeId, clientId, hours, Date.newInstance(year, month, 1)));
        }

        return records;
    }

    public void execute(Database.BatchableContext BC, List<FTEEmployeeMonthUpdated> scope) {
        for (FTEEmployeeMonthUpdated emplMonth : scope) {
            List<Time_Card__c> monthlyTimeCards = [SELECT Id, Client__c, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c
                                                   WHERE CALENDAR_MONTH(Date__c) =: emplMonth.fteDate.month()
                                                   AND CALENDAR_YEAR(Date__c) =: emplMonth.fteDate.year()
                                                   AND Employee__c =: emplMonth.employeeId];
            Map<Id, List<Time_Card__c>> timeCardsMap = new Map<Id, List<Time_Card__c>>();
            Map<Id, Decimal> summedHoursMap = new Map<Id, Decimal>();

            for (Time_Card__c timeCard : monthlyTimeCards) {
                Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
                Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);

                if (timeCard.FTE_Contract__c != null) { // We want cache time cards with tags
                    if (!timeCardsMap.containsKey(timeCard.Client__c)) {
                        timeCardsMap.put(timeCard.Client__c, new List<Time_Card__c>());
                    }
                    List<Time_Card__c> clientTcList = timeCardsMap.get(timeCard.Client__c);
                    clientTcList.add(timeCard);
                    timeCardsMap.put(timeCard.Client__c, clientTcList);
                }

                if (!summedHoursMap.containsKey(timeCard.Client__c)) {
                    summedHoursMap.put(timeCard.Client__c, 0);
                }
                Decimal hoursSum = summedHoursMap.get(timeCard.Client__c);
                hoursSum += (loggedTime - movedTime);
                summedHoursMap.put(timeCard.Client__c, hoursSum);

                // If no FTE Tag values we don't need to process moved hours
                if (timeCard.FTE_Contract__c == null || movedTime == 0) {
                    continue;
                }
                if (!summedHoursMap.containsKey(timeCard.FTE_Contract__c)) {
                    summedHoursMap.put(timeCard.FTE_Contract__c, 0);
                }
                Decimal hoursSum2 = summedHoursMap.get(timeCard.FTE_Contract__c);
                hoursSum2 += movedTime;
                summedHoursMap.put(timeCard.FTE_Contract__c, hoursSum2);
            }

            List<Id> clientsToCheck = new List<Id>();
            clientsToCheck.addAll(summedHoursMap.keySet());
            Map<Id, Time_Card__c> tcToUpdate = new Map<Id, Time_Card__c>();

            while (!clientsToCheck.isEmpty()) { // We must check if we have some negative hours in clients
                Decimal hoursValue = summedHoursMap.get(clientsToCheck.get(0));
                if (hoursValue < 0) {
                    hoursValue = (-1) * hoursValue;
                    // we must find time cards to update
                    List<Time_Card__c> clientTimeCards = timeCardsMap.get(clientsToCheck.get(0));
                    if (clientTimeCards != null) {
                        for (Time_Card__c tc : clientTimeCards) {
                            if (tc.FTE_Contract__c == null) {
                                continue;
                            }
                            Decimal movedTime = tc.FTE_Hours__c != null ? tc.FTE_Hours__c : 0;
                            Decimal hoursToDelete = movedTime > hoursValue ? hoursValue : movedTime;
                            tc.FTE_Hours__c = movedTime - hoursToDelete;
                            hoursValue -= hoursToDelete;
                            clientsToCheck.add(tc.FTE_Contract__c);
                            Decimal fteContractTime = summedHoursMap.get(tc.FTE_Contract__c);
                            summedHoursMap.put(clientsToCheck.get(0), fteContractTime != null ? fteContractTime - hoursToDelete : 0);
                            if (tc.FTE_Hours__c <= 0) {
                                tc.FTE_Contract__c = null;
                            }

                            tcToUpdate.put(tc.Id, tc);
                            if (hoursValue <= 0) {
                                break;
                            }
                        }
                    }
                    summedHoursMap.put(clientsToCheck.get(0), 0); // there is no possibility to have negative time without time cards, we only want take back hours to have 0 hours.
                }
                clientsToCheck.remove(0);
            }

            if (tcToUpdate.size() > 0) {
                update tcToUpdate.values();
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        try {
            List<FTE_Tag__c> tagsToRemove = [SELECT Id FROm FTE_Tag__c WHERE Action__c = 'Updated'];
            if (tagsToRemove.size() > 0) {
                delete tagsToRemove;
            }
            if (!Test.isRunningTest()) {
                Integer fteYear = (FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year());
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(fteYear), 1);
            }
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'FTERemoveNegativeHoursBatch error', 'Cannot remove negative FTE Tags', ex);
            }
        }
    }

    public class FTEEmployeeMonthUpdated {

        public FTEEmployeeMonthUpdated() {}

        public FTEEmployeeMonthUpdated(Id employeeId, Id clientId, Decimal hours, Date fteDate) {
            this.employeeId = employeeId;
            this.clientId = clientId;
            this.hours = hours;
            this.fteDate = fteDate;
        }

        public Id employeeId {get; set;}
        public Id clientId {get; set;}
        public Decimal hours {get; set;}
        public Date fteDate {get; set;}
    }
}