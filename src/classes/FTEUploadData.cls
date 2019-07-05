public class FTEUploadData {

    private Id employeeId;
    private Id contractId;
    private String employeeName;
    private String contractName;
    private Integer fteYear;
    private Decimal[] timeTable;

    public FTEUploadData (Id employeeId, Id contractId, String employeeName, String contractName, Integer fteYear) {
        this.employeeId = employeeId;
        this.contractId = contractId;
        this.employeeName = employeeName;
        this.contractName = contractName;
        this.fteYear = fteYear;
        this.timeTable = new Decimal[] {-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2}; // -2 means that month wasn't uploaded, -1 means we want reset threshold
    }

    public Decimal getMonthTime(Integer month) {
        return this.timeTable[month - 1];
    }

    public void addMonthTime(Integer month, Decimal value) {
        if (this.timeTable[month - 1] == -2) {
            this.timeTable[month - 1] = value;
        } else if (value >= 0) { // we don't want add (-1) just skip it if employee data was duplicated in uploaded CSV
            if (this.timeTable[month - 1] == -1) {
                value += 1;
            }
            this.timeTable[month - 1] = this.timeTable[month - 1] + value;
        }
    }

    public Id getEmployeeId() {
        return this.employeeId;
    }

    public Id getContractId() {
        return this.contractId;
    }

    public String getEmployeeName() {
        return this.employeeName;
    }

    public String getContractName() {
        return this.contractName;
    }

    public Integer getFTEYear() {
        return this.fteYear;
    }

    public FTE_Data_Record__c mergeData(FTE_Data_Record__c rec) {
        if (rec == null) {
            rec = new FTE_Data_Record__c(Year__c = this.fteYear, Contract__c = this.contractId, Employee__c = this.employeeId);
        }

        SObject recSObj = (SObject) rec;
        for (Integer month = 1; month <= 12; month++) {
            Decimal oldValue = null;
            if (rec.Id != null) {
                oldValue = (Decimal) recSObj.get(FTETrackerHelper.getFieldName(month));
            }
            System.debug('Month merge : old : ' + oldValue + ' new ' + this.timeTable[month - 1]);
            if (this.timeTable[month - 1] > -2 && ((oldValue == null && this.timeTable[month - 1] != -1) || (oldValue != null && oldValue != this.timeTable[month - 1]))) { // -2 means that nothing was uploaded for that month
                System.debug('Month merge set true');
                recSObj.put(FTETrackerHelper.getFieldName(month), this.timeTable[month - 1]);
                recSObj.put(FTETrackerHelper.getFieldUpdatedName(month), true);
            }
        }

        return (FTE_Data_Record__c) recSObj;
    }
}