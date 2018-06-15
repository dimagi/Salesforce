/**
 * Controller for FTE Tracker views.
 */
public class FTETrackerController {

    public Integer currentYear { get; set;}
    public Id employeeId { get; set;}
    public JobWrapper workCardJobStatus {get; set;}
    public List<FTEEmployeeTime> employees { get; set;}
    public Integer resultSize { get; set;}
    public Integer pageSize { get; set;}
    public Integer pageNumber { get; set;}
    public Boolean hasPrevious { get; set;}
    public Boolean hasNext { get; set;}
    public String employeeNameSearch { get; set;}

    public FTETrackerController () {
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.currentYear = Integer.valueOf(yearString);
        } else {
            this.currentYear = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year();
        }
    }

    public void initEmployeeListView() {
        loadWorkCardJobStatus();

        if (workCardJobStatus.isRunning) {
            return;
        }

        if (this.pageNumber == null) {
            this.pageNumber = 1;
            this.resultSize = 0;
            this.pageSize = 10;
            this.hasPrevious = true;
            this.hasNext = true;
        }
    }

    public List<FTEEmployeeTime> getEmployeesList() {
        this.employees = new List<FTEEmployeeTime>();
        this.hasPrevious = true;
        this.hasNext = true;
        Integer offsetValue = ((this.pageNumber - 1) * this.pageSize);

        String soqlQuery = 'SELECT Id, Employee__c, Employee__r.Hire_Date__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,'
                                + ' Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,'
                                + ' Total__c, Total_Hours__c, Year__c, Unloaded_Rate_Total_Cost__c'
                                + ' FROM FTE_Work_Card__c'
                                + (this.employeeNameSearch != null && this.employeeNameSearch != '' ? ' WHERE Employee__r.Name LIKE \'%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%\'' : '')
                                + ' ORDER BY Employee__r.Name LIMIT : pageSize OFFSET : offsetValue';
        List<FTE_Work_Card__c> workCards = Database.query(soqlQuery);
        this.resultSize = Database.countQuery('SELECT count() FROM FTE_Work_Card__c' + (this.employeeNameSearch != null && this.employeeNameSearch != '' ? ' WHERE Employee__r.Name LIKE \'%' + String.escapeSingleQuotes(this.employeeNameSearch) + '%\'' : ''));

        if (pageNumber == 1) {
            this.HasPrevious = false;
        }
        if (offsetValue + this.pageSize >= this.resultSize) {
            this.HasNext = false;
        }

        for (FTE_Work_Card__c workCard : workCards) {
            Integer empNetworkDays = FTETrackerHelper.getNetworkDays(workCard.Employee__r.Hire_Date__c, this.currentYear);
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
            empTime.daysArray[13] = (workCard.Unloaded_Rate_Total_Cost__c != null ? workCard.Unloaded_Rate_Total_Cost__c : 0.00).setScale(2);
            this.employees.add(empTime);
        }

        return this.employees;
    }

    public void searchEmplopyee() {
        this.pageNumber = 1;
    }

    public void previousPage() {
        this.pageNumber--;
    }

    public void nextPage() {
        this.pageNumber++;
    }

    public void updatePageNumber() {
        this.pageNumber = 1;
    }

    public PageReference goToProjectListView() {
        return Page.FTE_Project_List_View;
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.currentYear));
        return pageRef;
    }

    public void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }
}