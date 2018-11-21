/**
 * Controller for Dimagi Force.com Tools like PRO, Financial, Projects, Global Metrics and RED forms.
 */
public without sharing class DimagiToolsController {

    /**
    * Init page section
    */
    public DimagiToolsController() {
        this.tokenIsValid = false;
        this.currentTab = 0;
    }

    public PageReference initSFToolsPage() {
        if (ApexPages.currentPage().getParameters().get('state') != null
                && ApexPages.currentPage().getParameters().get('state') != 'null'
                && ApexPages.currentPage().getParameters().get('state') InstanceOf Id) {
            this.projId = ApexPages.currentPage().getParameters().get('state');
        }

        Cookie googleResponse = ApexPages.currentPage().getCookies().get('googleResponse');
        Cookie projectState = ApexPages.currentPage().getCookies().get('projectState');
        String code = ApexPages.currentPage().getParameters().get('code');

        if (code != null) {
            List<Cookie> cookies = new List<Cookie>();
            cookies.add(new Cookie('googleResponse', code, null, 60, true));
            if (this.projId != null && this.projId != 'null') {
                cookies.add(new Cookie('projectState', this.projId, null, 60, true));
            }
            ApexPages.currentPage().setCookies(cookies);
            PageReference sfToolsPage = Page.DimagiSFTools;
            sfToolsPage.setRedirect(true);
            return sfToolsPage;
        } else {
            if (googleResponse != null) {
                code = googleResponse.getValue();
                if (projectState != null) {
                    this.projId = projectState.getValue();
                }
                googleResponse = new Cookie('googleResponse', null, null, 0, true);
                projectState = new Cookie('projectState', null, null, 0, true);
                ApexPages.currentPage().setCookies(new Cookie[] { googleResponse, projectState });
                this.token = getFromJSON(getAuthorizedReqToken(code), 'access_token');
                this.currentLoginEmail = callForUserInfo(this.token);
                isTokenValid();
            }
        }

        if (this.projId != null && this.projId != 'null') {
            this.currentTab = 2;
        } else {
            this.currentTab = 0;
        }

        return null;
    }

    /**
     * Manage page and components
     */

    public Integer currentTab { get; set; }
    public String projId { get; set; }

    public DimagiToolsController getThis() {
        return this;
    }

    /**
     * OAuth section
     */

    private static final String AUTH_URL = 'https://accounts.google.com/o/oauth2/auth';
    private static final String ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    private static final String USER_INFO_URL = 'https://www.googleapis.com/oauth2/v1/userinfo';

    private String token;
    private Boolean tokenIsValid; // we must use it because checking token with google in some cases cause Pending job exception.

    public String currentLoginEmail { get; set; }

    public PageReference signIn() {
        PRO_OAuth_Settings__c settings = getSettings();
        String body = 'client_id=' + settings.ClientID__c + '&redirect_uri=' + settings.Auth_Callback_URL__c + '&state=' + this.projId;
        String retUrl = AUTH_URL + '?' + body + '&response_type=code&scope=profile+email';
        if (settings.Domain_Name__c != 'gmail.com') {
            retUrl = retUrl + '&hd=' + settings.Domain_Name__c;
        }

        PageReference authPage = new PageReference(retUrl);
        authPage.setRedirect(true);
        return authPage;
    }

    public Boolean getAccessGranted() {
        if (Test.isRunningTest()) {
            return true;
        }

        if (this.token != null && this.tokenIsValid) {
            return true;
        }
        return false;
    }

    public Boolean isTokenValid() {
        if (Test.isRunningTest()) {
            return true;
        }

        String userEmail = callForUserInfo(this.token);
        if (userEmail == this.currentLoginEmail) {
             this.tokenIsValid = true;
        } else {
            this.tokenIsValid = false;
        }
        return this.tokenIsValid;
    }

    private String getAuthorizedReqToken(String code) {
        PRO_OAuth_Settings__c settings = getSettings();
        String body = 'client_id=' + settings.ClientID__c + '&redirect_uri=' + settings.Auth_Callback_URL__c + '&client_secret=' +
                            settings.ClientSecret__c + '&code=' + code + '&grant_type=authorization_code';
        String tokenResponse = basicAuthCallout(ACCESS_TOKEN_URL, '', body, 'POST');
        return tokenResponse;
    }

    private String callForUserInfo(string token) {
        String userInfoURL = USER_INFO_URL + '?access_token=' + token;
        String responseJSON = basicAuthCallout(userInfoURL, '', '', 'GET');
        String response = getFromJSON(responseJSON, 'email');

        return response;
    }

    private String basicAuthCallout(String endPoint, String header, String body, String method) {
        HttpRequest req = new HttpRequest();

        req.setEndpoint(endPoint);
        req.setMethod(method);
        if (method == 'POST') {
            req.setBody(body);
        }
        Http http = new Http();

        HTTPResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Incorrect data');
        }
        return res.getBody();
    }

    private string getFromJSON(String response, String fieldName){
        JSONParser parser = JSON.createParser(response);
        String accessToken='';

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                (parser.getText() == fieldName)) {
                parser.nextToken();
                accessToken = parser.getText();
            }
        }
        return accessToken;
    }

    private PRO_OAuth_Settings__c getSettings() { // we don't want store settings in StateView
        List<PRO_OAuth_Settings__c> googleSettings = PRO_OAuth_Settings__c.getAll().values();
        if (googleSettings != null && googleSettings.size() > 0) {
            return googleSettings.get(0);
        }
        return null;
    }

    /**
     * Wrappers
     */

    public class PROProject {

        public PROProject() {}

        public DContract__c contract { get; set; }
        public Boolean customAdded { get; set; }
        public String cssClass{ get; set; }
    }

    public class ProjectExecutionStatus {

        public String fieldName { get; set; }
        public Integer fieldValue {
            get {
                return (fieldValue == null) ? 0 : fieldValue;
            }
            set;
        }
    }

    public class PROProjectBudget {

        public PROProjectBudget() {}

        public String categoryName { get; set; }
        public Integer contractamount { get; set; }
        public Integer spentAmount { get; set; }
        public Integer amountRemaining { get; set; }
        public Integer prcntgUsed { get; set; }
        public Integer throughContract { get; set; }
        public Integer throughSOWDeliverable { get; set; }
    }

    public class PROProjectTimeSpentHistory implements Comparable {

        public String laborName { get; set; }
        public Decimal currentMonthHours {
            get {
                return (currentMonthHours == null) ? 0 : currentMonthHours;
            }
            set;
        }

        public Decimal firstMonthHours {
            get {
                return (firstMonthHours == null) ? 0 : firstMonthHours;
            }
            set;
        }

        public Decimal secondMonthHours {
            get {
                return (secondMonthHours == null) ? 0 : secondMonthHours;
            }
            set;
        }

        public Decimal thirdMonthHours {
            get {
                return (thirdMonthHours == null) ? 0 : thirdMonthHours;
            }
            set;
        }

        public Decimal moreThanThreeMonthAgoHours {
            get {
                return (moreThanThreeMonthAgoHours == null) ? 0 : moreThanThreeMonthAgoHours;
            }
            set;
        }

        public Decimal totalHourstoDate{
            get {
                return (totalHourstoDate == null) ? 0 : totalHourstoDate;
            }
            set;
        }

        public Decimal laborCost {
            get {
                return laborCost != null ? laborCost.setScale(2) : 0.00;
            }
            set; }

        public Integer compareTo(Object objToCompare) {
            return Integer.valueOf(((PROProjectTimeSpentHistory)objToCompare).totalHourstoDate - totalHourstoDate);
        }
    }
}