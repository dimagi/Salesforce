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
        this.timeTable = new Decimal[] {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
    }

    public Decimal getMonthTime(Integer month) {
        return this.timeTable[month - 1];
    }

    public void addMonthTime(Integer month, Decimal value) {
        if (this.timeTable[month - 1] == -1) {
            this.timeTable[month - 1] = value;
        } else {
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

    public FTE_Data_Record__c buildDBRec() {
        return new FTE_Data_Record__c(Month_1__c = this.timeTable[0], Month_2__c = this.timeTable[1], Month_3__c = this.timeTable[2],
                                      Month_4__c = this.timeTable[3], Month_5__c = this.timeTable[4], Month_6__c = this.timeTable[5],
                                      Month_7__c = this.timeTable[6],Month_8__c = this.timeTable[7], Month_9__c = this.timeTable[8],
                                      Month_10__c = this.timeTable[9], Month_11__c = this.timeTable[10], Month_12__c = this.timeTable[11],
                                      Year__c = this.fteYear, Contract__c = this.contractId, Employee__c = this.employeeId, Line_Number__c = 1);
    }
}