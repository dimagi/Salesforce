/**
 * Controler for Employee View in FTE Tracker.
 */
public class FTEEmployeeController {

    private Id employeeId;
    private Integer employeeNetworkDays = 0;

    public Id contractId { get; set;}
    public Integer fteYear { get; set;}
    public Integer exportMonth { get; set;}
    public SFDC_Employee__c employee { get; set;}

    public FTEEmployeeTime unassigned { get; set;}
    public FTEEmployeeTime totalAssignedDays { get; set;}
    public FTEEmployeeTime totalDaysWorked { get; set;}
    public Map<Id, FTEEmployeeTime> assignedMap { get; set;}
    public List<FTEEmployeeTime> contractsTime { get; set;}
    public Map<Id, FTEEmployeeTime> unassignedMap { get; set;}

    public void setViewData() {
        // We need this empty method to set values before loading new view. ?? TODO !::::: we must check it
    }

    public FTEEmployeeController() {
        String emplId = ApexPages.currentPage().getParameters().get('employeeId');
        if (emplId != null && emplId InstanceOf Id) {
            this.employeeId = (Id) emplId;
        }

        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year();
        }
    }

    public void initFteEmployeeView() {
        if (this.employeeId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            return;
        }

        List<SFDC_Employee__c> emplList = [SELECT Id, Name, Unloaded_Daily_Rate__c, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
        if (emplList.size() > 0) {
            this.employee = emplList.get(0);
        }

        this.employeeNetworkDays = FTETrackerHelper.getNetworkDays(this.employee.Hire_Date__c, this.fteYear);
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Time_Card_Salary__c, Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND CALENDAR_YEAR(Date__c) =: this.fteYear
                                        ORDER BY Client__r.Name];

        this.assignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassigned = new FTEEmployeeTime('Unassigned', null);

        FTEEmployeeTime tmpHelper;
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

        this.contractsTime = new List<FTEEmployeeTime>();

        this.contractsTime = this.assignedMap.values();
        this.totalAssignedDays = new FTEEmployeeTime('Total Assigned Days', null);
        this.totalDaysWorked = new FTEEmployeeTime('Total Days Worked', null);
        generateStyles();
        this.contractsTime.add(this.unassigned);
        this.contractsTime.add(this.totalAssignedDays);
        this.contractsTime.add(this.totalDaysWorked);
    }

    public PageReference goToEmployeeListView () {
        PageReference pageRef = Page.FTE_Employee_List_View;
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageRef;
    }

    public PageReference goToProjectListView() {
        return Page.FTE_Project_List_View;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageref.getParameters().put('contractId', this.contractId);
        return pageref;
    }

    public PageReference goToAssignView() {
        PageReference pageRef = Page.FTE_Unassign_Days_View;
        if (String.isBlank(this.contractId)) {
            pageRef = Page.FTE_Assign_Days_View;
        }

        pageRef.setRedirect(false);
        return pageRef;
    }


    public PageReference goToTimeCardView() {
        PageReference pageRef = null;
        pageRef = Page.FTE_Time_Card_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        pageref.getParameters().put('month', String.valueOf(this.exportMonth));
        return pageRef;
    }

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month, Decimal salary) {
        FTEEmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
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
        for (FTEEmployeeTime empT : this.contractsTime) {
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
    public String contractName { get; set;}

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
            this.monthName = DateTime.newInstance(this.fteYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
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
            this.monthName = DateTime.newInstance(this.fteYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
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
            Date monthStart = Date.newInstance(this.fteYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.fteYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.fteYear, this.employeeMonth + 1));
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
            Date monthStart = Date.newInstance(this.fteYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.fteYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.fteYear, this.employeeMonth + 1));
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