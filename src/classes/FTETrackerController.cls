/**
 * Controller for FTE Employee List views.
 */
public class FTETrackerController {

    public Integer fteYear { get; set;}
    public Id employeeId { get; set;}
    public JobWrapper workCardJobStatus {get; set;}
    public List<FTEEmployeeTime> employees { get; set;}
    public String employeeNameSearch { get; set;}
    public Pagination employeePagination { get; set;}

    public FTETrackerController () {
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        this.employeePagination = new Pagination();
        this.employeePagination.pageSize = 50;
    }

    public void initEmployeeListView() {
        loadWorkCardJobStatus();

        if (workCardJobStatus.isRunning) {
            return;
        }
    }

    public List<FTEEmployeeTime> getEmployeesList() {
        this.employees = new List<FTEEmployeeTime>();

        List<FTE_Work_Card__c> workCards = null;
        if (this.employeeNameSearch != null && this.employeeNameSearch != '') {
            workCards = [SELECT Id, Employee__c, Employee__r.Hire_Date__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Employee__r.Name LIKE: ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%')
                AND Year__c =: this.fteYear ORDER BY Total_Hours__c DESC LIMIT: this.employeePagination.pageSize OFFSET: this.employeePagination.getOffsetValue()];
            this.employeePagination.handleResulSize([SELECT count() FROM FTE_Work_Card__c WHERE Year__c =: this.fteYear
                                                     AND Employee__r.Name LIKE: ('%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%')]);
        } else {
            workCards = [SELECT Id, Employee__c, Employee__r.Hire_Date__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: this.fteYear
                ORDER BY Total_Hours__c DESC LIMIT: this.employeePagination.pageSize OFFSET: this.employeePagination.getOffsetValue()];
            this.employeePagination.handleResulSize([SELECT count() FROM FTE_Work_Card__c WHERE Year__c =: this.fteYear]);
        }

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

    public PageReference goToProjectListView() {
        return Page.FTE_Project_List_View;
    }

    public PageReference goToCSVUploadView() {
        return Page.FTE_CSV_Upload;
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageRef;
    }

    public List<SelectOption> getYearsData() {
        return FTETrackerHelper.getYearsData();
    }

    public void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }
}