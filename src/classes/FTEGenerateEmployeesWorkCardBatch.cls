/**
 * Batch job for createing FTE Work Cards for FTE Employee List View.
 */
public without sharing class FTEGenerateEmployeesWorkCardBatch implements Database.Batchable<SFDC_Employee__c>, Database.Stateful {

    private Integer calculationYear;
    private Set<Id> contractsId;

    public FTEGenerateEmployeesWorkCardBatch(Integer year) {
        this.calculationYear = year;
    }

    public FTEGenerateEmployeesWorkCardBatch(Set<Id> contractsId, Integer year) {
        this.contractsId = contractsId;
        this.calculationYear = year;
    }

    public List<SFDC_Employee__c> start(Database.BatchableContext BC) {
        try {
            if (this.contractsId == null) {
                List<FTE_Work_Card__c> oldCards = [SELECT Id FROM FTE_Work_Card__c];
                if (oldCards.size() > 0) {
                    delete oldCards;
                }
                return [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
            }
            List<Time_Card__c> contractTimeCards = [SELECT Id, Employee__c FROM Time_Card__c WHERE
                                                        Client__c IN: this.contractsId AND CALENDAR_YEAR(Date__c) =: this.calculationYear];
            Set<Id> employees = new Set<Id>();
            for (Time_Card__c tc : contractTimeCards) {
                if (!employees.contains(tc.Employee__c)) {
                    employees.add(tc.Employee__c);
                }
            }
            return [SELECT Id, Name FROM SFDC_Employee__c WHERE Id IN: employees AND Employee_Status__c = 'Active' ORDER BY Name];
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot calculate Employee FTE Work Card', 'Error : ', ex);
            }
        }
        // We need return empty list to avoid errors with sending email about exception
        return new List<SFDC_Employee__c>();
    }

    public void execute(Database.BatchableContext BC, List<SFDC_Employee__c> scope) {
        for (SFDC_Employee__c employee : scope) {
            List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id FROM FTE_Work_Card__c WHERE Employee__c =: employee.Id];
            FTE_Work_Card__c employeeWorkCard = new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = this.calculationYear, Month_1__c = 0,
                                                        Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                                        Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                                        Month_12__c = 0, Total__c = 0, Total_Hours__c = 0);
            if (employeeWorkCards.size() > 0) {
                employeeWorkCard.Id = employeeWorkCards.get(0).Id;
            }

            SObject sObj = (SObject) employeeWorkCard;

            Decimal totalHours = 0;
            Decimal monthHours = 0;
            Decimal monthDays = 0;
            Decimal totalCost = 0;
            Integer month = 1;
            List<Time_Card__c> employeeYearTimeCards = [SELECT Id, Total__c, Date__c, Client__r.FTE_Tracker__c, FTE_hours__c, FTE_Contract__c,
                                                        FTE_Contract__r.FTE_Tracker__c, Time_Card_Salary__c FROM Time_Card__c
                                                        WHERE Employee__c =: employee.Id AND CALENDAR_YEAR(Date__c) =: this.calculationYear AND (Client__r.FTE_Tracker__c = 'Yes'
                                                        OR (Client__r.FTE_Tracker__c != 'Yes' AND FTE_Contract__r.FTE_Tracker__c = 'Yes'))
                                                        AND Total__c != null ORDER BY Date__c]; // we need only fetch timcards assigned and unassigned which are moving time to assigned
            System.debug('TC List: ' + employeeYearTimeCards.size());
            for (Time_Card__c tc : employeeYearTimeCards) {
                System.debug('TC Date: ' + tc.Date__c);
                System.debug('TC Time: ' + tc.Date__c);
                if (tc.Date__c.month() != month) {
                    monthDays = FTETrackerHelper.roundtoDays(monthHours);
                    sObj.put('Month_' + month + '__c', monthDays);
                    month = tc.Date__c.month();
                    monthHours = 0;
                }
                Decimal realHours = tc.Total__c;

                if (tc.Client__r.FTE_Tracker__c == 'Yes' && tc.FTE_Contract__c != null && tc.FTE_Contract__r.FTE_Tracker__c != 'Yes') { // We must substract hours if moved to unassigned
                    realHours = realHours - tc.FTE_hours__c;
                } else if (tc.Client__r.FTE_Tracker__c != 'Yes' && tc.FTE_Contract__c != null && tc.FTE_Contract__r.FTE_Tracker__c == 'Yes') { // we must move hours from unassigned
                    realHours = tc.FTE_hours__c;
                }

                monthHours += realHours;
                totalHours += realHours;
                totalCost += realHours * (tc.Time_Card_Salary__c != null ? tc.Time_Card_Salary__c : 0);
            }

            monthDays = FTETrackerHelper.roundtoDays(monthHours);
            sObj.put('Month_' + month + '__c', monthDays);

            employeeWorkCard = (FTE_Work_Card__c) sObj;
            employeeWorkCard.Total_Hours__c = totalHours;
            employeeWorkCard.Total__c = FTETrackerHelper.roundtoDays(totalHours);
            employeeWorkCard.Unloaded_Rate_Total_Cost__c = totalCost.setScale(2);

            System.debug('WC totalHours: ' + totalHours);
            upsert employeeWorkCard;
        }
    }

    public void finish(Database.BatchableContext BC) {

    }
}