public class FTESortController extends FTEController{
    public static final String B_ASC = 'ASC';
    public static final String B_DESC = 'DESC';

    public Integer fteYear { get; set;}
    public Id employeeId { get; set;}
    public List<FTEEmployeeTime> employees { get; set;}
    public String employeeNameSearch { get; set;}
    public Pagination employeePagination { get; set;}
   // public String emplDepartment { get; set; }
    public string Division{get; set;}
    public string subDivision{get; set;}
    public Map<Id, FTEEmployeeTime> employeeTimeMap { get; set;}
    public boolean isDisplay;
    public string mode {get;set;}
    public Boolean isExportExcel{get;set;}
    public Boolean isExportPDF{get;set;}
    public Boolean toggleSort{get;set;}
    public string sortField{get;set;}
    public string orderBy{get;set;}
    public string orderType{get;set;}
    public string sortDirection{get;set;}
    public List<FTE_Work_Card__c> work_cards{get;set;}
    public list<String> sortingFields {get;set;}
    public list<String> sortingFieldsPosition{get;set;}
    public string sortDir{get;set;}
    

     public List<SelectOption> divisionList {
        get {
            List<SelectOption> result = SFUtils.getPicklistValuesWithLabel(new SFDC_Employee__c(), 'Division__c');
            result.add(0, new SelectOption('-', 'Empty'));
            result.add(0, new SelectOption('---', 'All'));
            return result;
        }
        set;
    }
    
    public List<SelectOption> subDivisionList {
        get {
            List<SelectOption> result = SFUtils.getPicklistValuesWithLabel(new SFDC_Employee__c(), 'Sub_Division__c');
            result.add(0, new SelectOption('-', 'Empty'));
            result.add(0, new SelectOption('---', 'All'));
            return result;
        }
        set;
    }

    public FTESortController () {
        isDisplay = true;
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        this.employeePagination = new Pagination();
        this.employeePagination.pageSize = 50;
        this.division = '---';
        this.subdivision = '---';
        this.employeeTimeMap = new Map<Id, FTEEmployeeTime>();
        this.work_cards  = new List<FTE_Work_Card__c>();
        this.orderBy = 'Total_Hours__c';
        this.sortDirection = 'DESC';
        sortingFields = new list<string>{'Employee__r.Name','Employee__r.Hire_Date__c','Employee__r.Termination_Date__c',
            'Month_1__c','Month_2__c','Month_3__c','Month_4__c','Month_5__c','Month_6__c','Month_7__c','Month_8__c','Month_9__c','Month_10__c','Month_11__c','Month_12__c'};
         sortingFieldsPosition = new list<String>{'ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC','ASC'};        
        this.work_cards = EmployeesList();
        this.employees = setWorkCardsonPages(work_cards, 'FTE_Work_Card__c');
      //  this.employees = EmployeesList();
       // sortField = 'Employee Name';
        
        
    }

    public String testQuery { get; set; }
    public String testQueryCount { get; set; }
    
    public void toggleSort() {
         this.orderby = sortField;
         Integer fldIndex = sortingFields.indexOf(sortField);
         this.sortDirection = sortingFieldsPosition.get(fldIndex);
         this.employeeTimeMap.clear();
         this.employees = new List<FTEEmployeeTime>();
        // List<FTE_Work_Card__c> work_cards = new List<FTE_Work_Card__c>();
         this.work_cards = EmployeesList();
         this.employees = setWorkCardsonPages(work_cards, 'FTE_Work_Card__c');
      
        if(sortingFieldsPosition.get(fldIndex) == 'ASC')
        {
           sortingFieldsPosition[fldIndex] = 'DESC NULLS LAST'; 
        }else
            sortingFieldsPosition[fldIndex] = 'ASC'; 
    }
   
    
    public List<FTEEmployeeTime> getEmployeesListExport() {
        system.debug('Export');
        this.employeeTimeMap.clear();
        this.employees = new List<FTEEmployeeTime>();
      //  List<FTE_Work_Card__c> work_cards = new List<FTE_Work_Card__c>();
        this.work_cards = EmployeesList();
        this.employees = queryWorkCards(work_cards);
        return this.employees;
    } 
    
