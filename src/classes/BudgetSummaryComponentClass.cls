public class BudgetSummaryComponentClass {
    
    public class BudgetRow {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value1 { get; set; }
        @AuraEnabled public String value2 { get; set; }
        @AuraEnabled public String value3 { get; set; }
        @AuraEnabled public String value4 { get; set; }
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public List<BudgetRow> childRows { get; set; }
        
        public BudgetRow() {}
        public BudgetRow(String label, String value1,String value2,String value3,String value4, String Id) {
            this.label = label;
            this.value1 = value1;
            this.value2 = value2;
            this.value3 = value3;
            this.value4 = value4;
            this.Id = Id;
            this.childRows = new List<BudgetRow>(); 
            
        }
    }
    public static Decimal EmployeetotalSalary;
    public static Decimal FringetotalSalary;
    public static Decimal TraveltotalSalary;
    public static Decimal OthertotalSalary;
    public static Decimal GtotalSalary;
    public static Decimal OverheadtotalSalary;
    public static Decimal Indirecttotalcost;
    public static Decimal TotalEstimatedCost;
    public static Decimal EmployeetotalSalarys;
    public static Decimal FringetotalSalarys;
    public static Decimal TraveltotalSalarys;
    public static Decimal OthertotalSalarys;
    public static Decimal GtotalSalarys;
    public static Decimal OverheadtotalSalarys;
    public static Decimal Indirecttotalcosts;
    public static Decimal TotalEstimateds;
    public static Decimal FringeRemaining;
    
    @AuraEnabled(cacheable=true)
    public static List<BudgetRow> getRelatedData(String recordId) {
        Budget__c relatedData = [
            SELECT Id, Name, Budgeted_Salaries_Wages__c, Budgeted_Fringe_Benefits__c, 
            Budgeted_Travel_Transportation__c, Budgeted_Other_Direct_Costs__c, 
            Budgeted_Overhead_Amount__c, Budgeted_G_A_Amount__c, Budgeted_Contractual_Costs__c,Budgeted_Equipment_Costs__c,Budgeted_Direct_Costs__c,Budgeted_Grand_Total__c,
            Total_Indirect_Costs__c, Total_Budgeted_Amount__c,Indirect_Cost_Type__c,Fee_Percentage__c,Budgeted_Fee_Amount__c,Budgeted_Custom__c
            FROM Budget__c WHERE Id = :recordId
        ];
        
        List<Budget_Line_Item__c> combinedResults = [select Actual_Total_Salary__c,Budget__c,Cost_Category__c,Overhead_Amount__c,
                                                     G_A_Amount__c,Custom_Indirect_Cost_Amount__c,Fringe_Amount__c
                                                     FROM Budget_Line_Item__c
                                                     WHERE Budget__c = :recordId
                                                     AND Budget_Line_Item_Start_Date__c = THIS_MONTH
                                                     AND Budget_Line_Item_EndDate__c = THIS_MONTH];
        
        
        Decimal TotalEstimatedCost = 0;
        Decimal EmployeetotalSalary = 0;
        Decimal FringetotalSalary = 0;
        Decimal TraveltotalSalary = 0;
        Decimal OthertotalSalary = 0;
        Decimal GtotalSalary = 0;
        Decimal OverheadtotalSalary = 0;
        Decimal Indirecttotalcost = 0;
        Decimal EquipmenttotalSalary = 0;
        Decimal ContractualtotalSalary = 0;
        
        for (Budget_Line_Item__c ar : combinedResults) {
            
            TotalEstimatedCost += ar.Actual_Total_Salary__c;
            String costCategory = ar.Cost_Category__c;
            Decimal salary = ar.Actual_Total_Salary__c;
            FringetotalSalary += ar.Fringe_Amount__c;
            Indirecttotalcost += ar.Custom_Indirect_Cost_Amount__c;
            
            if (costCategory == 'Employee') {
                EmployeetotalSalary += salary;
            }  else if (costCategory == 'Travel & Transportation') {
                TraveltotalSalary += salary;
            } else if (costCategory == 'Other Direct Cost') {
                OthertotalSalary += salary;
            } else if (costCategory == 'G&A Rate') {
                GtotalSalary = salary;
            }else if (costCategory == 'Overhead Rate') {
                OverheadtotalSalary = salary;
            }else if (costCategory == 'Equipment') {
                EquipmenttotalSalary = salary;
            } else if (costCategory == 'Contractual') {
                ContractualtotalSalary = salary;
            }
        }
        List<Budget_Line_Item__c> combinedResult = [select Actual_Total_Salary__c,Budget__c,Cost_Category__c,Overhead_Amount__c,
                                                    G_A_Amount__c,Custom_Indirect_Cost_Amount__c,Fringe_Amount__c
                                                    FROM Budget_Line_Item__c
                                                    WHERE Budget__c = :recordId
                                                    AND Actuals_Locked__c = 'Yes, actuals final'];
        
        Decimal TotalEstimateds = 0;
        Decimal EmployeetotalSalarys = 0;
        Decimal FringetotalSalarys = 0;
        Decimal TraveltotalSalarys = 0;
        Decimal OthertotalSalarys = 0;
        Decimal GtotalSalarys = 0;
        Decimal OverheadtotalSalarys = 0;
        Decimal Indirecttotalcosts = 0;
        Decimal EquipmenttotalSalarys = 0;
        Decimal ContractualtotalSalarys = 0;
        
        
        for (Budget_Line_Item__c ar : combinedResult) {
            
            TotalEstimateds += ar.Actual_Total_Salary__c;
            String costCategory = ar.Cost_Category__c;
            Decimal salary = ar.Actual_Total_Salary__c;
            Indirecttotalcosts += ar.Custom_Indirect_Cost_Amount__c;
                        FringetotalSalarys += ar.Fringe_Amount__c;

            if (costCategory == 'Employee') {
                EmployeetotalSalarys = salary;
            }  else if (costCategory == 'Travel & Transportation') {
                TraveltotalSalarys = salary;
            } else if (costCategory == 'Other Direct Cost') {
                OthertotalSalarys = salary;
            } else if (costCategory == 'G&A Rate') {
                GtotalSalarys = salary;
            }else if (costCategory == 'Overhead Rate') {
                OverheadtotalSalarys = salary;
            } else if (costCategory == 'Equipment') {
                EquipmenttotalSalarys = salary;
            } else if (costCategory == 'Contractual') {
                ContractualtotalSalarys = salary;
            }
        }
        
        AggregateResult[] combinedTotalResult = [
            SELECT Cost_Category__c, SUM(Actual_Total_Salary__c) totalSalary
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Budget_Line_Item_Start_Date__c = THIS_MONTH
            AND Budget_Line_Item_EndDate__c = THIS_MONTH
            GROUP BY Cost_Category__c
        ];
        
        AggregateResult[] combinedTotalResults = [SELECT Cost_Category__c, SUM(Actual_Total_Salary__c) totalSalary
                                                  FROM Budget_Line_Item__c
                                                  WHERE Budget__c = :recordId
                                                  AND Actuals_Locked__c = 'Yes, actuals final'     GROUP BY Cost_Category__c];
        Decimal totalSalary = 0;
        Decimal totalSalarys = 0;
        
        if (!combinedTotalResult.isEmpty()) {
            totalSalary = (Decimal)combinedTotalResult[0].get('totalSalary');
        }
        if (!combinedTotalResults.isEmpty()) {
            totalSalarys = (Decimal)combinedTotalResults[0].get('totalSalary');
        }
        
        List<BudgetRow> rows = new List<BudgetRow>();
        
        rows.add(new BudgetRow('Salaries & Wages', String.valueOf(relatedData.Budgeted_Salaries_Wages__c), String.valueOf(EmployeetotalSalary), String.valueOf(EmployeetotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Salaries_Wages__c != null ? relatedData.Budgeted_Salaries_Wages__c : 0) - (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0)), relatedData.Id));
        
        rows.add(new BudgetRow('Fringe Benefits', String.valueOf(relatedData.Budgeted_Fringe_Benefits__c), String.valueOf(FringetotalSalary), String.valueOf(FringetotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Fringe_Benefits__c != null ? relatedData.Budgeted_Fringe_Benefits__c : 0) - (FringetotalSalarys != null ? FringetotalSalarys : 0)), relatedData.Id));
        
        rows.add(new BudgetRow('Travel & Transportation', String.valueOf(relatedData.Budgeted_Travel_Transportation__c), String.valueOf(TraveltotalSalary), String.valueOf(TraveltotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Travel_Transportation__c != null ? relatedData.Budgeted_Travel_Transportation__c : 0) - (TraveltotalSalarys != null ? TraveltotalSalarys : 0)), relatedData.Id));
        rows.add(new BudgetRow('Equipment', String.valueOf(relatedData.Budgeted_Equipment_Costs__c), String.valueOf(EquipmenttotalSalary), String.valueOf(EquipmenttotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Equipment_Costs__c != null ? relatedData.Budgeted_Equipment_Costs__c : 0) - (EquipmenttotalSalarys != null ? EquipmenttotalSalarys : 0)), relatedData.Id));
        rows.add(new BudgetRow('Contractual', String.valueOf(relatedData.Budgeted_Contractual_Costs__c), String.valueOf(ContractualtotalSalary), String.valueOf(ContractualtotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Contractual_Costs__c != null ? relatedData.Budgeted_Contractual_Costs__c : 0) - (ContractualtotalSalarys != null ? ContractualtotalSalarys : 0)), relatedData.Id));
        
        
        rows.add(new BudgetRow('Other Direct Costs', String.valueOf(relatedData.Budgeted_Other_Direct_Costs__c), String.valueOf(OthertotalSalary), String.valueOf(OthertotalSalarys), 
                               String.valueOf((relatedData.Budgeted_Other_Direct_Costs__c != null ? relatedData.Budgeted_Other_Direct_Costs__c : 0) - (OthertotalSalarys != null ? OthertotalSalarys : 0)), relatedData.Id));
        Decimal totalBudgeted = 
            (relatedData.Budgeted_Salaries_Wages__c != null ? relatedData.Budgeted_Salaries_Wages__c : 0) +
            (relatedData.Budgeted_Fringe_Benefits__c != null ? relatedData.Budgeted_Fringe_Benefits__c : 0) +
            (relatedData.Budgeted_Travel_Transportation__c != null ? relatedData.Budgeted_Travel_Transportation__c : 0) +
            (relatedData.Budgeted_Other_Direct_Costs__c != null ? relatedData.Budgeted_Other_Direct_Costs__c : 0)+
            (relatedData.Budgeted_Equipment_Costs__c != null ? relatedData.Budgeted_Equipment_Costs__c : 0)+
            (relatedData.Budgeted_Contractual_Costs__c != null ? relatedData.Budgeted_Contractual_Costs__c : 0);
        
        Decimal totalCurrent = 
            (EmployeetotalSalary != null ? EmployeetotalSalary : 0) +
            (FringetotalSalary != null ? FringetotalSalary : 0) +
            (TraveltotalSalary != null ? TraveltotalSalary : 0) +
            (OthertotalSalary != null ? OthertotalSalary : 0)+
            (EquipmenttotalSalary != null ? EquipmenttotalSalary : 0)+
            (ContractualtotalSalary != null ? ContractualtotalSalary : 0);
        
        
        Decimal totalSpent = 
            (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0) +
            (FringetotalSalarys != null ? FringetotalSalarys : 0) +
            (TraveltotalSalarys != null ? TraveltotalSalarys : 0) +
            (OthertotalSalarys != null ? OthertotalSalarys : 0)+
            (EquipmenttotalSalarys != null ? EquipmenttotalSalarys : 0)+
            (ContractualtotalSalarys != null ? ContractualtotalSalarys : 0);
        
        Decimal totalRemaining = relatedData.Budgeted_Direct_Costs__c - totalSpent;
        
       
        
        List<AggregateResult> SubContractResult = [
            SELECT Agreement__r.Name AgreementName, 
            SUM(Actual_Total_Salary__c) TotalActualSalary
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Cost_Category__c = 'Subcontracts'
            GROUP BY Agreement__r.Name
        ];
        List<AggregateResult> SubContractResults = [
            SELECT Agreement__r.Name AgreementName, 
            SUM(Actual_Total_Salary__c) TotalActualSalary
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Cost_Category__c = 'Subcontracts'
            AND Budget_Line_Item_Start_Date__c = THIS_MONTH
            AND Budget_Line_Item_EndDate__c = THIS_MONTH
            GROUP BY Agreement__r.Name
        ];
        
        List<AggregateResult> SubContractcombinedResult = [
            SELECT Agreement__r.Name AgreementName, 
            SUM(Actual_Total_Salary__c) TotalActualSalary
            FROM Budget_Line_Item__c
            WHERE Budget__c = :recordId
            AND Cost_Category__c = 'Subcontracts'
            AND Actuals_Locked__c = 'Yes, actuals final'
            GROUP BY Agreement__r.Name
        ];
        
        Set<String> agreementNames = new Set<String>();
        for (AggregateResult ar : SubContractResult) {
            agreementNames.add((String) ar.get('AgreementName'));
        }
        for (AggregateResult ar : SubContractResults) {
            agreementNames.add((String) ar.get('AgreementName'));
        }
        for (AggregateResult ar : SubContractcombinedResult) {
            agreementNames.add((String) ar.get('AgreementName'));
        }
        
        Map<String, Decimal> budgetedAmountMap = new Map<String, Decimal>();
        List<Agreement__c> agreements = [
            SELECT Name, Contract_Budget__c FROM Agreement__c WHERE Name IN :agreementNames
        ];
        if (agreements != null && !agreements.isEmpty()) {
            system.debug('agreements'+agreements.size());
            rows.add(new BudgetRow('Subcontracts', '', '', '', '', null));
            
            
            for (Agreement__c agreement : agreements) {
                if (!budgetedAmountMap.containsKey(agreement.Name)) {
                    budgetedAmountMap.put(agreement.Name, 0);
                }
                Decimal budget = agreement.Contract_Budget__c != null ? agreement.Contract_Budget__c : 0;
                budgetedAmountMap.put(agreement.Name, budgetedAmountMap.get(agreement.Name) + budget);}
            for (String agreementName : agreementNames) {
                Decimal budgetedAmount = budgetedAmountMap.containsKey(agreementName) ? budgetedAmountMap.get(agreementName) : 0;
                Decimal totalActualSalary = 0;
                Decimal finalActualSalary = 0;
                
                for (AggregateResult ar : SubContractResults) {
                    if (agreementName == (String) ar.get('AgreementName')) {
                        totalActualSalary = (Decimal) ar.get('TotalActualSalary');
                        break;
                    }
                }
                
                for (AggregateResult ar : SubContractcombinedResult) {
                    if (agreementName == (String) ar.get('AgreementName')) {
                        finalActualSalary = (Decimal) ar.get('TotalActualSalary');
                        break;
                    }
                }
                if(agreementName != null){
                    
                    rows.add(new BudgetRow(
                        '  → ' + agreementName,
                        String.valueOf(budgetedAmount),
                        String.valueOf(totalActualSalary),
                        String.valueOf(finalActualSalary),
                        String.valueOf(budgetedAmount - finalActualSalary),
                        null
                    )); 
                }
            }        
        }
        rows.add(new BudgetRow('Total Direct', 
                               String.valueOf(relatedData.Budgeted_Direct_Costs__c), 
                               String.valueOf(totalCurrent), 
                               String.valueOf(totalSpent), 
                               String.valueOf(totalRemaining), 
                               relatedData.Id));
        Decimal Fee = (relatedData.Fee_Percentage__c != null ? relatedData.Fee_Percentage__c : 0) / 100;
        if (String.valueOf(relatedData.Indirect_Cost_Type__c) == 'Standard') {
            rows.add(new BudgetRow('Indirect Cost - G&A', String.valueOf(relatedData.Budgeted_G_A_Amount__c), String.valueOf(GtotalSalary), String.valueOf(GtotalSalarys), 
                                   String.valueOf((relatedData.Budgeted_G_A_Amount__c != null ? relatedData.Budgeted_G_A_Amount__c : 0) - (GtotalSalarys != null ? GtotalSalarys : 0)), relatedData.Id));
            
            rows.add(new BudgetRow('Indirect Cost - Overhead', String.valueOf(relatedData.Budgeted_Overhead_Amount__c), String.valueOf(OverheadtotalSalary), String.valueOf(OverheadtotalSalarys), 
                                   String.valueOf((relatedData.Budgeted_Overhead_Amount__c != null ? relatedData.Budgeted_Overhead_Amount__c : 0) - (OverheadtotalSalarys != null ? OverheadtotalSalarys : 0)), relatedData.Id));
        } else if (String.valueOf(relatedData.Indirect_Cost_Type__c) == 'Custom') {
            rows.add(new BudgetRow('Indirect Costs', String.valueOf(relatedData.Budgeted_Custom__c), String.valueOf(Indirecttotalcost), String.valueOf(Indirecttotalcosts), 
                                   String.valueOf((relatedData.Budgeted_Custom__c != null ? relatedData.Budgeted_Custom__c : 0) - (Indirecttotalcosts != null ? Indirecttotalcosts : 0)), relatedData.Id));
        }
         
        // Step 1: Sum all Direct Costs
        Decimal totalDirectBudgeted = 
            (relatedData.Budgeted_Salaries_Wages__c != null ? relatedData.Budgeted_Salaries_Wages__c : 0) +
            (relatedData.Budgeted_Fringe_Benefits__c != null ? relatedData.Budgeted_Fringe_Benefits__c : 0) +
            (relatedData.Budgeted_Travel_Transportation__c != null ? relatedData.Budgeted_Travel_Transportation__c : 0) +
            (relatedData.Budgeted_Other_Direct_Costs__c != null ? relatedData.Budgeted_Other_Direct_Costs__c : 0)+
            (relatedData.Budgeted_Equipment_Costs__c != null ? relatedData.Budgeted_Equipment_Costs__c : 0)+
            (relatedData.Budgeted_Contractual_Costs__c != null ? relatedData.Budgeted_Contractual_Costs__c : 0);
        
        
        Decimal totalDirectCurrent = 
            (EmployeetotalSalary != null ? EmployeetotalSalary : 0) +
            (FringetotalSalary != null ? FringetotalSalary : 0) +
            (TraveltotalSalary != null ? TraveltotalSalary : 0) +
            (OthertotalSalary != null ? OthertotalSalary : 0)+
                        (EquipmenttotalSalary != null ? EquipmenttotalSalary : 0)+
            (ContractualtotalSalary != null ? ContractualtotalSalary : 0);
        
        Decimal totalDirectSpent = 
            (EmployeetotalSalarys != null ? EmployeetotalSalarys : 0) +
            (FringetotalSalarys != null ? FringetotalSalarys : 0) +
            (TraveltotalSalarys != null ? TraveltotalSalarys : 0) +
            (OthertotalSalarys != null ? OthertotalSalarys : 0)+
                        (EquipmenttotalSalarys != null ? EquipmenttotalSalarys : 0)+
            (ContractualtotalSalarys != null ? ContractualtotalSalarys : 0);
        
        Decimal totalDirectRemaining = totalDirectBudgeted - totalDirectSpent;
        
        
        
        // Step 2: Add Indirect Cost rows
        Decimal indirectBudgeted = 0;
        Decimal indirectCurrent = 0;
        Decimal indirectSpent = 0;
        
        if (String.valueOf(relatedData.Indirect_Cost_Type__c) == 'Standard') {
            // Add G&A
            Decimal gaBudgeted = (relatedData.Budgeted_G_A_Amount__c != null ? relatedData.Budgeted_G_A_Amount__c : 0);
            Decimal gaCurrent = (GtotalSalary != null ? GtotalSalary : 0);
            Decimal gaSpent = (GtotalSalarys != null ? GtotalSalarys : 0);
            
            // Add Overhead
            Decimal ohBudgeted = (relatedData.Budgeted_Overhead_Amount__c != null ? relatedData.Budgeted_Overhead_Amount__c : 0);
            Decimal ohCurrent = (OverheadtotalSalary != null ? OverheadtotalSalary : 0);
            Decimal ohSpent = (OverheadtotalSalarys != null ? OverheadtotalSalarys : 0);
            
            // Total indirects for final sum
            indirectBudgeted = gaBudgeted + ohBudgeted;
            indirectCurrent = gaCurrent + ohCurrent;
            indirectSpent = gaSpent + ohSpent;
            
        } else if (String.valueOf(relatedData.Indirect_Cost_Type__c) == 'Custom') {
            Decimal customBudgeted = (relatedData.Budgeted_Custom__c != null ? relatedData.Budgeted_Custom__c : 0);
            Decimal customCurrent = (Indirecttotalcost != null ? Indirecttotalcost : 0);
            Decimal customSpent = (Indirecttotalcosts != null ? Indirecttotalcosts : 0);
            
            
            
            indirectBudgeted = customBudgeted;
            indirectCurrent = customCurrent;
            indirectSpent = customSpent;
        }
        
        // Step 3: Add final Total Budget row
        Decimal totalBudgeteds = totalDirectBudgeted + indirectBudgeted;
        Decimal totalCurrents = totalDirectCurrent + indirectCurrent;
        Decimal totalSpents = totalDirectSpent + indirectSpent;
        Decimal totalRemainings = relatedData.Total_Budgeted_Amount__c - totalSpents;
        
        rows.add(new BudgetRow('Total Budget',
                               String.valueOf(relatedData.Total_Budgeted_Amount__c),
                               String.valueOf(totalCurrents),
                               String.valueOf(totalSpents),
                               String.valueOf(totalRemainings),
                               relatedData.Id));
        
        rows.add(new BudgetRow('Fee', String.valueOf(relatedData.Budgeted_Fee_Amount__c), String.valueOf(totalSalary*Fee), String.valueOf(totalSalarys*Fee), 
                               String.valueOf((relatedData.Budgeted_Fee_Amount__c != null ? relatedData.Budgeted_Fee_Amount__c : 0) - (totalSalarys*Fee != null ? totalSalarys*Fee : 0)), relatedData.Id));
        
        
        rows.add(new BudgetRow('Est Grand Total', String.valueOf(relatedData.Budgeted_Grand_Total__c), String.valueOf(TotalEstimatedCost+(totalSalary*Fee)), String.valueOf(TotalEstimateds+(totalSalarys*Fee)), 
                               String.valueOf((relatedData.Budgeted_Grand_Total__c != null ? relatedData.Budgeted_Grand_Total__c: 0) - ((TotalEstimateds+(totalSalarys*Fee)) != null ? (TotalEstimateds+(totalSalarys*Fee)) : 0)), relatedData.Id));
        
        return rows;
        
    }
    
  /*  @AuraEnabled
    public static void updateBudget(List<BudgetRow> budgetData, Id recordId) {
        List<Budget__c> budgetsToUpdate = new List<Budget__c>();
        Budget__c budget = new Budget__c();
        Agreement__c agreement = new Agreement__c();
        String agreementId;
        
        budget.Id = recordId;
        
        List<Budget_Line_Item__c> agg = [
            SELECT Id, Agreement__c, Agreement__r.Name 
            FROM Budget_Line_Item__c 
            WHERE Budget__c = :recordId AND Cost_Category__c = 'Subcontracts'
        ];
        
        try {
            for (BudgetRow data : budgetData) {
                String label = data.label;
                Decimal value1 = Decimal.valueOf(data.value1);
                System.debug('Processing label: ' + label + ', value1: ' + value1);
                
                String cleanedLabel = label.replace(' → ', '').trim();
                
                if (label.contains(' → ')) {
                    System.debug('Checking for Agreement match...');
                    for (Budget_Line_Item__c BL : agg) {
                        if (BL.Agreement__r != null && BL.Agreement__r.Name != null && BL.Agreement__r.Name.contains(cleanedLabel)) {
                            System.debug('Match found: ' + BL.Agreement__r.Name);
                            agreementId = BL.Agreement__c;
                            agreement.Id = agreementId; 
                            agreement.Contract_Budget__c = value1;
                            System.debug('Updating Agreement: ' + agreementId + ' with Contract_Budget__c: ' + value1);
                        }
                    }
                } 
                else if (label == 'Salaries & Wages') {
                    budget.Budgeted_Salaries_Wages__c = value1;
                } else if (label == 'Travel & Transportation') {
                    budget.Budgeted_Travel_Transportation__c = value1;
                } else if (label == 'Fringe Benefits') {
                    budget.Budgeted_Fringe_Benefits__c = value1;
                } else if (label == 'Other Direct Costs') {
                    budget.Budgeted_Other_Direct_Costs__c = value1;
                }
            }
            
            if (budget.Id != null) {
                update budget;
                System.debug('Budget updated successfully.');
            }
            
            if (agreementId != null) {
                update agreement;
                System.debug('Agreement updated successfully.');
            }
            
            
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while updating the budget data: ' + e.getMessage());
        }
    }*/
}