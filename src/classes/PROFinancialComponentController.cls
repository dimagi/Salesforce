public class PROFinancialComponentController {
    
    public String employeeEmail { get; set; }
    public DimagiToolsController pageController { get; set; }
    
    public String contractUrl { get; set; }
    public String financialContractId { get; set; }
    public String contractToAdd { get; set; }
    public String contractToRemove { get; set; }
    public List<DimagiToolsController.ProjectExecutionStatus> executionStatusList { get; set; }
    public List<DimagiToolsController.PROProjectTimeSpentHistory> timeSpendHistoryList { get; set; }
    public List<DimagiToolsController.PROProjectBudget> proExpenseSpendList { get; set; }
    public List<DimagiToolsController.PROProjectBudget> proBudgetList { get; set; }
    public Date lastFBSyncDate { get; set;}
    public Map<Id,DContract__c> contractMap { get; set; }
    public String searchError { get; set; }
    public string seachProjectName { get; set; }
    public List<DContract__c> searchedProjects { get; set; }
    public string myLightningHostname {get;set;}
    
    private String sfInstanceName;
    private Map<Id,List<DContract__c>> childcontractMap;
    private Set<Id> excludeContractFromSearch = new Set<Id>();
    
    public PROFinancialComponentController() {
        this.searchedProjects = new List<DContract__c>();
        this.seachProjectName = '';
        this.sfInstanceName = ApexPages.currentPage().getHeaders().get('Host'); //ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');
        system.debug('@@this.sfInstanceName' +this.sfInstanceName);
        this.myLightningHostname = DomainCreator.getLightningHostname();
    }
    
    public List<DimagiToolsController.PROProject> getProjectsForFinancialTab() {
        Time_Card__c lastTimeCard = [SELECT Id, CreatedDate FROM Time_Card__c ORDER BY CreatedDate DESC LIMIT 1];
        if (lastTimeCard != null) {
            this.lastFBSyncDate = Date.newInstance(lastTimeCard.CreatedDate.year(), lastTimeCard.CreatedDate.month(), lastTimeCard.CreatedDate.day());
        }
        
        List<DimagiToolsController.PROProject> proList = new List<DimagiToolsController.PROProject>();
        Set<Id> customContractsIdsToAddInList = new Set<Id>();
        this.excludeContractFromSearch.clear();
        
        for (PRO_Searched_Contract__c obj : [SELECT id,Contract__c FROM PRO_Searched_Contract__c WHERE Email__c =: this.employeeEmail]) {
            customContractsIdsToAddInList.add(obj.Contract__c);
        }
        
        this.childcontractMap = new Map<Id,List<DContract__c>>();
        this.contractMap = new Map<Id,DContract__c>([SELECT Id, Name, Requires_Developer_Work__c, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c,
                                                     Burdened_Income_Budget__c, Total_ID_Subcontract_Expense_Budgets__c, ID_Subcontract_1_Type__c, ID_Subcontract_Spend__c, Direct_Costs_Travel_BUDGET__c, Direct_Costs_Total_Expenses__c, Percent_through_Contract__c,
                                                     Product_Income_Budget__c, Services_Income__c, Product_Spend__c, Total_Amount_of_Contract__c, Direct_Costs_Sub_Contract_BUDGET__c,
                                                     Internal_Sub_contract_BUDGET__c, Project_Other_BUDGET__c, Direct_Costs_Travel_Expenses__c, Direct_Costs_Sub_contract_Expenses__c,
                                                     Internal_Sub_contract_Spend__c, Project_Other_Spent__c, Expected_Margin__c,Budget_Used__c, Margin_by_SOW_Completed__c,
                                                     Margin_by_Contract_Dates__c, Execution_Efficiency__c, Contract_Expense_BUDGET__c, ID_Subcontract_Expense_Spend__c,
                                                     (SELECT Id, Name, Requires_Developer_Work__c, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c,
                                                      Burdened_Income_Budget__c, Total_ID_Subcontract_Expense_Budgets__c,ID_Subcontract_1_Type__c, ID_Subcontract_Spend__c, Direct_Costs_Travel_BUDGET__c, Direct_Costs_Total_Expenses__c, Percent_through_Contract__c,
                                                      Product_Income_Budget__c, Services_Income__c, Product_Spend__c, Total_Amount_of_Contract__c, Direct_Costs_Sub_Contract_BUDGET__c,
                                                      Internal_Sub_contract_BUDGET__c, Project_Other_BUDGET__c, Direct_Costs_Travel_Expenses__c, Direct_Costs_Sub_contract_Expenses__c,
                                                      Internal_Sub_contract_Spend__c, Project_Other_Spent__c, Expected_Margin__c, Budget_Used__c ,Margin_by_SOW_Completed__c,
                                                      Margin_by_Contract_Dates__c, Execution_Efficiency__c, Contract_Expense_BUDGET__c,ID_Subcontract_Expense_Spend__c FROM Contracts__r)
                                                     FROM DContract__c
                                                     WHERE Id IN : customContractsIdsToAddInList OR
                                                     (In_Charge_Of_Report_Out__c='Project Manager' AND  Project_Manager__r.Email=:this.employeeEmail) OR
                                                     (In_Charge_Of_Report_Out__c='Field Manager' AND  Field_Manager__r.Email=:this.employeeEmail) OR
                                                     (In_Charge_Of_Report_Out__c='Backstop' AND  Backstop__r.Email=:this.employeeEmail)
                                                     ORDER BY Name]);
        
        for (DContract__c dc : this.contractMap.values()) {
            if (dc.Contracts__r.size() > 0) {
                this.childcontractMap.put(dc.Id,dc.Contracts__r);
            }
        }
        
        if (this.contractMap.values().size() > 0 && this.financialContractId == null) {
            this.financialContractId = this.contractMap.values()[0].id;
            loadContractBudgetAndSpentData();
        }
        
        for (DContract__c dc:this.contractMap.values()) {
            this.excludeContractFromSearch.add(dc.Id);
            DimagiToolsController.PROProject prObj = new DimagiToolsController.PROProject();
            prObj.Contract = dc;
            
            if (this.financialContractId != null && this.financialContractId != '') {
                prObj.cssClass = dc.id == this.financialContractId ? 'bgColorCls' : '';
            }
            
            if (customContractsIdsToAddInList.contains(dc.Id)) {
                prObj.customAdded = true;
            }
            proList.add(prObj);
        }
        
        return proList;
    }
    
    public void searchProject() {
        System.debug('this.seachProjectName: ' + this.seachProjectName);
        if (!this.seachProjectName.equals('')) {
            String soql = 'SELECT Id, Name, Last_Report_Out_Date__c FROM DContract__c WHERE (Requires_Report_Out__c = \'Yes\' OR Status__c = \'Active\') AND Id NOT IN :excludeContractFromSearch';
            soql += ' AND Name LIKE \'' + String.escapeSingleQuotes(this.seachProjectName) + '%\'';
            soql += ' LIMIT 20';
            System.debug('Final query: ' + soql);
            
            this.searchedProjects = Database.query(soql);
            
            if(this.searchedProjects.size() == 0) {
                this.searchError = 'No projects were found.';
            } else {
                this.searchError = '';
            }
        } else {
            this.searchedProjects.clear();
            this.searchError = '';
        }
    }
    
    public void addProjectToUserList() {
        if (!this.pageController.isTokenValid()) {
            return;
        }
        try {
            PRO_Searched_Contract__c proSearchCon = new PRO_Searched_Contract__c(Email__c = this.employeeEmail, Contract__c = this.contractToAdd);
            insert proSearchCon;
            
            for (Integer i=0; i < this.searchedProjects.size() ; i++) {
                if (this.searchedProjects[i].Id == this.contractToAdd) {
                    this.searchedProjects.remove(i);
                    break;
                }
            }
            
            getProjectsForFinancialTab();
            this.seachProjectName = '';
            this.contractToAdd = '';
            this.contractToRemove = '';
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error occurred while adding project'));
            System.debug('Error occured while adding project: '+ e.getMessage());
        }
    }
    
    public void removeProjectFromUserList() {
        if (!this.pageController.isTokenValid()) {
            return;
        }
        System.debug('this.contractToRemove: ' + this.contractToRemove);
        if (this.contractToRemove != '') {
            try { 
                delete [SELECT Id FROM PRO_Searched_Contract__c WHERE Email__c =: this.employeeEmail AND Contract__C =: this.contractToRemove];
                if (this.financialContractId == this.contractToRemove) {
                    this.financialContractId = null;
                }
                
                this.contractToRemove = '';
                getProjectsForFinancialTab();
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error occurred while deleting project'));
                System.debug('Error occurred while deleting project: ' + e.getMessage());
            }
        }
    }
    
    public void loadContractBudgetAndSpentData() {
        if (!this.pageController.isTokenValid()) {
            return;
        }
        
        this.proBudgetList = new List<DimagiToolsController.PROProjectBudget>();
        Map<Id, List<Time_Card__c>> contractIdTimeCardsMap = new Map<Id, List<Time_Card__c>>();
        if (this.contractMap.containsKey(this.financialContractId)) {
            this.contractUrl = 'https://' + this.myLightningHostname + '/' + this.financialContractId;
            Set<Id> parentAndChildContractIds = new Set<Id> {this.financialContractId};
                DContract__c contractObj = this.contractMap.get(this.financialContractId);
            List<DContract__c> childContracts = this.childcontractMap.containsKey(this.financialContractId) ? this.childcontractMap.get(this.financialContractId) : null;
            
            Decimal Burdened_Income_Budget = contractObj.Burdened_Income_Budget__c!= null ? contractObj.Burdened_Income_Budget__c : 0;
            Decimal LaborSpent = 0;
            Decimal Contract_Expense_BUDGET = contractObj.Contract_Expense_BUDGET__c != null ? contractObj.Contract_Expense_BUDGET__c: 0 ;
            Decimal Direct_Costs_Total_Expenses = contractObj.Direct_Costs_Total_Expenses__c != null ? contractObj.Direct_Costs_Total_Expenses__c: 0 ;
            Decimal Product_Income_Budget = contractObj.Product_Income_Budget__c != null ? contractObj.Product_Income_Budget__c: 0 ;
            Decimal Product_Spend = contractObj.Product_Spend__c != null ? contractObj.Product_Spend__c: 0 ;
            Decimal Total_Amount_of_Contract = contractObj.Total_Amount_of_Contract__c != null ? contractObj.Total_Amount_of_Contract__c: 0 ;
            Decimal Percent_through_Contract = contractObj.Percent_through_Contract__c != null ? contractObj.Percent_through_Contract__c: 0 ;
            Decimal Percent_through_SOW_deliverables = contractObj.Percent_through_SOW_deliverables__c != null ? contractObj.Percent_through_SOW_deliverables__c: 0 ;
            Decimal Expected_Margin = contractObj.Expected_Margin__c != null ? contractObj.Expected_Margin__c: 0 ;
            //SAL-36
            Decimal Total_ID_Subcontract_Expense_Budgets = contractObj.Total_ID_Subcontract_Expense_Budgets__c != null ? contractObj.Total_ID_Subcontract_Expense_Budgets__c : 0;
            Decimal ID_Subcontract_Spend = contractObj.ID_Subcontract_Spend__c != null ? contractObj.ID_Subcontract_Spend__c : 0 ;
            Decimal idSubcontractValue;            
            String subContractType = contractObj.ID_Subcontract_1_Type__c;
            /*if('LOE'.equals(subContractType)){                
                idSubcontractValue = 0;
            } else {*/
                idSubcontractValue = contractObj.ID_Subcontract_Expense_Spend__c != null ? contractObj.ID_Subcontract_Expense_Spend__c : 0 ;
            //}            
            
            if(childContracts != null && childContracts.size() > 0) {
                for(DContract__c childContract : childContracts) {
                    parentAndChildContractIds.add(childContract.Id);
                    Direct_Costs_Total_Expenses += childContract.Direct_Costs_Total_Expenses__c != null ? childContract.Direct_Costs_Total_Expenses__c: 0 ;
                }
            }
            
            for(Time_Card__c obj : [select Employee__r.Name,Date__c,Total__c,Time_Card_Rate_Cost__c,Client__c  from Time_Card__c where Client__c IN:parentAndChildContractIds]) {
                if(contractIdTimeCardsMap.containsKey(obj.Client__c)){
                    List<Time_Card__c> tempList = contractIdTimeCardsMap.get(obj.Client__c);
                    tempList.add(obj);
                    contractIdTimeCardsMap.put(obj.Client__c,tempList);
                }else{
                    contractIdTimeCardsMap.put(obj.Client__c,new List<Time_Card__c>{obj});
                }
            }
            
            for(Id contractId : parentAndChildContractIds) {
                List<Time_Card__c> timeEntries = contractIdTimeCardsMap.get(contractId);
                if(timeEntries != null && timeEntries.size() > 0) {
                    for(Time_Card__c obj : timeEntries) {
                        if(obj.Time_Card_Rate_Cost__c != null) {
                            LaborSpent += obj.Time_Card_Rate_Cost__c;
                        }
                    }
                }
            }
            
            Decimal a = Product_Income_Budget;
            Decimal b = Product_Spend;
            Decimal c = Total_ID_Subcontract_Expense_Budgets;
            DimagiToolsController.PROProjectBudget prbjObj1 = new DimagiToolsController.PROProjectBudget();
            prbjObj1.categoryName = 'Product';
            prbjObj1.contractamount = Integer.valueOf(Product_Income_Budget);
            prbjObj1.spentAmount = Integer.valueOf(Product_Spend);
            prbjObj1.amountRemaining = Integer.valueOf(Product_Income_Budget - Product_Spend);
            prbjObj1.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proBudgetList.add(prbjObj1);
            
            a = Burdened_Income_Budget;
            b = LaborSpent;
            DimagiToolsController.PROProjectBudget prbjObj2 = new DimagiToolsController.PROProjectBudget();
            prbjObj2.categoryName = 'Services & Labor';
            prbjObj2.contractamount = Integer.valueOf(Burdened_Income_Budget - Total_ID_Subcontract_Expense_Budgets);  //SAL-35
            prbjObj2.spentAmount = Integer.valueOf(LaborSpent);
            prbjObj2.amountRemaining = Integer.valueOf((Burdened_Income_Budget - Total_ID_Subcontract_Expense_Budgets) - LaborSpent);
            prbjObj2.prcntgUsed = a != 0 ? Math.round((b/(a-c)) * 100) : 0;
            this.proBudgetList.add(prbjObj2);
            
            a = Contract_Expense_BUDGET;
            b = Direct_Costs_Total_Expenses;
            DimagiToolsController.PROProjectBudget prbjObj3 = new DimagiToolsController.PROProjectBudget();
            prbjObj3.categoryName = 'Expense & Travel';
            prbjObj3.contractamount = Integer.valueOf(Contract_Expense_BUDGET);
            prbjObj3.spentAmount = Integer.valueOf(Direct_Costs_Total_Expenses);
            prbjObj3.amountRemaining = Integer.valueOf(Contract_Expense_BUDGET - Direct_Costs_Total_Expenses);
            prbjObj3.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proBudgetList.add(prbjObj3);
            
            a = Total_ID_Subcontract_Expense_Budgets;
            b = idSubcontractValue;
            DimagiToolsController.PROProjectBudget prbjObj4 = new DimagiToolsController.PROProjectBudget();
            prbjObj4.categoryName = 'Interdivision Expense';
            prbjObj4.contractamount = Integer.valueOf(Total_ID_Subcontract_Expense_Budgets);
            prbjObj4.spentAmount = Integer.valueOf(idSubcontractValue);
            prbjObj4.amountRemaining = Integer.valueOf(a-b);
            prbjObj4.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proBudgetList.add(prbjObj4);
            
            a = Total_Amount_of_Contract;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount+ prbjObj4.spentAmount;
            DimagiToolsController.PROProjectBudget prbjObj5 = new DimagiToolsController.PROProjectBudget();
            prbjObj5.categoryName = 'Total';
            prbjObj5.contractamount = Integer.valueOf(Total_Amount_of_Contract);
            prbjObj5.spentAmount = Integer.valueOf(b);
            prbjObj5.amountRemaining = Integer.valueOf(Total_Amount_of_Contract - b);
            prbjObj5.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proBudgetList.add(prbjObj5);
        }
        
        loadProjectexecutionStatusList();
        loadHistoryOfTimeSpend(contractIdTimeCardsMap);
        loadContractExpenseSpend();
    }
    
    public void loadContractExpenseSpend() {
        this.proExpenseSpendList = new List<DimagiToolsController.PROProjectBudget>();
        
        if( this.contractMap.containsKey(this.financialContractId) ){
            DContract__c contractObj = this.contractMap.get(this.financialContractId);
            List<DContract__c> childContracts = this.childcontractMap.containsKey(this.financialContractId) ? this.childcontractMap.get(this.financialContractId) : null;
            
            Decimal Direct_Costs_Travel_BUDGET = contractObj.Direct_Costs_Travel_BUDGET__c != null ? contractObj.Direct_Costs_Travel_BUDGET__c : 0 ;
            Decimal Direct_Costs_Sub_Contract_BUDGET = contractObj.Direct_Costs_Sub_Contract_BUDGET__c != null ? contractObj.Direct_Costs_Sub_Contract_BUDGET__c : 0 ;
            Decimal Internal_Sub_contract_BUDGET = contractObj.Internal_Sub_contract_BUDGET__c != null ? contractObj.Internal_Sub_contract_BUDGET__c : 0 ;
            Decimal Project_Other_BUDGET = contractObj.Project_Other_BUDGET__c != null ? contractObj.Project_Other_BUDGET__c : 0 ;
            
            Decimal Direct_Costs_Travel_Expenses = contractObj.Direct_Costs_Travel_Expenses__c != null ? contractObj.Direct_Costs_Travel_Expenses__c : 0 ;
            Decimal Direct_Costs_Sub_contract_Expenses = contractObj.Direct_Costs_Sub_contract_Expenses__c != null ? contractObj.Direct_Costs_Sub_contract_Expenses__c : 0 ;
            Decimal Internal_Sub_contract_Spend = contractObj.Internal_Sub_contract_Spend__c != null ? contractObj.Internal_Sub_contract_Spend__c : 0 ;
            Decimal Project_Other_Spent = contractObj.Project_Other_Spent__c != null ? contractObj.Project_Other_Spent__c : 0 ;
            
            Decimal Percent_through_SOW_deliverables = contractObj.Percent_through_SOW_deliverables__c != null ? contractObj.Percent_through_SOW_deliverables__c: 0 ;
            
            if(childContracts != null) {
                for(DContract__c childContract : childContracts) {
                    Direct_Costs_Travel_Expenses += childContract.Direct_Costs_Travel_Expenses__c != null ? childContract.Direct_Costs_Travel_Expenses__c : 0 ;
                    Direct_Costs_Sub_contract_Expenses += childContract.Direct_Costs_Sub_contract_Expenses__c != null ? childContract.Direct_Costs_Sub_contract_Expenses__c : 0 ;
                    Internal_Sub_contract_Spend += childContract.Internal_Sub_contract_Spend__c != null ? childContract.Internal_Sub_contract_Spend__c : 0 ;
                    Project_Other_Spent += childContract.Project_Other_Spent__c != null ? childContract.Project_Other_Spent__c : 0 ;
                    
                    Percent_through_SOW_deliverables += childContract.Percent_through_SOW_deliverables__c != null ? childContract.Percent_through_SOW_deliverables__c: 0 ;
                }
            }
            
            //SAL-37
            Decimal Total_ID_Subcontract_Expense_Budgets = contractObj.Total_ID_Subcontract_Expense_Budgets__c != null ? contractObj.Total_ID_Subcontract_Expense_Budgets__c : 0;
            Decimal ID_Subcontract_Spend = contractObj.ID_Subcontract_Spend__c != null ? contractObj.ID_Subcontract_Spend__c : 0 ;
            Decimal idSubcontractValue;            
            /*String subContractType = contractObj.ID_Subcontract_1_Type__c;
            if('LOE'.equals(subContractType)){                
                idSubcontractValue = 0;
            } else {*/
                idSubcontractValue = contractObj.ID_Subcontract_Expense_Spend__c != null ? contractObj.ID_Subcontract_Expense_Spend__c : 0 ;
           // } 
            
            Decimal a = Direct_Costs_Travel_BUDGET;
            Decimal b = Direct_Costs_Travel_Expenses;
            DimagiToolsController.PROProjectBudget prbjObj1 = new DimagiToolsController.PROProjectBudget();
            prbjObj1.categoryName = 'Expense Travel';
            prbjObj1.contractamount = Integer.valueOf( Direct_Costs_Travel_BUDGET );
            prbjObj1.spentAmount = Integer.valueOf( Direct_Costs_Travel_Expenses );
            prbjObj1.throughSOWDeliverable = Integer.valueOf( Direct_Costs_Travel_BUDGET - Direct_Costs_Travel_Expenses );
            prbjObj1.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj1);
            
            a = Direct_Costs_Sub_Contract_BUDGET;
            b = Direct_Costs_Sub_contract_Expenses;
            DimagiToolsController.PROProjectBudget prbjObj2 = new DimagiToolsController.PROProjectBudget();
            prbjObj2.categoryName = 'Expense External Subcontract';
            prbjObj2.contractamount = Integer.valueOf( Direct_Costs_Sub_Contract_BUDGET );
            prbjObj2.spentAmount = Integer.valueOf( Direct_Costs_Sub_contract_Expenses );
            prbjObj2.throughSOWDeliverable = Integer.valueOf( Direct_Costs_Sub_Contract_BUDGET - Direct_Costs_Sub_contract_Expenses );
            prbjObj2.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj2);
            
            a = Project_Other_BUDGET;
            b = Project_Other_Spent;//calculate manually
            DimagiToolsController.PROProjectBudget prbjObj3 = new DimagiToolsController.PROProjectBudget();
            prbjObj3.categoryName = 'Expense Other Direct Costs';
            prbjObj3.contractamount = Integer.valueOf( Project_Other_BUDGET );
            prbjObj3.spentAmount = Integer.valueOf( Project_Other_Spent );
            prbjObj3.throughSOWDeliverable = Integer.valueOf( Project_Other_BUDGET - Project_Other_Spent );
            prbjObj3.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj3);
            
            a = Internal_Sub_contract_BUDGET;
            b = Internal_Sub_contract_Spend;
            DimagiToolsController.PROProjectBudget prbjObj4 = new DimagiToolsController.PROProjectBudget();
            prbjObj4.categoryName = 'Expense Internal Subcontract';
            prbjObj4.contractamount = Integer.valueOf( Internal_Sub_contract_BUDGET );
            prbjObj4.spentAmount = Integer.valueOf( Internal_Sub_contract_Spend );
            prbjObj4.throughSOWDeliverable = Integer.valueOf( Internal_Sub_contract_BUDGET - Internal_Sub_contract_Spend );
            prbjObj4.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj4);
            
            a = Total_ID_Subcontract_Expense_Budgets;
            b = idSubcontractValue;
            DimagiToolsController.PROProjectBudget prbjObj7 = new DimagiToolsController.PROProjectBudget();
            prbjObj7.categoryName = 'Expense Interdivision Subcontract';
            prbjObj7.contractamount = Integer.valueOf(Total_ID_Subcontract_Expense_Budgets);
            prbjObj7.spentAmount = Integer.valueOf(idSubcontractValue);
            prbjObj7.throughSOWDeliverable = Integer.valueOf(Total_ID_Subcontract_Expense_Budgets - idSubcontractValue);
            prbjObj7.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj7);
            
            a = prbjObj1.contractamount + prbjObj2.contractamount + prbjObj3.contractamount;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount;
            DimagiToolsController.PROProjectBudget prbjObj5 = new DimagiToolsController.PROProjectBudget();
            prbjObj5.categoryName = 'Total Costs (not including Internal or Interdivisional subcontracts)';
            prbjObj5.contractamount = Integer.valueOf(a);
            prbjObj5.spentAmount = Integer.valueOf(b);
            prbjObj5.throughSOWDeliverable = Integer.valueOf( a - b );
            prbjObj5.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj5);
            
            a = prbjObj1.contractamount + prbjObj2.contractamount + prbjObj3.contractamount + prbjObj4.contractamount + prbjObj7.contractamount;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount + prbjObj4.spentAmount + prbjObj7.spentAmount;
            DimagiToolsController.PROProjectBudget prbjObj6 = new DimagiToolsController.PROProjectBudget();
            prbjObj6.categoryName = 'Total Costs (including Internal and Interdivisional subcontracts)';
            prbjObj6.contractamount = Integer.valueOf(a);
            prbjObj6.spentAmount = Integer.valueOf(b);
            prbjObj6.throughSOWDeliverable = Integer.valueOf( a - b );
            prbjObj6.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            this.proExpenseSpendList.add(prbjObj6);
        }
    }
    
    public void loadHistoryOfTimeSpend(Map<Id,List<Time_Card__c>> contractIdTimeCardsMap){
        DimagiToolsController.PROProjectTimeSpentHistory projTmSpntHstryObj;
        Map<String, DimagiToolsController.PROProjectTimeSpentHistory> laborWithHours = new Map<String, DimagiToolsController.PROProjectTimeSpentHistory>();
        
        Date currentDate = Date.today();
        Integer currentMonth = currentDate.month();
        Integer currentYear = currentDate.year();
        Integer oneMonthAgo = currentDate.addMonths(-1).month();
        Integer oneMonthAgoYear = currentDate.addMonths(-1).year();
        Integer twoMonthAgo = currentDate.addMonths(-2).month();
        Integer twoMonthAgoYear = currentDate.addMonths(-2).year();
        
        Integer threeMonthAgo = currentDate.addMonths(-3).month();
        Integer threeMonthAgoYear = currentDate.addMonths(-3).year();
        
        Date moreThanThreeMonthAgo = currentDate.addMonths(-3);
        
        Decimal currentMonthTotalhours = 0;
        Decimal firstMonthTotalhours = 0;
        Decimal secondMonthTotalhours = 0;
        Decimal thirdMonthTotalhours = 0;
        Decimal moreThanThreeMonthTotalhours = 0;
        Decimal totalHours = 0;
        Decimal totalCost = 0;
        
        this.timeSpendHistoryList = new List<DimagiToolsController.PROProjectTimeSpentHistory>();
        if( this.contractMap.containsKey(this.financialContractId) ){
            List<Time_Card__c> timeEntries = new List<Time_Card__c>();
            if(contractIdTimeCardsMap.containsKey(this.financialContractId)) {
                timeEntries.addAll(contractIdTimeCardsMap.get(this.financialContractId));
            }
            
            List<DContract__c> childContracts = this.childcontractMap.containsKey(this.financialContractId) ? this.childcontractMap.get(this.financialContractId) : null;
            
            if(childContracts != null) {
                for(DContract__c childContract : childContracts) {
                    if(contractIdTimeCardsMap.containsKey(childContract.Id))
                        timeEntries.addAll(contractIdTimeCardsMap.get(childContract.Id));
                }
            }
            
            if(timeEntries != null && timeEntries.size() > 0) {
                
                for(Time_Card__c  obj: timeEntries) {
                    String employeeName = obj.Employee__r.Name;
                    Date entryDate = obj.Date__c != null ? obj.Date__c : Date.today();
                    Integer entryDateMonth = obj.Date__c != null ? obj.Date__c.month() : 0;
                    Integer entryDateYear = obj.Date__c != null ? obj.Date__c.year() : 0;
                    Decimal totalHoursPerMonth = obj.Total__c != null ? obj.Total__c: 0;
                    Decimal laborCost = obj.Time_Card_Rate_Cost__c != null ? obj.Time_Card_Rate_Cost__c : 0;
                    
                    if (laborWithHours.containsKey(employeeName)) {
                        projTmSpntHstryObj = laborWithHours.get(employeeName);
                        projTmSpntHstryObj.laborCost += laborCost;
                    } else {
                        projTmSpntHstryObj = new DimagiToolsController.PROProjectTimeSpentHistory();
                        projTmSpntHstryObj.laborName = employeeName;
                        projTmSpntHstryObj.laborCost = laborCost;
                    }
                    
                    totalHours += totalHoursPerMonth;
                    totalCost += laborCost;
                    
                    if (entryDateMonth == currentMonth && entryDateYear == currentYear) {
                        projTmSpntHstryObj.currentMonthHours += totalHoursPerMonth;
                    } else if(entryDateMonth == oneMonthAgo && entryDateYear == oneMonthAgoYear ){
                        projTmSpntHstryObj.firstMonthHours += totalHoursPerMonth;
                    } else if(entryDateMonth == twoMonthAgo && entryDateYear == twoMonthAgoYear ) {
                        projTmSpntHstryObj.secondMonthHours += totalHoursPerMonth;
                    } else if(entryDateMonth == threeMonthAgo && entryDateYear == threeMonthAgoYear ) {
                        projTmSpntHstryObj.thirdMonthHours += totalHoursPerMonth;
                    } else if(entryDate < moreThanThreeMonthAgo) {
                        projTmSpntHstryObj.moreThanThreeMonthAgoHours += totalHoursPerMonth;
                    }
                    
                    projTmSpntHstryObj.totalHourstoDate = projTmSpntHstryObj.currentMonthHours + projTmSpntHstryObj.firstMonthHours + projTmSpntHstryObj.secondMonthHours + projTmSpntHstryObj.thirdMonthHours + projTmSpntHstryObj.moreThanThreeMonthAgoHours;
                    
                    laborWithHours.put(employeeName,projTmSpntHstryObj);
                }
                
                for (DimagiToolsController.PROProjectTimeSpentHistory obj :laborWithHours.values()) {
                    this.timeSpendHistoryList.add(obj);
                    currentMonthTotalhours += obj.currentMonthHours;
                    firstMonthTotalhours += obj.firstMonthHours;
                    secondMonthTotalhours += obj.secondMonthHours;
                    thirdMonthTotalhours += obj.thirdMonthHours;
                    moreThanThreeMonthTotalhours += obj.moreThanThreeMonthAgoHours;
                }
            }
        }
        
        this.timeSpendHistoryList.sort();
        
        projTmSpntHstryObj = new DimagiToolsController.PROProjectTimeSpentHistory();
        projTmSpntHstryObj.laborName = 'Total';
        projTmSpntHstryObj.currentMonthHours = currentMonthTotalhours;
        projTmSpntHstryObj.firstMonthHours = firstMonthTotalhours;
        projTmSpntHstryObj.secondMonthHours = secondMonthTotalhours;
        projTmSpntHstryObj.thirdMonthHours = thirdMonthTotalhours;
        projTmSpntHstryObj.moreThanThreeMonthAgoHours = moreThanThreeMonthTotalhours;
        projTmSpntHstryObj.totalHourstoDate = totalHours;
        projTmSpntHstryObj.laborCost = totalCost;
        this.timeSpendHistoryList.add(projTmSpntHstryObj);
    }
    
    public void loadProjectexecutionStatusList() {
        if(this.contractMap.containsKey(this.financialContractId)){
            DContract__c contractObj = this.contractMap.get(this.financialContractId);
            
            DimagiToolsController.ProjectExecutionStatus execStatus1 = new DimagiToolsController.ProjectExecutionStatus();
            execStatus1.FieldName = 'Execution Efficiency';
            execStatus1.FieldValue = Integer.valueOf(contractObj.Execution_Efficiency__c);
            
            DimagiToolsController.ProjectExecutionStatus execStatus2 = new DimagiToolsController.ProjectExecutionStatus();
            execStatus2.FieldName = '% Budget Used';
            execStatus2.FieldValue = Integer.valueOf(contractObj.Budget_Used__c);
            
            DimagiToolsController.ProjectExecutionStatus execStatus3 = new DimagiToolsController.ProjectExecutionStatus();
            execStatus3.FieldName = '% of Work Completed';
            execStatus3.FieldValue = Integer.valueOf(contractObj.Percent_through_SOW_deliverables__c);
            
            DimagiToolsController.ProjectExecutionStatus execStatus4 = new DimagiToolsController.ProjectExecutionStatus();
            execStatus4.FieldName = '% Time into Contract';
            execStatus4.FieldValue = Integer.valueOf(contractObj.Percent_through_Contract__c);
            
            this.executionStatusList = new List<DimagiToolsController.ProjectExecutionStatus> { execStatus1, execStatus2, execStatus3, execStatus4 };
                }
    }
}