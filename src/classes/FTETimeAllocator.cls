public without sharing class FTETimeAllocator implements Database.Batchable<FTEEmployeeMonthWrapper>, Database.Stateful {

    private Integer cacheYear;
    private Id cacheEmployee;
    private List<FTE_Data_Record__c> cacheRecords;
    private Set<Id> cacheWorkCards;
    private Boolean csvUpload;

    public FTETimeAllocator(Boolean csvUpload) {
        this.csvUpload = csvUpload;
        this.cacheWorkCards = new Set<Id>();
    }

    public List<FTEEmployeeMonthWrapper> start(Database.BatchableContext BC) { // we use data wrapper because we don't want process same month a few times, for example multiple contract updates
        List<FTE_Data_Record__c> result = null;

        result = [SELECT Id, Employee__c, Year__c,
                  Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                  Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                  Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                  Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                  FROM FTE_Data_Record__c
                  WHERE Month_Updated_1__c = true OR Month_Updated_2__c = true OR Month_Updated_3__c = true OR Month_Updated_4__c = true OR
                        Month_Updated_5__c = true OR Month_Updated_6__c = true OR Month_Updated_7__c = true OR Month_Updated_8__c = true OR
                        Month_Updated_9__c = true OR Month_Updated_10__c = true OR Month_Updated_11__c = true OR Month_Updated_12__c = true
                  ORDER BY Employee__c];

        Set<FTEEmployeeMonthWrapper> emplDateSet = new Set<FTEEmployeeMonthWrapper>();
        for (FTE_Data_Record__c fteData : result) {
            SObject sObjTemplate = (SObject) fteData;
            for (Integer month = 1; month <= 12; month++) {
                Boolean needUpdate = (Boolean) sObjTemplate.get(FTETrackerHelper.getFieldUpdatedName(month));
                if (needUpdate) {
                    emplDateSet.add(new FTEEmployeeMonthWrapper(fteData.Employee__c, month, Integer.valueOf(fteData.Year__c)));
                }
            }
        }

        List<FTEEmployeeMonthWrapper> batchData = new List<FTEEmployeeMonthWrapper>();
        batchData.addAll(emplDateSet);
        batchData.sort(); // we want employees in the same order to cache DB data

        return  batchData;
    }

    public void execute(Database.BatchableContext BC, List<FTEEmployeeMonthWrapper> scope) {
        for (FTEEmployeeMonthWrapper employeeMonth : scope) {
            // Handle cache reload
            if (employeeMonth.getEmployeeId() != this.cacheEmployee) {
                this.cacheEmployee = employeeMonth.getEmployeeId();
                this.cacheYear = employeeMonth.getYear();
                List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id FROM FTE_Work_Card__c WHERE Employee__c =: this.cacheEmployee AND Year__c =: this.cacheYear];
                if (employeeWorkCards.size() > 0) {
                    this.cacheWorkCards.add(employeeWorkCards.get(0).Id);
                }
                this.cacheRecords = [SELECT Id, Employee__c, Year__c, Contract__c,
                                                    Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                    Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                    Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                                                    Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                                    FROM FTE_Data_Record__c WHERE Employee__c =: this.cacheEmployee AND Year__c =: this.cacheYear AND Contract__r.FTE_Tracker__c = 'Yes'
                                                    ORDER BY LastModifiedDate];
            }

            // Load employee month time table
            Integer month = employeeMonth.getMonth();
            FTEDataManager fteManager = new FTEDataManager(this.cacheYear, month, this.cacheEmployee, true);
            fteManager.loadEmployeeTime();
            fteManager.removeNegativeTime();

            List<FTE_Data_Record__c> toAssignTemplates = new List<FTE_Data_Record__c>(); // Helper list for sorting, first we must unassign time to be sure all time will be allocated if possible
            List<FTE_Data_Record__c> templatesInOrder = new List<FTE_Data_Record__c>();
            for (FTE_Data_Record__c templateRecord : this.cacheRecords) {
                SObject sObjTemplate = (SObject) templateRecord;
                Decimal monthValue = (Decimal) sObjTemplate.get(FTETrackerHelper.getFieldName(month)); // get month threshold
                if (fteManager.shouldUnassign(templateRecord.Contract__c, monthValue, month)) {
                    templatesInOrder.add(templateRecord);
                } else {
                    toAssignTemplates.add(templateRecord);
                }
            }
            if (toAssignTemplates.size() > 0) {
                templatesInOrder.addAll(toAssignTemplates);
            }

            // Template time allocation loop
            for (FTE_Data_Record__c template : templatesInOrder) {
                SObject sObjTemplate = (SObject) template;
                Decimal monthValue = (Decimal) sObjTemplate.get(FTETrackerHelper.getFieldName(month)); // get month threshold

                fteManager.setTime(template.Contract__c, monthValue * 8); // allocate time in hours not days

                sObjTemplate.put(FTETrackerHelper.getFieldUpdatedName(month), false); // rest month flag
            }

            if (this.cacheRecords.size() > 0) {
                update this.cacheRecords;
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (this.csvUpload == false && !Test.isRunningTest()) { // we want run daily update for all work cards and employees
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(), 1);
        } else if (this.csvUpload == true && this.cacheWorkCards.size() > 0 && !Test.isRunningTest()) {
            Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(this.cacheWorkCards), 1); // refresh only uploaded contract and employees
        }
    }
}