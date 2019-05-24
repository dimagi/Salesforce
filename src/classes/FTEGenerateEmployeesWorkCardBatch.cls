/**
 * Batch job for createing FTE Work Cards for FTE Employee List View.
 */
public without sharing class FTEGenerateEmployeesWorkCardBatch implements Database.Batchable<FTEEmployeeWrapper>, Database.Stateful {

    private Map<Integer, List<FTE_Work_Card__c>> workCardsMap;
    private Set<Id> dataSet;

    public FTEGenerateEmployeesWorkCardBatch() {
        this(null);
    }

    public FTEGenerateEmployeesWorkCardBatch(Set<Id> dataSet) {
        this.dataSet = dataSet;
    }

    public List<FTEEmployeeWrapper> start(Database.BatchableContext BC) {
        List<FTEEmployeeWrapper> result = new List<FTEEmployeeWrapper>();

        try {
            if (this.dataSet == null || this.dataSet.size() == 0) {
                result = generateWrapperList([SELECT Id, Name, Hire_Date__c, Termination_Date__c, Employee_Type__c, Employee_Status__c
                                              FROM SFDC_Employee__c ORDER BY Name]);
                List<FTE_Work_Card__c> oldCards = [SELECT Id FROM FTE_Work_Card__c];
                if (oldCards.size() > 0) {
                    delete oldCards;
                }
            } else if (this.dataSet != null && this.dataSet.size() > 0) {
                for (FTE_Work_Card__c emplWorkCard : [SELECT Employee__c, Year__c FROM FTE_Work_Card__c WHERE Id IN: this.dataSet]) {
                    result.add(new FTEEmployeeWrapper(emplWorkCard.Employee__c, Integer.valueOf(emplWorkCard.Year__c)));
                }
            }

        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot calculate Employee FTE Work Card', 'Error : ', ex);
            }
        }

        return result;
    }

    public void execute(Database.BatchableContext BC, List<FTEEmployeeWrapper> scope) {
        for (FTEEmployeeWrapper employee : scope) {
            List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id FROM FTE_Work_Card__c WHERE Employee__c =: employee.employeeId AND Year__c =: employee.year];
            FTE_Work_Card__c employeeWorkCard = new FTE_Work_Card__c(Employee__c = employee.employeeId, Year__c = employee.year, Month_1__c = 0,
                                                        Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                                        Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                                        Month_12__c = 0, Total__c = 0, Total_Hours__c = 0);
            if (employeeWorkCards.size() > 0) {
                employeeWorkCard.Id = employeeWorkCards.get(0).Id;
            }
            SObject sObj = (SObject) employeeWorkCard;

            Map<Id, FTE_Data_Record__c> contractAllocationMapping = new Map<Id, FTE_Data_Record__c>();
            for (FTE_Data_Record__c futureTemplate : [SELECT Contract__c, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                       Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                       FROM FTE_Data_Record__c
                                                       WHERE Employee__c =: employee.employeeId AND Year__c =: employee.year AND Contract__r.FTE_Tracker__c = 'Yes']) {
                contractAllocationMapping.put(futureTemplate.Contract__c, futureTemplate);
            }

            FTEDataManager dataManager = new FTEDataManager(employee.year, employee.employeeId, true);
            dataManager.loadEmployeeTime();
            dataManager.loadTemplateTime();

            Decimal totalValue = 0;
            Decimal[] timeArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            for (Id contractId : dataManager.assignedMap.keySet()) {
                FTEEmployeeTime emplTime = dataManager.assignedMap.get(contractId);
                for (Integer month = 1; month <= 12; month++) {
                    Decimal templateTime = (emplTime.templateArray[month - 1] != -1 ? emplTime.templateArray[month - 1] * 8 : -1);
                    Decimal loggedTime = emplTime.hoursArray[month - 1];
                    Decimal finalResult = 0;

                    if (templateTime != -1 && templateTime > loggedTime) {
                        finalResult = templateTime;
                        sObj.put(FTETrackerHelper.getFieldTemplateFutureName(month), true); // UI metadata, increase performance
                    } else if (templateTime != -1 && templateTime == loggedTime) {
                        finalResult = loggedTime;
                        sObj.put(FTETrackerHelper.getFieldTemplateBlockedName(month), true); // UI metadata increase performance
                    } else {
                        finalResult = loggedTime;
                    }
                    timeArray[month - 1] += finalResult;
                    totalValue += finalResult;
                }
            }
            employeeWorkCard.Total_Hours__c = totalValue;
            employeeWorkCard.Total__c = FTETrackerHelper.roundtoDays(totalValue);
            // Merge temlate data and real data
            for (Integer month = 1; month <= 12; month++) {
                sObj.put(FTETrackerHelper.getFieldName(month), FTETrackerHelper.roundtoDays(timeArray[month - 1]));
            }
            upsert employeeWorkCard;
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

    private List<FTEEmployeeWrapper> generateWrapperList(List<SFDC_Employee__c> employees) {
        List<FTEEmployeeWrapper> result = new List<FTEEmployeeWrapper>();
        Integer currentYear = Date.today().year();
        Integer twoYearsAhead = currentYear + 2;
        Integer nextYear = currentYear + 1;
        Integer oneYearAgo = currentYear - 1;

        for (SFDC_Employee__c emplRec : employees) {
            if (emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= twoYearsAhead)
                    && emplRec.Termination_Date__c == null) {
                result.add(new FTEEmployeeWrapper(emplRec.Id, twoYearsAhead));
            }

            if (emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= nextYear)
                    && emplRec.Termination_Date__c == null) {
                result.add(new FTEEmployeeWrapper(emplRec.Id, nextYear));
            }

            if ((emplRec.Employee_Status__c == 'Active' && (emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= currentYear))
                || (emplRec.Termination_Date__c != null && emplRec.Termination_Date__c.year() == currentYear)) {
                result.add(new FTEEmployeeWrapper(emplRec.Id, currentYear));
            }

            if ((emplRec.Hire_Date__c != null && emplRec.Hire_Date__c.year() <= oneYearAgo)
                || (emplRec.Termination_Date__c != null && emplRec.Termination_Date__c.year() == oneYearAgo)) {
                result.add(new FTEEmployeeWrapper(emplRec.Id, oneYearAgo));
            }
        }

        return result;
    }
}