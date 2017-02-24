/**
 * Controller for refreshing Corporate Dashboard charts.
 */
public without sharing class CorporateDashboardController {

    public Boolean refreshing { get; set;}

    public CorporateDashboardController() {
        this.refreshing = false;
    }

    public PageReference refreshDashboard() {
        if (this.refreshing == false) {
            this.refreshing = true;
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setMethod('PUT');
            req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v36.0/analytics/dashboards/01Zb0000000gCws');

            Http http = new Http();
            HttpResponse res = http.send(req);
        }

        return null;
    }

    public void resetRefreshFlag() {
        this.refreshing = false;
    }
}