/**
 * This class provides functionality to Dimagi Project Report Outs Site.
 *
 * @author Virginia Fernández
 * @modifiedBy Nick Nestle - nnestle@dimagi.com
 * @modifiedBy Pablo Vigil - pablo.vigil@roundfusion.com
 * @modifiedBy Mustafa Turab - mustafa.turab@gmail.com
 * @since 2014-05
 */
public with sharing class ProjectReportOutController{
    
    private String OAUTH_CALLBACK_URL='';
    private String clientId='';
    private String clientSecret='';
    private string domainName='';
    
    public String AUTH_URL = 'https://accounts.google.com/o/oauth2/auth';
    public String ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    
    private String sfInstanceName;
    public String contractUrl{get;set;}

    PROEmailContractSnoozeHelper snoozeHelper=new PROEmailContractSnoozeHelper();
    
    string currentLoginUser='';
    public string CurrentLoginEmail{
        get;set;
    }
    private Set<Id> excludeContractFromSearch = new Set<Id>();
    public Map<Id, DContract__C> contractIdName = new Map<Id, DContract__C> {};

    public String dateAlert {get; set;}
    public Project_Report_Out__c pro {get; set;}
    public DContract__c proTabContract {get; set;}
    public Decimal proTabContractPercntgethroughSOW {get; set;}
    public String contractId {get; set;}
    public Map<Id,DContract__c> contractMap{get;set;}
    public Map<Id,List<DContract__c>> childContractMap;
    public String contractId2 {get; set;}
    public String contractToAdd {get; set;}
    public String contractToRemove {get; set;}
    public String searchError{ get; set;}
    public Boolean showDevWork {get; set;}

    public Boolean isAuthenticated {get; set;}
    public String password {get; set;}
       
    public Project_Report_Out__c ProObj{get;set;}


   //public String oauth_code {get;set;}
    public string oauth_token {get;set;}
    public string LastProjectId{
        get;set;
    }
    public string ProjectId{
        get;set;
    }
    public string SelectedTab{
        get;set;
    }
    
    Map<string,integer> frequencyMap=new Map<string,integer>();
    public string seachProjectName{get;set;}
    public List<DContract__c> searchedProjects{get;set;}

    
    public ProjectReportOutController() {
           
            List<PRO_OAuth_Settings__c> googleSettings=PRO_OAuth_Settings__c.getALL().values();
            if(googleSettings!=null && googleSettings.size()>0){
                clientId=googleSettings[0].ClientID__c;
                clientSecret=googleSettings[0].ClientSecret__c;
                domainName=googleSettings[0].Domain_Name__c;
                OAUTH_CALLBACK_URL=googleSettings[0].Auth_Callback_URL__c;
            }
            
            List<PRO_Frequency_Settings__C> proSettings=PRO_Frequency_Settings__C.getAll().values();
            for(PRO_Frequency_Settings__C proSet : proSettings){
                frequencyMap.put(proSet.Name,Integer.valueOf(proSet.Frequency_In_Week__C));
            }
            
            if(ApexPages.currentPage().getParameters().get('state')!=null){
                ProjectId=ApexPages.currentPage().getParameters().get('state');
            }

            if(ProjectId!=null){
                 SelectedTab='projectTab';
            }
            else{
                SelectedTab='reportTab';
            }

        sfInstanceName = ApexPages.currentPage().getHeaders().get('X-Salesforce-Forwarded-To');

        searchedProjects = new List<DContract__c>();
        seachProjectName = '';
        isAuthenticated = false;
        showDevWork = false;
    }  
   

    // What to do initially.
    public void initAction() {
           
           oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
           String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
           string oauth_code = ApexPages.currentPage().getParameters().get('code');
           
           System.debug('Google Code: '+oauth_code);
           
           
           
           if(oauth_code!=null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
           }
           
           if(oauth_token!=null){
               string message=callForUserInfo(oauth_token);
               if(message!=''){
                   isAuthenticated =true;
                   
                   currentLoginUser=message;
               }
           }
    }
            
    public void loadProjectReport(){
        pro=new Project_Report_Out__c();

        proTabContract = contractIdName.get(contractid);
        proTabContractPercntgethroughSOW = contractIdName.get(contractid).Percent_through_SOW_deliverables__c != null ? Integer.valueOf(contractIdName.get(contractid).Percent_through_SOW_deliverables__c): Integer.valueOf(contractIdName.get(contractid).Percent_through_Contract__c);

        List<Project_Report_Out__c> prlist = new list<Project_Report_Out__c>(
            [select id ,PM_email__c,Cap_planning_GDoc__c,Key_Accomplishments_Last_Two_Weeks__c,
            Key_Next_Steps_next_2_weeks__c,Client_Facing__c,Requires_Developer_Work__c,Ability_to_meet_Schedule__c,
            Ability_to_stay_within_Scope__c,Current_System_Usage__c,Partner_Relationship__c,
            Issues_Questions_Notables__c,Resource_Planning__c,Contract__r.Requires_Developer_Work__c,
            Project_Dashboard__c from Project_Report_Out__c
            where Contract__c =: contractid order by lastmodifieddate desc limit 1]
        );
        
        pro.PM_email__c = CurrentLoginEmail;
        
        if(!prlist.isempty()){
            lastProjectId=prlist[0].id;
            
            pro.Report_Out_Date__c = system.today();
            pro.Key_Accomplishments_Last_Two_Weeks__c= prlist[0].Key_Accomplishments_Last_Two_Weeks__c;
            pro.Key_Next_Steps_next_2_weeks__c= prlist[0].Key_Next_Steps_next_2_weeks__c;
            pro.Issues_Questions_Notables__c = prlist[0].Issues_Questions_Notables__c;
            pro.Client_Facing__c = prlist[0].Client_Facing__c;
            pro.Requires_Developer_Work__c = prlist[0].Requires_Developer_Work__c;
            showDevWork = prlist[0].Contract__r.Requires_Developer_Work__c;
            pro.Project_Dashboard__c = prlist[0].Project_Dashboard__c;
            pro.Resource_Planning__c = '----';
            pro.Cap_planning_GDoc__c = prlist[0].Cap_planning_GDoc__c;
            ToMeetSchedule=prlist[0].Ability_to_meet_Schedule__c;
            StayWithinScope=prlist[0].Ability_to_stay_within_Scope__c;
            CurrentSystemUsage=prlist[0].Current_System_Usage__c;
            PartnerRelationship=prlist[0].Partner_Relationship__c;
        }
        else{
            DContract__c contractObj=[select id,Requires_Developer_Work__c from DContract__c 
            where Id=:contractid limit 1];
            
            lastProjectId=null;
            pro.Report_Out_Date__c = system.today();
            pro.Key_Accomplishments_Last_Two_Weeks__c= null;
            pro.Key_Next_Steps_next_2_weeks__c= null;
            pro.Issues_Questions_Notables__c = null;
            pro.Client_Facing__c = null;
            pro.Requires_Developer_Work__c = null;
            showDevWork = contractObj.Requires_Developer_Work__c;
            pro.Project_Dashboard__c = null;
            pro.Resource_Planning__c = '----';
            pro.Cap_planning_GDoc__c = null;
            ToMeetSchedule=null;
            StayWithinScope=null;
            CurrentSystemUsage=null;
            PartnerRelationship=null;
        
        }
        
    }
    
    Map<Id,List<Time_Card__c>> contractIdTimeCardsMap;
    public List<PROProject> getProjectList3(){
        List<PROProject> proList=new List<PROProject>();
        Set<Id> customContractsIdsToAddInList = new Set<Id>();
        excludeContractFromSearch.clear();

        for(PRO_Searched_Contract__c obj : [Select id,Contract__c from PRO_Searched_Contract__c where Email__c = :CurrentLoginEmail]){//change static email to 'CurrentLoginEmail'
            customContractsIdsToAddInList.add(obj.Contract__c);
        }
        childContractMap = new Map<Id,List<DContract__c>>();
        contractMap = new Map<Id,DContract__c>([SELECT Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c,
                                            Burdened_Income_Budget__c, Direct_Costs_Travel_BUDGET__c, Direct_Costs_Total_Expenses__c ,Percent_through_Contract__c,
                                            Product_Income_Budget__c, Services_Income__c,Product_Spend__c, Total_Amount_of_Contract__c,Direct_Costs_Sub_Contract_BUDGET__c,
                                            Internal_Sub_contract_BUDGET__c,Project_Other_BUDGET__c,Direct_Costs_Travel_Expenses__c,Direct_Costs_Sub_contract_Expenses__c,
                                            Internal_Sub_contract_Spend__c,Project_Other_Spent__c, Expected_Margin__c,Budget_Used__c ,Margin_by_SOW_Completed__c,
                                            Margin_by_Contract_Dates__c,Execution_Efficiency__c,Buffer_by_SOW_Completed__c,Contract_Expense_BUDGET__c, 
                                            (Select Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c,
                                            Burdened_Income_Budget__c, Direct_Costs_Travel_BUDGET__c, Direct_Costs_Total_Expenses__c ,Percent_through_Contract__c,
                                            Product_Income_Budget__c, Services_Income__c,Product_Spend__c, Total_Amount_of_Contract__c,Direct_Costs_Sub_Contract_BUDGET__c,
                                            Internal_Sub_contract_BUDGET__c,Project_Other_BUDGET__c,Direct_Costs_Travel_Expenses__c,Direct_Costs_Sub_contract_Expenses__c,
                                            Internal_Sub_contract_Spend__c,Project_Other_Spent__c, Expected_Margin__c,Budget_Used__c ,Margin_by_SOW_Completed__c,
                                            Margin_by_Contract_Dates__c,Execution_Efficiency__c,Buffer_by_SOW_Completed__c,Contract_Expense_BUDGET__c from Contracts__r)
                                           FROM DContract__c 
                                           //WHERE Name = 'USAID:CommCare for Ebola'
                                           //Where Id = 'a0Nb000000SqF30'
                                           WHERE Id IN : customContractsIdsToAddInList Or
                                                (In_Charge_Of_Report_Out__c='Project Manager' and  Project_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Field Manager' and  Field_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Backstop' and  Backstop__r.Email=:CurrentLoginEmail)
                                       ORDER BY Name]);

        if(contractMap.values().size()>0 && contractid2==null){
            contractid2 = contractMap.values()[0].id;
            loadContractBudgetAndSpentData();
        }

        for(DContract__c dc:contractMap.values()){
            //contractIdName.put(dc.Id, dc);
            
            excludeContractFromSearch.add(dc.Id);
            PROProject prObj=new PROProject();
            prObj.Contract=dc;
            if(contractid2!=null && contractid2!=''){
                prObj.cssClass=dc.id==contractid2?'bgColorCls':'';
            }
            if(customContractsIdsToAddInList.contains(dc.Id)) {
                prObj.customAdded = true;
            }
            proList.add(prObj);

            if(dc.Contracts__r.size() > 0) {
                childContractMap.put(dc.Id,dc.Contracts__r);
            }

        }
        return proList;
    }

    public List<PROProject> getProjectList2(){
        List<PROProject> proList=new List<PROProject>();

        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c,
                                    Percent_through_SOW_deliverables__c , Percent_through_Contract__c, Margin_by_Contract_Dates__c,
                                    Margin_by_SOW_Completed__c, Expected_Margin__c, Execution_Efficiency__c
                                           FROM DContract__c 
                                           WHERE Requires_Report_Out__c = 'Yes' and(
                                                (In_Charge_Of_Report_Out__c='Project Manager' and  Project_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Field Manager' and  Field_Manager__r.Email=:CurrentLoginEmail) or 
                                                (In_Charge_Of_Report_Out__c='Backstop' and  Backstop__r.Email=:CurrentLoginEmail) 
                                                or Owner.Email=:CurrentLoginEmail
                                            )
                                       ORDER BY Name];
                                       
        if(contracts.size()>0 && contractid==null){
            contractid= contracts[0].id;
            proTabContract = contracts[0];
            //proTabContractPercntgethroughSOW = Integer.valueOf(contracts[0].Percent_through_Contract__c);
            proTabContractPercntgethroughSOW = contracts[0].Percent_through_SOW_deliverables__c != null ? Integer.valueOf(contracts[0].Percent_through_SOW_deliverables__c): Integer.valueOf(contracts[0].Percent_through_Contract__c);
            for(DContract__c dc:contracts)
                contractIdName.put(dc.Id, dc);

            loadProjectReport();
        }

        for(DContract__c dc:contracts){
            PROProject prObj=new PROProject();
            prObj.Contract=dc;
            if(contractId!=null && contractId!=''){
                prObj.cssClass=dc.id==contractId?'bgColorCls':'';
            }
            proList.add(prObj);
        }
        return proList;
    }
    public List<PROProject> getAllProjectList1(){
        List<PROProject> proList=new List<PROProject>();
        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c,Last_Report_Out_Date__c,Last_Report_Out_Status__c,Percent_through_Contract__c,Percent_through_SOW_deliverables__c
                                           FROM DContract__c 
                                           WHERE Requires_Report_Out__c = 'Yes'
                                           ORDER BY Name];
        if(contracts.size()>0 && selectedProjectId==null){
            if(ProjectId!=null){
                selectedProjectId=ProjectId;
            }
            else{
                selectedProjectId= contracts[0].id;
            }
            FillProjectDetails();
        }
        for(DContract__c dc:contracts){
            PROProject prObj=new PROProject();
            prObj.Contract=dc;
            if(selectedProjectId!=null && selectedProjectId!=''){
                prObj.cssClass=dc.id==selectedProjectId?'bgColorCls':'';
            }
            proList.add(prObj);
        }
        return proList;                                  
    }
    
    /**
     * Checks if the date entered is the second or fourth thursday.
     * @return True if the date format it's right, false otherwise.
     */
    public boolean validData() {
        // Check if user has selected one project.
        if (contractId == null || contractId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        if (status== null || status== '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Status cannot be blank'));
            return false;
        }
        
        if (pro.PM_email__c == null || pro.PM_email__c == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Email cannot be blank'));
            return false;
        }
        if (pro.Report_Out_Date__c == null ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Report out Date cannot be blank'));
            return false;
        }
        if (proTabContractPercntgethroughSOW == null ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, '% Deliverables Completed'));
            return false;
        }
        return true;
        /*else{ 
            DContract__C contract=contractIdName.get(contractId);
            string lastStatus=contract.Last_Report_Out_Status__c;
            
            integer noOfWeeks=frequencyMap.get(lastStatus);
            
            //For New Project Last PRO Status is null then we set 2 weeks;
            if(noOfWeeks==null){
                noOfWeeks=2;
            }
            List<Date> thudayList=PROHelper.GetAllThursDayOfMonth(pro.Report_Out_Date__c.Year(),pro.Report_Out_Date__c.Month());
            
            if(noOfWeeks==4){
                 if(thudayList[3]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the fourth Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==3){
                 if(thudayList[2]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the third Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==2){
                 if(thudayList[1]==pro.Report_Out_Date__c || thudayList[3]==pro.Report_Out_Date__c){
                     return true;
                 }
                 else{
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the second or forth Thursday of the month.'));
                     return false;
                 }
            }
            else if(noOfWeeks==1){
                 for(Date dt : thudayList){
                     if(dt==pro.Report_Out_Date__c){
                         return true;
                     }
                 }
                 
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the Thursday of the month.'));
                 return false;
            }
           return false;
        }*/
    }

    // Alert that the day is wrong.
    private void alertInvalidDate() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the second or fourth Thursday of the month.'));
    }

    // What to do when submit is clicked.
    public PageReference save() {
        PageReference page = null;

        // Check all required fields are set, otherwise returns an error message.
        if (validData()) {
            List<Project_Report_Out__c> proList = new list<Project_Report_Out__c>([SELECT Id, Name, Last_Report_ID__C, Contract_Snapshot__c, Contract__c,
                                                                                    Status__c, Ability_to_meet_Schedule__c, Ability_to_stay_within_Scope__c,
                                                                                    Current_System_Usage__c, Partner_Relationship__c, User_Name__C,
                                                                                    Key_Accomplishments_Last_Two_Weeks__c, Key_Next_Steps_next_2_weeks__c,
                                                                                    Issues_Questions_Notables__c, Client_Facing__c, Requires_Developer_Work__c,
                                                                                    Project_Dashboard__c, Resource_Planning__c, Cap_planning_GDoc__c, PM_email__c
                                                                                    FROM Project_Report_Out__c
                                                                                    WHERE Contract__c =: contractid AND Report_Out_Date__c =: pro.Report_Out_Date__c LIMIT 1]);

            Project_Report_Out__c proToUpdate = createPROToUpdate(proList.isEmpty() ? null : proList[0]);
            DContract__c dcontract = [SELECT Id, Name, Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c, Budget_Used__c, of_Services_budget_for_GS__c, Total_Costs__c, Services_Spend__c,
                                        Buffer_by_SOW_Completed__c, Execution_Efficiency__c, Expected_Buffer__c, Direct_Costs_Total_Expenses__c, Net_Income_based_on_SOW_Completed__c, Product_Spend__c
                                        FROM DContract__c WHERE Id =: contractId];

            dcontract.Last_Report_Out_Status__c = status;
            dcontract.Percent_through_SOW_deliverables__c = proTabContractPercntgethroughSOW;

            PRO_Contract_Snapshot__c proContractSnapshot = createProSnapshot(proToUpdate.Contract_Snapshot__c == null ? null : proList[0].Contract_Snapshot__c, dcontract);

            try {
                snoozeHelper.ResetEmailRemindar(contractId);
                upsert proContractSnapshot Id;
                proToUpdate.Contract_Snapshot__c = proContractSnapshot.Id;
                upsert proToUpdate Id;
                update dcontract;
                SendEmail(proToUpdate.id);
                page = new PageReference('/apex/ProjectReportOutSubmitted?id='+proToUpdate.id);
            } catch(DmlException ex) {
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getDmlMessage(0)));
            } catch (Exception e) {
                System.debug(e);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'There was an error trying to save. Please try again.'));
                //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
            }
        }

        return page;
    }

    private Project_Report_Out__c createPROToUpdate(Project_Report_Out__c currentPRO) {
        pro.Contract__c = contractId;
        if (currentPRO != null) { // we must update PRO
            currentPRO.Name = contractIdName.get(pro.Contract__c).Name + ' - [' + pro.Report_Out_Date__c.format() + ']';
            currentPRO.Status__c = status;
            currentPRO.Ability_to_meet_Schedule__c = ToMeetSchedule;
            currentPRO.Ability_to_stay_within_Scope__c = StayWithinScope;
            currentPRO.Current_System_Usage__c = CurrentSystemUsage;
            currentPRO.Partner_Relationship__c = PartnerRelationship;
            currentPRO.User_Name__C = currentLoginUser;
            currentPRO.Report_Out_Date__c = pro.Report_Out_Date__c;
            currentPRO.Key_Accomplishments_Last_Two_Weeks__c = pro.Key_Accomplishments_Last_Two_Weeks__c;
            currentPRO.Key_Next_Steps_next_2_weeks__c = pro.Key_Next_Steps_next_2_weeks__c;
            currentPRO.Issues_Questions_Notables__c = pro.Issues_Questions_Notables__c;
            currentPRO.Client_Facing__c = pro.Client_Facing__c;
            currentPRO.Requires_Developer_Work__c = pro.Requires_Developer_Work__c;
            currentPRO.Project_Dashboard__c = pro.Project_Dashboard__c;
            currentPRO.Resource_Planning__c = pro.Resource_Planning__c;
            currentPRO.Cap_planning_GDoc__c = pro.Cap_planning_GDoc__c;
            currentPRO.PM_email__c = pro.PM_email__c;

            return currentPRO;
        } else {
            pro.Last_Report_ID__C = lastProjectId;
            pro.Name = contractIdName.get(pro.Contract__c).Name + ' - [' + pro.Report_Out_Date__c.format() + ']';
            pro.Status__c = status;
            pro.Ability_to_meet_Schedule__c = ToMeetSchedule;
            pro.Ability_to_stay_within_Scope__c = StayWithinScope;
            pro.Current_System_Usage__c = CurrentSystemUsage;
            pro.Partner_Relationship__c = PartnerRelationship;
            pro.User_Name__C = currentLoginUser;

            return pro;
        }
    }

    private PRO_Contract_Snapshot__c createProSnapshot(Id currentSnapshot, DContract__c dcontract) {
        PRO_Contract_Snapshot__c proContractSnapshot = new PRO_Contract_Snapshot__c();
        if (currentSnapshot != null) { // we must update snapshot
            proContractSnapshot = [SELECT Id, Budget_Used__c, Percent_Of_Work_Completed__c, Percent_Services_Budget_For_GS__c, Buffer_By_Deliverables_Complete__c,
                                        Execution_Efficiency__c, Expected_Buffer__c, Expense_And_Travel_Spend__c, Net_Income_By_Deliverables_Complete__c, Product_Spend__c,
                                        Services_Spend__c, Total_Calculated_Costs__c, Contract__c, Name, Snapshot_Date__c
                                        FROM PRO_Contract_Snapshot__c WHERE Id =: currentSnapshot];
        }

        proContractSnapshot.Budget_Used__c = dcontract.Budget_Used__c;
        proContractSnapshot.Percent_Of_Work_Completed__c = dcontract.Percent_through_SOW_deliverables__c;
        proContractSnapshot.Percent_Services_Budget_For_GS__c = dcontract.of_Services_budget_for_GS__c;
        proContractSnapshot.Buffer_By_Deliverables_Complete__c = dcontract.Buffer_by_SOW_Completed__c;
        proContractSnapshot.Execution_Efficiency__c = dcontract.Execution_Efficiency__c;
        proContractSnapshot.Expected_Buffer__c = dcontract.Expected_Buffer__c;
        proContractSnapshot.Expense_And_Travel_Spend__c = dcontract.Direct_Costs_Total_Expenses__c;
        proContractSnapshot.Net_Income_By_Deliverables_Complete__c = dcontract.Net_Income_based_on_SOW_Completed__c;
        proContractSnapshot.Product_Spend__c = dcontract.Product_Spend__c;
        proContractSnapshot.Services_Spend__c = dcontract.Services_Spend__c;
        proContractSnapshot.Total_Calculated_Costs__c = dcontract.Total_Costs__c;
        proContractSnapshot.Contract__c = dcontract.Id;
        proContractSnapshot.Name = dcontract.Name;
        proContractSnapshot.Snapshot_Date__c = Date.today();

        return proContractSnapshot;
    }

    public PageReference submitAnother() {
        pro = new Project_Report_Out__c();
        DeleteContactList.clear();
        loadProjectReport();

        PageReference newPage = new PageReference('/apex/ProjectReportOut');
        newPage.getParameters().put('oauth_token',oauth_token);
        newPage.setRedirect(true);

        return newPage ;
    }

    public void getPRO() {
        String PROId = ApexPages.currentPage().getParameters().get('id');
        if(PROId != null) {
            ProObj = [Select id,Name,Resource_Planning__c,Status__c,
                        Ability_to_meet_Schedule__c,Ability_to_stay_within_Scope__c,
                        Current_System_Usage__c,Partner_Relationship__c,
                        Key_Accomplishments_Last_Two_Weeks__c,
                        Key_Next_Steps_next_2_weeks__c,Issues_Questions_Notables__c,
                        Client_Facing__c,Requires_Developer_Work__c,Project_Dashboard__c
                    FROM
                        Project_Report_Out__c
                    WHERE 
                        Id = :PROId];
        }
    }
    
    
    public PageReference authenticateButton() {
        Misc_Settings__c settings = Misc_Settings__c.getOrgDefaults();
        if (password == settings.Project_Report_Out_Password__c) {
            isAuthenticated =true;
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Wrong password.'));
        }
        return null;
    }

    public PageReference authenticate() {
           PageReference authPage=null;

            oauth_token = ApexPages.currentPage().getParameters().get('oauth_token');
            String oauth_verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            string oauth_code = ApexPages.currentPage().getParameters().get('code');
    
            if (oauth_code != null){
               oauth_token=getFromJSON(getAuthorizedReqToken(oauth_code),'access_token');
               
               string message=callForUserInfo(oauth_token);
               System.debug('message: '+message);
               if(message!=''){
                   isAuthenticated =true;
                   currentLoginUser=message;
               }
            }
            else{
                 
                 String authURL = getUnauthorizedReqToken();
                 authPage=new PageReference(authURL);
                 authPage.setRedirect(false);
                 
            }
            return authPage;
        
    }
   
     // Get a list of picklist values from an existing object field.
    private List<SelectOption> getPicklistValues(SObject obj, String fieldName) {
      List<SelectOption> options = new list<SelectOption>();
      Schema.sObjectType objType = obj.getSObjectType(); 
      // Describe the SObject using its object type.
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
      // Get a map of fields for the SObject
      map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
      // Get the list of picklist values for this field.
      list<Schema.PicklistEntry> values =fieldMap.get(fieldName).getDescribe().getPickListValues();
      // Add these values to the selectoption list.
      
      for (Schema.PicklistEntry a : values)
      { 
         options.add(new SelectOption(a.getValue(),'')); 
      }
      options.add(new SelectOption('N/A',''));
      return options;
    }

    public List<selectoption> StatusList{
           get{
              return getPicklistValues(new Project_Report_Out__c(),'Status__c');
           }
           set;
    }
    public string status{
        get;set;
    }
    public string ToMeetSchedule{
         get;set;
    }
    public string StayWithinScope{
         get;set;
    }
    public string CurrentSystemUsage{
         get;set;
    }
    /*public string CustomReportsDevelopment{
        get;set;
    }*/
    public string PartnerRelationship{
        get;set;
    }
    
     public String getUnauthorizedReqToken(){
         
          String vf_url=this.OAUTH_CALLBACK_URL;
          String state = projectId; //Random String
          String body='client_id='+this.clientId+'&redirect_uri='+this.OAUTH_CALLBACK_URL+'&state='+state;
         
          String retUrl=this.AUTH_URL+'?'+body+'&response_type=code&scope=profile+email';
          
          if(domainName!='gmail.com'){
              retUrl=retUrl+'&hd='+domainName;
          }
          
          return retUrl;
    }
    public static String getRandomNonce(){
           String allChars='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
           String nonce='';
           for(integer cnt=0; cnt<=9;cnt++)   {
               Integer i = 1+Math.Round(700.0*Math.random()/26);
               if (i<=26)
               {
                  i--;
                  String newStr=allChars.substring(i,i+1);
                  nonce=nonce+newStr;
              }else{
                cnt--;
              }
          }
          return nonce;
    }
    
    public String getAuthorizedReqToken(String code){
         
            String body='client_id='+this.clientId+'&redirect_uri='+this.OAUTH_CALLBACK_URL+'&client_secret='+this.clientSecret+'&code='+code+'&grant_type=authorization_code';
             
            String tokenResponse = basicAuthCallout(this.ACCESS_TOKEN_URL,'',body,'POST');
             
            System.debug('=========================== RESPONSE:'+tokenResponse);
             
            String authReqToken = tokenResponse;
            return authReqToken;
    }

    public string callForUserInfo(string token){
        string userInfoURL='https://www.googleapis.com/oauth2/v1/userinfo?access_token='+token;
        string responseJSON=basicAuthCallout(userInfoURL,'','','GET');
        string response=getFromJSON(responseJSON,'name');
        
        CurrentLoginEmail=getFromJSON(responseJSON,'email');
        
        return response;
    }
    
    public String basicAuthCallout(String endPoint,String header, String body,String method){
            HttpRequest req = new HttpRequest();
          
            req.setEndpoint(endPoint);
            req.setMethod(method);
            if(method=='POST'){
                 req.setBody(body);
            }
            Http http = new Http();
            System.debug('=========== REQ BODY:'+endPoint);
            HTTPResponse res = http.send(req);
            return res.getBody();
    }

    public string getFromJSON(string response,string fieldName){
        JSONParser parser = JSON.createParser(response);
        
        string accessToken='';
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == fieldName)) {
                parser.nextToken();
                accessToken= parser.getText();
            }
        }
        return accessToken;
     }
     
    public List<Project_Report_Out__c> PastReportOuts{
         get{
              List<Project_Report_Out__c> lastReportOuts=[select id,status__c,Contract__r.Name,Contract__r.Last_Report_Out_Date__c from Project_Report_Out__c 
              where PM_email__c=:CurrentLoginEmail order by Contract__r.Name,Contract__r.Last_Report_Out_Date__c desc ];
              return lastReportOuts;
         }
         set;
     }
     
    public string selectedProjectId{get;set;}
    public string selectedProjectId2{get;set;}
    public string InChangeOfReportOut{get;set;}
    public string ProjectManager{get;set;}
    public string FieldManager{get;set;}
    public string Backstop{get;set;}
    public DContract__c Project{
        get;set;
    }
    public boolean EnableAddButton{
        get;set;
    }
     
    //When project is changed this method is called.
    public void FillProjectDetails(){
        DeleteContactList.clear();
        ContractContacts=new List<Contract_Contact__c>();

        List<DContract__c> contractList=[select id,Project_Manager__c,Backstop__c,Field_Manager__c,In_Charge_Of_Report_Out__c from DContract__c 
        where Id=:selectedProjectId];
        if(contractList!=null && contractList.size()>0){
            Project=contractList[0];
        }
        ContractContactsProject=[select id,Contact__C,Contract__C,Type__C,Email__C from Contract_Contact__c where Contract__C=:selectedProjectId and Type__C not in('Person','Email')];

        ContractContacts=[select id,Contact__C,Contract__C,Type__C,Email__C  from Contract_Contact__c where Contract__C=:selectedProjectId and Type__C in('Person','Email') order by Type__C desc];

        //Fill Last Report outs of project   
        LastRepotOuts=[select id,Name,status__c,Contract__r.Name,Contract__r.Last_Report_Out_Date__c,Report_Out_Date__c  from Project_Report_Out__c 
        where Contract__C=:selectedProjectId order by Report_Out_Date__c desc ];
        EnableAddButton=true;
    }
    public List<Project_Report_Out__c> LastRepotOuts{
        get;set;
    }

    public List<PROProjectBudget> proBudgetList{
         get;set;
     }
    public void loadContractBudgetAndSpentData() {
        proBudgetList = new List<PROProjectBudget>();

        if( contractMap.containsKey(contractid2) ){
            contractUrl = 'https://'+sfInstanceName+'/'+contractid2;
            Set<Id> parentAndChildContractIds = new Set<Id>{contractid2};
            DContract__c contractObj = contractMap.get(contractid2);
            List<DContract__c> childContracts = childContractMap.containsKey(contractid2) ? childContractMap.get(contractid2) : null;
            contractIdTimeCardsMap = new Map<Id,List<Time_Card__c>>();

            Decimal Burdened_Income_Budget = contractObj.Burdened_Income_Budget__c!= null ? contractObj.Burdened_Income_Budget__c : 0;
            //Decimal Services_Income = contractObj.Services_Income__c != null ? contractObj.Services_Income__c: 0 ;
            Decimal LaborSpent = 0;
            Decimal Contract_Expense_BUDGET = contractObj.Contract_Expense_BUDGET__c != null ? contractObj.Contract_Expense_BUDGET__c: 0 ;
            Decimal Direct_Costs_Total_Expenses = contractObj.Direct_Costs_Total_Expenses__c != null ? contractObj.Direct_Costs_Total_Expenses__c: 0 ;
            Decimal Product_Income_Budget = contractObj.Product_Income_Budget__c != null ? contractObj.Product_Income_Budget__c: 0 ;
            Decimal Product_Spend = contractObj.Product_Spend__c != null ? contractObj.Product_Spend__c: 0 ;
            Decimal Total_Amount_of_Contract = contractObj.Total_Amount_of_Contract__c != null ? contractObj.Total_Amount_of_Contract__c: 0 ;
            Decimal Percent_through_Contract = contractObj.Percent_through_Contract__c != null ? contractObj.Percent_through_Contract__c: 0 ;
            Decimal Percent_through_SOW_deliverables = contractObj.Percent_through_SOW_deliverables__c != null ? contractObj.Percent_through_SOW_deliverables__c: 0 ;
            Decimal Expected_Margin = contractObj.Expected_Margin__c != null ? contractObj.Expected_Margin__c: 0 ;

            if(childContracts != null && childContracts.size() > 0) {
                for(DContract__c childContract : childContracts) {
                    parentAndChildContractIds.add(childContract.Id);
                    /*Contract_Expense_BUDGET += childContract.Contract_Expense_BUDGET__c != null ? childContract.Contract_Expense_BUDGET__c: 0 ;
                    Direct_Costs_Total_Expenses += childContract.Direct_Costs_Total_Expenses__c != null ? contractObj.Direct_Costs_Total_Expenses__c: 0 ;
                    Product_Income_Budget += childContract.Product_Income_Budget__c != null ? childContract.Product_Income_Budget__c: 0 ;
                    Product_Spend += childContract.Product_Spend__c != null ? childContract.Product_Spend__c: 0 ;
                    Total_Amount_of_Contract += childContract.Total_Amount_of_Contract__c != null ? childContract.Total_Amount_of_Contract__c: 0 ;
                    Percent_through_Contract += childContract.Percent_through_Contract__c != null ? childContract.Percent_through_Contract__c: 0 ;
                    Percent_through_SOW_deliverables += childContract.Percent_through_SOW_deliverables__c != null ? childContract.Percent_through_SOW_deliverables__c: 0 ;
                    Expected_Margin += childContract.Expected_Margin__c != null ? childContract.Expected_Margin__c: 0 ;*/
                }
            }
            
            //List<Time_Card__c> timeEntries = contractMap.get(contractid2).Time_Cards__r;
            
            for(Time_Card__c obj : [select Employee__r.Name,Date__c,Total__c,labor_cost__c,Client__c  from Time_Card__c where Client__c IN:parentAndChildContractIds]) {
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
                        if(obj.labor_cost__c != null) {
                            LaborSpent += obj.labor_cost__c;
                        }

                    }
                }
            }


            Decimal a = Product_Income_Budget;
            Decimal b = Product_Spend;
            PROProjectBudget prbjObj1 = new PROProjectBudget();
            prbjObj1.categoryName = 'Product';
            prbjObj1.contractamount = Integer.valueOf( Product_Income_Budget );
            prbjObj1.spentAmount = Integer.valueOf( Product_Spend );
            prbjObj1.amountRemaining = Integer.valueOf( Product_Income_Budget - Product_Spend );
            prbjObj1.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proBudgetList.add(prbjObj1);

            a = Burdened_Income_Budget;
            b = LaborSpent;
            PROProjectBudget prbjObj2 = new PROProjectBudget();
            prbjObj2.categoryName = 'Services & Labor';
            prbjObj2.contractamount = Integer.valueOf( Burdened_Income_Budget );
            prbjObj2.spentAmount = Integer.valueOf( LaborSpent );
            prbjObj2.amountRemaining = Integer.valueOf( Burdened_Income_Budget - LaborSpent );
            prbjObj2.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proBudgetList.add(prbjObj2);

            a = Contract_Expense_BUDGET;
            b = Direct_Costs_Total_Expenses;
            PROProjectBudget prbjObj3 = new PROProjectBudget();
            prbjObj3.categoryName = 'Expense & Travel';
            prbjObj3.contractamount = Integer.valueOf( Contract_Expense_BUDGET );
            prbjObj3.spentAmount = Integer.valueOf( Direct_Costs_Total_Expenses );
            prbjObj3.amountRemaining = Integer.valueOf( Contract_Expense_BUDGET - Direct_Costs_Total_Expenses );
            prbjObj3.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proBudgetList.add(prbjObj3);

            a = Total_Amount_of_Contract;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount;//calculate manually
            PROProjectBudget prbjObj4 = new PROProjectBudget();
            prbjObj4.categoryName = 'Total';
            prbjObj4.contractamount = Integer.valueOf( Total_Amount_of_Contract );
            prbjObj4.spentAmount = Integer.valueOf( b );
            prbjObj4.amountRemaining = Integer.valueOf( Total_Amount_of_Contract - b);
            prbjObj4.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proBudgetList.add(prbjObj4);

        }
        loadProjectExecutionStatusList();
        loadHistoryOfTimeSpend();
        loadContractExpenseSpend();
    }

    public List<ProjectExecutionStatus> executionStatusList{
        get;set;
    }

    public void loadProjectExecutionStatusList() { 
        if( contractMap.containsKey(contractid2) ){
            DContract__c contractObj = contractMap.get(contractid2);
            //List<DContract__c> childContracts = childContractMap.containsKey(contractid2) ? childContractMap.get(contractid2) : null;

            ProjectExecutionStatus execStatus1 = new ProjectExecutionStatus();
            execStatus1.FieldName = 'Execution Efficiency';
            execStatus1.FieldValue = Integer.valueOf(contractObj.Execution_Efficiency__c);
            
            ProjectExecutionStatus execStatus2 = new ProjectExecutionStatus();
            execStatus2.FieldName = '% Budget Used';
            execStatus2.FieldValue = Integer.valueOf(contractObj.Budget_Used__c);

            ProjectExecutionStatus execStatus3 = new ProjectExecutionStatus();
            execStatus3.FieldName = '% of Work Completed';
            execStatus3.FieldValue = Integer.valueOf(contractObj.Percent_through_SOW_deliverables__c);

            ProjectExecutionStatus execStatus4 = new ProjectExecutionStatus();
            execStatus4.FieldName = '% Time into Contract';
            execStatus4.FieldValue = Integer.valueOf(contractObj.Percent_through_Contract__c);

            ProjectExecutionStatus execStatus5 = new ProjectExecutionStatus();
            execStatus5.FieldName = 'Buffer % by Work Completed';
            execStatus5.FieldValue = Integer.valueOf(contractObj.Buffer_by_SOW_Completed__c);
                        
            /*if(childContracts != null) {
                for(DContract__c childContract : childContracts) {
                    execStatus1.FieldValue += Integer.valueOf(childContract.Execution_Efficiency__c);
                    execStatus2.FieldValue += Integer.valueOf(childContract.Budget_Used__c);
                    execStatus3.FieldValue += Integer.valueOf(childContract.Percent_through_SOW_deliverables__c);
                    execStatus4.FieldValue += Integer.valueOf(childContract.Percent_through_Contract__c);
                    execStatus5.FieldValue += Integer.valueOf(childContract.Buffer_by_SOW_Completed__c);
                }
            }*/
            executionStatusList = new List<ProjectExecutionStatus>{execStatus1, execStatus2, execStatus3, execStatus4, execStatus5};
            
        }
    }
    
    
    /*public List<PROProjectTimeSpent> timeSpendList{
        get;set;
    }

    public void loadTimeSpendOnProject() { 
        timeSpendList = new List<PROProjectTimeSpent>();
        Map<String,PROProjectTimeSpent> laborSpentTime = new Map<String,PROProjectTimeSpent>();
        PROProjectTimeSpent prtmspObj;
        Integer totalHours = 0;
        Integer totalCost = 0;
        if( contractMap.containsKey(contractid2) ){
            //List<Time_Card__c> timeEntries = contractMap.get(contractid2).Time_Cards__r;
            List<Time_Card__c> timeEntries = contractIdTimeCardsMap.get(contractid2);
            if(timeEntries != null && timeEntries.size() > 0) {

                for(Time_Card__c  obj: timeEntries) {
                    Integer laborHours = obj.Total__c != null ? Integer.valueOf(obj.Total__c) : 0;
                    Integer laborCost = obj.labor_cost__c != null ? Integer.valueOf(obj.labor_cost__c) : 0;

                    totalHours += laborHours;
                    totalCost += laborCost;

                    if(laborSpentTime.containsKey(obj.Employee__r.Name)){
                        System.debug('if: obj.Employee__r.Name: '+obj.Employee__r.Name);
                        prtmspObj = laborSpentTime.get(obj.Employee__r.Name);
                        prtmspObj.laborName = obj.Employee__r.Name;
                        prtmspObj.laborHours += laborHours;
                        prtmspObj.laborCost += laborCost;

                    }else{
                        System.debug('else: obj.Employee__r.Name: '+obj.Employee__r.Name);
                        prtmspObj = new PROProjectTimeSpent();
                        prtmspObj.laborName = obj.Employee__r.Name;
                        prtmspObj.laborHours = laborHours;
                        prtmspObj.laborCost = laborCost;
                    }
                    laborSpentTime.put(obj.Employee__r.Name,prtmspObj);
                }
                system.debug('laborSpentTime: '+laborSpentTime);

                for(PROProjectTimeSpent obj : laborSpentTime.values()){
                    timeSpendList.add(obj);
                }
            }

        }
        timeSpendList.sort();

        prtmspObj = new PROProjectTimeSpent();
        prtmspObj.laborName = 'Total';
        prtmspObj.laborHours = totalHours;
        prtmspObj.laborCost = totalCost;
        timeSpendList.add(prtmspObj);
    }*/

    public List<PROProjectTimeSpentHistory> timeSpendHistoryList{
        get;set;
    }

    public void loadHistoryOfTimeSpend(){
        PROProjectTimeSpentHistory projTmSpntHstryObj;
        Map<String,PROProjectTimeSpentHistory> laborWithHours = new Map<String,PROProjectTimeSpentHistory>();

        /*Date todayDate = Date.today();
        Date oneMonthAgo = Date.today().addMonths(-1);
        Date twoMonthAgo = Date.today().addMonths(-2);
        Date threeMonthAgo = Date.today().addMonths(-3);
        Date fourMonthAgo = Date.today().addMonths(-4);
        Date fiveMonthAgo = Date.today().addMonths(-5);
        Date sixMonthAgo = Date.today().addMonths(-6);
        */
        
        Date currentDate = Date.today();


        Integer currentMonth = currentDate.month();
        Integer currentYear = currentDate.year();
        
        Integer oneMonthAgo = currentDate.addMonths(-1).month();
        Integer oneMonthAgoYear = currentDate.addMonths(-1).year();

        //Date oneMonthAgoStartDate = currentDate.addMonths(-1).toStartOfMonth();
        //Date oneMonthAgoEndDate = oneMonthAgoStartDate.addDays(Date.daysInMonth(oneMonthAgoStartDate.year(), oneMonthAgoStartDate.month()) - 1);        

        Integer twoMonthAgo = currentDate.addMonths(-2).month();
        Integer twoMonthAgoYear = currentDate.addMonths(-2).year();

        Integer threeMonthAgo = currentDate.addMonths(-3).month();
        Integer threeMonthAgoYear = currentDate.addMonths(-3).year();

        Date moreThanThreeMonthAgo = currentDate.addMonths(-3);

        //System.debug('oneMonthAgoStartDate: '+oneMonthAgoStartDate + ' - oneMonthAgoEndDate: '+oneMonthAgoEndDate);

        Decimal currentMonthTotalhours = 0;
        Decimal firstMonthTotalhours = 0;
        Decimal secondMonthTotalhours = 0;
        Decimal thirdMonthTotalhours = 0;
        Decimal moreThanThreeMonthTotalhours = 0;
        Decimal totalHours = 0;
        Integer totalCost = 0;

        timeSpendHistoryList = new List<PROProjectTimeSpentHistory>();
        if( contractMap.containsKey(contractid2) ){
            //List<Time_Card__c> timeEntries = contractMap.get(contractid2).Time_Cards__r;
            List<Time_Card__c> timeEntries = new List<Time_Card__c>();
            if(contractIdTimeCardsMap.containsKey(contractid2)) {
                timeEntries.addAll(contractIdTimeCardsMap.get(contractid2));
            }

            List<DContract__c> childContracts = childContractMap.containsKey(contractid2) ? childContractMap.get(contractid2) : null;
            
            if(childContracts != null) {
                for(DContract__c childContract : childContracts) {
                    if(contractIdTimeCardsMap.containsKey(childContract.Id))
                        timeEntries.addAll(contractIdTimeCardsMap.get(childContract.Id));
                }
            }
            
            
            if(timeEntries != null && timeEntries.size() > 0) {

                for(Time_Card__c  obj: timeEntries)  {
                    String employeeName = obj.Employee__r.Name;
                    Date entryDate = obj.Date__c != null ? obj.Date__c : Date.today();
                    Integer entryDateMonth = obj.Date__c != null ? obj.Date__c.month() : 0;
                    Integer entryDateYear = obj.Date__c != null ? obj.Date__c.year() : 0;
                    Decimal totalHoursPerMonth = obj.Total__c != null ? obj.Total__c: 0;
                    Integer laborCost = obj.labor_cost__c != null ? Integer.valueOf(obj.labor_cost__c) : 0;

                    if(laborWithHours.containsKey(employeeName)) {
                        projTmSpntHstryObj = laborWithHours.get(employeeName);
                        projTmSpntHstryObj.laborCost += laborCost;
                    }else{
                        projTmSpntHstryObj = new PROProjectTimeSpentHistory();
                        projTmSpntHstryObj.laborName = employeeName;
                        projTmSpntHstryObj.laborCost = laborCost;
                    }

                    totalHours += totalHoursPerMonth;
                    totalCost += laborCost;
                    
                    if(entryDateMonth == currentMonth && entryDateYear == currentYear){

                        projTmSpntHstryObj.currentMonthHours += totalHoursPerMonth;

                    } else if(entryDateMonth == oneMonthAgo && entryDateYear == oneMonthAgoYear ){

                        projTmSpntHstryObj.firstMonthHours += totalHoursPerMonth;

                    } else if(entryDateMonth == twoMonthAgo && entryDateYear == twoMonthAgoYear ) {
                        
                        projTmSpntHstryObj.secondMonthHours += totalHoursPerMonth;

                    } else if(entryDateMonth == threeMonthAgo && entryDateYear == threeMonthAgoYear ) {
                        
                        projTmSpntHstryObj.thirdMonthHours += totalHoursPerMonth;

                    }else if(entryDate < moreThanThreeMonthAgo) {
                        
                        projTmSpntHstryObj.moreThanThreeMonthAgoHours += totalHoursPerMonth;
                    }

                    projTmSpntHstryObj.totalHourstoDate = projTmSpntHstryObj.currentMonthHours + projTmSpntHstryObj.firstMonthHours + projTmSpntHstryObj.secondMonthHours + projTmSpntHstryObj.thirdMonthHours + projTmSpntHstryObj.moreThanThreeMonthAgoHours;

                    laborWithHours.put(employeeName,projTmSpntHstryObj);
                }

                for(PROProjectTimeSpentHistory obj :laborWithHours.values() ) { 

                    timeSpendHistoryList.add(obj);
                    currentMonthTotalhours += obj.currentMonthHours;
                    firstMonthTotalhours += obj.firstMonthHours;
                    secondMonthTotalhours += obj.secondMonthHours;
                    thirdMonthTotalhours += obj.thirdMonthHours;
                    moreThanThreeMonthTotalhours += obj.moreThanThreeMonthAgoHours;
                }


            }
        }
        
        timeSpendHistoryList.sort();

        projTmSpntHstryObj = new PROProjectTimeSpentHistory();
        projTmSpntHstryObj.laborName = 'Total';
        projTmSpntHstryObj.currentMonthHours = currentMonthTotalhours;
        projTmSpntHstryObj.firstMonthHours = firstMonthTotalhours;
        projTmSpntHstryObj.secondMonthHours = secondMonthTotalhours;
        projTmSpntHstryObj.thirdMonthHours = thirdMonthTotalhours;
        projTmSpntHstryObj.moreThanThreeMonthAgoHours = moreThanThreeMonthTotalhours;
        projTmSpntHstryObj.totalHourstoDate = totalHours;
        projTmSpntHstryObj.laborCost = totalCost;
        timeSpendHistoryList.add(projTmSpntHstryObj);

    }

    public List<PROProjectBudget> proExpenseSpendList{
         get;set;
     }

     public void loadContractExpenseSpend() {
        proExpenseSpendList = new List<PROProjectBudget>();

        if( contractMap.containsKey(contractid2) ){
            DContract__c contractObj = contractMap.get(contractid2);
            List<DContract__c> childContracts = childContractMap.containsKey(contractid2) ? childContractMap.get(contractid2) : null;
            
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
                    Direct_Costs_Travel_BUDGET += childContract.Direct_Costs_Travel_BUDGET__c != null ? childContract.Direct_Costs_Travel_BUDGET__c : 0 ;
                    Direct_Costs_Sub_Contract_BUDGET += childContract.Direct_Costs_Sub_Contract_BUDGET__c != null ? childContract.Direct_Costs_Sub_Contract_BUDGET__c : 0 ;
                    Internal_Sub_contract_BUDGET += childContract.Internal_Sub_contract_BUDGET__c != null ? childContract.Internal_Sub_contract_BUDGET__c : 0 ;
                    Project_Other_BUDGET += childContract.Project_Other_BUDGET__c != null ? childContract.Project_Other_BUDGET__c : 0 ;
                    
                    Direct_Costs_Travel_Expenses += childContract.Direct_Costs_Travel_Expenses__c != null ? childContract.Direct_Costs_Travel_Expenses__c : 0 ;
                    Direct_Costs_Sub_contract_Expenses += childContract.Direct_Costs_Sub_contract_Expenses__c != null ? childContract.Direct_Costs_Sub_contract_Expenses__c : 0 ;
                    Internal_Sub_contract_Spend += childContract.Internal_Sub_contract_Spend__c != null ? childContract.Internal_Sub_contract_Spend__c : 0 ;
                    Project_Other_Spent += childContract.Project_Other_Spent__c != null ? childContract.Project_Other_Spent__c : 0 ;

                    Percent_through_SOW_deliverables += childContract.Percent_through_SOW_deliverables__c != null ? childContract.Percent_through_SOW_deliverables__c: 0 ;
                }
            }
            
            
            Decimal a = Direct_Costs_Travel_BUDGET;
            Decimal b = Direct_Costs_Travel_Expenses;
            PROProjectBudget prbjObj1 = new PROProjectBudget();
            prbjObj1.categoryName = 'Expense Travel';
            prbjObj1.contractamount = Integer.valueOf( Direct_Costs_Travel_BUDGET );
            prbjObj1.spentAmount = Integer.valueOf( Direct_Costs_Travel_Expenses );
            prbjObj1.throughSOWDeliverable = Integer.valueOf( Direct_Costs_Travel_BUDGET - Direct_Costs_Travel_Expenses );
            prbjObj1.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj1);

            a = Direct_Costs_Sub_Contract_BUDGET;
            b = Direct_Costs_Sub_contract_Expenses;
            PROProjectBudget prbjObj2 = new PROProjectBudget();
            prbjObj2.categoryName = 'Expense External Subcontract';
            prbjObj2.contractamount = Integer.valueOf( Direct_Costs_Sub_Contract_BUDGET );
            prbjObj2.spentAmount = Integer.valueOf( Direct_Costs_Sub_contract_Expenses );
            prbjObj2.throughSOWDeliverable = Integer.valueOf( Direct_Costs_Sub_Contract_BUDGET - Direct_Costs_Sub_contract_Expenses );
            prbjObj2.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj2);

            a = Project_Other_BUDGET;
            b = Project_Other_Spent;//calculate manually
            PROProjectBudget prbjObj3 = new PROProjectBudget();
            prbjObj3.categoryName = 'Expense Other Direct Costs';
            prbjObj3.contractamount = Integer.valueOf( Project_Other_BUDGET );
            prbjObj3.spentAmount = Integer.valueOf( Project_Other_Spent );
            prbjObj3.throughSOWDeliverable = Integer.valueOf( Project_Other_BUDGET - Project_Other_Spent );
            prbjObj3.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj3);

            a = Internal_Sub_contract_BUDGET;
            b = Internal_Sub_contract_Spend;
            PROProjectBudget prbjObj4 = new PROProjectBudget();
            prbjObj4.categoryName = 'Expense Internal Subcontract';
            prbjObj4.contractamount = Integer.valueOf( Internal_Sub_contract_BUDGET );
            prbjObj4.spentAmount = Integer.valueOf( Internal_Sub_contract_Spend );
            prbjObj4.throughSOWDeliverable = Integer.valueOf( Internal_Sub_contract_BUDGET - Internal_Sub_contract_Spend );
            prbjObj4.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj4);

            a = prbjObj1.contractamount + prbjObj2.contractamount + prbjObj3.contractamount;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount;
            PROProjectBudget prbjObj5 = new PROProjectBudget();
            prbjObj5.categoryName = 'Total Costs (not including subcontracts)';
            prbjObj5.contractamount = Integer.valueOf(a);
            prbjObj5.spentAmount = Integer.valueOf(b);
            prbjObj5.throughSOWDeliverable = Integer.valueOf( a - b );
            prbjObj5.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj5);

            a = prbjObj1.contractamount + prbjObj2.contractamount + prbjObj3.contractamount + prbjObj4.contractamount;
            b = prbjObj1.spentAmount + prbjObj2.spentAmount + prbjObj3.spentAmount + prbjObj4.spentAmount;
            PROProjectBudget prbjObj6 = new PROProjectBudget();
            prbjObj6.categoryName = 'Total Costs (including subcontracts)';
            prbjObj6.contractamount = Integer.valueOf(a);
            prbjObj6.spentAmount = Integer.valueOf(b);
            prbjObj6.throughSOWDeliverable = Integer.valueOf( a - b );
            prbjObj6.prcntgUsed = a != 0 ? Math.round((b/a) * 100) : 0;
            proExpenseSpendList.add(prbjObj6);
            
        }
    }

    public void searchProject() {
        System.debug('seachProjectName: '+seachProjectName);
        if (!seachProjectName.equals('')){

            String soql = 'select Id,Name,Last_Report_Out_Date__c from DContract__c WHERE (Requires_Report_Out__c = \'Yes\' OR Status__c = \'Active\') AND Id NOT IN :excludeContractFromSearch';
                soql += ' and Name LIKE \''+String.escapeSingleQuotes(seachProjectName)+'%\'';
            system.debug('Final query: '+soql + ' limit 20');

            searchedProjects = Database.query(soql + ' limit 20');

            if(searchedProjects.size() == 0)
                searchError = 'No projects were found.';

        }else{
            searchedProjects.clear();
            searchError= '';
        }
    }

    public void addProjectToUserList() {
        try{
            PRO_Searched_Contract__c proSearchCon = new PRO_Searched_Contract__c(
                Email__c = CurrentLoginEmail, //change static email to 'CurrentLoginEmail'
                Contract__c = contractToAdd
            );
            insert proSearchCon;

            for(Integer i=0; i < searchedProjects.size() ; i++) {
                if(searchedProjects[i].Id == contractToAdd) {
                    searchedProjects.remove(i);
                    break;
                }
            }

            getProjectList3();
            seachProjectName = '';
            contractToAdd = '';
            contractToRemove = '';
        }catch(Exception e) {
            System.debug('Error occured: '+ e.getMessage());
        }
        
    }

    public void removeProjectFromUserList() {
        System.debug('contractToRemove: '+contractToRemove);
        if(contractToRemove != '') {
            try{ 
                delete [Select id from PRO_Searched_Contract__c where Email__c = :CurrentLoginEmail AND Contract__C = :contractToRemove];
                if(contractid2 == contractToRemove){
                    contractid2 = null;
                }
                contractToRemove = '';
                getProjectList3();
            }catch(Exception e) {
                System.debug('Error occurred while deleting project: '+e.getMessage());
            }
        }
    }

    public PageReference saveProjectOnly(){
        PageReference page = null;
         
        if(ValidateProject()){
            try{
                update Project;
            }
            catch(DmlException ex){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getDmlMessage(0)));
            }
            catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
            }
            ContractContactsProject=[select id,Contact__C,Contract__C,Type__C from Contract_Contact__c 
                    where Contract__C=:selectedProjectId and Type__C not in('Person','Email')];
        }
        return page;
    }
     
    public PageReference saveProject(){
        PageReference page = null;
         
        page=saveProjectOnly();
        SaveContact();
         
        return page;
         
    }
     
    List<Contract_Contact__c> DeleteContactList=new List<Contract_Contact__c>();
     
    public void SaveContact(){
         /*string PMId=null;
         if(Project.Project_Manager__c!=null){
             PMId=Project.Project_Manager__c;
         }
         
         string FMId=null;
         if(Project.Field_Manager__c!=null){
             FMId=Project.Field_Manager__c;
         }
         
         string BTId=null;
         if(Project.Backstop__c!=null){
             BTId=Project.Backstop__c;
         }
         
         boolean PMFound=false,FMFound=false,BTFound=false;
         
         for(Contract_Contact__c contContact : ContractContacts){
            if(contContact.Type__C=='Project Manager'){
                contContact.Contact__C=PMId;
                PMFound=true;
            }
            else if(contContact.Type__C=='Field Manager'){
                contContact.Contact__C=FMId;
                FMFound=true;
            }
            else if(contContact.Type__C=='Backstop'){
                contContact.Contact__C=BTId;
                BTFound=true;
            }
        }
        if(PMId!=null && !PMFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=PMId;
             contractContact.Type__C='Project Manager';
             ContractContacts.add(contractContact);
        }
        if(FMId!=null && !FMFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=FMId;
             contractContact.Type__C='Field Manager';
             ContractContacts.add(contractContact);
        }
        if(BTId!=null && !BTFound){
             Contract_Contact__c contractContact=new Contract_Contact__c();
             contractContact.Contract__c=selectedProjectId;
             contractContact.Contact__C=BTId;
             contractContact.Type__C='Backstop';
             ContractContacts.add(contractContact);
        }*/
        
        List<integer>removeIndex=new List<integer>();
        if(ContractContacts!=null){
            for(integer index=0;index<ContractContacts.size();index++){
                Contract_Contact__c contContact=ContractContacts[index];
                if(contContact.Contact__C!=null || contContact.Email__C!=null){
                     upsert contContact;
                }
                else{
                    if(contContact.Id!=null){
                        removeIndex.add(index);
                        delete contContact;
                    }
                }
            }
        }
        for(integer index=0;index<removeIndex.size();index++){
            ContractContacts.remove(removeIndex[index]);
        }
        
        if(DeleteContactList.size()>0){
            delete DeleteContactList;
            DeleteContactList.clear();
        }
        
    }
    public boolean ValidateProject(){
         
        if (selectedProjectId == null || selectedProjectId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        return true;
     
    }
    public ID RemoveContactId{
         get;set;
    }
     public void RemoveContact(){
          if(ContractContacts.size()>0){
             integer removeIndex=-1;
             for(integer index=0;index<ContractContacts.size();index++){
                 Contract_Contact__c ct=ContractContacts[index];
                 if(ct.Contact__c==RemoveContactId ){
                     if(ct.id!=null){
                          DeleteContactList.add(ct);
                     }
                     removeIndex=index;
                     break;
                 }
             }
             if(removeIndex==-1){
                 for(integer index=0;index<ContractContacts.size();index++){
                     Contract_Contact__c ct=ContractContacts[index];
                     if(ct.Type__C=='Person' && ct.Contact__c==null){
                         removeIndex=index;
                         break;
                     }
                 }
             }
             
             if(removeIndex!=-1){
                 ContractContacts.remove(removeIndex);
             }
         }
     }
     public string RemoveEmailId{
         get;set;
     }
     public void RemoveEmail(){
          if(ContractContacts.size()>0){
             integer removeIndex=-1;
             for(integer index=0;index<ContractContacts.size();index++){
                 Contract_Contact__c ct=ContractContacts[index];
                 if(ct.Email__C==RemoveEmailId){
                     if(ct.id!=null){
                          DeleteContactList.add(ct);
                     }
                     removeIndex=index;
                     break;
                 }
             }
             if(removeIndex==-1){
                 for(integer index=0;index<ContractContacts.size();index++){
                     Contract_Contact__c ct=ContractContacts[index];
                     if(ct.Type__C=='Email' && ct.Email__C==null){
                         removeIndex=index;
                         break;
                     }
                 }
             }
             
             if(removeIndex!=-1){
                 ContractContacts.remove(removeIndex);
             }
         }
     }
     
     public void AddContact(){
         Contract_Contact__c contractContact=new Contract_Contact__c();
         contractContact.Contract__c=selectedProjectId;
         contractContact.Type__C='Person';
         ContractContacts.add(contractContact);
     }
     public void AddEmail(){
         Contract_Contact__c contractContact=new Contract_Contact__c();
         contractContact.Contract__c=selectedProjectId;
         contractContact.Type__C='Email';
         ContractContacts.add(contractContact);
     }

     public List<Contract_Contact__c> ContractContacts{
         get;set;
     }
    
    public List<Contract_Contact__c> ContractContactsProject{
         get;set;
     }
    
    public void SendEmail(string PROID){
         Id templateId=[select id from EmailTemplate where DeveloperName='Project_Report_Out_VF' limit 1].id;
         List<Contact> contactList=new List<Contact>();
         OrgWideEmailAddress orgWideAddress= [select Id from OrgWideEmailAddress where 
                                              Address = 'dimagi-salesforce@dimagi.com' limit 1];
         /*List<DContract__c> contractList=[select id,Project_Manager__c,Backstop__c,Field_Manager__c,
                                          Project_Manager__r.Name,Backstop__r.Name,Field_Manager__r.Name,
                                          In_Charge_Of_Report_Out__c from DContract__c 
                                          where Id=:contractid];
         if(contractList!=null && contractList.size()>0){
            if(contractList[0].Project_Manager__c!=null){
                contactList.add(contractList[0].Project_Manager__r);
            }
            if(contractList[0].Backstop__c!=null){
                contactList.add(contractList[0].Backstop__r);
            }
            if(contractList[0].Field_Manager__c!=null){
                contactList.add(contractList[0].Field_Manager__r);
            }
         }*/
         List<Contract_Contact__c> contractContactList= [select id,Contact__C,Email__C,Type__c,Contact__r.Email,Contact__r.Id,Contact__r.Name,Contract__C from 
                                                             Contract_Contact__c 
                                                        where Contract__C=:contractid];
         List<string> emailList=new List<string>();
         for(Contract_Contact__c conContact:contractContactList){
             if(conContact.Type__C!='Email'){
                 contactList.add(conContact.Contact__r);
             }
             else{
                 emailList.add(conContact.Email__C);
             }
         }
         
         for(Contact con:contactList){
             if(con!=null && con.Email!=null && con.Email.containsIgnoreCase('dimagi.com')){
                 emailList.add(con.Email);
             }
         }

         System.debug('Contact List Size: '+contactList.size());
         if(contactList.size()>0){
             Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
             msg.setTemplateId(templateId);
             msg.setTargetObjectId(contactList[0].Id);
             msg.setToAddresses(emailList);
             msg.setWhatId(PROID);
             msg.setSaveAsActivity(false);
             msg.setOrgWideEmailAddressId(orgWideAddress.id);
             Messaging.sendEmail(new Messaging.SingleEmailMessage[]{msg} );
         }
         
         /*List<Messaging.SingleEmailMessage> messageList=new List<Messaging.SingleEmailMessage>();
         
         for(Contact con:contactList){
             Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
             msg.setTemplateId(templateId);
             //msg.setCcAddresses(new String[] {'email1@recipient.com', 'email2@recipient.com'});
             msg.setTargetObjectId(con.Id);
             msg.setWhatId(PROID);
             msg.setSaveAsActivity(false);
             messageList.add(msg);
         }
         if(messageList.size()>0){
             Messaging.sendEmail(messageList);
         }*/
     }
    
    public void AddMe(){
     
         List<Contact> contList=[select id,name from contact where email=:CurrentLoginEmail];
         
         if(contList.size()>0){
           Contract_Contact__c contractContact=new Contract_Contact__c();
           contractContact.Contract__c=selectedProjectId;
           contractContact.Type__C='Person';
           contractContact.Contact__C=contList[0].id;
           ContractContacts.add(contractContact);
         
         }
     }
    
    public class PROProject{
         public PROProject(){
         
         }
         public DContract__c contract{
             get;set;
         }
         public Boolean customAdded {
            get;set;
         }
         public string CSSClass{
             get;set;
         }
     
     
     }

    public class ProjectExecutionStatus{
         public String fieldName{
             get;set;
         }
         public Integer fieldValue{
             get{ return (fieldValue == null) ? 0 : fieldValue; }
             set;
         }
     }
     
    public class PROProjectBudget{
         public PROProjectBudget(){
         
         }
         public String categoryName{
             get;set;
         }
         public Integer contractamount{
             get;set;
         }
         public Integer spentAmount{
             get;set;
         }
         public Integer amountRemaining{
             get;set;
         }
         public Integer prcntgUsed{
             get;set;
         }

         public Integer throughContract{
             get;set;
         }

         public Integer throughSOWDeliverable{
             get;set;
         }
     
     }

    /*public class PROProjectTimeSpent implements Comparable{
        public String laborName{
            get;set;
        }
        public Integer laborHours{
            get;set;
        }
        public Integer laborCost{
            get;set;
        }

        public Integer compareTo(Object objToCompare) {
            return Integer.valueOf( ((PROProjectTimeSpent)objToCompare).laborHours - laborHours);
        }


     }*/
    
    public class PROProjectTimeSpentHistory implements Comparable{
         public String laborName{
             get;set;
         }
         public Decimal currentMonthHours{
             get{ return (currentMonthHours == null) ? 0 : currentMonthHours; }
             set;
         }
         public Decimal firstMonthHours{
             get{ return (firstMonthHours == null) ? 0 : firstMonthHours; }
             set;
         }
         public Decimal secondMonthHours{
             get{ return (secondMonthHours == null) ? 0 : secondMonthHours; }
             set;
         }
         public Decimal thirdMonthHours{
             get{ return (thirdMonthHours == null) ? 0 : thirdMonthHours; }
             set;
         }
         public Decimal moreThanThreeMonthAgoHours{
             get{ return (moreThanThreeMonthAgoHours == null) ? 0 : moreThanThreeMonthAgoHours; }
             set;
         }
         public Decimal totalHourstoDate{
             get{ return (totalHourstoDate == null) ? 0 : totalHourstoDate; }
             set;
        }

        public Integer laborCost{
            get;set;
        }

        public Integer compareTo(Object objToCompare) {
            return Integer.valueOf( ((PROProjectTimeSpentHistory)objToCompare).totalHourstoDate - totalHourstoDate);
        }

     }

 }