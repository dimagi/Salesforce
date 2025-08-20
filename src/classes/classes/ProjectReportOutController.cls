/**
 * Redirect controller for old projectreportout url.
 */
public without sharing class ProjectReportOutController {

    private String redirectURL = '';

    public ProjectReportOutController() {
        List<PRO_OAuth_Settings__c> googleSettings = PRO_OAuth_Settings__c.getALL().values();
        if (googleSettings != null && googleSettings.size() > 0) {
            this.redirectURL = googleSettings[0].Auth_Callback_URL__c;
        }
    }

    public PageReference redirectToSFTools() {
        String params = null;
        if (ApexPages.currentPage().getParameters().get('state') != null
                && ApexPages.currentPage().getParameters().get('state') != 'null'
                && ApexPages.currentPage().getParameters().get('state') != '') {
            params = '?state=' + ApexPages.currentPage().getParameters().get('state');
        }

        PageReference retURL = new PageReference(redirectURL + (params != null ? params : ''));
        retURL.setRedirect(true);
        return retURL;
    }
}