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
                // List<FTE_Work_Card__c> oldCards = [SELECT Id FROM FTE_Work_Card__c];
                // if (oldCards.size() > 0) {
                //     delete oldCards;
                // }
            } else if (this.calculationYear != null) {
                Integer currentYear = Date.today().year();
                if (this.contractsId.size() > 0) {
                    List<Time_Card__c> contractTimeCards = [SELECT Id, Employee__c FROM Time_Card__c WHERE
                                                       (Client__c IN: this.contractsId OR FTE_Contract__c IN: this.contractsId)
                                                       AND CALENDAR_YEAR(Date__c) =: this.calculationYear
                                                       AND (Employee__r.Employee_Type__c = 'Employee' OR Employee__r.Employee_Type__c = 'Contractor')];
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
            if (employeeWorkCards.size() == 0) {
               insert employeeWorkCard;
            }
        }
    }

    public void finish(Database.BatchableContext BC) {

    }

    private List<EmployeeWrapper> generateWrapperList(List<SFDC_Employee__c> employees) {
        List<EmployeeWrapper> result = new List<EmployeeWrapper>();
        Integer currentYear = Date.today().year();
        Integer twoYearsAhead = currentYear + 2;
        Integer nextYear = currentYear + 1;
        Integer oneYearAgo = currentYear - 1;

        for (SFDC_Employee__c emplRec : employees) {
            if (emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= twoYearsAhead)
                    && emplRec.Termination_Date__c == null) {
                result.add(new EmployeeWrapper(emplRec.Id, twoYearsAhead));
            }

            if (emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= nextYear)
                    && emplRec.Termination_Date__c == null) {
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