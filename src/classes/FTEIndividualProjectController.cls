/**
 * Controller for FTE_Individual_Project_View.
 */
public class FTEIndividualProjectController {

    public Id contractId { get; set;}
    public String contractName { get; set;}
    public Id employeeId { get; set;}
    public List<FTEEmployeeTime> individualContractDataList { get; set;}

    public FTEIndividualProjectController() {
        String conId = ApexPages.currentPage().getParameters().get('contractId');
        if (conId != null && conId InstanceOf Id) {
            this.contractId = (Id) conId;
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

        List<Time_Card__c> contractTimeCards = [SELECT Id, Employee__c, Employee__r.Name, Date__c, Total__c, FTE_hours__c, FTE_Contract__c, Time_Card_Salary__c FROM Time_Card__c WHERE
                                                (Client__c =: this.contractId OR FTE_Contract__c =: this.contractId) AND Date__c <=: Date.today()];

        FTEEmployeeTime totalProjectTime = new FTEEmployeeTime('Total', null);
        for (Time_Card__c timeCard : contractTimeCards) {
            FTEEmployeeTime tmpHelper;
            if (projectTimeMap.containsKey(timeCard.Employee__c)) {
                tmpHelper = projectTimeMap.get(timeCard.Employee__c);
            } else {
                tmpHelper = new FTEEmployeeTime(timeCard.Employee__r.Name, timeCard.Employee__c);
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
        Map<Id, SFDC_Employee__c> empMap = new Map<Id, SFDC_Employee__c>([SELECT Id, Name FROM SFDC_Employee__c WHERE Id IN: projectTimeMap.keySet()]);

        for (FTEEmployeeTime empT : this.individualContractDataList) {
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

    public PageReference goToEmployeeView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        return pageRef;
    }

    public PageReference goToProjectList() {
        PageReference pageRef = Page.FTE_Project_List_View;
        return pageRef;
    }
}