/**
 * Class for to pre load empl salary and contract billing rate for time card trigger. used to calculate time card cost.
 */
public class TimeCardCalculatorHelper {

    // salary
    private Map<Id, Decimal> employeeSalaryMap;
    private Map<Id, Map<Date, Decimal>> employeeSalarySnpMap;

    // billing rate
    private String lastRateName = '';
    private Date lastFromRateDate = Date.newInstance(1900, 1, 1);
    private Date lastToRateDate = Date.today().addYears(1);
    private Decimal contractRate;
    private Map<String, List<SalaryHistoryRecord>> billingRateHistoryMap;
    private List<SalaryHistoryRecord> currentRateHistory;

    public TimeCardCalculatorHelper() {
        this.employeeSalaryMap = new Map<Id, Decimal>();
        this.employeeSalarySnpMap = new Map<Id, Map<Date, Decimal>>();

        this.billingRateHistoryMap = new Map<String, List<SalaryHistoryRecord>>();
        this.currentRateHistory = new List<SalaryHistoryRecord>();

        this.lastRateName = '';
        this.lastFromRateDate = Date.newInstance(1900, 1, 1);
        this.lastToRateDate = Date.today().addYears(1);
        this.contractRate = 1.0;
    }

    public Boolean containsEmployee(Id employeeId) {
        return this.employeeSalaryMap.containsKey(employeeId);
    }

    public void loadEmployeesSalary(Map<Id, Set<Date>> emplMap) {
        for (Id emplId : emplMap.keySet()) {
            loadEmployeeSalary(emplId, emplMap.get(emplId));
        }
    }

    public void loadEmployeeSalary(Id employeeId, Set<Date> dateSet) {
        if (this.employeeSalaryMap.containsKey(employeeId)) {
            return;
        }

        SFDC_Employee__c employee = [SELECT Id, Salary__c, Exchange_Rate__c, Per_Week_Hours__c FROM SFDC_Employee__c WHERE Id =: employeeId];
        this.employeeSalaryMap.put(employeeId, TimeCardCalculatorUtils.calculateSalaryForEmployee(employee));

        Map<Date, Decimal> emplSnpTmp = new Map<Date, Decimal>();
        for (SFDC_Employee_Snapshot__c emplSnp : [SELECT Id, Salary__c, Exchange_Rate__c, Per_Week_Hours__c, Snapshot_Date__c FROM SFDC_Employee_Snapshot__c
                                                    WHERE Employee_Record__c =: employeeId AND Snapshot_Date__c IN: dateSet]) {
            emplSnpTmp.put(emplSnp.Snapshot_Date__c, TimeCardCalculatorUtils.calculateSalaryForEmplSnapshot(emplSnp));
        }

        this.employeeSalarySnpMap.put(employeeId, emplSnpTmp);
    }

    public Decimal getSalary(Id employeeId, Date tcDate) {
        Date keyDate = Date.newInstance(tcDate.year(), tcDate.month(), Date.daysInMonth(tcDate.year(), tcDate.month())); // Employee Snapshot is taken in the last month day

        if (employeeSalarySnpMap.containsKey(employeeId)) {
            Map<Date, Decimal> currentMap = employeeSalarySnpMap.get(employeeId);

            if (currentMap.containsKey(keyDate)) {
                return currentMap.get(keyDate);
            }
        }

        return employeeSalaryMap.get(employeeId); // Snapshot not yet created, calculate salary with current employee salary
    }

    public Decimal getBillingRate(String billingRate, Date tcDate) {
        if (!this.billingRateHistoryMap.containsKey(billingRate)) { // Load missin billing rate
            this.billingRateHistoryMap.put(billingRate, loadBillingRatesHistory(billingRate));
        }

        if (billingRate != this.lastRateName) {
            this.lastRateName = billingRate;
            this.currentRateHistory = this.billingRateHistoryMap.get(billingRate);
            this.lastToRateDate = this.currentRateHistory.size() > 1 ? this.currentRateHistory.get(1).getValueDate() : Date.today().addYears(1);
            this.lastFromRateDate = Date.newInstance(1900, 1, 1);
            this.contractRate = this.currentRateHistory.get(0).getValue();
        }

        if (tcDate < this.lastFromRateDate || tcDate >= this.lastToRateDate) {
            Integer index = 0;
            for (Integer i = 0; i < this.currentRateHistory.size(); i++) {
                index = i;
                if (tcDate >= this.currentRateHistory.get(i).getValueDate()) {
                    this.contractRate = this.currentRateHistory.get(i).getValue();
                    this.lastFromRateDate = this.currentRateHistory.get(i).getValueDate();
                } else {
                    index = i - 1;
                    break;
                }
            }
            this.lastToRateDate = this.currentRateHistory.size() > index + 1 ? this.currentRateHistory.get(index + 1).getValueDate() : Date.today().addYears(1);
        }

        return this.contractRate;
    }

    public List<SalaryHistoryRecord> loadBillingRatesHistory(String billingRateName) {
        List<SalaryHistoryRecord> billingRateHistory = new List<SalaryHistoryRecord>();
        if (billingRateName == '' || billingRateName == null) {
            billingRateName = 'Loaded Daily Rate';
        }

        List<Project_Billing_Rate__c> ratesRecords = [SELECT Id, Date__c, Custom_1__c, Custom_2__c, Custom_3__c, Fee__c, Fringe__c, G_A__c, Overhead__c FROM Project_Billing_Rate__c
                                                        WHERE Name =: billingRateName ORDER BY Date__c];

        for (Project_Billing_Rate__c rate : ratesRecords) {
            Decimal custom1 = rate.Custom_1__c != null ? 1.00 + (rate.Custom_1__c / 100.00) : 1;
            Decimal custom2 = rate.Custom_2__c != null ? 1.00 + (rate.Custom_2__c / 100.00) : 1;
            Decimal custom3 = rate.Custom_3__c != null ? 1.00 + (rate.Custom_3__c / 100.00) : 1;
            Decimal fee = rate.Fee__c != null ? 1.00 + (rate.Fee__c / 100.00) : 1;
            Decimal fringe = rate.Fringe__c != null ? 1.00 + (rate.Fringe__c / 100.00) : 1;
            Decimal ga = rate.G_A__c != null ? 1.00 + (rate.G_A__c / 100.00) : 1;
            Decimal over = rate.Overhead__c != null ? 1.00 + (rate.Overhead__c / 100.00) : 1;

            Decimal rateValue = custom1 * custom2 * custom3 * fee * fringe * ga * over;
            billingRateHistory.add(new SalaryHistoryRecord(rateValue, rate.Date__c));
        }

        if (billingRateHistory.size() == 0) {
            billingRateHistory.add(new SalaryHistoryRecord(1.0, Date.newInstance(1900, 1, 1))); // 100% of Daily Rate
        }

        return billingRateHistory;
    }
}