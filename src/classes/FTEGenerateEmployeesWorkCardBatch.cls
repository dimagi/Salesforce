public without sharing class FTEGenerateEmployeesWorkCardBatch implements Database.Batchable<SFDC_Employee__c>, Database.Stateful {

    private Integer calculationYear;

    public FTEGenerateEmployeesWorkCardBatch(Integer year) {
        this.calculationYear = year;
    }

    public List<SFDC_Employee__c> start(Database.BatchableContext BC) {
        return [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
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
            Integer month = 1;
            List<Time_Card__c> employeeYearTimeCards = [SELECT Id, Total__c, Date__c FROM Time_Card__c WHERE Employee__c =: employee.Id
                                                        AND Client__r.FTE_Tracker__c = 'Yes'AND CALENDAR_YEAR(Date__c) =: this.calculationYear
                                                        AND Total__c != null ORDER BY Date__c];
            System.debug('TC List: ' + employeeYearTimeCards.size());
            for (Time_Card__c tc : employeeYearTimeCards) {
                System.debug('TC Date: ' + tc.Date__c);
                System.debug('TC Time: ' + tc.Date__c);
                if (tc.Date__c.month() != month) {
                    monthDays = roundtoDays(monthHours);
                    sObj.put('Month_' + month + '__c', monthDays);
                    month = tc.Date__c.month();
                    monthHours = 0;
                }
                monthHours += tc.Total__c;
                totalHours += tc.Total__c;
            }
            monthDays = roundtoDays(monthHours);
            sObj.put('Month_' + month + '__c', monthDays);

            employeeWorkCard = (FTE_Work_Card__c) sObj;
            employeeWorkCard.Total_Hours__c = totalHours;
            employeeWorkCard.Total__c = roundtoDays(totalHours);
            System.debug('WC totalHours: ' + totalHours);
            upsert employeeWorkCard;
        }
    }

    public void finish(Database.BatchableContext BC) {

    }

    public Decimal roundtoDays(Decimal hours) {
        Decimal totalDays = (hours / 8.0).intValue();
        Decimal restValue = hours - (totalDays * 8);
        return totalDays + (0.25 * (restValue / 2.0).setScale(0, System.RoundingMode.HALF_UP));
    }
}