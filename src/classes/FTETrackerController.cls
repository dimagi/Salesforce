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
        qb.addColumns(new List<String> { 'Id', 'Employee__c', 'Employee__r.Hire_Date__c', 'Employee__r.Name', 'Total__c', 'Total_Hours__c',
                                         'Year__c', 'Month_1__c', 'Month_2__c', 'Month_3__c', 'Month_4__c', 'Month_5__c', 'Month_6__c',
                                         'Month_7__c', 'Month_8__c', 'Month_9__c', 'Month_10__c', 'Month_11__c', 'Month_12__c',
                                         'Month_Future_1__c', 'Month_Future_2__c', 'Month_Future_3__c', 'Month_Future_4__c', 'Month_Future_5__c', 'Month_Future_6__c',
                                         'Month_Future_7__c', 'Month_Future_8__c', 'Month_Future_9__c', 'Month_Future_10__c', 'Month_Future_11__c', 'Month_Future_12__c',
                                         'Month_Blocked_1__c', 'Month_Blocked_2__c', 'Month_Blocked_3__c', 'Month_Blocked_4__c', 'Month_Blocked_5__c', 'Month_Blocked_6__c',
                                         'Month_Blocked_7__c', 'Month_Blocked_8__c', 'Month_Blocked_9__c', 'Month_Blocked_10__c', 'Month_Blocked_11__c', 'Month_Blocked_12__c'
                                         });
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
            SObject sObj = (SObject) workCard;

            Boolean wasFuture = false;
            Boolean wasBlocked = false;

            for (Integer month = 1; month <= 12; month++) {
                Boolean futureValue = (Boolean) sObj.get(FTETrackerHelper.getFieldTemplateFutureName(month));
                Boolean blockedValue = (Boolean) sObj.get(FTETrackerHelper.getFieldTemplateBlockedName(month));
                Decimal realValue = (Decimal) sObj.get(FTETrackerHelper.getFieldName(month));
                empTime.daysArray[month - 1] = realValue;
                if (empTime.daysArray[month - 1] > 21) {
                    empTime.cssStyle[month - 1] = empTime.cssStyle[month - 1] + ' overbilled';
                }
                if (futureValue == true) {
                    wasFuture = true;
                    empTime.cssStyle[month - 1] = empTime.cssStyle[month - 1] + ' future';
                } else if (blockedValue == true) {
                    wasBlocked = true;
                    empTime.cssStyle[month - 1] = empTime.cssStyle[month - 1] + ' blocked';
                }
            }

            empTime.daysArray[12] = workCard.Total__c;
            if (workCard.Total__c > empNetworkDays) {
                empTime.cssStyle[12] = 'fteCell overbilled';
            }
            if (wasFuture == true) {
                empTime.cssStyle[12] = empTime.cssStyle[12] + ' future';
            } else if (wasBlocked == true) {
                empTime.cssStyle[12] = empTime.cssStyle[12] + ' blocked';
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