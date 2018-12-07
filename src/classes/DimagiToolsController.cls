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
        PRO_OAuth_Settings__c settings = getSettings();
        this.callback = settings != null ? settings.Auth_Callback_URL__c : '';
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
                this.token = SFAuthUtils.getFromJSON(SFAuthUtils.getAuthorizedReqToken(getSettings(), this.callback, code), 'access_token');
                this.currentLoginEmail = SFAuthUtils.callForUserInfo(this.token);
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

    private String callback;
    private String token;
    private Boolean tokenIsValid; // we must use it because checking token with google in some cases cause Pending job exception.

    public String currentLoginEmail { get; set; }

    public PageReference signIn() {
        PageReference authPage = new PageReference(SFAuthUtils.getSignInUrl(getSettings(), this.callback, this.projId));
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
        this.token = null;
        return false;
    }

    public Boolean isTokenValid() {
        if (Test.isRunningTest()) {
            return true;
        }

        String domainName = getSettings().Domain_Name__c;
        String userEmail = SFAuthUtils.callForUserInfo(this.token);
        if (userEmail == this.currentLoginEmail && (domainName == 'gmail.com' || domainName == this.currentLoginEmail.split('@')[1])) {
             this.tokenIsValid = true;
        } else {
            this.token = null;
            this.tokenIsValid = false;
        }
        return this.tokenIsValid;
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