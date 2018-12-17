/**
 * Controller for FTE_Project_List_View, allows to manage FTE contracts.
 */
public class FTEProjectListController {

    public Id contractId { get; set;}
    public String seachProjectName { get; set;}
    public JobWrapper workCardJobStatus {get; set;}
    public Pagination projectsPagination { get; set;}

    public FTEProjectListController() {
        this.seachProjectName = '';
        this.projectsPagination = new Pagination();
        this.projectsPagination.pageSize = 10;
    }

    public void initProjectList() {
        loadWorkCardJobStatus();
    }

    public List<DContract__c> getListToSubmit() {
        List<DContract__c> result = null;
        if (this.seachProjectName != null && this.seachProjectName != '') {
            result = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c WHERE FTE_Tracker__c = 'Yes' AND Name LIKE: ('%' + String.escapeSingleQuotes(this.seachProjectName) + '%')
                        ORDER BY Name LIMIT: this.projectsPagination.pageSize OFFSET: this.projectsPagination.getOffsetValue()];
            this.projectsPagination.handleResulSize([SELECT count() FROM DContract__c WHERE FTE_Tracker__c = 'Yes' AND Name LIKE: ('%' + String.escapeSingleQuotes(this.seachProjectName) + '%')]);
        } else {
            result = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c WHERE FTE_Tracker__c = 'Yes' ORDER BY Name LIMIT: this.projectsPagination.pageSize OFFSET: this.projectsPagination.getOffsetValue()];
            this.projectsPagination.handleResulSize([SELECT count() FROM DContract__c WHERE FTE_Tracker__c = 'Yes']);
        }
        return result;
    }

    public void searchProject() {
        this.projectsPagination.pageNumber = 1;
    }

    public PageReference goToEmployeeListView() {
        return Page.FTE_Employee_List_View;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageref.getParameters().put('contractId', this.contractId);
        return pageref;
    }

   public void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }
}