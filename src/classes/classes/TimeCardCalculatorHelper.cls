/**
 * Class for to pre load empl salary and contract billing rate for time card trigger. used to calculate time card cost.
 */
public class TimeCardCalculatorHelper {

    // salary
    private Map<Id, Decimal> employeeSalaryMap;
    private Map<Id, Map<Date, Decimal>> employeeSalarySnpMap;
    private Map<Id, String> billingRateMap;

    // contractor
    private Set<Id> employeeContractor; // we need this map to store info if empl is now contractor
    private Map<Id, Set<Date>> employeeContractorMap; // we need this map to check if there was snapshot and ie employee was contractor
    private Map<Id, Set<Date>> employeeNotContractorMap; // we need this additional map to check if there was snapshot

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

        this.employeeContractor = new Set<Id>();
        this.employeeContractorMap = new Map<Id, Set<Date>>();
        this.employeeNotContractorMap = new Map<Id, Set<Date>>();

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

    public String getClientBillingRate(Id clientId) {
        return this.billingRateMap.get(clientId);
    }

    public Boolean wasContractor(Id employeeId, Time_Card__c timeCard) {
        Date keyDate = getKeyDate(timeCard.Date__c);
        if (this.employeeContractorMap.containsKey(employeeId)
            && this.employeeContractorMap.get(employeeId).contains(keyDate)) {
            // In time card month employee was contractor so we want use Contractor Billing Rate instead of Project Billing Rate
            return true;
        } else if (this.employeeNotContractorMap.containsKey(employeeId)
                   && this.employeeNotContractorMap.get(employeeId).contains(keyDate)) {
            // In time card month employee wasn't contractor, we need this additional map in some important cases
            return false;
        }

        return this.employeeContractor.contains(employeeId);
    }

    public void loadEmployeesSalary(List<Time_Card__c> timeCards) {
        Map<Id, Set<Date>> emplMap = new Map<Id, Set<Date>>();
        Set<Id> contractsIds = new Set<Id>();

        for (Time_Card__c timeCard : timeCards) {
            contractsIds.add(timeCard.Client__c);

            Date lastMonthDate = getKeyDate(timeCard.Date__c);
            if (emplMap.containsKey(timeCard.Employee__c)) {
                Set<Date> dateSet = emplMap.get(timeCard.Employee__c);
                dateSet.add(lastMonthDate);
                emplMap.put(timeCard.Employee__c, dateSet);
            } else {
                emplMap.put(timeCard.Employee__c, new Set<Date> { lastMonthDate });
            }
        }

        this.billingRateMap = new Map<Id, String>();
        for (DContract__c client : [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id IN: contractsIds]) {
            this.billingRateMap.put(client.Id, client.Project_Billing_Rate__c);
        }

        for (Id emplId : emplMap.keySet()) {
            loadEmployeeSalary(emplId, emplMap.get(emplId));
        }
    }

    public void loadEmployeeSalary(Id employeeId, Set<Date> dateSet) {
        if (this.employeeSalaryMap.containsKey(employeeId)) {
            return;
        }

        SFDC_Employee__c employee = [SELECT Id, Salary__c, Exchange_Rate__c, Per_Week_Hours__c, Employee_Type__c
                                     FROM SFDC_Employee__c WHERE Id =: employeeId];
        this.employeeSalaryMap.put(employeeId, TimeCardCalculatorUtils.calculateSalaryForEmployee(employee));
        if (employee.Employee_Type__c == TimeCardCalculatorUtils.CONTRACTOR
            || employee.Employee_Type__c == TimeCardCalculatorUtils.EXTERNAL_CONTRACTOR) {
            // If employee is now contractor we want mark it if there is no snapshot for current month
            this.employeeContractor.add(employee.Id);
        }
        Set<Date> employeeContractorMapping = new Set<Date>();
        Set<Date> employeeNotContractorMapping = new Set<Date>();

        Map<Date, Decimal> emplSnpTmp = new Map<Date, Decimal>();
        for (SFDC_Employee_Snapshot__c emplSnp : [SELECT Id, Salary__c, Exchange_Rate__c, Per_Week_Hours__c, Snapshot_Date__c, Employee_Type__c
                                                  FROM SFDC_Employee_Snapshot__c WHERE Employee_Record__c =: employeeId AND Snapshot_Date__c IN: dateSet]) {
            emplSnpTmp.put(emplSnp.Snapshot_Date__c, TimeCardCalculatorUtils.calculateSalaryForEmplSnapshot(emplSnp));
            if (emplSnp.Employee_Type__c == TimeCardCalculatorUtils.CONTRACTOR
                || emplSnp.Employee_Type__c == TimeCardCalculatorUtils.EXTERNAL_CONTRACTOR) {
                // If employee is contractor or was we want use different billing rates for calculating services spend
                employeeContractorMapping.add(emplSnp.Snapshot_Date__c);
            } else {
                employeeNotContractorMapping.add(emplSnp.Snapshot_Date__c);
            }
        }

        this.employeeSalarySnpMap.put(employeeId, emplSnpTmp);
        this.employeeContractorMap.put(employeeId, employeeContractorMapping);
        this.employeeNotContractorMap.put(employeeId, employeeNotContractorMapping);
    }

    public Decimal getSalary(Id employeeId, Date tcDate) {
        Date keyDate = getKeyDate(tcDate); // Employee Snapshot is taken in the last month day

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

    public static Date getKeyDate(Date inputDate) {
        return Date.newInstance(inputDate.year(), inputDate.month(), Date.daysInMonth(inputDate.year(), inputDate.month()));
    }
}