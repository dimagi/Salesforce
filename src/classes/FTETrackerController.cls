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

    public FTETrackerController () {
        this.currentYear = FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c != null ? FTE_Tracker_Settings__c.getOrgDefaults().FTE_Year__c.intValue() : Date.today().year();
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
        return pageRef;
    }

    public void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
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
     /**
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

    private Integer getContractIndex() {
        Integer upperLimit = this.unassignedMap.size();
        if (upperLimit == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find unassigned contract'));
            return 0;
        }
        Integer rand = Math.round(Math.random()*1000);
        return Math.mod(rand, upperLimit);
    }*/
}