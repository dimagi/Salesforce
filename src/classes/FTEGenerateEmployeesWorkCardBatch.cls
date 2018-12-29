/**
 * Batch job for createing FTE Work Cards for FTE Employee List View.
 */
public without sharing class FTEGenerateEmployeesWorkCardBatch implements Database.Batchable<EmployeeWrapper>, Database.Stateful {

    private Map<Integer, List<FTE_Work_Card__c>> workCardsMap;
    private Integer calculationYear;
    private Set<Id> contractsId;
    private Set<Id> employeesId;

    public FTEGenerateEmployeesWorkCardBatch() {
        this(null);
    }

    public FTEGenerateEmployeesWorkCardBatch(Integer year) {
        this(new Set<Id>(), new Set<Id>(), year);
    }

    public FTEGenerateEmployeesWorkCardBatch(Set<Id> emplSet, Set<Id> contractSet, Integer year) {
        this.employeesId = emplSet;
        this.contractsId = contractSet;
        this.calculationYear = year;
        this.workCardsMap = new Map<Integer, List<FTE_Work_Card__c>>();
    }

    public List<EmployeeWrapper> start(Database.BatchableContext BC) {
        List<EmployeeWrapper> result = new List<EmployeeWrapper>();

        try {

            if (this.calculationYear == null) {
                result = generateWrapperList([SELECT Id, Name, Hire_Date__c, Termination_Date__c, Employee_Type__c, Employee_Status__c
                                              FROM SFDC_Employee__c ORDER BY Name]);
                List<FTE_Work_Card__c> oldCards = [SELECT Id FROM FTE_Work_Card__c];
                if (oldCards.size() > 0) {
                    delete oldCards;
                }
            } else if (this.calculationYear != null) {
                Integer currentYear = Date.today().year();
                if (this.contractsId.size() > 0) {
                    List<Time_Card__c> contractTimeCards = [SELECT Id, Employee__c FROM Time_Card__c WHERE
                                                       (Client__c IN: this.contractsId OR FTE_Contract__c IN: this.contractsId)
                                                       AND CALENDAR_YEAR(Date__c) =: this.calculationYear];
                    for (Time_Card__c tc : contractTimeCards) {
                        if (!this.employeesId.contains(tc.Employee__c)) {
                            this.employeesId.add(tc.Employee__c);
                        }
                    }
                }

                List<SFDC_Employee__c> emplList = null;
                if (this.employeesId.size() > 0) {
                    emplList = [SELECT Id, Name, Hire_Date__c, Termination_Date__c, Employee_Type__c, Employee_Status__c
                                FROM SFDC_Employee__c WHERE Id IN: this.employeesId AND (Employee_Type__c = 'Employee' OR Employee_Type__c = 'Contractor') ORDER BY Name];
                } else {
                    emplList = [SELECT Id, Name, Hire_Date__c, Termination_Date__c, Employee_Type__c, Employee_Status__c
                                FROM SFDC_Employee__c WHERE (Employee_Type__c = 'Employee' OR Employee_Type__c = 'Contractor') ORDER BY Name];
                }

                for (SFDC_Employee__c emplRec : emplList) {
                    result.add(new EmployeeWrapper(emplRec.Id, currentYear));
                }
            }

        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot calculate Employee FTE Work Card', 'Error : ', ex);
            }
        }

        return result;
    }

    public void execute(Database.BatchableContext BC, List<EmployeeWrapper> scope) {
        for (EmployeeWrapper employee : scope) {
            List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id FROM FTE_Work_Card__c WHERE Employee__c =: employee.employeeId AND Year__c =: employee.year];
            FTE_Work_Card__c employeeWorkCard = new FTE_Work_Card__c(Employee__c = employee.employeeId, Year__c = employee.year, Month_1__c = 0,
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
            Integer month = 1;
            List<Time_Card__c> employeeYearTimeCards = [SELECT Id, Total__c, Date__c, Client__r.FTE_Tracker__c, FTE_hours__c, FTE_Contract__c,
                                                        FTE_Contract__r.FTE_Tracker__c FROM Time_Card__c
                                                        WHERE Employee__c =: employee.employeeId AND CALENDAR_YEAR(Date__c) =: employee.year AND (Client__r.FTE_Tracker__c = 'Yes'
                                                        OR (Client__r.FTE_Tracker__c != 'Yes' AND FTE_Contract__r.FTE_Tracker__c = 'Yes'))
                                                        AND Total__c != null ORDER BY Date__c]; // we need only fetch timcards assigned and unassigned which are moving time to assigned

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
            }

            monthDays = FTETrackerHelper.roundtoDays(monthHours);
            sObj.put('Month_' + month + '__c', monthDays);

            employeeWorkCard = (FTE_Work_Card__c) sObj;
            employeeWorkCard.Total_Hours__c = totalHours;
            employeeWorkCard.Total__c = FTETrackerHelper.roundtoDays(totalHours);

            upsert employeeWorkCard;
        }
    }

    public void finish(Database.BatchableContext BC) {

    }

    private List<EmployeeWrapper> generateWrapperList(List<SFDC_Employee__c> employees) {
        List<EmployeeWrapper> result = new List<EmployeeWrapper>();
        Integer currentYear = Date.today().year();
        Integer nextYear = currentYear + 1;
        Integer oneYearAgo = currentYear - 1;
        Integer twoYearsAgo = currentYear - 2;
        Integer threeYearsAgo = currentYear - 3;

        for (SFDC_Employee__c emplRec : employees) {
            if (emplRec.Employee_Status__c == 'Active') {
                result.add(new EmployeeWrapper(emplRec.Id, nextYear));
            }

            if ((emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= currentYear))
                || (emplRec.Termination_Date__c != null && emplRec.Termination_Date__c.year() == currentYear)) {
                result.add(new EmployeeWrapper(emplRec.Id, currentYear));
            }

            if ((emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= oneYearAgo)
                || (emplRec.Termination_Date__c != null && emplRec.Termination_Date__c.year() == oneYearAgo)) {
                result.add(new EmployeeWrapper(emplRec.Id, oneYearAgo));
            }

            if ((emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= twoYearsAgo)
                || (emplRec.Termination_Date__c != null && emplRec.Termination_Date__c.year() == twoYearsAgo)) {
                result.add(new EmployeeWrapper(emplRec.Id, twoYearsAgo));
            }
        }

        return result;
    }

    public class EmployeeWrapper {

        public Id employeeId { get; set; }
        public Integer year { get; set; }

        public EmployeeWrapper(Id employeeId, Integer year) {
            this.employeeId = employeeId;
            this.year = year;
        }
    }
}