    public List<FTE_Work_Card__c> queryEmployeeList(String ObjectName, Boolean isDisplay, String orderBy, String orderType) {
        system.debug('Querying Employee List for Object: ' + ObjectName);
    
        // Initialize the QueryBuilder
        QueryBuilder qb = new QueryBuilder(ObjectName);
        qb.addColumns(new List<String> {
            'Id', 'Employee__c', 'Employee__r.Hire_Date__c', 'Employee__r.Termination_Date__c', 'Employee__r.Name',
            'Month_1__c', 'Month_2__c', 'Month_3__c', 'Month_4__c', 'Month_5__c', 'Month_6__c',
            'Month_7__c', 'Month_8__c', 'Month_9__c', 'Month_10__c', 'Month_11__c', 'Month_12__c',
            'Total__c', 'Total_Hours__c', 'Year__c'
        });
    
        // Apply filters and ordering
        if (!String.isEmpty(this.employeeNameSearch)) {
            qb.addLike('Employee__r.Name', '%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%');
        }
    
        if (this.Division != '---') {
            qb.addAnd('Employee__r.Division__c', this.Division, null);
        }
    
        if (this.subDivision != '---') {
            qb.addAnd('Employee__r.Sub_Division__c', this.subDivision, null);
        }
    
        qb.addAnd('Year__c', '' + this.fteYear, QueryBuilder.QB_DECIMAL_TYPE);
        qb.orderBy(orderBy, orderType);
    
        if (isDisplay) {
            qb.setLimit(this.employeePagination.pageSize);
            qb.setOffset(this.employeePagination.getOffsetValue());
        }
    
        // Execute the query
        List<FTE_Work_Card__c> workCards = Database.query(qb.buildQuery());
        system.debug('Queried Work Cards: ' + workCards.size());
    
        // Aggregation logic
        Map<Id, FTE_Work_Card__c> employeeAggregates = new Map<Id, FTE_Work_Card__c>();
    
        for (FTE_Work_Card__c card : workCards) {
            if (!employeeAggregates.containsKey(card.Employee__c)) {
                FTE_Work_Card__c aggregatedCard = new FTE_Work_Card__c(
                    Employee__c = card.Employee__c,
                    Employee__r = card.Employee__r,
                    Year__c = card.Year__c,
                    Total_Hours__c = 0,
                    Month_1__c = 0, Month_2__c = 0, Month_3__c = 0, Month_4__c = 0,
                    Month_5__c = 0, Month_6__c = 0, Month_7__c = 0, Month_8__c = 0,
                    Month_9__c = 0, Month_10__c = 0, Month_11__c = 0, Month_12__c = 0
                );
                employeeAggregates.put(card.Employee__c, aggregatedCard);
            }
    
            FTE_Work_Card__c aggregatedCard = employeeAggregates.get(card.Employee__c);
            aggregatedCard.Total_Hours__c += card.Total_Hours__c;
    
            for (Integer i = 1; i <= 12; i++) {
                String monthField = 'Month_' + i + '__c';
                aggregatedCard.put(monthField, (Decimal)aggregatedCard.get(monthField) + (Decimal)card.get(monthField));
            }
        }
        system.debug('employeeAggregates.values(): ' + employeeAggregates.values().size());

        // Return the list of aggregated records
        return employeeAggregates.values();
    }
    
    
    
    
    
    public list<FTEEmployeeTime> setWorkCardsonPages(List<FTE_Work_Card__c> workCards, String ObjectName){
        
        List<FTE_Work_Card__c> eachPage_workcards = new List<FTE_Work_Card__c>();
        this.employeePagination.handleResulSize(workcards.size());
        integer val = this.employeePagination.getOffsetValue();
        integer size = this.employeePagination.pageSize + this.employeePagination.getOffsetValue();
        if(size > workCards.size()) size  = workCards.size();
        system.debug('((size))' + size);
        system.debug('((val))' + val);
        for(integer i=val;i<size;i++){
            eachPage_workcards.add(this.work_cards[i]);
        }
        system.debug('((eachpage))' + eachPage_workcards.size());
        this.employees = queryWorkCards(eachPage_workcards);
        return this.employees;
    }
    
    public List<FTEEmployeeTime> queryWorkCards(List<FTE_Work_Card__c> workCards){      
        List<FTEEmployeeTime> employeeList = new List<FTEEmployeeTime>(); 
        calculateEmployeeTime(workCards);
        for (FTEEmployeeTime empT : this.employeeTimeMap.values()) {
            empT.calculateDays();
            System.debug('LOG:::' + JSON.serialize(empT.daysArray));
            employeeList.add(empT);
        }

       system.debug('size' + employeeList.size());
       return employeeList;
    }
    

