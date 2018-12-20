/**
 * Controller for FTE_Project_List_View, allows to manage FTE contracts.
 */
public class FTEProjectListController {

    public Id contractId { get; set;}
    public JobWrapper workCardJobStatus {get; set;}

    public FTEProjectListController() {
    }

    public void initProjectList() {
        loadWorkCardJobStatus();
    }

    public List<DContract__c> getListToSubmit() {
        List<DContract__c> result = [SELECT Id, Name, Contract_End_Date__c, Project_Manager__c, FTE_Tracker__c FROM DContract__c WHERE FTE_Tracker__c = 'Yes' AND Status__c = 'Active' ORDER BY Name];
        return result;
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