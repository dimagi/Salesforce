public with sharing class BudgetViewController {
    @AuraEnabled(cacheable=true)
    public static List<EmployeeContractData> getEmployeeContractData(String recordId, string year) {
        List<EmployeeContractData> employeeDataList = new List<EmployeeContractData>();
        Integer selectedYear = String.isNotBlank(year) ? Integer.valueOf(year) : Date.today().year();
        Date startOfYear = Date.newInstance(selectedYear, 1, 1);
        Date endOfYear = Date.newInstance(selectedYear, 12, 31);
        
        List<Budget_Line_Item__c> budgetLineItems = [
            SELECT Id, Employee__r.Id, Employee__r.Name, 
            Actual_Units__c, Actual_Daily_Rate__c, Actual_Total_Salary__c, Actuals_Locked__c,
            Budget_Line_Item_Start_Date__c, Budget_Line_Item_EndDate__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId 
            AND Cost_Category__c = 'Employee'
            AND (Budget_Line_Item_Start_Date__c <= :endOfYear 
                 AND Budget_Line_Item_EndDate__c >= :startOfYear)
        ];
        Map<Id, EmployeeContractData> employeeDataMap = new Map<Id, EmployeeContractData>();
        for (Budget_Line_Item__c item : budgetLineItems) {
            Id employeeId = item.Employee__r.Id;
            if (employeeId != null) {
                if (!employeeDataMap.containsKey(employeeId)) {
                    EmployeeContractData empData = new EmployeeContractData();
                    empData.id = employeeId;
                    empData.name = item.Employee__r.Name;
                    empData.monthlyData = new Map<String, MonthData>();
                    employeeDataMap.put(employeeId, empData);
                } 
                Date startDate = item.Budget_Line_Item_Start_Date__c;
                Date endDate = item.Budget_Line_Item_EndDate__c;  
                DateTime currentMonthDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
                String monthKey = currentMonthDateTime.format('MMM'); 
                Decimal unitsPerMonth = (item.Actual_Units__c != null) ? item.Actual_Units__c : 0;
                Decimal dailyRate = (item.Actual_Daily_Rate__c != null) ? item.Actual_Daily_Rate__c : 0;
                Decimal totalPerMonth = (item.Actual_Total_Salary__c != null) ? item.Actual_Total_Salary__c : 0;
                String ActualLocked = item.Actuals_Locked__c;
                employeeDataMap.get(employeeId).monthlyData.put(monthKey, 
                                                                new MonthData(item.Id, unitsPerMonth, dailyRate, totalPerMonth,ActualLocked)
                                                               );
            }
        }
        for (EmployeeContractData empData : employeeDataMap.values()) {
            for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
                if (!empData.monthlyData.containsKey(month)) {
                    empData.monthlyData.put(month, new MonthData(null, 0, 0, 0,'')); 
                }
            }
        }
        employeeDataList.addAll(employeeDataMap.values());
        return employeeDataList;
    }
    @AuraEnabled(cacheable=true)
    public static List<EmployeeContractData> getContractersData(String recordId, string year) {
        List<EmployeeContractData> employeeDataList = new List<EmployeeContractData>();
        Integer selectedYear = String.isNotBlank(year) ? Integer.valueOf(year) : Date.today().year();
        
        Date startOfYear = Date.newInstance(selectedYear, 1, 1);
        Date endOfYear = Date.newInstance(selectedYear, 12, 31);
        List<Budget_Line_Item__c> budgetLineItems = [
            SELECT Id, Employee__r.Id, Employee__r.Name, 
            Actual_Units__c, Actual_Daily_Rate__c, Actual_Total_Salary__c, Actuals_Locked__c,
            Budget_Line_Item_Start_Date__c, Budget_Line_Item_EndDate__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Cost_Category__c = 'Internal Contractor'
            AND (Budget_Line_Item_Start_Date__c <= :endOfYear 
                 AND Budget_Line_Item_EndDate__c >= :startOfYear)
            
        ];
        Map<Id, EmployeeContractData> employeeDataMap = new Map<Id, EmployeeContractData>();
        for (Budget_Line_Item__c item : budgetLineItems) {
            Id employeeId = item.Employee__r.Id;
            if (employeeId != null) {
                if (!employeeDataMap.containsKey(employeeId)) {
                    EmployeeContractData empData = new EmployeeContractData();
                    empData.id = employeeId;
                    empData.name = item.Employee__r.Name;
                    empData.monthlyData = new Map<String, MonthData>();
                    employeeDataMap.put(employeeId, empData);
                }
                Date startDate = item.Budget_Line_Item_Start_Date__c;
                Date endDate = item.Budget_Line_Item_EndDate__c;
                DateTime currentMonthDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
                String monthKey = currentMonthDateTime.format('MMM');  
                Decimal unitsPerMonth = (item.Actual_Units__c != null) ? item.Actual_Units__c : 0;
                Decimal dailyRate = (item.Actual_Daily_Rate__c != null) ? item.Actual_Daily_Rate__c : 0;
                Decimal totalPerMonth = (item.Actual_Total_Salary__c != null) ? item.Actual_Total_Salary__c : 0;
                String ActualLocked = item.Actuals_Locked__c;
                employeeDataMap.get(employeeId).monthlyData.put(monthKey, 
                                                                new MonthData(item.Id, unitsPerMonth, dailyRate, totalPerMonth,ActualLocked)
                                                               );
            }
        }
        for (EmployeeContractData empData : employeeDataMap.values()) {
            for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
                if (!empData.monthlyData.containsKey(month)) {
                    empData.monthlyData.put(month, new MonthData(null, 0, 0, 0,'')); 
                }
            }
        }
        employeeDataList.addAll(employeeDataMap.values());
        return employeeDataList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SFDC_Employee__c> searchEmployees(String searchQuery) {
        String searchTerm = '%' + searchQuery + '%';
        return [
            SELECT Id, Name
            FROM SFDC_Employee__c
            WHERE Name LIKE :searchTerm
            LIMIT 50
        ];
    }
    
    @AuraEnabled
    public static void deleteColumnData(Id recordId, List<Id> empIds) {
        List<Budget_Line_Item__c> itemsToDelete = [
            SELECT Id FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId AND Employee__r.Id IN :empIds
        ];
        
        delete itemsToDelete;
    }
    
    @AuraEnabled
    public static void updateEmployeeContractData(Id budgetId, List<Map<String, Object>> draftValues, String selectedYear, String source) {
        Map<Id, Budget_Line_Item__c> updates = new Map<Id, Budget_Line_Item__c>();
        List<Budget_Line_Item__c> inserts = new List<Budget_Line_Item__c>();
        Integer currentYear = String.isNotBlank(selectedYear) ? Integer.valueOf(selectedYear) : Date.today().year(); 
        for (Map<String, Object> draft : draftValues) {
            Id budgetItemId = (Id) draft.get('budgetItemId'); 
            Id employeeId = (Id) draft.get('EmployeeId'); 
            Integer month = Integer.valueOf((Decimal) draft.get('Month')); 
            Decimal dailyRate = draft.containsKey('dailyRate') ? (Decimal) draft.get('dailyRate') : null;
            Decimal units = draft.containsKey('units') ? (Decimal) draft.get('units') : null;
            system.debug('units'+units);
            if (budgetItemId != null) {
                Budget_Line_Item__c budgetLine = new Budget_Line_Item__c();
                budgetLine.Id = budgetItemId;
                if (dailyRate != null) budgetLine.Actual_Daily_Rate__c = dailyRate;
                if (units != null) budgetLine.Actual_Units__c = units;
                updates.put(budgetLine.Id, budgetLine);
            } else {
                Date startDate = Date.newInstance(currentYear, month, 1);
                Date endDate = startDate.toStartOfMonth().addMonths(1).addDays(-1);        
                Budget_Line_Item__c newBudgetLine = new Budget_Line_Item__c(
                    Employee__c = employeeId,
                    Budget_Line_Item_Start_Date__c = startDate,
                    Budget_Line_Item_EndDate__c = endDate,
                    Budget__c = budgetId,
                    Actual_Daily_Rate__c = dailyRate,
                    Actual_Units__c = units
                );
                if (source == 'Employee') {
                    newBudgetLine.Cost_Category__c = 'Employee';
                } else {
                    newBudgetLine.Cost_Category__c = 'Internal Contractor';
                }
                inserts.add(newBudgetLine);
            }
        }
        if (!updates.isEmpty()) {
            update updates.values();
        }
        if (!inserts.isEmpty()) {
            insert inserts;
        }
    }
    @AuraEnabled
    public static void updateEmployeeData(Id budgetId, List<Map<String, Object>> draftValues, String selectedYear, String source) {
        Map<Id, Budget_Line_Item__c> updates = new Map<Id, Budget_Line_Item__c>();
        List<Budget_Line_Item__c> inserts = new List<Budget_Line_Item__c>();
        Integer currentYear = String.isNotBlank(selectedYear) ? Integer.valueOf(selectedYear) : Date.today().year(); 
        for (Map<String, Object> draft : draftValues) {   
            Id budgetItemId = (Id) draft.get('budgetItemId'); 
            Id employeeId = (Id) draft.get('EmployeeId'); 
            Integer month = Integer.valueOf((Decimal) draft.get('Month')); 
            Decimal dailyRate = draft.containsKey('dailyRate') ? (Decimal) draft.get('dailyRate') : null;
            Decimal units = draft.containsKey('units') ? (Decimal) draft.get('units') : null;
            
            system.debug('units'+units);
            if (budgetItemId != null) {
                Budget_Line_Item__c budgetLine = new Budget_Line_Item__c();
                budgetLine.Id = budgetItemId;
                if (dailyRate != null) budgetLine.Actual_Daily_Rate__c = dailyRate;
                if (units != null) budgetLine.Actual_Units__c = units;
                updates.put(budgetLine.Id, budgetLine);
            } else {
                Date startDate = Date.newInstance(currentYear, month, 1);
                Date endDate = startDate.toStartOfMonth().addMonths(1).addDays(-1);     
                Budget_Line_Item__c newBudgetLine = new Budget_Line_Item__c(
                    Employee__c = employeeId,
                    Budget_Line_Item_Start_Date__c = startDate,
                    Budget_Line_Item_EndDate__c = endDate,
                    Budget__c = budgetId,
                    Actual_Daily_Rate__c = dailyRate,
                    Actual_Units__c = units
                );
                if (source == 'Employee') {
                    newBudgetLine.Cost_Category__c = 'Employee';
                } else {
                    newBudgetLine.Cost_Category__c = 'Internal Contractor';
                }
                inserts.add(newBudgetLine);
            }
        }
        if (!updates.isEmpty()) {
            update updates.values();
        }
        if (!inserts.isEmpty()) {
            insert inserts;
        }
    }
    public class BudgetRow {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String month { get; set; } 
        @AuraEnabled public String value1 { get; set; }
        @AuraEnabled public String value2 { get; set; }
        @AuraEnabled public String value3 { get; set; }
        @AuraEnabled public String value4 { get; set; }
        @AuraEnabled public String Id { get; set; }
        
        public BudgetRow() {}
        public BudgetRow(String label, String month, String value1, String value2, String value3, String value4, String Id) {
            this.label = label;
            this.month = month;
            this.value1 = value1;
            this.value2 = value2;
            this.value3 = value3;
            this.value4 = value4;
            this.Id = Id;
        }
    }
    
    public class BudgetRows {
        @AuraEnabled
        public String rowName;
        @AuraEnabled
        public Decimal BudgetValue;
        @AuraEnabled
        public Decimal AmountRemaining;
        @AuraEnabled
        public List<BudgetLineItem> monthValues;
        public BudgetRows(String rowName,Decimal BudgetValue,Decimal AmountRemaining, List<BudgetLineItem> monthValues) {
            this.rowName = rowName;
            this.BudgetValue = BudgetValue;
            this.AmountRemaining = AmountRemaining;
            this.monthValues = monthValues;
        }
    }
    
    public class BudgetLineItem {
            @AuraEnabled public String label { get; set; }          
        @AuraEnabled public Decimal total { get; set; }
        @AuraEnabled public Id lineItemId { get; set; }
        @AuraEnabled public string actualsLocked { get; set; }
        
            public BudgetLineItem() {}
        
        public BudgetLineItem(Id lineItemId, Decimal total, string actualsLocked) {
            this.lineItemId = lineItemId;
            this.total = total;
            this.actualsLocked = actualsLocked;
            
        }
    }
    
    @AuraEnabled
    public static List<BudgetRows> getRelatedData(String recordId, string selectedYear) {
        Budget__c Budgetrecord = [
            SELECT id,Budgeted_Travel_Transportation__c,Budgeted_Subcontracts_Costs__c,Budgeted_Salaries_Wages__c,Budgeted_Other_Direct_Costs__c,Budgeted_Indirect_Cost_Overhead__c,
            Budgeted_Indirect_Cost_G_A__c,Budgeted_Fringe_Benefits__c,Budgeted_Equipment_Costs__c,Budgeted_Direct_Costs__c,Budgeted_Custom__c,Budgeted_Contractual_Costs__c,
            Budgeted_Overhead_Amount__c,Budgeted_G_A_Amount__c,Budget_Period_Start_Date__c,Fee_Percentage__c,Budgeted_Fee_Amount__c
            FROM Budget__c
            WHERE id = :recordId 
        ];
        Integer budgetStartDate;
        Date budstartDate;
        if (budgetRecord != null) {
            budgetStartDate = budgetRecord.Budget_Period_Start_Date__c.year();
            budstartDate = Date.newInstance(budgetStartDate, 1, 1);
            System.debug('Budget Period Start Date: ' + budgetStartDate);
        } else {
            System.debug('No Budget record found for the given recordId.');
        }   
        Integer yearInt = Integer.valueOf(selectedYear);
        Date startDate = Date.newInstance(yearInt, 1, 1);
        Date endDate = Date.newInstance(yearInt, 12, 31);
        List<Budget_Line_Item__c> combinedResults = [
            SELECT Actual_Total_Salary__c, Budget__c, Cost_Category__c, Overhead_Amount__c,Actuals_Locked__c, 
            G_A_Amount__c, Custom_Indirect_Cost_Amount__c, Budget_Line_Item_Start_Date__c,Agreement__r.Name   
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Budget_Line_Item_Start_Date__c >= :startDate
            AND Budget_Line_Item_Start_Date__c <= :endDate
        ];
        system.debug('endDate   '+endDate);
        Map<Integer, Map<String, BudgetLineItem>> monthlyData = new Map<Integer, Map<String, BudgetLineItem>>();
        for (Integer i = 1; i <= 12; i++) {
            monthlyData.put(i, new Map<String, BudgetLineItem>{
                'Contractual' => new BudgetLineItem(null, 0,null),
                    'Equipment' => new BudgetLineItem(null, 0,null),
                    'travelTransportation' => new BudgetLineItem(null, 0,null),
                    'Subcontract' => new BudgetLineItem(null, 0,null),
                    'otherDirectCost' => new BudgetLineItem(null, 0,null),
                    'indirectGA' => new BudgetLineItem(null, 0,null),
                    'indirectOverhead' => new BudgetLineItem(null, 0,null)
                    
                    });
        }
        
        for (Budget_Line_Item__c item : combinedResults) {
            Integer month = (item.Budget_Line_Item_Start_Date__c != null) 
                ? item.Budget_Line_Item_Start_Date__c.month() 
                : 0;
            if (month > 0 && month <= 12) {
                Map<String, BudgetLineItem> monthData = monthlyData.get(month);
                
                String costCategory = item.Cost_Category__c;
                Decimal totalSalary = item.Actual_Total_Salary__c != null ? item.Actual_Total_Salary__c : 0;
                Decimal indirectOverhead = item.Overhead_Amount__c != null ? item.Overhead_Amount__c : 0;
                Decimal indirectGA = item.G_A_Amount__c != null ? item.G_A_Amount__c : 0;                 
                Decimal indirectCost = item.Custom_Indirect_Cost_Amount__c != null ? item.Custom_Indirect_Cost_Amount__c : 0;
                if (indirectGA != 0) {
                    BudgetLineItem data = monthData.get('indirectGA');
                                            if (data != null) {
                    data.total += indirectGA;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('indirectGA', data);
                                            }
                }
                if (indirectCost != 0) {
                    BudgetLineItem data = monthData.get('indirectCost');
                        if (data != null) {
                    data.total += indirectCost;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('indirectCost', data);
                        }
                }
                if (indirectOverhead != 0) {
                    BudgetLineItem data = monthData.get('indirectOverhead');
                                            if (data != null) {
                    data.total += indirectOverhead;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('indirectOverhead', data);
                                            }
                }
                if (costCategory == 'Equipment') {
                    BudgetLineItem data = monthData.get('Equipment');
                                            if (data != null) {
                    data.total = data.total + totalSalary;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('Equipment', data);
                                            }
                } else if (costCategory == 'Contractual') {
                    BudgetLineItem data = monthData.get('Contractual');
                                            if (data != null) {
                    data.total = data.total + totalSalary;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('Contractual', data);
                                            }
                } else if (costCategory == 'Travel & Transportation') {
                    BudgetLineItem data = monthData.get('travelTransportation');
                                            if (data != null) {
                    data.total = data.total + totalSalary;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('travelTransportation', data);
                                            }
                }  else if (costCategory == 'Subcontracts') {
String agreementName = (item.Agreement__r != null && item.Agreement__r.Name != null)
    ? item.Agreement__r.Name
    : 'Unknown Agreement';
                    String subcontractKey = 'Subcontract_' + agreementName;

            BudgetLineItem data = monthData.get(subcontractKey);
            if (data == null) {
                data = new BudgetLineItem();
                data.label = agreementName;
                data.total = 0;
            }
            data.total += totalSalary;
            data.lineItemId = item.Id;
            data.actualsLocked = item.Actuals_Locked__c;

            monthData.put(subcontractKey, data);
        }
                else if (costCategory == 'Other Direct Cost') {
                    BudgetLineItem data = monthData.get('otherDirectCost');
                                            if (data != null) {
                    data.total = data.total + totalSalary;
                    data.lineItemId = item.Id;
                    data.actualsLocked = item.Actuals_Locked__c;
                    monthData.put('otherDirectCost', data);
                                            }
                }
                
            }
            
        }
        Decimal overallTotal = 0; 
        Decimal budgetoverallTotal = 0; 
        
        Decimal overTotal = 0; 
        Decimal TotalValue = 0; 
        Decimal budgetTotalValue = 0;
        Decimal TotalBudgetValue = 0; 
        Decimal budgetTotalBudgetValue = 0; 
        
        List<Budget_Line_Item__c> combinedResult = [
            SELECT Actual_Total_Salary__c, Budget__c, Cost_Category__c, Overhead_Amount__c,Actuals_Locked__c, 
            G_A_Amount__c, Custom_Indirect_Cost_Amount__c, Budget_Line_Item_Start_Date__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Budget_Line_Item_Start_Date__c >= :budstartDate
            AND Budget_Line_Item_Start_Date__c <= :endDate
        ];
        
        Decimal TotalEstimateds = 0;
        Decimal EmployeetotalSalarys = 0;
        Decimal FringetotalSalarys = 0;
        Decimal TraveltotalSalarys = 0;
        Decimal OthertotalSalarys = 0;
        Decimal Subcontracts = 0;
        Decimal GtotalSalarys = 0;
        Decimal OverheadtotalSalarys = 0;
        Decimal Indirecttotalcosts = 0;
        
        for (Budget_Line_Item__c ar : combinedResult) {
            TotalEstimateds += ar.Actual_Total_Salary__c;
            String costCategory = ar.Cost_Category__c;
            Decimal salary = ar.Actual_Total_Salary__c;
            GtotalSalarys += ar.G_A_Amount__c;
            OverheadtotalSalarys += ar.Overhead_Amount__c;
            Indirecttotalcosts += ar.Custom_Indirect_Cost_Amount__c;
            
            if (costCategory == 'Equipment') {
                EmployeetotalSalarys += salary;
            } else if (costCategory == 'Contractual') {
                FringetotalSalarys += salary;
            } else if (costCategory == 'Travel & Transportation') {
                TraveltotalSalarys += salary;
            } else if (costCategory == 'Other Direct Cost') {
                OthertotalSalarys += salary;
            } else if (costCategory == 'Subcontracts') {
                Subcontracts += salary;
            } 
        }
        
        
        List<BudgetRows> budgetRows = new List<BudgetRows>();
        Decimal combinedTotalSum = 0;
        List<BudgetLineItem> combinedsTotals = new List<BudgetLineItem>();
                List<BudgetLineItem> combinedsemployeeTotals = new List<BudgetLineItem>();
        system.debug('combinedsTotals'+combinedsTotals);
        List<Decimal> monthlyTotals = new List<Decimal>();
        
        for (Integer i = 1; i <= 12; i++) {
            Decimal totalForMonth = 
                monthlyData.get(i).get('travelTransportation').total +
                monthlyData.get(i).get('Equipment').total +
                monthlyData.get(i).get('Contractual').total +
                monthlyData.get(i).get('Subcontract').total +
                monthlyData.get(i).get('otherDirectCost').total;
            monthlyTotals.add(totalForMonth);
            
        }
        Decimal  BudgetfringeBenefit;
        Budget__c fringeBenefit = [
            SELECT id, Fringe_Benefit_Rate__c 
            FROM Budget__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        BudgetfringeBenefit = fringeBenefit.Fringe_Benefit_Rate__c;
      
        List<EmployeeContractData> employeeDataList = getEmployeeContractData(recordId, selectedYear);
        List<EmployeeContractData> contractorDataList = getContractersData(recordId, selectedYear);
        Map<String, Decimal> monthlyTotalsMap = new Map<String, Decimal>();
        for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
            monthlyTotalsMap.put(month, 0);
        }
        for (EmployeeContractData empData : employeeDataList) {
            for (String month : empData.monthlyData.keySet()) {
                Decimal existingTotal = monthlyTotalsMap.get(month);
                Decimal monthTotal = empData.monthlyData.get(month).total;
                monthlyTotalsMap.put(month, existingTotal + monthTotal);
            }
        }
        for (EmployeeContractData empData : employeeDataList) {
            System.debug('Employee: ' + empData.name + ', Monthly Data: ' + empData.monthlyData);
        }
        
        for (EmployeeContractData contractorData : contractorDataList) {
            for (String month : contractorData.monthlyData.keySet()) {
                Decimal existingTotal = monthlyTotalsMap.get(month);
                Decimal monthTotal = contractorData.monthlyData.get(month).total;
                monthlyTotalsMap.put(month, existingTotal + monthTotal);
            }
        }
        
        List<Decimal> totalmonthlyTotals = new List<Decimal>();
        for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
            totalmonthlyTotals.add(monthlyTotalsMap.get(month));
        }
        Decimal totaloverallTotal = 0;
        for (Decimal monthlyTotal : monthlyTotals) {
            totaloverallTotal += monthlyTotal;
        }
        List<BudgetLineItem> combinedTotals = new List<BudgetLineItem>();
        if (monthlyTotals.size() == totalmonthlyTotals.size()) {
            for (Integer i = 0; i < monthlyTotals.size(); i++) {
                Decimal combinedTotal = monthlyTotals[i] + totalmonthlyTotals[i] + (totalmonthlyTotals[i]* (budgetFringeBenefit / 100));
                combinedTotals.add(new BudgetLineItem(null, combinedTotal,null));
            }
        } else {
            System.debug('Error: monthlyTotals and totalmonthlyTotals have different sizes.');
        }
        for (Decimal total : totalmonthlyTotals) {
            combinedsTotals.add(new BudgetLineItem(null, total, null));
            if (total != null) {
                combinedTotalSum += total;
            }
        }
        
        budgetRows.add(new BudgetRows('Total Salary Cost', Budgetrecord.Budgeted_Salaries_Wages__c, Budgetrecord.Budgeted_Salaries_Wages__c-combinedTotalSum, combinedsTotals));
          Map<String, Decimal> monthlyTotalsEmployeeMap = new Map<String, Decimal>();
        for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
            monthlyTotalsEmployeeMap.put(month, 0);
        }
        system.debug('monthlyTotalsEmployeeMap'+monthlyTotalsEmployeeMap);
        for (EmployeeContractData empData : employeeDataList) {
            for (String month : empData.monthlyData.keySet()) {
                Decimal existingTotal = monthlyTotalsEmployeeMap.get(month);
                Decimal monthTotal = empData.monthlyData.get(month).total;
                monthlyTotalsEmployeeMap.put(month, existingTotal + monthTotal);
                        system.debug('monthlyTotalsEmployeeMap   : '+monthlyTotalsEmployeeMap);

            }
        }
        for (EmployeeContractData empData : employeeDataList) {
            System.debug('Employee: ' + empData.name + ', Monthly Data: ' + empData.monthlyData);
        }
        
        
        List<Decimal> totalemployeeDataList = new List<Decimal>();
        for (String month : new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}) {
            totalemployeeDataList.add(monthlyTotalsEmployeeMap.get(month));
        }
       
        List<BudgetLineItem> combinedemployeeTotals = new List<BudgetLineItem>();
        if (monthlyTotals.size() == totalemployeeDataList.size()) {
            for (Integer i = 0; i < monthlyTotals.size(); i++) {
                Decimal combinedTotal = monthlyTotals[i] + totalemployeeDataList[i] + (totalemployeeDataList[i]* (budgetFringeBenefit / 100));
                combinedemployeeTotals.add(new BudgetLineItem(null, combinedTotal,null));
            }
        } else {
            System.debug('Error: monthlyTotals and totalemployeeDataList have different sizes.');
        }
        for (Decimal total : totalemployeeDataList) {
            combinedsemployeeTotals.add(new BudgetLineItem(null, total, null));
            if (total != null) {
                combinedTotalSum += total;
            }
        }
        List<BudgetLineItem> fringeTotals = new List<BudgetLineItem>();
        Decimal overallFringeTotal = 0;
        for (BudgetLineItem item : combinedsemployeeTotals) {
            Decimal fringeAmount = (item.total != null ? item.total : 0) * (budgetFringeBenefit / 100);
            fringeTotals.add(new BudgetLineItem(null, fringeAmount, null));
        }
        system.debug('fringeTotals'+fringeTotals.size());
        
        for (BudgetLineItem item : fringeTotals) {
            if (item.total != null) {
                overallFringeTotal += item.total;
            }
        }
        System.debug('Overall Fringe Total: ' + overallFringeTotal);
        system.debug('fringeBenefit.Fringe_Benefit_Rate__c;  '+fringeBenefit.Fringe_Benefit_Rate__c);
          overallTotal =   (Budgetrecord.Budgeted_Travel_Transportation__c != null ? Budgetrecord.Budgeted_Travel_Transportation__c : 0) +
            (Budgetrecord.Budgeted_Equipment_Costs__c != null ? Budgetrecord.Budgeted_Equipment_Costs__c : 0) +
            (Budgetrecord.Budgeted_Contractual_Costs__c != null ? Budgetrecord.Budgeted_Contractual_Costs__c : 0) +
            (Budgetrecord.Budgeted_Subcontracts_Costs__c != null ? Budgetrecord.Budgeted_Subcontracts_Costs__c : 0) +
            (Budgetrecord.Budgeted_Other_Direct_Costs__c != null ? Budgetrecord.Budgeted_Other_Direct_Costs__c : 0)+
                          (Budgetrecord.Budgeted_Salaries_Wages__c != null ? Budgetrecord.Budgeted_Salaries_Wages__c : 0)+
            (Budgetrecord.Budgeted_Fringe_Benefits__c != null ? Budgetrecord.Budgeted_Fringe_Benefits__c : 0);

        
        budgetoverallTotal = ((Budgetrecord.Budgeted_Travel_Transportation__c != null ? Budgetrecord.Budgeted_Travel_Transportation__c : 0) - (TraveltotalSalarys != null ? TraveltotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Equipment_Costs__c != null ? Budgetrecord.Budgeted_Equipment_Costs__c : 0) 
             - (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Contractual_Costs__c != null ? Budgetrecord.Budgeted_Contractual_Costs__c : 0) 
             - (FringetotalSalarys != null ? FringetotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Subcontracts_Costs__c != null ? Budgetrecord.Budgeted_Subcontracts_Costs__c : 0) 
             - (Subcontracts != null ? Subcontracts : 0)) +
            ((Budgetrecord.Budgeted_Other_Direct_Costs__c != null ? Budgetrecord.Budgeted_Other_Direct_Costs__c : 0) 
             - (OthertotalSalarys != null ? OthertotalSalarys : 0))+
            ((Budgetrecord.Budgeted_Salaries_Wages__c != null ? Budgetrecord.Budgeted_Salaries_Wages__c : 0) - (combinedTotalSum != null ? combinedTotalSum : 0))+
            ((Budgetrecord.Budgeted_Fringe_Benefits__c != null ? Budgetrecord.Budgeted_Fringe_Benefits__c : 0) - (overallFringeTotal != null ? overallFringeTotal : 0));
        
        budgetRows.add(new BudgetRows('Fringe Benefit Cost', Budgetrecord.Budgeted_Fringe_Benefits__c, Budgetrecord.Budgeted_Fringe_Benefits__c-overallFringeTotal, fringeTotals));
        budgetRows.add(new BudgetRows('Travel & Transportation', Budgetrecord.Budgeted_Travel_Transportation__c,((Budgetrecord.Budgeted_Travel_Transportation__c != null ? Budgetrecord.Budgeted_Travel_Transportation__c : 0) - (TraveltotalSalarys != null ? TraveltotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('travelTransportation'), monthlyData.get(2).get('travelTransportation'), 
                                          monthlyData.get(3).get('travelTransportation'), monthlyData.get(4).get('travelTransportation'), 
                                          monthlyData.get(5).get('travelTransportation'), monthlyData.get(6).get('travelTransportation'), 
                                          monthlyData.get(7).get('travelTransportation'), monthlyData.get(8).get('travelTransportation'), 
                                          monthlyData.get(9).get('travelTransportation'), monthlyData.get(10).get('travelTransportation'), 
                                          monthlyData.get(11).get('travelTransportation'), monthlyData.get(12).get('travelTransportation') }));
        
        budgetRows.add(new BudgetRows('Equipment', Budgetrecord.Budgeted_Equipment_Costs__c,((Budgetrecord.Budgeted_Equipment_Costs__c != null ? Budgetrecord.Budgeted_Equipment_Costs__c : 0) 
                                                                                             - (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('Equipment'), monthlyData.get(2).get('Equipment'), 
                                          monthlyData.get(3).get('Equipment'), monthlyData.get(4).get('Equipment'), 
                                          monthlyData.get(5).get('Equipment'), monthlyData.get(6).get('Equipment'), 
                                          monthlyData.get(7).get('Equipment'), monthlyData.get(8).get('Equipment'), 
                                          monthlyData.get(9).get('Equipment'), monthlyData.get(10).get('Equipment'), 
                                          monthlyData.get(11).get('Equipment'), monthlyData.get(12).get('Equipment') }));
        budgetRows.add(new BudgetRows('Contractual', Budgetrecord.Budgeted_Contractual_Costs__c,((Budgetrecord.Budgeted_Contractual_Costs__c != null ? Budgetrecord.Budgeted_Contractual_Costs__c : 0) 
                                                                                                 - (FringetotalSalarys != null ? FringetotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('Contractual'), monthlyData.get(2).get('Contractual'), 
                                          monthlyData.get(3).get('Contractual'), monthlyData.get(4).get('Contractual'), 
                                          monthlyData.get(5).get('Contractual'), monthlyData.get(6).get('Contractual'), 
                                          monthlyData.get(7).get('Contractual'), monthlyData.get(8).get('Contractual'), 
                                          monthlyData.get(9).get('Contractual'), monthlyData.get(10).get('Contractual'), 
                                          monthlyData.get(11).get('Contractual'), monthlyData.get(12).get('Contractual') }));
        List<AggregateResult> subContractAggregates = [
        SELECT Agreement__r.Name AgreementName, 
               SUM(Actual_Total_Salary__c) TotalActualSalary
        FROM Budget_Line_Item__c
        WHERE Budget__c = :recordId
        AND Cost_Category__c = 'Subcontracts'
        GROUP BY Agreement__r.Name
    ];



   for (AggregateResult ar : subContractAggregates) {
    String agreementName = (String) ar.get('AgreementName');
    Decimal totalActualSalary = (Decimal) ar.get('TotalActualSalary');
    Decimal totalContractBudget = 0;

    List<Agreement__c> agreements = [
        SELECT Contract_Budget__c 
        FROM Agreement__c 
        WHERE Name = :agreementName
        LIMIT 1
    ];
    if (!agreements.isEmpty() && agreements[0].Contract_Budget__c != null) {
        totalContractBudget = agreements[0].Contract_Budget__c;
    }

    if (agreementName != null) {
        List<BudgetLineItem> monthlyItems = new List<BudgetLineItem>();

        for (Integer m = 1; m <= 12; m++) {
            Map<String, BudgetLineItem> monthMap = monthlyData.get(m);
            if (monthMap != null) {
                String subcontractKey = 'Subcontract_' + agreementName;
                BudgetLineItem data = monthMap.get(subcontractKey);

                if (data == null) {
                    data = new BudgetLineItem();
                    data.label = agreementName;
                    data.total = 0;
                }
                monthlyItems.add(data);
            } else {
                BudgetLineItem emptyItem = new BudgetLineItem();
                emptyItem.label = agreementName;
                emptyItem.total = 0;
                monthlyItems.add(emptyItem);
            }
        }
    budgetRows.add(new BudgetRows('Subcontracts', 0, 0, new List<BudgetLineItem>()));

        budgetRows.add(new BudgetRows(
            '  → ' + agreementName,
            totalContractBudget,
            (totalContractBudget != null ? totalContractBudget : 0) - totalActualSalary,
            monthlyItems
        ));
    }
}

        budgetRows.add(new BudgetRows('Other Direct Costs', Budgetrecord.Budgeted_Other_Direct_Costs__c,((Budgetrecord.Budgeted_Other_Direct_Costs__c != null ? Budgetrecord.Budgeted_Other_Direct_Costs__c : 0) 
                                                                                                         - (OthertotalSalarys != null ? OthertotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('otherDirectCost'), monthlyData.get(2).get('otherDirectCost'), 
                                          monthlyData.get(3).get('otherDirectCost'), monthlyData.get(4).get('otherDirectCost'), 
                                          monthlyData.get(5).get('otherDirectCost'), monthlyData.get(6).get('otherDirectCost'), 
                                          monthlyData.get(7).get('otherDirectCost'), monthlyData.get(8).get('otherDirectCost'), 
                                          monthlyData.get(9).get('otherDirectCost'), monthlyData.get(10).get('otherDirectCost'), 
                                          monthlyData.get(11).get('otherDirectCost'), monthlyData.get(12).get('otherDirectCost') }));
        
        System.debug('Combined Total Sum: ' + combinedTotalSum);
        
        System.debug('Combined Totals: ' + combinedTotals);        
        budgetRows.add(new BudgetRows('Total Direct Cost', overallTotal,budgetoverallTotal, combinedTotals));
        budgetRows.add(new BudgetRows('Indirect Cost - Overhead', Budgetrecord.Budgeted_Overhead_Amount__c,((Budgetrecord.Budgeted_Overhead_Amount__c != null ? Budgetrecord.Budgeted_Overhead_Amount__c : 0) 
                                                                                                            - (OverheadtotalSalarys != null ? OverheadtotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('indirectOverhead'), monthlyData.get(2).get('indirectOverhead'), 
                                          monthlyData.get(3).get('indirectOverhead'), monthlyData.get(4).get('indirectOverhead'), 
                                          monthlyData.get(5).get('indirectOverhead'), monthlyData.get(6).get('indirectOverhead'), 
                                          monthlyData.get(7).get('indirectOverhead'), monthlyData.get(8).get('indirectOverhead'), 
                                          monthlyData.get(9).get('indirectOverhead'), monthlyData.get(10).get('indirectOverhead'), 
                                          monthlyData.get(11).get('indirectOverhead'), monthlyData.get(12).get('indirectOverhead') }));
        budgetRows.add(new BudgetRows('Indirect Cost - G&A', Budgetrecord.Budgeted_G_A_Amount__c,((Budgetrecord.Budgeted_G_A_Amount__c != null ? Budgetrecord.Budgeted_G_A_Amount__c : 0) 
                                                                                                  - (GtotalSalarys != null ? GtotalSalarys : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('indirectGA'), monthlyData.get(2).get('indirectGA'), 
                                          monthlyData.get(3).get('indirectGA'), monthlyData.get(4).get('indirectGA'), 
                                          monthlyData.get(5).get('indirectGA'), monthlyData.get(6).get('indirectGA'), 
                                          monthlyData.get(7).get('indirectGA'), monthlyData.get(8).get('indirectGA'), 
                                          monthlyData.get(9).get('indirectGA'), monthlyData.get(10).get('indirectGA'), 
                                          monthlyData.get(11).get('indirectGA'), monthlyData.get(12).get('indirectGA') }));
        system.debug('mee : '+monthlyData.get(5).get('indirectGA'));
        budgetRows.add(new BudgetRows('Indirect Cost - Custom', Budgetrecord.Budgeted_Custom__c,((Budgetrecord.Budgeted_Custom__c != null ? Budgetrecord.Budgeted_Custom__c : 0) 
                                                                                                                - (Indirecttotalcosts != null ? Indirecttotalcosts : 0)),
                                      new List<BudgetLineItem>{ monthlyData.get(1).get('indirectCost'), monthlyData.get(2).get('indirectCost'), 
                                          monthlyData.get(3).get('indirectCost'), monthlyData.get(4).get('indirectCost'), 
                                          monthlyData.get(5).get('indirectCost'), monthlyData.get(6).get('indirectCost'), 
                                          monthlyData.get(7).get('indirectCost'), monthlyData.get(8).get('indirectCost'), 
                                          monthlyData.get(9).get('indirectCost'), monthlyData.get(10).get('indirectCost'), 
                                          monthlyData.get(11).get('indirectCost'), monthlyData.get(12).get('indirectCost') }));
        List<Decimal> Totals = new List<Decimal>();
        TotalValue = (Budgetrecord.Budgeted_Travel_Transportation__c != null ? Budgetrecord.Budgeted_Travel_Transportation__c : 0) +
            (Budgetrecord.Budgeted_Equipment_Costs__c != null ? Budgetrecord.Budgeted_Equipment_Costs__c : 0) +
            (Budgetrecord.Budgeted_Contractual_Costs__c != null ? Budgetrecord.Budgeted_Contractual_Costs__c : 0) +
            (Budgetrecord.Budgeted_Subcontracts_Costs__c != null ? Budgetrecord.Budgeted_Subcontracts_Costs__c : 0) +
            (Budgetrecord.Budgeted_Other_Direct_Costs__c != null ? Budgetrecord.Budgeted_Other_Direct_Costs__c : 0)+
            (Budgetrecord.Budgeted_Overhead_Amount__c != null ? Budgetrecord.Budgeted_Overhead_Amount__c : 0) +
            (Budgetrecord.Budgeted_G_A_Amount__c != null ? Budgetrecord.Budgeted_G_A_Amount__c : 0)+
              (Budgetrecord.Budgeted_Salaries_Wages__c != null ? Budgetrecord.Budgeted_Salaries_Wages__c : 0)+
            (Budgetrecord.Budgeted_Fringe_Benefits__c != null ? Budgetrecord.Budgeted_Fringe_Benefits__c : 0);
        
        system.debug('TotalValue'+TotalValue);
        budgetTotalValue = ((Budgetrecord.Budgeted_Travel_Transportation__c != null ? Budgetrecord.Budgeted_Travel_Transportation__c : 0) - (TraveltotalSalarys != null ? TraveltotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Equipment_Costs__c != null ? Budgetrecord.Budgeted_Equipment_Costs__c : 0) 
             - (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Contractual_Costs__c != null ? Budgetrecord.Budgeted_Contractual_Costs__c : 0) 
             - (FringetotalSalarys != null ? FringetotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_Subcontracts_Costs__c != null ? Budgetrecord.Budgeted_Subcontracts_Costs__c : 0) 
             - (Subcontracts != null ? Subcontracts : 0)) +
            ((Budgetrecord.Budgeted_Other_Direct_Costs__c != null ? Budgetrecord.Budgeted_Other_Direct_Costs__c : 0) 
             - (OthertotalSalarys != null ? OthertotalSalarys : 0))+
            ((Budgetrecord.Budgeted_Overhead_Amount__c != null ? Budgetrecord.Budgeted_Overhead_Amount__c : 0) 
             - (OverheadtotalSalarys != null ? OverheadtotalSalarys : 0)) +
            ((Budgetrecord.Budgeted_G_A_Amount__c != null ? Budgetrecord.Budgeted_G_A_Amount__c : 0) 
             - (GtotalSalarys != null ? GtotalSalarys : 0))+
             ((Budgetrecord.Budgeted_Salaries_Wages__c != null ? Budgetrecord.Budgeted_Salaries_Wages__c : 0) - (combinedTotalSum != null ? combinedTotalSum : 0))+
            ((Budgetrecord.Budgeted_Fringe_Benefits__c != null ? Budgetrecord.Budgeted_Fringe_Benefits__c : 0) - (overallFringeTotal != null ? overallFringeTotal : 0));

        
        system.debug('TotalValue'+TotalValue);
        for (Integer i = 1; i <= 12; i++) {
            Decimal totalForMonth = 
                monthlyData.get(i).get('travelTransportation').total +
                monthlyData.get(i).get('Equipment').total +
                monthlyData.get(i).get('Contractual').total +
                monthlyData.get(i).get('Subcontract').total +
                monthlyData.get(i).get('otherDirectCost').total +
                monthlyData.get(i).get('indirectOverhead').total +
                monthlyData.get(i).get('indirectGA').total;
            Totals.add(totalForMonth);          
        }
        List<BudgetLineItem> overallTotals = new List<BudgetLineItem>(); 
        if (Totals.size() == monthlyTotals.size() && monthlyTotals.size() == totalmonthlyTotals.size()) {
            for (Integer i = 0; i < Totals.size(); i++) {
                Decimal combinedTotal = Totals[i] + monthlyTotals[i] + totalmonthlyTotals[i]+ (totalmonthlyTotals[i]* (budgetFringeBenefit / 100));
                overallTotals.add(new BudgetLineItem(null, combinedTotal,null));
            }
        } else {
            System.debug('Error: List sizes are not matching.');
        }
        List<BudgetLineItem> feeTotals = new List<BudgetLineItem>();
        Decimal feePercentage = Budgetrecord.Fee_Percentage__c != null ? Budgetrecord.Fee_Percentage__c/ 100 : 0;
        
        for (BudgetLineItem overallTotalItem : overallTotals) {
            Decimal feeAmount = overallTotalItem.total != null ? (overallTotalItem.total * feePercentage) : 0;
            feeTotals.add(new BudgetLineItem(null, feeAmount,null));
        }
        
        Decimal feeTotalValue = Budgetrecord.Budgeted_Fee_Amount__c;
        Decimal feeBudgetTotalValue = feeTotalValue-((TraveltotalSalarys != null ? TraveltotalSalarys : 0) + 
                                                     (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0) +
                                                     (FringetotalSalarys != null ? FringetotalSalarys : 0) +
                                                     (Subcontracts != null ? Subcontracts : 0) +
                                                     (OthertotalSalarys != null ? OthertotalSalarys : 0)+
                                                     (OverheadtotalSalarys != null ? OverheadtotalSalarys : 0) +
                                                     (GtotalSalarys != null ? GtotalSalarys : 0))*feePercentage;
        System.debug('feeTotalValue.'+JSON.serialize(feeTotalValue));      
        System.debug('feeBudgetTotalValue.'+JSON.serialize(feeBudgetTotalValue));      
        System.debug('feeTotals.'+JSON.serialize(feeTotals));      
                budgetRows.add(new BudgetRows('Total Cost', TotalValue,budgetTotalValue, overallTotals));
        budgetRows.add(new BudgetRows('Fee', feeTotalValue, feeBudgetTotalValue, feeTotals));
        TotalBudgetValue = TotalValue+feeTotalValue;
        budgetTotalBudgetValue = budgetTotalValue+feeBudgetTotalValue;
        List<BudgetLineItem> finalTotals = new List<BudgetLineItem>();
        
        if (overallTotals.size() == feeTotals.size()) {
            for (Integer i = 0; i < overallTotals.size(); i++) {
                Decimal finalTotal = overallTotals[i].total + feeTotals[i].total;
                
                finalTotals.add(new BudgetLineItem(null, finalTotal,null));
            }
        } else {
            System.debug('Error: List sizes are not matching.');
        }
        budgetRows.add(new BudgetRows('Grand Total', TotalBudgetValue,budgetTotalBudgetValue, finalTotals));
        System.debug('budgetRows.'+JSON.serialize(budgetRows)); 
        
        return budgetRows;
    }    
    
    @AuraEnabled
    public static void updateBudgetRecord(Id recordId, List<Map<String, Object>> modifiedRows) {
        try {
            Budget__c budgetRecord = new Budget__c(Id = recordId);
            Boolean isUpdate = false;
            for (Map<String, Object> modifiedRow : modifiedRows) {
                String budgetValue = modifiedRow.containsKey('BudgetValue') ? (String) modifiedRow.get('BudgetValue') : null;
                String rowName = modifiedRow.containsKey('rowName') ? (String) modifiedRow.get('rowName') : null;
                if (budgetValue != null) {
                    if(rowName == 'Travel & Transportation'){
                        budgetRecord.Budgeted_Travel_Transportation__c = Decimal.valueOf(budgetValue);
                        isUpdate = true;
                    } else if(rowName == 'Equipment'){
                        budgetRecord.Budgeted_Equipment_Costs__c = Decimal.valueOf(budgetValue);
                        isUpdate = true;
                    }else if(rowName == 'Contractual'){
                        budgetRecord.Budgeted_Contractual_Costs__c = Decimal.valueOf(budgetValue);
                        isUpdate = true;
                    }else if(rowName == 'Subcontracts'){
                        budgetRecord.Budgeted_Subcontracts_Costs__c = Decimal.valueOf(budgetValue);
                        isUpdate = true;
                    }else if(rowName == 'Other Direct Costs'){
                        budgetRecord.Budgeted_Other_Direct_Costs__c = Decimal.valueOf(budgetValue);
                        isUpdate = true;
                    }
                }
            }
            
            
            if (isUpdate) {
                update budgetRecord;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating budget records: ' + e.getMessage());
        }
    }
    
    public class BudgetDirectRow {
        public String rowName;
        public Decimal BudgetValue;
        public BudgetDirectRow() {
            this.rowName = '';
            this.BudgetValue = 0.0;
        }
    }   
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Date> getBudgetPeriodDates(Id recordId) {
        Budget__c budget = [SELECT Budget_Period_Start_Date__c, Budget_Period_End_Date__c 
                            FROM Budget__c 
                            WHERE Id = :recordId LIMIT 1];
        return new Map<String, Date>{
            'startDate' => budget.Budget_Period_Start_Date__c,
                'endDate' => budget.Budget_Period_End_Date__c
                };
                    }
    
    public class EmployeeContractData {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Map<String, MonthData> monthlyData;
    }
    
    public class MonthData {
        @AuraEnabled public Decimal units;
        @AuraEnabled public Decimal dailyRate;
        @AuraEnabled public Decimal total;
        @AuraEnabled public string ActualLocked;
        @AuraEnabled public Id budgetItemId;
        
        public MonthData(Id budgetItemId, Decimal units, Decimal dailyRate, Decimal total,String ActualLocked) {
            this.units = units;
            this.dailyRate = dailyRate;
            this.total = total;
            this.budgetItemId = budgetItemId;
            this.ActualLocked = ActualLocked;
        }
    }    
    
    @AuraEnabled(cacheable=true)
    public static Decimal getFringeBenefitData(String recordId) {
        Budget__c fringeBenefit = [
            SELECT id, Fringe_Benefit_Rate__c 
            FROM Budget__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        system.debug('fringeBenefit.Fringe_Benefit_Rate__c;  '+fringeBenefit.Fringe_Benefit_Rate__c);
        return fringeBenefit.Fringe_Benefit_Rate__c;
        
    }   
    @AuraEnabled
    public static void updateBudgetData(Id budgetId, List<Map<String, Object>> draftValues, String selectedYear) {
        system.debug('budgetId'+ budgetId);
        system.debug('draftValues'+ draftValues);
        system.debug('selectedYear'+ selectedYear);
        Map<Id, Budget_Line_Item__c> updates = new Map<Id, Budget_Line_Item__c>();
        List<Budget_Line_Item__c> inserts = new List<Budget_Line_Item__c>();
        Integer currentYear = String.isNotBlank(selectedYear) ? Integer.valueOf(selectedYear) : Date.today().year(); 
        Map<String, Integer> monthMap = new Map<String, Integer>{
            'Jan' => 1, 'Feb' => 2, 'Mar' => 3,
                'Apr' => 4, 'May' => 5, 'Jun' => 6,
                'Jul' => 7, 'Aug' => 8, 'Sep' => 9,
                'Oct' => 10, 'Nov' => 11, 'Dec' => 12
                };
                    
                    for (Map<String, Object> draft : draftValues) {  
                        Id budgetItemId = (Id) draft.get('budgetItemId'); 
                        String monthStr = (String) draft.get('Month');
                        String rowName = (String) draft.get('rowName');
                        if (rowName == 'Indirect Cost - Overhead') {
                            rowName = 'Overhead Rate';
                        }else if(rowName == 'Indirect Cost - G&A'){
                            rowName = 'G&A Rate';    
                        }
                        Integer month = monthMap.containsKey(monthStr) ? monthMap.get(monthStr) : null; 
                        Decimal dailyRate = draft.containsKey('value') && draft.get('value') != null
                            ? Decimal.valueOf((String) draft.get('value'))
                            : null;
                        if (budgetItemId != null) {
                            Budget_Line_Item__c budgetLine = new Budget_Line_Item__c();
                            budgetLine.Id = budgetItemId;
                            if (dailyRate != null) budgetLine.Actual_Daily_Rate__c = dailyRate;
                            updates.put(budgetLine.Id, budgetLine);
                        } else {
                            Date startDate = Date.newInstance(currentYear, month, 1);
                            Date endDate = startDate.toStartOfMonth().addMonths(1).addDays(-1);     
                            Budget_Line_Item__c newBudgetLine = new Budget_Line_Item__c(
                                Budget_Line_Item_Start_Date__c = startDate,
                                Budget_Line_Item_EndDate__c = endDate,
                                Budget__c = budgetId,
                                Actual_Daily_Rate__c = dailyRate,
                                Cost_Category__c = rowName,
                                Actual_Units__c = 1
                            );
                            
                            inserts.add(newBudgetLine);
                        }
                    }
        system.debug('updates'+ updates);
        system.debug('inserts'+ inserts);
        if (!updates.isEmpty()) {
            update updates.values();
        }
        if (!inserts.isEmpty()) {
            insert inserts;
        }
    }
    
}