    public List<FTE_Work_Card__c> EmployeesList() { 
        system.debug('Querylist');
     //   List<FTEEmployeeTime> list_employees = new list<FTEEmployeeTime>();
        List<FTE_Work_Card__c> work_cards = new List<FTE_Work_Card__c>(); 
        work_cards = queryEmployeeList('FTE_Work_Card__c', false, this.orderBy, this.sortDirection);
       // list_employees = queryWorkCards(work_cards, 'FTE_Work_Card__c');
        return  work_cards; 
    }
    
   
    
    public void renderOnpageSize(){
        this.employeeTimeMap.clear();
        system.debug(this.employeePagination.pageSize);
        system.debug(this.work_cards.size());
        this.employees = setWorkCardsonPages(this.work_cards, 'FTE_Work_Card__c');
        
    }
    
    public void calculateEmployeeTime(List<FTE_Work_Card__c> workCards){
        try{
            System.debug('LOG:::' + workCards.size());    
            for (FTE_Work_Card__c workCard : workCards) {
                FTEEmployeeTime tmpHelper;

                if (!this.employeeTimeMap.containsKey(workCard.Employee__c)) {
                    this.employeeTimeMap.put(workCard.Employee__c, new FTEEmployeeTime(workCard.employee__r.name, workCard.Employee__c, workCard.employee__r.Hire_Date__c, workCard.employee__r.Termination_Date__c,false));
                }
                tmpHelper = this.employeeTimeMap.get(workCard.Employee__c);
                
                Double total = 0;
                for(Integer i=1; i< tmpHelper.hoursArray.size(); i++){
                    Decimal hoursTotal = (Decimal) workCard.get('month_'+ i + '__c') * 8;
                    tmpHelper.hoursArray[i-1] += hoursTotal;
                    total += hoursTotal;
                }
                System.debug('LOG:::' + JSON.serialize(tmpHelper.hoursArray));
                System.debug('LOG:::' + total);
                System.debug('LOG:::' + tmpHelper.hoursArray[12]);
                System.debug('LOG:::' + workCard.Total__c);

                if (total == 0) {
                    tmpHelper.hoursArray[12] += workCard.Total__c != null ? workCard.Total__c * 8 : 0;
                } else {
                    tmpHelper.hoursArray[12] += total;
                }
				
            }
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }
    public PageReference export_FTEListViewExcel(){
        isDisplay = false;
        isExportExcel = true;
        isExportPDF = false;
        PageReference pageRef = Page.FTE_Employee_List_Export;
        mode = 'application/vnd.ms-excel#Employeereport.xls';
        pageref.getParameters().put('mode', 'xls');
        return pageRef;        
    }
    
    public PageReference export_FTEListViewPDF(){
        isDisplay = false;
        isExportExcel = false;
        isExportPDF = true;
        PageReference pageRef = Page.FTE_Employee_List_Export;
        pageref.getParameters().put('mode', 'pdf');
        String PDFGeneratedFileName = 'EmployeePDFreport.pdf';
        pageRef.getHeaders().put('content-disposition', 'attachment; filename='+PDFGeneratedFileName);
        return pageRef;        
    }

     public void searchEmplopyee() {
         system.debug('debug');
         this.employeePagination.pageNumber = 1;
         this.employeeTimeMap.clear();
         this.work_cards = EmployeesList();
         this.employees = setWorkCardsonPages(this.work_cards, 'FTE_Work_Card__c');
     }

    public void goToPreviousPage(){
         this.employeePagination.pageNumber -= 1;
         this.employeeTimeMap.clear();
         this.employees = setWorkCardsonPages(this.work_cards, 'FTE_Work_Card__c'); 
        
    }

    public void goToNextPage(){
         this.employeePagination.pageNumber += 1;
         this.employeeTimeMap.clear();
         system.debug('((this.work_cards))' + this.work_cards.size());
         this.employees = setWorkCardsonPages(this.work_cards, 'FTE_Work_Card__c'); 
    } 

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        if (Date.today().year() != this.fteYear) {
            pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        }
        return pageRef;
    }
    

}