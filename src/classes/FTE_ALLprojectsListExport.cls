public class FTE_ALLprojectsListExport extends FTEController{
    public Id contractId { get; set;}
    public String contractName { get; set;}
    public Id employeeId { get; set;}
    public list<listIndividualContractDataList> displayProjectList { get; set;}
    public Integer fteYear { get; set;}
    public Map<Id, FTEEmployeeTime> projectTimeTrackingMap { get; set;}
    public List<DContract__c> list_contracts {get;set;}
    public boolean Isexportexcel{get;set;}
    public boolean Isexportpdf{get;set;}
    public string mode {get;set;}
    public set<id> set_Contract_Id {get;set;}
    public string Filename {get;set;}
    public boolean Ispdf{get;set;}
    
    public FTE_ALLprojectsListExport(){
         String yearString = ApexPages.currentPage().getParameters().get('fteYear');
         system.debug('yearString' +yearString);
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        system.debug('yearString' +yearString);
        list_contracts = new List<DContract__c>();
        FTEProjectListController projectsvar = new FTEProjectListController();
        projectsvar.contract.Project_Years__c = String.valueOf(this.fteYear); 
        projectsvar.ListToSubmit();
        list_contracts.addAll(projectsvar.list_contracts);
        FileName= 'ProjectsPDFReport';
        
       // FileName= '(' + this.fteYear + ') ProjectsPDFReport'+ '_' + Date.today();
        string exportexcel = ApexPages.currentPage().getParameters().get('Isexportexcel');
      //  system.debug();
        Isexportexcel = (exportexcel == 'true' && exportexcel != null) ? true : false;
        string exportPdf = ApexPages.currentPage().getParameters().get('Isexportpdf');
        Ispdf = (exportPdf == 'true' && exportPdf != null ) ? true : false ;
        mode = ApexPages.currentPage().getParameters().get('mode');
        system.debug('Isexportexcel' + Isexportexcel);
        system.debug('Isexportpdf' + Isexportpdf);
        system.debug('mode' + mode); 
        
        getContractsList();
        ProjectListview();
    }
     public PageReference ProjectListview(){
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('fteYear', ApexPages.currentPage().getParameters().get('fteYear'));
        return pageRef;
        
    }
    
    public class listIndividualContractDataList{
        public List<FTEEmployeeTime> empDataTable {get;set;}
        public String ContractName {get;set;}
        
        public listIndividualContractDataList(){
            empDataTable= new List<FTEEmployeeTime>();
        }
    }

    public void getContractsList (){
        displayProjectList = new list<listIndividualContractDataList>();
      //  listIndividualContractDataList = new list<List<FTEEmployeeTime>>();
       
        for(DContract__c eachContract: list_contracts) {
            List<FTEEmployeeTime> list_empRecords = new  List<FTEEmployeeTime>();
            map<String, List<FTEEmployeeTime>> eachindividualContractDataList = new map<String, List<FTEEmployeeTime>>();
            eachindividualContractDataList = initIndividualProject(eachContract.id);
           listIndividualContractDataList Contractwrapper = new listIndividualContractDataList();
            for(list<FTEEmployeeTime> eachVal : eachindividualContractDataList.values()){
                system.debug(eachVal);
               Contractwrapper.empDataTable.addAll(eachVal); 
               Contractwrapper.ContractName = eachVal[0].ContractName;
                
            }
            displayProjectList.add(Contractwrapper);
         //   Contractwrapper.empDataTable = eachindividualContractDataList.values();
           
          
           // system.debug();
         //   system.debug(eachindividualContractDataList);
          //  list_empRecords.addAll(eachindividualContractDataList.values());
        } 
        
       // listIndividualContractDataList.addAll(eachindividualContractDataList.values());
      //  system.debug('keyset' + listIndividualContractDataList.size());
      //  system.debug('keyset'+ eachindividualContractDataList.values());
      //  system.debug('Val' + listIndividualContractDataList);
    } 
   
   
    public map<String, List<FTEEmployeeTime>> initIndividualProject(Id contractId) {
      map<String, List<FTEEmployeeTime>> mapindividualContractDataList = new map<String, List<FTEEmployeeTime>>();
        
       
        List<DContract__c> contractList = [SELECT Id, Name FROM DContract__c WHERE Id =: contractId];
      
       // this.contractName = contractList.get(0).Name;
        Map<Id, FTEEmployeeTime> projectTimeMap = new Map<Id, FTEEmployeeTime>();
        Decimal totalHours = 0;

        FTEEmployeeTime totalProjectTime = new FTEEmployeeTime('Total', null, false);
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.name, Month_1__c, Month_2__c, Month_3__c, Month_4__c, 
                                                    Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, 
                                                    Month_10__c, Month_11__c, Month_12__c, Total__c, Total_Hours__c FROM FTE_Work_Card__c 
                                                    WHERE Contract__c =: contractId
                                                    AND Year__c	 =: this.fteYear
                                                    ORDER BY Employee__r.Name];
        this.projectTimeTrackingMap = new Map<Id, FTEEmployeeTime>();
        for(FTE_Work_Card__c workCard : workCards){
             FTEEmployeeTime tmpHelper;
           
            if (!this.projectTimeTrackingMap.containsKey(workCard.Employee__c)) {
                    this.projectTimeTrackingMap.put(workCard.Employee__c, new FTEEmployeeTime(workCard.Employee__r.name, workCard.Employee__c, false,contractList.get(0).Name));
            }
            tmpHelper = this.projectTimeTrackingMap.get(workCard.Employee__c);
            for(Integer i=1; i< tmpHelper.hoursArray.size(); i++){
                tmpHelper.hoursArray[i-1] = (Decimal) workCard.get('month_'+ i + '__c') * 8;
            }
            tmpHelper.hoursArray[12]=workCard.Total__c * 8;
        }

     /*   for (Time_Card__c timeCard : [SELECT Id, Employee__c, Employee__r.Name, Date__c, Total__c, FTE_hours__c, FTE_Contract__c FROM Time_Card__c WHERE
                                                (Client__c =: contractId OR FTE_Contract__c =: contractId) AND CALENDAR_YEAR(Date__c) =: this.fteYear]) {
            FTEEmployeeTime tmpHelper;
            if (projectTimeMap.containsKey(timeCard.Employee__c)) {
                tmpHelper = projectTimeMap.get(timeCard.Employee__c);
            } else {
                tmpHelper = new FTEEmployeeTime(timeCard.Employee__r.Name, timeCard.Employee__c, false,contractList.get(0).Name);
            }

            Decimal realHours = timeCard.Total__c != null ? timeCard.Total__c : 0;
            if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c != contractId) {
                realHours = realHours - timeCard.FTE_hours__c;
            } else if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c == contractId) {
                realHours = timeCard.FTE_hours__c;
            }

            Integer monthIndex = timeCard.Date__c.month() - 1;
            tmpHelper.hoursArray[monthIndex] += realHours;
            tmpHelper.hoursArray[12] += realHours;
            projectTimeMap.put(timeCard.Employee__c, tmpHelper);
        } */
       List<FTEEmployeeTime> individualContractDataList = new List<FTEEmployeeTime>();
       individualContractDataList = this.projectTimeTrackingMap.values();
        for (FTEEmployeeTime empT : individualContractDataList) {
            empT.calculateDays();
            totalProjectTime.sumHours(empT);
        }
        totalProjectTime.calculateDays();
        totalProjectTime.cssStyle[0] = 'topTotal';
        totalProjectTime.cssStyle[1] = 'topTotal';
        totalProjectTime.cssStyle[2] = 'topTotal';
        totalProjectTime.cssStyle[3] = 'topTotal';
        totalProjectTime.cssStyle[4] = 'topTotal';
        totalProjectTime.cssStyle[5] = 'topTotal';
        totalProjectTime.cssStyle[12] = 'topTotal';
        totalProjectTime.nameCss = 'topTotal';
        individualContractDataList.add(totalProjectTime);
        system.debug('individualContractDataList' + individualContractDataList);
        mapindividualContractDataList.put(contractList.get(0).Name, individualContractDataList);
        return mapindividualContractDataList;
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageRef;
    }

    public override PageReference goToEmployeeListView() {
        PageReference pageRef = Page.FTE_Employee_List_View;
        if (Date.today().year() != this.fteYear) {
            pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        }

        return pageRef;
    }

}