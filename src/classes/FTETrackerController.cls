/**
 * Controller for FTE Tracker views.
 */
public class FTETrackerController {

    public Integer currentYear { get; set;}
    public Date yearBegin { get; set;}
    public Date yearEnd { get; set;}
    public Id contractId { get; set;}
    public Id employeeId { get; set;}
    public String contractName { get; set;}
    public JobWrapper workCardJobStatus {get; set;}

    public FTETrackerController () {
        this.workCardJobStatus = new JobWrapper(false);
        this.currentYear = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year();
        this.yearBegin = Date.newInstance(this.currentYear, 1, 1);
        this.yearEnd = Date.newInstance(this.currentYear, 12, 31);
    }

    public void setViewData() {
        // We need this empty method to set values before loading new view.
    }

    public class EmployeeTime {
        public String name { get; set;}
        public Id objId { get; set;}
        public List<Decimal> hoursArray { get; set;}
        public List<Decimal> daysArray { get; set;}
        public List<String> cssStyle { get; set;}
        public String nameCss { get; set;}

        public EmployeeTime (String name, Id objId) {
            this.name = name;
            this.objId = objId;
            this.hoursArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                                            'fteCell', 'fteCell', '', ''};
            this.nameCss = 'fteProjectCell';
        }

        public void calculateDays() {
            for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
                this.daysArray[i] = roundtoDays(this.hoursArray[i]);
            }
            this.daysArray[13] =  this.daysArray[13].setScale(2);
        }

        public void sumHoursAndCost(EmployeeTime empTime) {
            for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
                this.hoursArray[i] += empTime.hoursArray[i];
            }
            this.daysArray[13] += empTime.daysArray[13];
        }

        public Decimal roundtoDays(Decimal hours) {
            Decimal totalDays = (hours / 8.0).intValue();
            Decimal restValue = hours - (totalDays * 8);
            return totalDays + (0.25 * (restValue / 2.0).setScale(0, System.RoundingMode.HALF_UP));
        }
    }

    public void loadWorkCardJobStatus() { // We want block FTE Tracker until all Work Cards will be generated from time cards
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name='FTEGenerateEmployeesWorkCardBatch' LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            workCardJobStatus.isRunning = true;
            workCardJobStatus.jobItemsProcessed = batchClassJobList[0].JobItemsProcessed;
            workCardJobStatus.totalJobItems = batchClassJobList[0].TotalJobItems;
        } else {
            workCardJobStatus.isRunning = false;
        }
    }

    /**
     * Project List View
     */
    public List<DContract__c> fteContractList { get; set;}
    public List<DContract__c> fteContractSearchList { get; set;}

    public List<DContract__c> finalFteContracts {get; set;}
    public List<DContract__c> toAddContracts {get; set;}
    public List<DContract__c> toRemoveContracts {get; set;}

    public String searchError { get; set;}
    public String seachProjectName { get; set;}
    public Boolean projectListUpdated { get; set;}

    public void loadContractList() {
        this.seachProjectName = '';
        this.searchError = '';
        this.fteContractSearchList = new List<DContract__c>();
        this.toAddContracts = new List<DContract__c>();
        this.toRemoveContracts = new List<DContract__c>();
        this.projectListUpdated = false;

        loadWorkCardJobStatus();

        if (workCardJobStatus.isRunning) {
            return;
        }
    }

    public void updateFteContracts() {
        for (DContract__c dc : this.toAddContracts) {
            dc.FTE_Tracker__c = 'Yes';
        }
        for (DContract__c dc : this.toRemoveContracts) {
            dc.FTE_Tracker__c = 'No';
        }
        List<DContract__c> forUpdate = new List<DContract__c>();
        forUpdate.addAll(this.toAddContracts);
        forUpdate.addAll(this.toRemoveContracts);
        if (forUpdate.size() > 0) {
            update forUpdate;
        }
        this.toAddContracts.clear();
        this.toRemoveContracts.clear();
        this.projectListUpdated = false;
        loadWorkCardJobStatus();
    }

    public List<DContract__c> getListToSubmit() {
        if (this.fteContractList == null) {
           this.fteContractList = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c
                                                 WHERE FTE_Tracker__c = 'Yes' ORDER BY Name];
        }

        return this.fteContractList;
    }

    public void searchProject() {
        if (this.seachProjectName != null && this.seachProjectName != '') {
            String seachProjectNameExpr = seachProjectName + '%';
            this.fteContractSearchList = [SELECT Id, Name, Status__c FROM DContract__c WHERE Id NOT IN : this.fteContractList
                    AND Name LIKE: seachProjectNameExpr LIMIT 20];

            if(this.fteContractSearchList.size() == 0) {
                this.searchError = 'No projects were found.';
            } else {
                this.searchError = '';
            }
        } else {
            this.fteContractSearchList.clear();
            this.searchError = 'Name cannot be empty';
        }
    }

    public void addProjectToFteTracker() {
        if (this.contractId != null) {
            List<DContract__c> recordsFromDb = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c WHERE Id =: this.contractId];
            if (recordsFromDb.size() > 0) {
                DContract__c newFteContract = recordsFromDb.get(0);
                Boolean aleradyAdded = false;
                for (DContract__c cc : fteContractList) {
                    if (cc.Id == newFteContract.Id) {
                        aleradyAdded = true;
                        break;
                    }
                }
                if (!aleradyAdded) {
                    this.fteContractList.add(newFteContract);
                    this.toAddContracts.add(newFteContract);
                }

                //check removed list
                Integer index = -1;
                for (Integer i = 0 ; i < this.toRemoveContracts.size(); i++) {
                    if (this.toRemoveContracts.get(i).Id == this.contractId) {
                        index = i;
                        break;
                    }
                }
                if (index > -1) {
                    this.toRemoveContracts.remove(index);
                }
            }
            this.projectListUpdated = true;
        }
        this.contractId = null;
    }

    public void removeProjectFromFteTracker() {
        if (this.contractId != null) {
            Integer index = -1;
            for (Integer i = 0; i < fteContractList.size(); i++) {
                if (fteContractList.get(i).Id == this.contractId) {
                    index = i;
                    break;
                }
            }
            if (index > -1) {
                DContract__c contractToRem = fteContractList.get(index);
                fteContractList.remove(index);
                this.toRemoveContracts.add(contractToRem);
            }

            //check added list
            index = -1;
            for (Integer i = 0 ; i < this.toAddContracts.size(); i++) {
                if (this.toAddContracts.get(i).Id == this.contractId) {
                    index = i;
                    break;
                }
            }
            if (index > -1) {
                this.toAddContracts.remove(index);
            }
            this.projectListUpdated = true;
        }
        this.contractId = null;
    }

    public PageReference goToEmployeeListViewFromProjectListView() {
        PageReference pageRef = Page.FTE_Employee_List_View;
        pageRef.setRedirect(false);
        clearProjectListViewData();
        return pageRef;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = null;
        if (String.isBlank(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Contract ID'));
        } else {
            clearProjectListViewData();
            pageRef = Page.FTE_Individual_Project_View;
            pageRef.setRedirect(false);
        }

        return pageRef;
    }

    private void clearProjectListViewData() {
        this.fteContractList = null;
        this.fteContractSearchList = null;
        this.searchError = '';
        this.seachProjectName = '';
    }

    /**
     * Individual Project View
     */

    public List<EmployeeTime> individualContractDataList { get; set;}

    public void loadIndividualProject() {
        this.individualContractDataList = new List<EmployeeTime>();
        if (this.contractId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Contract ID'));
            return;
        }

        List<DContract__c> contractList = [SELECT Id, Name FROM DContract__c WHERE Id =: this.contractId];
        if (contractList.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load FTE Contract'));
            return;
        }

        this.contractName = contractList.get(0).Name;
        Map<Id, EmployeeTime> projectTimeMap = new Map<Id, EmployeeTime>();

        Date currentDate = Date.today();
        Integer currentMonth = currentDate.month();
        Integer currentYear = currentDate.year();
        Integer oneMonthAgo = currentDate.addMonths(-1).month();
        Integer oneMonthAgoYear = currentDate.addMonths(-1).year();
        Integer twoMonthAgo = currentDate.addMonths(-2).month();
        Integer twoMonthAgoYear = currentDate.addMonths(-2).year();
        Integer threeMonthAgo = currentDate.addMonths(-3).month();
        Integer threeMonthAgoYear = currentDate.addMonths(-3).year();

        Decimal totalHours = 0;
        Decimal totalCost = 0;

        List<Time_Card__c> contractTimeCards = [SELECT Id, Employee__c, Employee__r.Name, Date__c, Total__c, FTE_hours__c, FTE_Contract__c FROM Time_Card__c WHERE
                                                (Client__c =: this.contractId OR FTE_Contract__c =: this.contractId) AND Date__c <=: Date.today()];

        EmployeeTime totalProjectTime = new EmployeeTime('Total', null);
        for (Time_Card__c timeCard : contractTimeCards) {
            EmployeeTime tmpHelper;
            if (projectTimeMap.containsKey(timeCard.Employee__c)) {
                tmpHelper = projectTimeMap.get(timeCard.Employee__c);
            } else {
                tmpHelper = new EmployeeTime(timeCard.Employee__r.Name, timeCard.Employee__c);
            }

            Date entryDate = timeCard.Date__c != null ? timeCard.Date__c : Date.today();
            Integer entryDateMonth = timeCard.Date__c != null ? timeCard.Date__c.month() : 0;
            Integer entryDateYear = timeCard.Date__c != null ? timeCard.Date__c.year() : 0;

            Decimal realHours = timeCard.Total__c != null ? timeCard.Total__c : 0;
            if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c != this.contractId) {
                realHours = realHours - timeCard.FTE_hours__c;
            } else if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c == this.contractId) {
                realHours = timeCard.FTE_hours__c;
            }

            if (entryDateMonth == currentMonth && entryDateYear == currentYear) {
                tmpHelper.hoursArray[0] += realHours;
            } else if(entryDateMonth == oneMonthAgo && entryDateYear == oneMonthAgoYear ){
                tmpHelper.hoursArray[1] += realHours;
            } else if(entryDateMonth == twoMonthAgo && entryDateYear == twoMonthAgoYear ) {
                tmpHelper.hoursArray[2] += realHours;
            } else if(entryDateMonth == threeMonthAgo && entryDateYear == threeMonthAgoYear ) {
                tmpHelper.hoursArray[3] += realHours;
            } else {
                tmpHelper.hoursArray[4] += realHours;
            }
            tmpHelper.hoursArray[12] += realHours;
            tmpHelper.daysArray[13] += (timeCard.Total__c != null ? timeCard.Total__c : 0) * (timeCard.Time_Card_Salary__c != null ? timeCard.Time_Card_Salary__c : 0);
            projectTimeMap.put(timeCard.Employee__c, tmpHelper);
        }
        this.individualContractDataList = projectTimeMap.values();
        Map<Id, SFDC_Employee__c> empMap = new Map<Id, SFDC_Employee__c>([SELECT Id, Name, Unloaded_Daily_Rate__c 
                        FROM SFDC_Employee__c WHERE Id IN: projectTimeMap.keySet()]);
        for (EmployeeTime empT : this.individualContractDataList) {
            empT.calculateDays();
            totalProjectTime.sumHoursAndCost(empT);
        }
        totalProjectTime.calculateDays();
        totalProjectTime.cssStyle[0] = 'topTotal';
        totalProjectTime.cssStyle[1] = 'topTotal';
        totalProjectTime.cssStyle[2] = 'topTotal';
        totalProjectTime.cssStyle[3] = 'topTotal';
        totalProjectTime.cssStyle[4] = 'topTotal';
        totalProjectTime.cssStyle[12] = 'topTotal';
        totalProjectTime.cssStyle[13] = 'topTotal';
        totalProjectTime.nameCss = 'topTotal';
        this.individualContractDataList.add(totalProjectTime);
    }

    public PageReference goToEmployeeViewFromProjectView() {
        PageReference pageRef = null;
        if (String.isBlank(this.employeeId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Employee ID'));
        } else {
            clearProjectIndividualData();
            pageRef = Page.FTE_Employee_View;
            pageRef.setRedirect(false);
        }

        return pageRef;
    }

    public PageReference goToProjectListViewFromProjectView() {
        clearProjectIndividualData();
        PageReference pageRef = Page.FTE_Project_List_View;
        pageRef.setRedirect(false);

        return pageRef;
    }

    private void clearProjectIndividualData() {
        this.individualContractDataList = null;
        this.contractId = null;
        this.contractName = '';
    }

    /**
     * Employee List View
     */
    public List<EmployeeTime> employees { get; set;}
    public Integer resultSize { get; set;}
    public Integer pageSize { get; set;}
    public Integer pageNumber { get; set;}
    public Boolean hasPrevious { get; set;}
    public Boolean hasNext { get; set;}

    public void loadEmployeeListTimeHistory() {
        loadWorkCardJobStatus();

        if (workCardJobStatus.isRunning) {
            return;
        }

        if (this.pageNumber == null) { // new open - initiate variables
            this.pageNumber = 1;
            this.resultSize = 0;
            this.pageSize = 10;
            this.hasPrevious = true;
            this.hasNext = true;
        }
    }

    public List<EmployeeTime> getEmployeesList() {
        this.employees = new List<EmployeeTime>();
        this.hasPrevious = true;
        this.hasNext = true;
        Integer offsetValue = ((this.pageNumber - 1) * this.pageSize);
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Hire_Date__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
                                           Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                           Total__c, Total_Hours__c, Year__c, Unloaded_Rate_Total_Cost__c
                                           FROM FTE_Work_Card__c ORDER BY Employee__r.Name LIMIT : this.pageSize OFFSET : offsetValue];
        this.resultSize = Database.countQuery('SELECT count() FROM FTE_Work_Card__c');
        if (pageNumber == 1) {
            this.HasPrevious = false;
        }
        if (offsetValue + this.pageSize >= this.resultSize) {
            this.HasNext = false;
        }


        for (FTE_Work_Card__c workCard : workCards) {
            Integer empNetworkDays = getNetworkDays(workCard.Employee__r.Hire_Date__c);
            EmployeeTime empTime = new EmployeeTime(workCard.Employee__r.Name, workCard.Employee__c);
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

    public void previousPage() {
        this.pageNumber--;
    }

    public void nextPage() {
        this.pageNumber++;
    }

    public void updatePageNumber() {
        this.pageNumber = 1;
    }

    public PageReference goToProjectListViewFromEmployeeListView() {
        PageReference pageRef = Page.FTE_Project_List_View;
        pageRef.setRedirect(false);
        clearEmployeeListData();
        return pageRef;
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = null;
        if (String.isBlank(this.employeeId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Employee ID'));
        } else {
            pageRef = Page.FTE_Employee_View;
            pageRef.setRedirect(false);
            clearEmployeeListData();
        }

        return pageRef;
    }

    private void clearEmployeeListData() {
        this.employees = null;
    }

    /**
     * Employee view
     */
    public SFDC_Employee__c employee { get; set;}
    public EmployeeTime unassigned { get; set;}
    public EmployeeTime totalAssignedDays { get; set;}
    public EmployeeTime totalDaysWorked { get; set;}
    public Map<Id, EmployeeTime> assignedMap { get; set;}
    public List<EmployeeTime> contractsTime { get; set;}
    public Map<Id, EmployeeTime> unassignedMap { get; set;}

    private Integer employeeNetworkDays = 0;

    public void loadEmployeeTimeHistory() {
        // Load employee logged time this year
        this.employee = [SELECT Id, Name, Unloaded_Daily_Rate__c, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
        this.employeeNetworkDays = getNetworkDays(this.employee.Hire_Date__c);
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Time_Card_Salary__c, Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND Date__c >=: this.yearBegin AND Date__c <=: this.yearEnd
                                        ORDER BY Client__r.Name];

        this.assignedMap = new Map<Id, EmployeeTime>();
        this.unassignedMap = new Map<Id, EmployeeTime>();
        this.unassigned = new EmployeeTime('Unassigned', null);

        EmployeeTime tmpHelper;
        for (Time_Card__c timeCard : timeCards) {
            Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
            Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);

            // "Moved from" part this.contractsTime.add(this.unassigned);
            calculateLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.month(), timeCard.Time_Card_Salary__c);
            // If no FTE Tag values we don't need to process moved hours
            if (timeCard.FTE_Contract__c == null || movedTime == 0) {
                continue;
            }
            // "Moved to" part
            calculateLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.month(), timeCard.Time_Card_Salary__c);
        }

        this.contractsTime = new List<EmployeeTime>();

        this.contractsTime = this.assignedMap.values();
        this.totalAssignedDays = new EmployeeTime('Total Assigned Days', null);
        this.totalDaysWorked = new EmployeeTime('Total Days Worked', null);
        generateStyles();
        this.contractsTime.add(this.unassigned);
        this.contractsTime.add(this.totalAssignedDays);
        this.contractsTime.add(this.totalDaysWorked);

    }

    public PageReference goToAssignView() {
        PageReference pageRef = Page.FTE_Unassign_Days_View;
        if (String.isBlank(this.contractId)) {
            pageRef = Page.FTE_Assign_Days_View;
        }

        pageRef.setRedirect(false);
        return pageRef;
    }

    public PageReference goToEmployeeListViewFromEmployeeView () {
        PageReference pageRef = Page.FTE_Employee_List_View;
        clearEmployeeViewData();
        pageRef.setRedirect(false);
        return pageRef;
    }

    public PageReference goToProjectListViewFromEmployeeView() {
        PageReference pageRef = Page.FTE_Project_List_View;
        clearEmployeeViewData();
        pageRef.setRedirect(false);
        return pageRef;
    }

    public PageReference goToIndividualProjectFromEmplView() {
        PageReference pageRef = null;
        if (String.isBlank(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Contract ID'));
        } else {
            clearEmployeeViewData();
            pageRef = Page.FTE_Individual_Project_View;
            pageRef.setRedirect(false);
        }

        return pageRef;
    }

    public PageReference goToTimeCardView() {
        PageReference pageRef = null;
        if (exportMonth != null) {
            pageRef = Page.FTE_Time_Card_View;
            pageRef.setRedirect(false);
        }
        return pageRef;
    }

    private void clearEmployeeViewData() {
        this.employee = null;
        this.unassigned = null;
        this.totalAssignedDays = null;
        this.totalDaysWorked = null;
        this.assignedMap = null;
        this.contractsTime = null;
        this.unassignedMap = null;
    }

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month, Decimal salary) {
        EmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
            tmpHelper = this.unassignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
        }
    }

    private void generateStyles() {
        // Calculate totals and labor cost
        for (EmployeeTime empT : this.contractsTime) {
            empT.calculateDays();
            this.totalAssignedDays.sumHoursAndCost(empT);
            this.totalDaysWorked.sumHoursAndCost(empT);
        }

        this.unassigned.calculateDays();
        this.totalAssignedDays.calculateDays();

        // We add css classes here to avoid complex if sections in visualgforce page
        for (Integer i = 0; i < 12; i++) {
            if (this.totalAssignedDays.daysArray[i] > 21) {
                this.totalAssignedDays.cssStyle[i] = 'topTotal overbilled';
            } else {
                this.totalAssignedDays.cssStyle[i] = 'topTotal';
            }
            this.totalDaysWorked.cssStyle[i] = '';
        }
        if (totalAssignedDays.daysArray[12] > employeeNetworkDays) {
            this.totalAssignedDays.cssStyle[12] = 'topTotal overbilled';
        } else {
            this.totalAssignedDays.cssStyle[12] = 'topTotal';
        }
        this.totalAssignedDays.cssStyle[13] = 'topTotal';
        this.totalDaysWorked.sumHoursAndCost(this.unassigned);
        this.totalDaysWorked.calculateDays();
        this.totalDaysWorked.nameCss = '';
        this.totalAssignedDays.nameCss = 'topTotal';
        this.unassigned.nameCss = '';
    }

    /**
     * Time Card Generation View
     */

    public Integer exportMonth {get; set;}
    public Integer monthDays {get; set;}
    public List<FTEMonthTimeCard> employeeMonthProjects { get; set;}
    public List<Integer> exportMonthDays {get; set;}
    public String monthYearText {get; set;}

    public void loadExportTimeCards() {
        this.monthDays = Date.daysInMonth(currentYear, this.exportMonth);
        this.exportMonthDays = new List<Integer>();
        this.monthYearText = DateTime.newInstance(currentYear, this.exportMonth, 1).format('MMMM yyyy');
        for (Integer i = 0; i < this.monthDays; i++) {
            this.exportMonthDays.add(i); // We need something to iterate if we want add dynamic columns on UI
        }
        if (exportMonth != null) {
            FTETimeCardGenerator generator = new FTETimeCardGenerator(this.exportMonth, this.employeeId);
            this.employeeMonthProjects = generator.generateMonthTimeCards();
        }
    }

    public PageReference goToEmployeeViewFromTimeCardView() {
        PageReference pageRef = null;
        pageRef = Page.FTE_Employee_View;
        clearTimeCardViewData();
        pageRef.setRedirect(false);
        return pageRef;
    }

    private void clearTimeCardViewData() {
        this.employeeMonthProjects = null;
        this.exportMonthDays = null;
    }

    /**
     * Unassign/Assign hours/days view
     */
    public List<DContract__c> fteContracts { get; set;}
    public List<SelectOption> fteContractsOptions { get;set; }
    public Id selectedFteContract { get; set;}
    public String fteDays { get; set;}
    public Integer employeeMonth { get; set;}
    public Decimal fteHoursMax { get; set;}
    public Decimal fteDaysMax { get; set;}
    public Decimal userAvailableDays { get; set;}
    public Boolean assignViewError { get; set;}
    public Boolean notValidDays {get; set;}
    public String monthName {get; set;}

    public void enableConfirmButton() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Button Enabled'));
        this.notValidDays = false;
    }

    public void disableConfirmButton() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Button Disabled'));
        this.notValidDays = true;
    }

    public void loadEmployeeMonth() {
        this.assignViewError = false;
        this.notValidDays = false;
        this.fteDays = '0.25';
        this.userAvailableDays = 0;

        if (this.employeeMonth != null) {
            this.fteDaysMax = unassigned.daysArray[this.employeeMonth];
            this.fteHoursMax = unassigned.hoursArray[this.employeeMonth];
            this.monthName = DateTime.newInstance(this.currentYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
            this.userAvailableDays = 21 - this.totalAssignedDays.daysArray[this.employeeMonth] > 0 ? 21 -
                                            this.totalAssignedDays.daysArray[this.employeeMonth] : 0;
            Decimal helperDecimal = employeeNetworkDays - this.totalAssignedDays.daysArray[12] > 0 ?
                employeeNetworkDays - this.totalAssignedDays.daysArray[12] : 0;
            this.userAvailableDays = this.userAvailableDays < helperDecimal ? this.userAvailableDays : helperDecimal;
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            this.fteHoursMax = 0;
        }

        this.fteContracts = [SELECT Id, Name FROM DContract__c WHERE FTE_Tracker__c = 'Yes' ORDER BY Name];
        this.fteContractsOptions = new List<SelectOption>();
        for (DContract__c con : this.fteContracts) {
            this.fteContractsOptions.add(new SelectOption(con.Id, con.Name));
        }
    }

    public void loadEmployeeUnassMonth() {
        this.assignViewError = false;
        this.notValidDays = false;
        this.fteDays = '0.25';
        if (this.employeeMonth != null && this.contractId != null) {
            this.contractName = this.assignedMap.get(this.contractId).name;
            this.fteHoursMax = this.assignedMap.get(this.contractId).hoursArray[this.employeeMonth];
            this.fteDaysMax = this.assignedMap.get(this.contractId).daysArray[this.employeeMonth];
            this.monthName = DateTime.newInstance(this.currentYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load contract month'));
            this.assignViewError = true;
            this.fteHoursMax = 0;
        }
    }

    public PageReference moveTimeToUnassigned() {
        if (notValidDays) {
            return null;
        }
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return null;
        }

        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        if (this.fteDaysMax < fteDaysdecimal || fteDaysdecimal < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return null;
        }

        if (String.isEmpty(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return null;
        }

        if (fteDaysdecimal == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return null;
        }

        try {
            Date monthStart = Date.newInstance(this.currentYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.currentYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.currentYear, this.employeeMonth + 1));
            Decimal hoursToUnassign = fteDaysdecimal * 8;
            if (this.fteHoursMax < hoursToUnassign) {
                hoursToUnassign = this.fteHoursMax;
            }
            Boolean stopUpdating = false;

            List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
            List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                        Date__c FROM Time_Card__c
                                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                        AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                        AND FTE_Contract__c =: this.contractId
                                                        AND Date__c >=: monthStart AND Date__c <=: endMonth];

            // If we have moved hours from unassigned to assigned we want take these hours back.
            for (Time_Card__c tc : timeCardsFromDB) {
                Decimal movedHours = tc.FTE_Hours__c;
                Decimal hours = movedHours > hoursToUnassign ? hoursToUnassign : movedHours;
                if (hours > 0) { // we try remove tag from tc
                    tc.FTE_hours__c = tc.FTE_hours__c - hours;
                    hoursToUnassign -= hours;
                    if (tc.FTE_hours__c <= 0) {
                        tc.FTE_Contract__c = null;
                    }
                    timeCardsToUpdate.add(tc);
                    if (hoursToUnassign <= 0) {
                        stopUpdating = true;
                        break;
                    }
                }
            }

            // If we already have tag from assigned we want take more hours from that tag,
            // we need only one time card we can move hours to one contract
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__c =: this.contractId AND FTE_Contract__c != null
                                                AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c = '')
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];

                if (timeCardsFromDB.size() > 0) {
                    Time_Card__c tc = timeCardsFromDB.get(0);
                    tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + hoursToUnassign : hoursToUnassign;
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
                }
            }

            // If we don't have any tag we need add one in time cards
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__c =: this.contractId
                                                AND FTE_Contract__c = null
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];

                if (timeCardsFromDB.size() > 0) {
                    Time_Card__c tc = timeCardsFromDB.get(0);
                    tc.FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].objId;
                    tc.FTE_hours__c = hoursToUnassign;
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
                }
            }

            // If we don't have any empty time card we need create a empty one to move hours 
            if (stopUpdating == false) {
                Time_Card__c tc = new Time_Card__c(Client__c = this.contractId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                       FTE_only__c = true, Total__c = 0, FTE_hours__c = hoursToUnassign,
                                                       FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].objId);
                timeCardsToUpdate.add(tc);
                stopUpdating = true;
            }

            upsert timeCardsToUpdate;
            moveHoursInFTEWorkCard((-1) * fteDaysdecimal, this.employeeMonth + 1, this.employee.Id);

            if (this.assignViewError == false) {
                return backToEmployeeView();
            }
        } catch (Exception e) {
            this.assignViewError = true;
        }

        return null;
    }

    public PageReference moveTimeFromUnassigned() {
        if (notValidDays) {
            return null;
        }
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return null;
        }

        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        if (this.fteDaysMax < fteDaysdecimal || fteDaysdecimal < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return null;
        }

        if (String.isEmpty(this.selectedFteContract)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return null;
        }

        if (fteDaysdecimal == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return null;
        }

        try {
            Date monthStart = Date.newInstance(this.currentYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.currentYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.currentYear, this.employeeMonth + 1));
            Decimal hoursToAssign = fteDaysdecimal * 8;
            if (this.fteHoursMax < hoursToAssign) {
                hoursToAssign = this.fteHoursMax;
            }
            Boolean stopUpdating = false;

            List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
            List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__r.FTE_Tracker__c = 'Yes' AND FTE_Hours__c > 0
                                                AND Client__c =: this.selectedFteContract AND FTE_Contract__c != null
                                                AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c  = '')
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

            Set<Id> emptyContracts = new Set<Id>();
            // If we have moved hours from assigned to unassigned we want take these hours back.
            for (Time_Card__c tc : timeCardsFromDB) {
                Decimal freeHours = this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[this.employeeMonth];
                Decimal movedHours = tc.FTE_Hours__c;
                Decimal hours = movedHours > freeHours ? freeHours : movedHours;
                if (hours > 0) { // we try remove tag from tc
                    Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                    tc.FTE_hours__c = tc.FTE_hours__c - toAssign;
                    hoursToAssign -= toAssign;
                    this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[this.employeeMonth] -= toAssign;
                    if (tc.FTE_hours__c <= 0) {
                        tc.FTE_Contract__c = null;
                    }
                    timeCardsToUpdate.add(tc);
                    if (hoursToAssign <= 0) {
                        stopUpdating = true;
                        break;
                    }
                }
            }

            // If we already have tag from unassigned we want take more hours from that tag
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                AND FTE_Contract__c =: this.selectedFteContract
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

                for (Time_Card__c tc : timeCardsFromDB) {
                    Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[this.employeeMonth];
                    if (hours > 0) { // we try move hours to this client tag
                        Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                        tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                        hoursToAssign -= toAssign;
                        this.unassignedMap.get(tc.Client__c).hoursArray[this.employeeMonth] -= toAssign;
                        timeCardsToUpdate.add(tc);
                        if (hoursToAssign <= 0) {
                            stopUpdating = true;
                            break;
                        }
                        emptyContracts.add(tc.Client__c);
                    } else {
                        emptyContracts.add(tc.Client__c);
                    }
                }
            }

            // if we still need hours we will take time cards without any tag and add tag there
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                AND (FTE_Contract__c = null OR FTE_Contract__c = '') AND Client__c NOT IN: emptyContracts
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

                for (Time_Card__c tc : timeCardsFromDB) {
                    Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[this.employeeMonth];
                    if (hours > 0) {
                        Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                        tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                        tc.FTE_Contract__c = this.selectedFteContract;
                        hoursToAssign -= toAssign;
                        this.unassignedMap.get(tc.Client__c).hoursArray[this.employeeMonth] -= toAssign;
                        timeCardsToUpdate.add(tc);
                        if (hoursToAssign <= 0) {
                            stopUpdating = true;
                            break;
                        }
                        emptyContracts.add(tc.Client__c);
                    } else {
                        emptyContracts.add(tc.Client__c);
                    }
                }
            }

            // If we have available time we need create empty time card with tag
            if (stopUpdating == false) {
                for (Id conId : this.unassignedMap.keySet()) {
                    if (!emptyContracts.contains(contractId)) {
                        Decimal hours = this.unassignedMap.get(conId).hoursArray[this.employeeMonth];
                        if (hours > 0) {
                            Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                            Time_Card__c tc = new Time_Card__c(Client__c = conId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                               FTE_only__c = true, Total__c = 0, FTE_hours__c = toAssign,
                                                               FTE_Contract__c = this.selectedFteContract);
                            hoursToAssign -= toAssign;
                            timeCardsToUpdate.add(tc);
                            if (hoursToAssign <= 0) {
                                stopUpdating = true;
                                break;
                            }
                        }
                    }
                }
            }

            upsert timeCardsToUpdate;
            moveHoursInFTEWorkCard(fteDaysdecimal, this.employeeMonth + 1, this.employee.Id);

            if (this.assignViewError == false) {
                return backToEmployeeView();
            }
        } catch (Exception e) {
            this.assignViewError = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unexpected error: ' + e.getMessage()));
        }
        return null;
    }

    public PageReference backToEmployeeView() {
        clearAssignUnassignViewData();
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.setRedirect(false);
        return pageRef;
    }

    private void moveHoursInFTEWorkCard(Decimal daysValue, Integer month, Id EmployeeId) {
        List<FTE_Work_Card__c> workCards = [SELECT Id, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c,
                            Month_12__c, Total__c, Total_Hours__c FROM FTE_Work_Card__c WHERE Employee__c =: EmployeeId];
        if (workCards.size() > 0) {
            Decimal totalValue = workCards.get(0).Total__c;
            Decimal totalHoursValue = workCards.get(0).Total_Hours__c;
            SObject workCard = workCards.get(0);
            Decimal monthValue = (Decimal) workCard.get('Month_' + month + '__c');

            workCard.put('Total__c', TotalValue + daysValue);
            workCard.put('Total_Hours__c', totalHoursValue + (daysValue * 8));
            workCard.put('Month_' + month + '__c', monthValue + daysValue);
            update workCard;
        }
    }

    private void clearAssignUnassignViewData() {
        this.contractId = null;
        this.fteHoursMax = 0;
        this.employeeMonth = null;
        this.fteContracts = null;
        this.fteContractsOptions = null;
        this.selectedFteContract = null;
        this.fteDays = '';
        this.contractName = null;
        this.fteDaysMax = 0;
        this.userAvailableDays = 0;
        this.assignViewError = false;
        this.notValidDays = false;
        this.monthName = null;
    }

    private Integer getNetworkDays(Date hireDate) {
        if (hireDate != null && hireDate.year() == this.currentYear) {
            return FTETrackerHelper.getWorkingDays(hireDate, Date.newInstance(this.currentYear, 12 ,1));
        }
        return 230;
    }

    private Integer getContractIndex() {
        Integer upperLimit = this.unassignedMap.size();
        if (upperLimit == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find unassigned contract'));
            return 0;
        }
        Integer rand = Math.round(Math.random()*1000);
        return Math.mod(rand, upperLimit);
    }
}