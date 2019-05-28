/**
 * Controler for Employee View in FTE Tracker.
 */
public class FTEEmployeeController extends FTEController {

    private Id employeeId;
    public SFDC_Employee__c employee { get; set; }

    public FTEDataManager fteTimeManager { get; set; }
    public FTEEmployeeTime totalAssignedDays { get; set; }
    public FTEEmployeeTime totalDaysWorked { get; set; }
    public List<FTEEmployeeTime> contractsTime { get; set; }

    public List<DContract__c> fteContracts { get; set; }
    public List<SelectOption> fteContractsOptions { get; set; }

    public Integer employeeNetworkDays { get; set; }
    public Id contractId { get; set; }
    public Integer fteYear { get; set; }
    public Integer exportMonth { get; set; }
    public Id selectedFteContract { get; set; }
    public String fteDays { get; set; }
    public Integer employeeMonth { get; set; }

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

        this.fteContracts = [SELECT Id, Name FROM DContract__c WHERE FTE_Tracker__c = 'Yes' ORDER BY Name];
        this.fteContractsOptions = new List<SelectOption>();
        for (DContract__c con : this.fteContracts) {
            this.fteContractsOptions.add(new SelectOption(con.Id, con.Name));
        }

        List<SFDC_Employee__c> emplList = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
        if (emplList.size() > 0) {
            this.employee = emplList.get(0);
        }
        this.employeeNetworkDays = FTETrackerHelper.getNetworkDays(this.employee.Hire_Date__c, this.fteYear);
    }

    public void initFteEmployeeView() {
        if (this.employeeId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            return;
        }

        this.fteTimeManager = new FTEDataManager(this.fteYear, this.employee.Id, false);
        this.fteTimeManager.loadEmployeeTime(); // loads employee time cards with tags
        this.fteTimeManager.loadTemplateTime(); // loads uploaded csv templates to allocate future time
        buildUITableData();
    }

    public void setThreshold() {
        if (!FTETrackerHelper.isContractFTE(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Contract is not in FTE Tracker, try refresh page.'));
            return;
        }
        if (this.fteDays != null && this.fteDays != '') {
            Decimal value = Decimal.valueOf(this.fteDays);
            if (value >= 0) {
                FTEDataManager manager = new FTEDataManager(this.fteYear, this.employeeMonth, this.employee.Id, false);
                manager.upsertTimeTemplate(this.contractId, value, this.employeeMonth, false); //set time will refresh work card
                manager.loadEmployeeTime();
                manager.loadTemplateTime();
                manager.setTime(this.contractId, value * 8);
            } else {
                resetThreshold(this.contractId, this.employeeMonth);
            }
        } else {
            resetThreshold(this.contractId, this.employeeMonth);
        }
    }

    public void resetThreshold(Id resetContract, Integer resetMonth) {
        this.fteTimeManager.removeTimeTemplate(resetContract, resetMonth);
    }

    public void assignTime() {
        if (!FTETrackerHelper.isContractFTE(this.selectedFteContract)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Contract is not in FTE Tracker, try refresh page.'));
            return;
        }

        if (this.fteDays != null && this.fteDays != '') {
            Decimal value = Decimal.valueOf(this.fteDays);
            if (value > 0) {
                FTEDataManager manager = new FTEDataManager(this.fteYear, this.employeeMonth, this.employee.Id, false);
                manager.loadEmployeeTime();
                manager.loadTemplateTime();

                FTEEmployeeTime emplTime = manager.assignedMap.get(this.selectedFteContract);
                if (emplTime == null || emplTime.templateArray[this.employeeMonth - 1] == -1) { // we want use this method only when no template was added
                    manager.addTime(this.selectedFteContract, value * 8);
                }
            }
        }
    }

    public void unassignTime() {
        if (!FTETrackerHelper.isContractFTE(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Contract is not in FTE Tracker, try refresh page.'));
            return;
        }
        if (this.fteDays != null && this.fteDays != '') {
            Decimal value = Decimal.valueOf(this.fteDays);
            if (value > 0) {
                FTEDataManager manager = new FTEDataManager(this.fteYear, this.employeeMonth, this.employee.Id, false);
                manager.loadEmployeeTime();
                manager.loadTemplateTime();

                FTEEmployeeTime emplTime = manager.assignedMap.get(this.selectedFteContract);
                if (emplTime == null || emplTime.templateArray[this.employeeMonth - 1] == -1) { // we want use this method only when no template was added
                    manager.removeTime(this.contractId, value * 8);
                }
            }
        }
    }

    public override PageReference goToEmployeeListView () {
        PageReference pageRef = Page.FTE_Employee_List_View;
        if (Date.today().year() != this.fteYear) {
            pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        }
        return pageRef;
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
        // Calculate totals
        for (FTEEmployeeTime empT : this.contractsTime) {
            empT.calculateDaysAndTotal();
            this.totalAssignedDays.mergeEmployeeTime(empT);
            this.totalDaysWorked.mergeEmployeeTime(empT);
        }

        this.totalDaysWorked.mergeEmployeeTime(this.fteTimeManager.unassigned);
        this.fteTimeManager.unassigned.calculateDaysAndTotal();
        this.totalAssignedDays.calculateDaysAndTotal();
        this.totalDaysWorked.calculateDaysAndTotal();

        // We add css classes here to avoid complex if sections in visualgforce page
        for (Integer i = 0; i < 12; i++) {
            if (this.totalAssignedDays.daysArray[i] > 21) {
                this.totalAssignedDays.cssStyle[i] = this.totalAssignedDays.cssStyle[i].remove('fteCell') + ' topTotal overbilled';
            } else {
                this.totalAssignedDays.cssStyle[i] = this.totalAssignedDays.cssStyle[i].remove('fteCell') + ' topTotal';
            }
            this.totalDaysWorked.cssStyle[i] = this.totalDaysWorked.cssStyle[i].remove('fteCell');
        }
        if (totalAssignedDays.daysArray[12] > employeeNetworkDays) {
            this.totalAssignedDays.cssStyle[12] = this.totalAssignedDays.cssStyle[12] + ' topTotal overbilled';
        } else {
            this.totalAssignedDays.cssStyle[12] = this.totalAssignedDays.cssStyle[12] + ' topTotal';
        }

        this.totalDaysWorked.nameCss = '';
        this.totalAssignedDays.nameCss = 'topTotal';
        this.fteTimeManager.unassigned.nameCss = '';
    }
}