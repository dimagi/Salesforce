public class GlobalMetricsComponentController extends GlobalMetricsPageController{

    public String employeeEmail { get; set; }
    public DimagiToolsController pageController { get; set; }

    public GlobalMetricsComponentController() {
        this.dashboardRefreshTime = null;
    }

    public PageReference loadScaleData() {
        if (!this.pageController.isTokenValid()) {
            return null;
        }
        try {
            List<Global_Metric_Graph__c> metrics = [SELECT Id, CreatedDate FROM Global_Metric_Graph__c LIMIT 1];
            if (metrics.size() > 0) {
                this.dashboardRefreshTime = metrics.get(0).CreatedDate;
            }
        } catch (Exception ex) {
             EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'PRO Corporate Dashboard errors', 'PRO Corporate Dashboard error', ex);
        }
        return null;
    }

}