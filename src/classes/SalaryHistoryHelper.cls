/**
 * Helper class for fetching salary history for employees
 */
public without sharing class SalaryHistoryHelper {

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

    public List<Project_Billing_Rate__c> loadBillingRates(String billingRateName) {
        if (billingRateName == '' || billingRateName == null) {
            billingRateName = 'Loaded Daily Rate';
        }

        List<Project_Billing_Rate__c> ratesRecords = [SELECT Id, Date__c, Custom_1__c, Custom_2__c, Custom_3__c, Fee__c, Fringe__c, G_A__c, Overhead__c FROM Project_Billing_Rate__c
                                                        WHERE Name =: billingRateName ORDER BY Date__c];

        return ratesRecords;
    }

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

            // If first history record contains OldValue we must take it to the list
            if (employeeSalaryHistory.get(0).OldValue != null && ((Decimal) employeeSalaryHistory.get(0).OldValue) >= 0.1) {
                lastSalary = (Decimal) employeeSalaryHistory.get(0).OldValue;

                if (employeeSalaryDateHistory.size() > 0 && employeeSalaryDateHistory.get(0).OldValue != null && employeeSalaryDateHistory.get(0).CreatedDate == employeeSalaryHistory.get(0).CreatedDate) {
                    lastSalaryDate = (Date) employeeSalaryDateHistory.get(0).OldValue;
                } else {
                    lastSalaryDate = takeDate(employeeSalaryHistory.get(0).CreatedDate);
                }

                salaryList.add(new SalaryHistoryRecord(lastSalary, lastSalaryDate));
            }

            Map <DateTime, Date> effectiveDateMap = new Map<DateTime, Date>();

            Date helperDate = Date.newInstance(1900, 1, 1);
            for (Integer i = 0; i < employeeSalaryDateHistory.size(); i++) {
                effectiveDateMap.put((DateTime) employeeSalaryDateHistory.get(i).CreatedDate,
                                      employeeSalaryDateHistory.get(i).NewValue == null ? helperDate : (Date) employeeSalaryDateHistory.get(i).NewValue);
                if (employeeSalaryDateHistory.get(i).NewValue != null) {
                    helperDate = (Date) employeeSalaryDateHistory.get(i).NewValue;
                }
            }

            Boolean needSort = false;
            for (Integer i = 0; i < employeeSalaryHistory.size(); i++) {

                Decimal currentSalary = (Decimal) employeeSalaryHistory.get(i).NewValue;
                // We must ignore exchange rate < 0.1 - Exception Divide by 0 and reject bad values from old history
                if (currentSalary == null || (currentSalary < 0.1 && salaryField == 'Exchange_Rate__c')) {
                    continue;
                }

                DateTime salCreateDateTime = (DateTime) employeeSalaryHistory.get(i).CreatedDate;
                Date toAdd;

                if (effectiveDateMap.containsKey(salCreateDateTime)) {
                    toAdd = effectiveDateMap.get(salCreateDateTime);
                } else {
                    toAdd = takeDate(salCreateDateTime);
                }
                salaryList.add(new SalaryHistoryRecord(currentSalary, toAdd));

                if (lastSalaryDate > toAdd) {
                    needSort = true;
                }
                lastSalaryDate = toAdd;
            }

            if (needSort) {
                salaryList.sort();
            }
        }

        if (salaryList.size() > 0) {
            SalaryHistoryRecord firstRec = salaryList.get(0);
            firstRec.setValueDate(Date.newInstance(1900, 1, 1));
            salaryList.set(0, firstRec);
        }

        return salaryList;
    }

    public List<SalaryHistoryRecord> mergeSalaryWithExchangeRateHistory(SFDC_Employee__c employee) {
        if (Test.isRunningTest() && (employee.Name == 'emp_9' || employee.Name == 'emp_10' || employee.Name == 'emp_11')) {
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

            result.add(new SalaryHistoryRecord(calculateSalary(currentSalary, currentRate,
                                                (employee.Hire_Date__c != null && employee.Expected_Termination_Date__c != null ?
                                                (employee.Hire_Date__c.monthsBetween(employee.Expected_Termination_Date__c) < 12 ? employee.Working_Days__c : null) : null)),
                                                toAdd));

            if (salaryIndex  >= salary.size() && exchangeRateIndex  >= exchangeRate.size()) {
                break;
            }
        }

        return result;
    }

    public List<SalaryHistoryRecord> mergeSalaryHistory(SFDC_Employee__c employee) {
        List<SalaryHistoryRecord> salary = mergeSalaryWithExchangeRateHistory(employee);
        return salary;
    }

    public static Decimal calculateSalary(Decimal sal, Decimal er, Decimal workingDays) {
        Decimal calcWorkingDays = 260.00 * 8.00;
        if (workingDays != null) {
            calcWorkingDays = workingDays * 8.00;
        }

        Double result = ((sal / (Double) er) / (Double) calcWorkingDays);
        return Decimal.valueOf(result);
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

    private Map<Id, List<SalaryHistoryWrapper>> fillMap(Set<Id> emps, List<SFDC_Employee__History> records) {
        Map<Id, List<SalaryHistoryWrapper>> tmpMap = new Map<Id, List<SalaryHistoryWrapper>>();
        for (Id ei: emps) {
            tmpMap.put(ei, new List<SalaryHistoryWrapper>());
        }

        for (SFDC_Employee__History rec : records) {
            List<SalaryHistoryWrapper> salaryHistory = tmpMap.get(rec.ParentId);
            salaryHistory.add(new SalaryHistoryWrapper(rec.OldValue, rec.NewValue, rec.CreatedDate));
            tmpMap.put(rec.ParentId, salaryHistory);
        }

        return tmpMap;
    }

    private Date takeDate(DateTime dt) {
        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }
}