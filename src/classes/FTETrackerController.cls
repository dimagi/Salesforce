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

        for (FTE_Work_Card__c workCard : workCards) {
            Integer empNetworkDays = FTETrackerHelper.getNetworkDays(workCard.Employee__r.Hire_Date__c, this.fteYear);
            FTEEmployeeTime empTime = new FTEEmployeeTime(workCard.Employee__r.Name, workCard.Employee__c);
            empTime.daysArray[0] = workCard.Month_1__c;
            empTime.daysArray[1] = workCard.Month_2__c;
            empTime.daysArray[2] = workCard.Month_3__c;
            empTime.daysArray[3] = workCard.Month_4__c;
            empTime.daysArray[4] = workCard.Month_5__c;
            empTime.daysArray[5] = workCard.Month_6__c;
            empTime.daysArray[6] = workCard.Month_7__c;
            empTime.daysArray[7] = workCard.Month_8__c;
            empTime.daysArray[8] = workCard.Month_9__c;
            empTime.daysArray[9] = workCard.Month_10__c;
            empTime.daysArray[10] = workCard.Month_11__c;
            empTime.daysArray[11] = workCard.Month_12__c;
            empTime.daysArray[12] = workCard.Total__c;
            if (workCard.Total__c > empNetworkDays) {
                empTime.cssStyle[12] = 'fteCell overbilled';
            }
            for (Integer i = 0; i < 12; i++) {
                if (empTime.daysArray[i] > 21) {
                    empTime.cssStyle[i] = 'fteCell overbilled';
                }
            }
            this.employees.add(empTime);
        }

        return this.employees;
    }

     public void searchEmplopyee() {
         this.employeePagination.pageNumber = 1;
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