public without sharing class FTEHoursUploadBatch implements Database.Batchable<FTEUploadData>, Database.Stateful {

    private Integer batchYear;
    private Set<Id> employeesSet;
    private Set<Id> contractSet;
    private List<FTEUploadData> timeData;

    public FTEHoursUploadBatch(List<FTEUploadData> timeData) {
        this.timeData = timeData;
    }

    public List<FTEUploadData> start(Database.BatchableContext BC) {
        this.employeesSet = new Set<Id>();
        this.contractSet = new Set<Id>();

        if (this.timeData.size() > 0) {
            DContract__c fteContract = [SELECT Id, Name, Skip_FTE_Tracker_Trigger__c, FTE_Tracker__c FROM DContract__c WHERE Id =: this.timeData.get(0).getContractId() LIMIT 1];
            if (fteContract.FTE_Tracker__c != 'Yes') { // we must move contract to FTE
                fteContract.FTE_Tracker__c = 'Yes';
                fteContract.Skip_FTE_Tracker_Trigger__c = true;
                update fteContract;
                contractSet.add(fteContract.Id);
            }
        }

        return this.timeData;
    }

    public void execute(Database.BatchableContext BC, List<FTEUploadData> scope) {
        for (FTEUploadData fteDataRec : scope) {
            this.batchYear = fteDataRec.getFTEYear();
            SFDC_Employee__c employee = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: fteDataRec.getEmployeeId() LIMIT 1];
            FTETimeManager fteTimeManager = new FTETimeManager(employee, this.batchYear);
            fteTimeManager.loadEmployeeTime();

            this.employeesSet.add(employee.Id);
            for (Integer i = 1; i <= 12; i++) {
                Decimal monthDays = fteDataRec.getMonthTime(i);

                if (monthDays != null && monthDays >= 0) {
                    try {
                        FTEEmployeeTime emplTime = fteTimeManager.assignedMap.get(fteDataRec.getContractId());
                        if (emplTime == null) {
                            emplTime = new FTEEmployeeTime(fteDataRec.getContractName(), fteDataRec.getContractId(), false);
                            fteTimeManager.assignedMap.put(fteDataRec.getContractId(), emplTime);
                        }

                        Decimal timeDiff = emplTime.hoursArray[i - 1] - (8 * (monthDays));
                        Decimal missingTime = 0;
                        if (timeDiff > 0) { // we must move time to unassigned
                            fteTimeManager.moveTimeToUnassigned(timeDiff, i, fteDataRec.getContractId());
                            fteTimeManager.updateWorkcard((timeDiff / 8), i, fteDataRec.getContractId());
                        } else if (timeDiff < 0) { // we must move time to assigned
                            missingTime = fteTimeManager.moveTimeToAssigned((-1) * timeDiff, i, fteDataRec.getContractId());
                            fteTimeManager.updateWorkcard((-1) *(timeDiff / 8), i, fteDataRec.getContractId());
                        }

                        if (missingTime > 0) {
                            insert new FTE_Data_Record_Status__c(Status__c = 'Insufficient hours', Status_Message__c = 'There was no enough hours to move from unassigned for month : ' + i + '. Contract: '
                                                                               + fteDataRec.getContractName() + ' Employee: ' + fteDataRec.getEmployeeName() + ' hours missing : ' + missingTime.setScale(2));
                        }
                    } catch (Exception e) {
                        insert new FTE_Data_Record_Status__c(Status__c = 'Other', Status_Message__c = e.getMessage()
                                               + ' Contract : ' + fteDataRec.getContractName() + ' Employee: ' + fteDataRec.getEmployeeName());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        List<FTE_Data_Record__c> result = [SELECT Year__c, Year_Text__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c,
                Month_10__c, Month_11__c, Month_12__c, Message__c, Employee__c, Employee__r.Name, Processed__c, Contract__c, Contract__r.Name, Line_Number__c
                FROM FTE_Data_Record__c ORDER BY Line_Number__c];

        if (result.size() > 0) {
            delete result;
        }

        if (!Test.isRunningTest()) {
            if (this.contractSet.size() > 0) {
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(), 1); // we want refresh all 2 years because we can exced transaction limit in SF
                                                                                   // to get empl list : 3 years time cards for contract can be bigger then 50k records
            } else if (this.batchYear >= Date.today().year() - 2) {
                Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(this.employeesSet, new Set<Id>(), this.batchYear), 1); // refresh only employees and uploaded year
            }
        }
    }
}