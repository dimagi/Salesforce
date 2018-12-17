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

    public FTETimeManager fteTimeManager { get; set;}
    public FTEEmployeeTime totalAssignedDays { get; set;}
    public FTEEmployeeTime totalDaysWorked { get; set;}
    public List<FTEEmployeeTime> contractsTime { get; set;}

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

    public FTEEmployeeController() {
        String emplId = ApexPages.currentPage().getParameters().get('employeeId');
        if (emplId != null && emplId InstanceOf Id) {
            this.employeeId = (Id) emplId;
        }

        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
    }

    public void initFteEmployeeView() {
        if (this.employeeId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            return;
        }

        List<SFDC_Employee__c> emplList = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
        if (emplList.size() > 0) {
            this.employee = emplList.get(0);
        }

        this.employeeNetworkDays = FTETrackerHelper.getNetworkDays(this.employee.Hire_Date__c, this.fteYear);
        this.fteTimeManager = new FTETimeManager(this.employee, this.fteYear);
        this.fteTimeManager.loadEmployeeTime();
        buildUITableData();
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
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageref;
    }

    public PageReference goToTimeCardView() {
        PageReference pageRef = null;
        pageRef = Page.FTE_Time_Card_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        pageref.getParameters().put('month', String.valueOf(this.exportMonth));
        return pageRef;
    }

    public void loadEmployeeMonth() {
        this.assignViewError = false;
        this.notValidDays = false;
        this.fteDays = '0.25';
        this.userAvailableDays = 0;

        if (this.employeeMonth != null) {
            this.fteDaysMax = this.fteTimeManager.unassigned.daysArray[this.employeeMonth];
            this.fteHoursMax = this.fteTimeManager.unassigned.hoursArray[this.employeeMonth];
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
            this.contractName = this.fteTimeManager.assignedMap.get(this.contractId).name;
            this.fteHoursMax = this.fteTimeManager.assignedMap.get(this.contractId).hoursArray[this.employeeMonth];
            this.fteDaysMax = this.fteTimeManager.assignedMap.get(this.contractId).daysArray[this.employeeMonth];
            this.monthName = DateTime.newInstance(this.fteYear, this.employeeMonth + 1, 1).format('MMMM yyyy');
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load contract month'));
            this.assignViewError = true;
            this.fteHoursMax = 0;
        }
    }

    public void moveTimeToUnassigned() {
        if (notValidDays) {
            return;
        }
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return;
        }

        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        if (this.fteDaysMax < fteDaysdecimal || fteDaysdecimal < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return;
        }

        if (String.isEmpty(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return;
        }

        if (fteDaysdecimal == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return;
        }

        try {
            Decimal hoursToUnassign = fteDaysdecimal * 8;
            if (this.fteHoursMax < hoursToUnassign) {
                hoursToUnassign = this.fteHoursMax;
            }
            this.fteTimeManager.moveTimeToUnassigned(hoursToUnassign, this.employeeMonth + 1, this.contractId);
            moveHoursInFTEWorkCard((-1) * fteDaysdecimal, this.employeeMonth + 1, this.employee.Id);
        } catch (Exception e) {
            this.assignViewError = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unexpected error: ' + e.getMessage()));
        }

        initFteEmployeeView();
    }

    public void moveTimeFromUnassigned() {
        if (notValidDays) {
            return;
        }
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return;
        }

        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        if (this.fteDaysMax < fteDaysdecimal || fteDaysdecimal < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return;
        }

        if (String.isEmpty(this.selectedFteContract)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return;
        }

        if (fteDaysdecimal == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return;
        }

        try {
            Decimal hoursToAssign = fteDaysdecimal * 8;
            if (this.fteHoursMax < hoursToAssign) {
                hoursToAssign = this.fteHoursMax;
            }
            this.fteTimeManager.moveTimeToAssigned(hoursToAssign, this.employeeMonth + 1, this.selectedFteContract);
            moveHoursInFTEWorkCard(fteDaysdecimal, this.employeeMonth + 1, this.employee.Id);
        } catch (Exception e) {
            this.assignViewError = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unexpected error: ' + e.getMessage() + ' Line : ' + e.getLineNumber()));
        }
        initFteEmployeeView();
    }

    private void buildUITableData() {
        this.contractsTime = new List<FTEEmployeeTime>();
        this.contractsTime = this.fteTimeManager.assignedMap.values();
        this.totalAssignedDays = new FTEEmployeeTime('Total Assigned Days', null);
        this.totalDaysWorked = new FTEEmployeeTime('Total Days Worked', null);
        generateStyles();
        this.contractsTime.add(this.fteTimeManager.unassigned);
        this.contractsTime.add(this.totalAssignedDays);
        this.contractsTime.add(this.totalDaysWorked);
    }

    private void generateStyles() {
        // Calculate totals and labor cost
        for (FTEEmployeeTime empT : this.contractsTime) {
            empT.calculateDays();
            this.totalAssignedDays.sumHoursAndCost(empT);
            this.totalDaysWorked.sumHoursAndCost(empT);
        }

        this.fteTimeManager.unassigned.calculateDays();
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

        this.totalDaysWorked.sumHoursAndCost(this.fteTimeManager.unassigned);
        this.totalDaysWorked.calculateDays();
        this.totalDaysWorked.nameCss = '';
        this.totalAssignedDays.nameCss = 'topTotal';
        this.fteTimeManager.unassigned.nameCss = '';
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
}