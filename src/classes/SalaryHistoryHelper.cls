/**
 * Helper class for fetching salary history for employees
 */
public without sharing class SalaryHistoryHelper {

    /**
     * Builds employee salary and exchange rate history.
     */
    public List<SalaryHistoryRecord> getHistoryForEmployee(SFDC_Employee__c employee, String salaryField, String dateField) {
        List<SalaryHistoryRecord> salaryList = new List<SalaryHistoryRecord>();
        List<SalaryHistoryWrapper> employeeSalaryHistory = getFieldHistory(employee, salaryField);
        List<SalaryHistoryWrapper> employeeSalaryDateHistory = getFieldHistory(employee, dateField);

        Date lastSalaryDate = Date.newInstance(1900, 1, 1);
        Decimal lastSalary;
        Integer salaryIndex = 0;

        // Cases for first History record:
        // * No history 
        // * Salary is empty and no history
        // * History record which updates from null to value (start value)
        // * History record which updates from first value to second (OldValue field is start value)

        // No history we must fetch data from current record - Effective date for first sallary will be 01.01.1900
        if (employeeSalaryHistory.size() == 0) {
            if (salaryField == 'Salary__c') {
                salaryList.add(new SalaryHistoryRecord(employee.Salary__c == null ? 0 : (Decimal) employee.Salary__c, lastSalaryDate));
            } else {
                salaryList.add(new SalaryHistoryRecord(employee.Exchange_Rate__c == null ? 1 : (Decimal) employee.Exchange_Rate__c, lastSalaryDate));
            }
        } else { // We have salary history
            // We can have history of first fill or first update we must check and set proper first salary - Effective date for first sallary will be 01.01.1900
            if (employeeSalaryHistory.get(0).OldValue == null) {
                // First salary is in NewValue
                lastSalary = getValueForSalary(salaryField, employeeSalaryHistory.get(0));
                salaryIndex++;
            } else {
                // First salary is in OldValue
                if (salaryField == 'Salary__c' ) {
                    lastSalary = (Decimal) employeeSalaryHistory.get(0).OldValue;
                } else {
                    lastSalary = ((Decimal) employeeSalaryHistory.get(0).OldValue) == 0 ? 1 : (Decimal) employeeSalaryHistory.get(0).OldValue;
                }
            }

            salaryList.add(new SalaryHistoryRecord(lastSalary, lastSalaryDate));

            Map <Date, Date> effectiveDateMap = new Map<Date, Date>();
            if (employeeSalaryDateHistory.size() > 0) {
                if (employeeSalaryDateHistory.get(0).OldValue != null) {
                    effectiveDateMap.put(takeDate((DateTime) employeeSalaryDateHistory.get(0).CreatedDate),
                                         (Date) employeeSalaryDateHistory.get(0).OldValue);
                }
            }

            Date lEffDate = Date.newInstance(1900, 1, 1);
            for (Integer i = 0; i < employeeSalaryDateHistory.size(); i++) {
                effectiveDateMap.put(takeDate((DateTime) employeeSalaryDateHistory.get(i).CreatedDate),
                                      employeeSalaryDateHistory.get(i).NewValue == null ? lEffDate : (Date) employeeSalaryDateHistory.get(i).NewValue);
                if (employeeSalaryDateHistory.get(i).NewValue != null) {
                    lEffDate = (Date) employeeSalaryDateHistory.get(i).NewValue;
                }
            }

            Integer helperIndex = 0;
            for (Integer i = salaryIndex; i < employeeSalaryHistory.size(); i++) {

                Date cDate = takeDate((DateTime) employeeSalaryHistory.get(i).CreatedDate);
                Date toAdd = cDate;

                if (effectiveDateMap.containsKey(cDate)) {
                    toAdd = effectiveDateMap.get(cDate);
                }

                if (lastSalaryDate == cDate) {
                    System.debug('Update: '+ helperIndex + ' ' + employeeSalaryHistory[i].NewValue);
                    salaryList.set(helperIndex, new SalaryHistoryRecord(getValueForSalary(salaryField, employeeSalaryHistory.get(i)),
                                                                        toAdd));
                } else {
                    salaryList.add(new SalaryHistoryRecord(getValueForSalary(salaryField, employeeSalaryHistory.get(i)),
                                                           toAdd));
                    helperIndex++;
                }

                lastSalaryDate = cDate;
            }
        }

        return salaryList;
    }

    public List<SalaryHistoryRecord> mergeSalaryHistory(SFDC_Employee__c employee, Boolean testMode) {
        System.debug('Using Mode : ' + testMode + ' for Name : ' + employee.Name);
        if (testMode == true) {
            System.debug('Using mock for Name : ' + employee.Name);
            return SalaryHistoryMock.getMockMergeData(employee);
        }

        List<SalaryHistoryRecord> salary = getHistoryForEmployee(employee, 'Salary__c', 'Effective_Salary_Date__c');
        List<SalaryHistoryRecord> exchangeRate = getHistoryForEmployee(employee, 'Exchange_Rate__c', 'Effective_Exchange_Rate_Date__c');
        List<SalaryHistoryRecord> result = new List<SalaryHistoryRecord>();
        Boolean endLoop = false;

        Decimal currentSalary = 0;
        Decimal currentRate = 1;
        Integer salaryIndex = 0;
        Integer exchangeRateIndex = 0;

        while (!endLoop) {

            Date salaryDate = null;
            Date exchangeRateDate = null;

            Decimal sal = 0;
            Decimal rate = 1;

            if (salaryIndex < salary.size()) {
                sal = salary.get(salaryIndex).getValue();
                salaryDate = salary.get(salaryIndex).getValueDate();
            }

            if (exchangeRateIndex < exchangeRate.size()) {
                rate = exchangeRate.get(exchangeRateIndex).getValue();
                exchangeRateDate = exchangeRate.get(exchangeRateIndex).getValueDate();
            }

            Date toAdd = salaryDate;
            if ((salaryDate == null && exchangeRateDate != null) || salaryDate > exchangeRateDate) {
                toAdd = exchangeRateDate;
                currentRate = rate;
                exchangeRateIndex++;
            } else if ((salaryDate != null && exchangeRateDate == null) || salaryDate < exchangeRateDate) {
                currentSalary = sal;
                salaryIndex++;
            } else if (salaryDate == exchangeRateDate) {
                currentSalary = sal;
                currentRate = rate;
                salaryIndex++;
                exchangeRateIndex++;
            } else {
                break;
            }

            result.add(new SalaryHistoryRecord(calculateSalary(currentSalary, currentRate), toAdd));

            if (salaryIndex  >= salary.size() && exchangeRateIndex  >= exchangeRate.size()) {
                break;
            }
        }

        return result;
    }

    public static Decimal calculateSalary(Decimal sal, Decimal er) {
        Double result = (sal / (Double) er);
        result = ((result / 260) * 1.3 * 1.52 * 1.1 * 1.1) / 8.0;

        return Decimal.valueOf(result).setScale(2);
    }

    private Decimal getValueForSalary(String field, SalaryHistoryWrapper record) {
        if (field == 'Exchange_Rate__c') {
            if (record.NewValue != null && ((Decimal) record.NewValue) != 0) {
                return (Decimal) record.NewValue;
            } else if (record.OldValue != null && ((Decimal) record.OldValue) != 0) {
                return (Decimal) record.OldValue;
            } else {
               return 1;
            }
        } else {
            if (record.NewValue != null) {
                return (Decimal) record.NewValue;
            } else if (record.OldValue != null) {
                return (Decimal) record.OldValue;
            } else {
               return 0;
            }
        }
    }

    private List<SalaryHistoryWrapper> getFieldHistory(SFDC_Employee__c employee, String fieldName) {
        if (Test.isRunningTest()) {
            return SalaryHistoryMock.getFieldHistory(employee, fieldName);
        }

        List<SFDC_Employee__History> records = [SELECT OldValue, NewValue, CreatedDate FROM SFDC_Employee__History WHERE parentId =: employee.Id AND Field =: fieldName ORDER BY CreatedDate ASC];
        List<SalaryHistoryWrapper> salaryHistory = new List<SalaryHistoryWrapper>();
        for (SFDC_Employee__History rec : records) {
            salaryHistory.add(new SalaryHistoryWrapper(rec.OldValue, rec.NewValue, rec.CreatedDate));
        }

        return salaryHistory;
    }

    private Date takeDate(DateTime dt) {
        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }
}