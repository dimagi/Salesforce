public class ContactDirectoryController {

    private String token;
    private String currentLoginEmail;
    private String callback;
    private Boolean tokenIsValid;

    public String empSearchName { get; set; }
    public String showMessage { get; set; }
    public String contractSearchName { get; set; }

    public List<DContract__c> contractList { get; set; }
    public List<SFDC_Employee__c> empList { get; set; }

    public ContactDirectoryController() {
        this.tokenIsValid = false;
        PRO_OAuth_Settings__c settings = getSettings();
        this.callback = settings != null ? settings.Contact_Directory_Callback_URL__c : '';
    }

    public PageReference initAction() {
        Cookie googleResponse = ApexPages.currentPage().getCookies().get('googleResponseCD');
        String code = ApexPages.currentPage().getParameters().get('code');

        if (code != null) {
            List<Cookie> cookies = new List<Cookie>();
            ApexPages.currentPage().setCookies(new Cookie[] { new Cookie('googleResponseCD', code, null, 60, true) });
            PageReference cdPage = Page.ContactDirectory;
            cdPage.setRedirect(true);
            return cdPage;
        } else {
            if (googleResponse != null) {
                code = googleResponse.getValue();
                googleResponse = new Cookie('googleResponseCD', null, null, 0, true);
                ApexPages.currentPage().setCookies(new Cookie[] { googleResponse });
                this.token = SFAuthUtils.getFromJSON(SFAuthUtils.getAuthorizedReqToken(getSettings(), this.callback, code), 'access_token'); // here is exceptoipn bad request 400
                this.currentLoginEmail = SFAuthUtils.callForUserInfo(this.token);
                isTokenValid();
                loadPageData();
            }
        }
        return null;
    }

    public void loadPageData() {
        if (isTokenValid()) {
            this.empList = [SELECT Id, Name, Email_Address__c, Skype_ID__c, Direct_Manager_Lookup__c, Direct_Manager_Lookup__r.Name,
                            Business_Unit__c, Sub_Unit__c, Entity__c, Personal_Phone_Number__c, Title__c,
                            Languages_Spoken__c, Language_1_Proficiency__c, Language_Spoken_2__c, Language_2_Proficiency__c,
                            Language_Spoken_3__c, Language_3_Proficiency__c, Language_Spoken_4__c, Language_4_Proficiency__c,
                            Language_Spoken_5__c, Language_5_Proficiency__c, Language_Spoken_6__c, Language_6_Proficiency__c
                            FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active'];

            this.contractList = [SELECT Id, Prime_Contracting_Business_Unit__c, Name, Prime_Contracting_Business_Unit__r.Name,
                                 Safety_Contact__c, Contract_End_Date__c
                                 FROM DContract__c WHERE Status__c IN ('Draft', 'Active')];
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,' If any information is incorrect please contact people-ops@dimagi.com'));
        }
    }

    public void searchEmp() {
        if (isTokenValid()) {
            String searchString = '%' + this.empSearchName + '%';
            this.empList = [SELECT Id, Name, Email_Address__c, Skype_ID__c, Direct_Manager__c, Direct_Manager_Lookup__c, Direct_Manager_Lookup__r.Name,
                            Business_Unit__c, Sub_Unit__c, Entity__c, Personal_Phone_Number__c, Title__c,
                            Languages_Spoken__c, Language_1_Proficiency__c, Language_Spoken_2__c, Language_2_Proficiency__c,
                            Language_Spoken_3__c, Language_3_Proficiency__c, Language_Spoken_4__c, Language_4_Proficiency__c,
                            Language_Spoken_5__c, Language_5_Proficiency__c, Language_Spoken_6__c, Language_6_Proficiency__c
                            FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' AND Name LIKE: searchString];
        }
    }

    public void searchContract(){
        if (isTokenValid()) {
            String searchString = '%' + this.contractSearchName + '%';
            this.contractList = [SELECT Id, Prime_Contracting_Business_Unit__c, Name, Prime_Contracting_Business_Unit__r.Name,
                                 Safety_Contact__c, Contract_End_Date__c
                                 FROM DContract__c WHERE Status__c IN ('Draft', 'Active') AND Name LIKE: searchString];
        }
    }

    public PageReference signIn() {
        PageReference authPage = new PageReference(SFAuthUtils.getSignInUrl(getSettings(), this.callback));
        authPage.setRedirect(true);
        return authPage;
    }

    public Boolean getAccessGranted() {
        if (Test.isRunningTest()) {
            return true;
        }

        if (this.token != null && this.tokenIsValid == true) {
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
        String userEmail = SFAuthUtils.callForUserInfo(this.token); // this method will throw an exception if token is not valid
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
}