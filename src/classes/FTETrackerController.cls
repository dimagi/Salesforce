/**
 * Controller for FTE Employee List views.
 * Test class - FTETrackerTest
 */
public class FTETrackerController extends FTEController {

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
    
 /*   public List<SelectOption> departmentList {
        get {
            List<SelectOption> result = SFUtils.getPicklistValuesWithLabel(new SFDC_Employee__c(), 'Sub_Unit__c');
            result.add(0, new SelectOption('-', 'Empty'));
            result.add(0, new SelectOption('---', 'All'));
            return result;
        }
        set;
    }
    public String emplBusinessUnit { get; set; }
    public List<SelectOption> buList {
        get {
            List<SelectOption> result = new List<SelectOption> { new SelectOption('---', 'All'), new SelectOption('-', 'Empty') }; // empty, any
            for (Business_Unit__c bu : [SELECT Id, Name FROM Business_Unit__c]) {
                result.add(new SelectOption(bu.Id, bu.Name));
            }
            return result;
        }
        set;
    } */
    
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

    public FTETrackerController () {
        isDisplay = true;
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        this.employeePagination = new Pagination();
        this.employeePagination.pageSize = 50;
       // this.emplDepartment = '---';
      //  this.emplBusinessUnit = '---';
        this.division = '---';
        this.subdivision = '---';
        this.employeeTimeMap = new Map<Id, FTEEmployeeTime>();
        this.employees = EmployeesList();
    }

    public String testQuery { get; set; }
    public String testQueryCount { get; set; }

    public List<FTEEmployeeTime> getEmployeesListExport() {
        system.debug('Export');
        this.employeeTimeMap.clear();
        this.employees = new List<FTEEmployeeTime>();
        this.employees = queryEmployeeList('FTE_Work_Card__c', false);
        return this.employees;
    }
    
   public List<FTEEmployeeTime> queryEmployeeList(String ObjectName, Boolean Isdisplay)
   {
       system.debug('Query');
       List<FTEEmployeeTime> employeeList = new List<FTEEmployeeTime>(); 
       List<FTE_Work_Card__c> workCards = null;
       QueryBuilder qb = new QueryBuilder(ObjectName);
        QueryBuilder qbCount = new QueryBuilder(ObjectName);
        qb.addColumns(new List<String> { 'Id', 'Employee__c', 'Employee__r.Hire_Date__c','Employee__r.Termination_Date__c','Employee__r.Name', 'Month_1__c', 'Month_2__c', 'Month_3__c',
                                         'Month_4__c', 'Month_5__c', 'Month_6__c', 'Month_7__c', 'Month_8__c', 'Month_9__c', 'Month_10__c', 'Month_11__c',
                                         'Month_12__c', 'Total__c', 'Total_Hours__c', 'Year__c'});
        qbCount.addColumn('count()');

        if (this.employeeNameSearch != null && this.employeeNameSearch != '') {
            qb.addLike('Employee__r.Name', ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%'));
            qbCount.addLike('Employee__r.Name', ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%'));
        }

      /*  if (this.emplBusinessUnit != '---') {
            qb.addAnd('Employee__r.Business_Unit__c', this.emplBusinessUnit != '-' ? this.emplBusinessUnit : '', null);
            qbCount.addAnd('Employee__r.Business_Unit__c', this.emplBusinessUnit != '-' ? this.emplBusinessUnit : '', null);
        }

        if (this.emplDepartment != '---') {
            qb.addAnd('Employee__r.Sub_Unit__c', this.emplDepartment != '-' ? this.emplDepartment : '', null);
            qbCount.addAnd('Employee__r.Sub_Unit__c', this.emplDepartment != '-' ? this.emplDepartment : '', null);
        } */
       
        if (this.Division != '---') {
            qb.addAnd('Employee__r.Division__c', this.Division != '-' ? this.Division : '', null);
            qbCount.addAnd('Employee__r.Division__c', this.Division != '-' ? this.Division : '', null);
        }
       if (this.subDivision != '---') {
            qb.addAnd('Employee__r.Sub_Division__c', this.subDivision != '-' ? this.subDivision : '', null);
            qbCount.addAnd('Employee__r.Sub_Division__c', this.subDivision != '-' ? this.subDivision : '', null);
        }

        qb.addAnd('Year__c', '' + this.fteYear, QueryBuilder.QB_DECIMAL_TYPE);
        qbCount.addAnd('Year__c', '' + this.fteYear, QueryBuilder.QB_DECIMAL_TYPE);

        qb.orderBy('Total_Hours__c', QueryBuilder.QB_DESC); //Total_Hours__c
        system.debug('pagesize' +this.employeePagination.pageSize);
        if(isDisplay == true) {
            qb.setLimit(this.employeePagination.pageSize);
            qb.setOffset(this.employeePagination.getOffsetValue());
        }
     
        testQuery = qb.buildQuery();
        testQueryCount = qbCount.buildQuery();
        workCards = Database.query(qb.buildQuery());
        system.debug('testQuery' + testQuery);
       
        this.employeePagination.handleResulSize(Database.countQuery(qbCount.buildQuery()));
        calculateEmployeeTime(workCards);
        for (FTEEmployeeTime empT : this.employeeTimeMap.values()) {
            empT.calculateDays();
           employeeList.add(empT);
        }
       system.debug('size' + employeeList.size());
       return employeeList;
   }
    

    public List<FTEEmployeeTime> EmployeesList() {
        system.debug('Querylist');
        List<FTEEmployeeTime> list_employees = new list<FTEEmployeeTime>();
        list_employees = queryEmployeeList('FTE_Work_Card__c', true);
        return list_employees; 
    }
    
    public void renderOnpageSize(){
        this.employeeTimeMap.clear();
        this.employees = EmployeesList();
        
    }
    
    public void calculateEmployeeTime(List<FTE_Work_Card__c> workCards){
        try{
            for (FTE_Work_Card__c workCard : workCards) {
                FTEEmployeeTime tmpHelper;
                if (!this.employeeTimeMap.containsKey(workCard.Employee__c)) {
                    system.debug(workCard.employee__r.Hire_Date__c);
                    system.debug(workCard.employee__r.Termination_Date__c);
                    this.employeeTimeMap.put(workCard.Employee__c, new FTEEmployeeTime(workCard.employee__r.name, workCard.Employee__c, workCard.employee__r.Hire_Date__c, workCard.employee__r.Termination_Date__c,false));
                }
                tmpHelper = this.employeeTimeMap.get(workCard.Employee__c);
                
                for(Integer i=1; i< tmpHelper.hoursArray.size(); i++){
                    tmpHelper.hoursArray[i-1] += (Decimal) workCard.get('month_'+ i + '__c') * 8;
                }
				tmpHelper.hoursArray[12] += workCard.Total__c * 8;
            }
        }
        catch(Exception e){
            System.debug(e.getMessage()+'------'+ e.getLineNumber());
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
         this.employeePagination.pageNumber = 1;
         this.employeeTimeMap.clear();
         this.employees = EmployeesList();
    }

    public void goToPreviousPage(){
         this.employeePagination.pageNumber -= 1;
         this.employeeTimeMap.clear();
         this.employees = EmployeesList();
        
    }

    public void goToNextPage(){
         this.employeePagination.pageNumber += 1;
         this.employeeTimeMap.clear();
         this.employees = EmployeesList();
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