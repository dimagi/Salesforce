public without sharing class FTEHoursUploadBatch implements Database.Batchable<FTE_Data_Record__c>, Database.Stateful {

    private Integer batchYear;
    private Set<Id> employeesSet;
    private Set<Id> contractSet;

    public List<FTE_Data_Record__c> start(Database.BatchableContext BC) {
        this.employeesSet = new Set<Id>();
        this.contractSet = new Set<Id>();
        List<FTE_Data_Record__c> result = [SELECT Year__c, Year_Text__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c,
                Month_10__c, Month_11__c, Month_12__c, Message__c, Employee__c, Employee__r.Name, Processed__c, Contract__c, Contract__r.Name, Line_Number__c
                FROM FTE_Data_Record__c ORDER BY Line_Number__c];

        if (result.size() > 0) {
            DContract__c fteContract = [SELECT Id, Name, Skip_FTE_Tracker_Trigger__c, FTE_Tracker__c FROM DContract__c WHERE Id =: result.get(0).Contract__c LIMIT 1];
            if (fteContract.FTE_Tracker__c != 'Yes') { // we must move contract to FTE
                fteContract.FTE_Tracker__c = 'Yes';
                fteContract.Skip_FTE_Tracker_Trigger__c = true;
                update fteContract;
                contractSet.add(fteContract.Id);
            }
        }

        return result;
    }

    public void execute(Database.BatchableContext BC, List<FTE_Data_Record__c> scope) {
        for (FTE_Data_Record__c fteDataRec : scope) {
            this.batchYear = fteDataRec.Year__c.intValue();
            SFDC_Employee__c employee = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: fteDataRec.Employee__c LIMIT 1];
            FTETimeManager fteTimeManager = new FTETimeManager(employee, this.batchYear);
            fteTimeManager.loadEmployeeTime();

            this.employeesSet.add(employee.Id);
            SObject sObj = (SObject) fteDataRec;
            for (Integer i = 1; i <= 12; i++) {
                Decimal monthDays = -1;
                Object objValue = sObj.get('Month_' + i + '__c');
                if (objValue != null) {
                    monthDays = (Decimal) objValue;
                }

                if (monthDays != null && monthDays >= 0) {
                    try {
                        FTEEmployeeTime emplTime = fteTimeManager.assignedMap.get(fteDataRec.Contract__c);
                        if (emplTime == null) {
                            emplTime = new FTEEmployeeTime(fteDataRec.Contract__r.Name, fteDataRec.Contract__c);
                            fteTimeManager.assignedMap.put(fteDataRec.Contract__c, emplTime);
                        }

                        Decimal timeDiff = emplTime.hoursArray[i - 1] - (8 * (monthDays));
                        Decimal missingTime = 0;
                        if (timeDiff > 0) { // we must move time to unassigned
                            fteTimeManager.moveTimeToUnassigned(timeDiff, i, fteDataRec.Contract__c);
                        } else if (timeDiff < 0) { // we must move time to assigned
                            missingTime = fteTimeManager.moveTimeToAssigned((-1) * timeDiff, i, fteDataRec.Contract__c);
                        }

                        if (missingTime > 0) {
                            insert new FTE_Data_Record_Status__c(Status__c = 'Insufficient hours', Status_Message__c = 'There was no enough hours to move from unassigned for month : ' + i + '. Contract: '
                                                                               + fteDataRec.Contract__r.Name + ' Employee: ' + fteDataRec.Employee__r.Name + ' hours missing : ' + missingTime.setScale(2),
                                                                               Line_Number__c = fteDataRec.Line_Number__c);
                        }
                    } catch (Exception e) {
                        insert new FTE_Data_Record_Status__c(Status__c = 'Other', Status_Message__c = e.getMessage()
                                               + ' Contract : ' + fteDataRec.Contract__r.Name + ' Employee: ' + fteDataRec.Employee__r.Name, Line_Number__c = fteDataRec.Line_Number__c);
                    }
                }
            }
        }

        delete scope;
    }

    public void finish(Database.BatchableContext BC) {
        List<FTE_Data_Record__c> result = [SELECT Year__c, Year_Text__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c,
                Month_10__c, Month_11__c, Month_12__c, Message__c, Employee__c, Employee__r.Name, Processed__c, Contract__c, Contract__r.Name, Line_Number__c
                FROM FTE_Data_Record__c ORDER BY Line_Number__c];

        if (result.size() > 0) {
            delete result;
        }

        Integer yearValue = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue()
                                : Date.today().year();
        if (!Test.isRunningTest() && yearValue == this.batchYear) {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(this.employeesSet, this.contractSet, yearValue), 1);
        }
    }
}