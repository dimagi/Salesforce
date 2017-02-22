/**
 * Controller for refreshing Corporate Dashboard charts.
 */
public class CorporateDashboardController {

    public Boolean refreshing { get; set;}

    public CorporateDashboardController() {
        this.refreshing = false;
    }

    public PageReference refreshDashboard() {
        this.refreshing = true;
        if (this.refreshing == false) {
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setMethod('PUT');
            req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v35.0/analytics/dashboards/01Zb0000000H9c6');

            Http http = new Http();
            HttpResponse res = http.send(req);
            EmailHelper.sendEmail('tstalka@soldevelo.com', 'Corporate Dashboard', 'sid=' + UserInfo.getSessionId() + ' ' + req + ' ' + res + '');
        }

        return null;
    }

    public void resetRefreshFlag() {
        this.refreshing = false;
    }
}