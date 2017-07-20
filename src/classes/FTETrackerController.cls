/**
 * Controller for FTE Tracker views.
 */
public class FTETrackerController {

    public Id testEmployeeId = 'a0Tm0000001h6iy';

    public Integer currentYear { get; set;}
    public Date yearBegin { get; set;}
    public Date yearEnd { get; set;}

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
     * Employee List View
     */

    public List<EmployeeTime> employees { get; set;}

    public void loadEmployeeListTimeHistory() {
       List<SFDC_Employee__c> employeesFromDB = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
       this.employees = new List<EmployeeTime>();
       for (SFDC_Employee__c emp : employeesFromDB) {
           this.employees.add(new EmployeeTime(emp.Name, emp.Id));
       }
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = null;
        if (String.isBlank(this.employeeId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty FTE Contract ID'));
        } else {
            pageRef = Page.FTE_Employee_List_View;
            pageRef.setRedirect(false); 
        }

        return pageRef;
    }

    /**
     * Employee view
     */

    public Id employeeId { get; set;}
    public SFDC_Employee__c employee { get; set;}
    public EmployeeTime unassigned { get; set;}
    public EmployeeTime totalAssignedDays { get; set;}
    public EmployeeTime totalDaysWorked { get; set;}
    public Map<Id, EmployeeTime> assignedMap { get; set;}
    public List<EmployeeTime> contractsTime { get; set;}
    public Map<Id, EmployeeTime> unassignedMap { get; set;}

    public void loadEmployeeTimeHistory() {
        // Load employee logged time this year
        this.employee = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Id =: testEmployeeId LIMIT 1];
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND Date__c >=: this.yearBegin AND Date__c <=: this.yearEnd
                                        ORDER BY Date__c];

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

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageRef.setRedirect(false); 
        return null;//return pageRef; // TODO FIX
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
     * Unassign/Assign hours/days view
     */
    public List<DContract__c> fteContracts { get; set;}
    public List<SelectOption> fteContractsOptions { get;set; }
    public Id selectedFteContract { get; set;}
    public String fteDays { get; set;}
    public Id contractId { get; set;}
    public String contractName { get; set;}
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

        this.fteContracts = [SELECT Id, Name FROM DContract__c WHERE FTE_Tracker__c = 'Yes'];
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
                                                        Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
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
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
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
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
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
            if (this.assignViewError == false) {
                return backToEmployeeView();
            }
        } catch (Exception e) {
            this.assignViewError = true;
        }

        return null;
    }

    public PageReference moveTimeFromUnassigned() {
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
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
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
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
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
        clearViewData();
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.setRedirect(false); 
        return pageRef;
    }

    private void clearViewData() {
        this.contractId = null;
        this.fteHoursMax = 0;
        this.employeeMonth = null;
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
        List<Time_Card__c> tagsTC = [SELECT Id, FTE_Contract__c, FTE_hours__c, FTE_only__c FROM Time_Card__c WHERE (FTE_Contract__c != null 
                                        AND FTE_Contract__c != '') OR FTE_hours__c > 0];
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