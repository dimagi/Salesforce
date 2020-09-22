/**
 * Controller for FTE Employee List views.
 */
public class FTETrackerController extends FTEController {

    public Integer fteYear { get; set;}
    public Id employeeId { get; set;}
    public List<FTEEmployeeTime> employees { get; set;}
    public String employeeNameSearch { get; set;}
    public Pagination employeePagination { get; set;}
    public String emplDepartment { get; set; }
    public Map<Id, FTEEmployeeTime> employeeTimeMap { get; set;}
    public List<SelectOption> departmentList {
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
    }

    public FTETrackerController () {
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        this.employeePagination = new Pagination();
        this.employeePagination.pageSize = 50;
        this.emplDepartment = '---';
        this.emplBusinessUnit = '---';
        this.employeeTimeMap = new Map<Id, FTEEmployeeTime>();
    }

    public String testQuery { get; set; }
    public String testQueryCount { get; set; }

    public List<FTEEmployeeTime> getEmployeesList() {
        this.employees = new List<FTEEmployeeTime>();
        List<FTE_Work_Card__c> workCards = null;

        QueryBuilder qb = new QueryBuilder('FTE_Work_Card__c');
        QueryBuilder qbCount = new QueryBuilder('FTE_Work_Card__c');
        qb.addColumns(new List<String> { 'Id', 'Employee__c', 'Employee__r.Hire_Date__c', 'Employee__r.Name', 'Month_1__c', 'Month_2__c', 'Month_3__c',
                                         'Month_4__c', 'Month_5__c', 'Month_6__c', 'Month_7__c', 'Month_8__c', 'Month_9__c', 'Month_10__c', 'Month_11__c',
                                         'Month_12__c', 'Total__c', 'Total_Hours__c', 'Year__c'});
        qbCount.addColumn('count()');

        if (this.employeeNameSearch != null && this.employeeNameSearch != '') {
            qb.addLike('Employee__r.Name', ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%'));
            qbCount.addLike('Employee__r.Name', ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%'));
        }

        if (this.emplBusinessUnit != '---') {
            qb.addAnd('Employee__r.Business_Unit__c', this.emplBusinessUnit != '-' ? this.emplBusinessUnit : '', null);
            qbCount.addAnd('Employee__r.Business_Unit__c', this.emplBusinessUnit != '-' ? this.emplBusinessUnit : '', null);
        }

        if (this.emplDepartment != '---') {
            qb.addAnd('Employee__r.Sub_Unit__c', this.emplDepartment != '-' ? this.emplDepartment : '', null);
            qbCount.addAnd('Employee__r.Sub_Unit__c', this.emplDepartment != '-' ? this.emplDepartment : '', null);
        }

        qb.addAnd('Year__c', '' + this.fteYear, QueryBuilder.QB_DECIMAL_TYPE);
        qbCount.addAnd('Year__c', '' + this.fteYear, QueryBuilder.QB_DECIMAL_TYPE);

        qb.orderBy('Total_Hours__c', QueryBuilder.QB_DESC);
        qb.setLimit(this.employeePagination.pageSize);
        qb.setOffset(this.employeePagination.getOffsetValue());

        testQuery = qb.buildQuery();
        testQueryCount = qbCount.buildQuery();
        workCards = Database.query(qb.buildQuery());
        this.employeePagination.handleResulSize(Database.countQuery(qbCount.buildQuery()));
        calculateEmployeeTime(workCards);
        for (FTEEmployeeTime empT : this.employeeTimeMap.values()) {
            empT.calculateDays();
            this.employees.add(empT);
        }
        return this.employees;
    }
    
    public void calculateEmployeeTime(List<FTE_Work_Card__c> workCards){
        try{
            for (FTE_Work_Card__c workCard : workCards) {
                FTEEmployeeTime tmpHelper;
                if (!this.employeeTimeMap.containsKey(workCard.Employee__c)) {
                    this.employeeTimeMap.put(workCard.Employee__c, new FTEEmployeeTime(workCard.employee__r.name, workCard.Employee__c, false));
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

     public void searchEmplopyee() {
         this.employeePagination.pageNumber = 1;
         this.employeeTimeMap.clear();
    }

    public void goToPreviousPage(){
         this.employeePagination.pageNumber -= 1;
         this.employeeTimeMap.clear();
    }

    public void goToNextPage(){
         this.employeePagination.pageNumber += 1;
         this.employeeTimeMap.clear();
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