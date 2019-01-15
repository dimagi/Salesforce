public virtual class FTEController {

    public JobWrapper workCardJobStatus {get; set;}

    public FTEController() {
        
    }

    public virtual PageReference goToEmployeeListView() {
        return Page.FTE_Employee_List_View;
    }

    public virtual PageReference goToProjectListView() {
        return Page.FTE_Project_List_View;
    }

    public virtual PageReference goToCSVUploadView() {
        return Page.FTE_CSV_Upload;
    }

    public virtual List<SelectOption> getYearsData() {
        return FTETrackerHelper.getYearsData();
    }

    public virtual void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }
}