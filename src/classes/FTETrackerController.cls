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

    public FTETrackerController () {
        Date currentDate = Date.today();
        this.yearBegin = Date.newInstance(currentDate.year(), 1, 1);
        this.yearEnd = Date.newInstance(currentDate.year(), 12, 31);
        this.currentYear = currentDate.year();
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
        }

        public void calculateDays(SFDC_Employee__c emp) {
            for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
                this.daysArray[i] = roundtoDays(this.hoursArray[i]);
            }
            this.daysArray[13] = (this.hoursArray[12] * emp.Unloaded_Daily_Rate__c).setScale(2);
        }

        public void sumHours(EmployeeTime empTime) {
            for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
                this.hoursArray[i] += empTime.hoursArray[i];
            }
        }

        public Decimal roundtoDays(Decimal hours) {
            Decimal totalDays = (hours / 8.0).intValue();
            Decimal restValue = hours - (totalDays * 8);
            return totalDays + (0.25 * (restValue / 2.0).setScale(0, System.RoundingMode.HALF_UP));
        }
    }

    /**
     * Project List View
     */
    public List<DContract__c> fteContractList { get; set;}
    public List<DContract__c> fteContractSearchList { get; set;}
    public String searchError { get; set;}
    public String seachProjectName { get; set;}

    public void loadContractList() {
       this.fteContractList = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c
                                                 WHERE FTE_Tracker__c = 'Yes' ORDER BY Name];
       this.seachProjectName = '';
       this.searchError = '';
       this.fteContractSearchList = new List<DContract__c>();
    }

    public void searchProject() {
        if (this.seachProjectName != null && this.seachProjectName != '') {
            String soql = 'SELECT Id, Name, Status__c FROM DContract__c WHERE FTE_Tracker__c != \'Yes\'';
            soql += ' AND Name LIKE \'' + String.escapeSingleQuotes(seachProjectName) + '%\'';
            soql += ' LIMIT 20';
            System.debug('Final query: ' + soql);
            this.fteContractSearchList = Database.query(soql);
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
            List<DContract__c> recordsFromDb = [SELECT Id, FTE_Tracker__c FROM DContract__c WHERE Id =: this.contractId];
            if (recordsFromDb.size() > 0) {
                DContract__c toUpdate = recordsFromDb.get(0);
                toUpdate.FTE_Tracker__c = 'Yes';
                try {
                    update toUpdate;
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot add project to FTE Tracker: '
                                                                                            +  e.getMessage()));
                }
                loadContractList();
            }
        }
        this.contractId = null;
    }

    public void removeProjectFromFteTracker() {
        if (this.contractId != null) {
            List<DContract__c> recordsFromDb = [SELECT Id, FTE_Tracker__c FROM DContract__c WHERE Id =: this.contractId];
            if (recordsFromDb.size() > 0) {
                DContract__c toUpdate = recordsFromDb.get(0);
                toUpdate.FTE_Tracker__c = 'No';
                try {
                    update toUpdate;
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot remove project from FTE Tracker: '
                                                                                            +  e.getMessage()));
                }
                loadContractList();
            }
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
            projectTimeMap.put(timeCard.Employee__c, tmpHelper);
        }
        this.individualContractDataList = projectTimeMap.values();
        Map<Id, SFDC_Employee__c> empMap = new Map<Id, SFDC_Employee__c>([SELECT Id, Name, Unloaded_Daily_Rate__c 
                        FROM SFDC_Employee__c WHERE Id IN: projectTimeMap.keySet()]);
        for (EmployeeTime empT : this.individualContractDataList) {
            empT.calculateDays(empMap.get(empT.objId));
            totalProjectTime.daysArray[13] += empT.daysArray[13];
            totalProjectTime.sumHours(empT);
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

    public void loadEmployeeListTimeHistory() {
       this.employees = new List<EmployeeTime>();
       List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
                                           Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                           Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c ORDER BY Employee__r.Name];
       for (FTE_Work_Card__c workCard : workCards) {
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
           if (workCard.Total__c > 230) {
               empTime.cssStyle[12] = 'fteCell overbilled';
           }
           for (Integer i = 0; i < 12; i++) {
               if (empTime.daysArray[i] > 21) {
                   empTime.cssStyle[i] = 'fteCell overbilled';
               }
           }
           empTime.daysArray[13] = (workCard.Total_Hours__c * workCard.Employee__r.Unloaded_Daily_Rate__c).setScale(2);
           this.employees.add(empTime);
       }
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

    public void loadEmployeeTimeHistory() {
        // Load employee logged time this year
        this.employee = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
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

            // "Moved from" partthis.contractsTime.add(this.unassigned);
            calculateLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.month());
            // If no FTE Tag values we don't need to process moved hours
            if (timeCard.FTE_Contract__c == null || movedTime == 0) {
                continue;
            }
            // "Moved to" part
            calculateLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.month());
        }

        this.contractsTime = new List<EmployeeTime>();
        if (this.assignedMap.size() > 0) {
            this.contractsTime = this.assignedMap.values();
            this.totalAssignedDays = new EmployeeTime('Total Assigned Days', null);
            this.totalDaysWorked = new EmployeeTime('Total Days Worked', null);
            generateStyles();
            this.contractsTime.add(this.unassigned);
            this.contractsTime.add(this.totalAssignedDays);
            this.contractsTime.add(this.totalDaysWorked);
        }
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

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month) {
        EmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper = this.unassignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
        }
    }

    private void generateStyles() {
        // Calculate totals and labor cost
        for (EmployeeTime empT : this.contractsTime) {
            empT.calculateDays(employee);
            this.totalAssignedDays.sumHours(empT);
            this.totalDaysWorked.sumHours(empT);
        }

        this.unassigned.calculateDays(employee);
        this.totalAssignedDays.calculateDays(employee);

        // We add css classes here to avoid complex if sections in visualgforce page
        for (Integer i = 0; i < 12; i++) {
            if (this.totalAssignedDays.daysArray[i] > 21) {
                this.totalAssignedDays.cssStyle[i] = 'topTotal overbilled';
            } else {
                this.totalAssignedDays.cssStyle[i] = 'topTotal';
            }
            this.totalDaysWorked.cssStyle[i] = '';
        }
        if (totalAssignedDays.daysArray[12] > 230) { // todo network days
            this.totalAssignedDays.cssStyle[12] = 'topTotal overbilled';
        } else {
            this.totalAssignedDays.cssStyle[12] = 'topTotal';
        }
        this.totalAssignedDays.cssStyle[13] = 'topTotal';
        this.totalDaysWorked.sumHours(this.unassigned);
        this.totalDaysWorked.calculateDays(employee);
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
        this.notValidDays = true;
        this.fteDays = '0.25';
        this.userAvailableDays = 0;

        if (this.employeeMonth != null) {
            this.fteDaysMax = unassigned.daysArray[this.employeeMonth];
            this.fteHoursMax = unassigned.hoursArray[this.employeeMonth];
            this.monthName = DateTime.newInstance(this.currentYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
            this.userAvailableDays = 21 - this.totalAssignedDays.daysArray[this.employeeMonth] > 0 ? 21 -
                                            this.totalAssignedDays.daysArray[this.employeeMonth] : 0;
            //TODO network days
            Decimal helperDecimal = 230 - this.totalAssignedDays.daysArray[12] > 0 ? 230 - this.totalAssignedDays.daysArray[12] : 0;
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

            // If we already have tag from assigned we want take more hours from that tag, we need only one time card we can move hours to one contract
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__c =: this.contractId AND FTE_Contract__c != null
                                                AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c = '')
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Time 1 cards: ' + timeCardsFromDB.size()));

                if (timeCardsFromDB.size() > 0) {
                    Time_Card__c tc = timeCardsFromDB.get(0);
                    tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + hoursToUnassign : hoursToUnassign;
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
                }
            }

            // If we don't have any tag we need add new one in time card
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

            Set<Id> emptyContracts = new Set<Id>();
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

    private Integer getContractIndex() {
        Integer upperLimit = this.unassignedMap.size();
        if (upperLimit == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find unassigned contract'));
            return 0;
        }
        Integer rand = Math.round(Math.random()*1000);
        return Math.mod(rand, upperLimit);
    }

    public void removeAllTags() {
        List<Time_Card__c> tagsTC = [SELECT Id, FTE_Contract__c, FTE_hours__c, FTE_only__c FROM Time_Card__c
                                     WHERE (FTE_Contract__c != null AND FTE_Contract__c != '') OR FTE_hours__c > 0];
        List<Time_Card__c> toUpdate = new List<Time_Card__c>();
        List<Time_Card__c> toRemove = new List<Time_Card__c>();

        for (Time_Card__c tc : tagsTC) {
            if (tc.FTE_only__c == true) {
                toRemove.add(tc);
            } else {
                tc.FTE_hours__c = 0;
                tc.FTE_Contract__c = null;
                toUpdate.add(tc);
            }
        }

        if (toRemove.size() > 0) {
            delete toRemove;
        }
        if (toUpdate.size() > 0) {
            update toUpdate;
        }
        loadEmployeeTimeHistory();
    }
}