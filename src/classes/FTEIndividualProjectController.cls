/**
 * Controller for FTE_Individual_Project_View.
 */
public class FTEIndividualProjectController extends FTEController {

    public Id contractId { get; set;}
    public String contractName { get; set;}
    public Id employeeId { get; set;}
    public List<FTEEmployeeTime> individualContractDataList { get; set;}
    public Integer fteYear { get; set;}

    public FTEIndividualProjectController() {
        String conId = ApexPages.currentPage().getParameters().get('contractId');
        if (conId != null && conId InstanceOf Id) {
            this.contractId = (Id) conId;
        }

        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
    }

    public void initIndividualProject() {
        this.individualContractDataList = new List<FTEEmployeeTime>();
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
        Map<Id, FTEEmployeeTime> projectTimeMap = new Map<Id, FTEEmployeeTime>();
        Decimal totalHours = 0;

        FTEEmployeeTime totalProjectTime = new FTEEmployeeTime('Total', null);
        for (Time_Card__c timeCard : [SELECT Id, Employee__c, Employee__r.Name, Date__c, Total__c, FTE_hours__c, FTE_Contract__c FROM Time_Card__c WHERE
                                                (Client__c =: this.contractId OR FTE_Contract__c =: this.contractId) AND CALENDAR_YEAR(Date__c) =: this.fteYear]) {
            FTEEmployeeTime tmpHelper;
            if (projectTimeMap.containsKey(timeCard.Employee__c)) {
                tmpHelper = projectTimeMap.get(timeCard.Employee__c);
            } else {
                tmpHelper = new FTEEmployeeTime(timeCard.Employee__r.Name, timeCard.Employee__c);
            }

            Decimal realHours = timeCard.Total__c != null ? timeCard.Total__c : 0;
            if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c != this.contractId) {
                realHours = realHours - timeCard.FTE_hours__c;
            } else if (timeCard.FTE_Contract__c != null && timeCard.FTE_Contract__c == this.contractId) {
                realHours = timeCard.FTE_hours__c;
            }

            Integer monthIndex = timeCard.Date__c.month() - 1;
            tmpHelper.hoursArray[monthIndex] += realHours;
            tmpHelper.hoursArray[12] += realHours;
            projectTimeMap.put(timeCard.Employee__c, tmpHelper);
        }

        this.individualContractDataList = projectTimeMap.values();
        for (FTEEmployeeTime empT : this.individualContractDataList) {
            empT.calculateDays();
            totalProjectTime.sumHours(empT);
        }
        totalProjectTime.calculateDays();
        totalProjectTime.cssStyle[0] = 'topTotal';
        totalProjectTime.cssStyle[1] = 'topTotal';
        totalProjectTime.cssStyle[2] = 'topTotal';
        totalProjectTime.cssStyle[3] = 'topTotal';
        totalProjectTime.cssStyle[4] = 'topTotal';
        totalProjectTime.cssStyle[5] = 'topTotal';
        totalProjectTime.cssStyle[12] = 'topTotal';
        totalProjectTime.nameCss = 'topTotal';
        this.individualContractDataList.add(totalProjectTime);
    }

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageRef;
    }

    public override PageReference goToEmployeeListView() {
        PageReference pageRef = Page.FTE_Employee_List_View;
        if (Date.today().year() != this.fteYear) {
            pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        }

        return pageRef;
    }
}