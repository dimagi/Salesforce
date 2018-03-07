/**
 * Apex Controller for Global Accounts View
 */
public class CountryListAcc{

    public List<Account> lstAcc {get; set;}
    public List<Contact> lstCon {get; set;}
    public List<DContract__c> lstContr {get; set;}
    public List<DContract__c> lstContrclosed {get; set;}
    public List<Domain__c> lstDomains {get; set;}
    public List<Accounting_Subscription__c> lstSubscriptions {get; set;}
    public List<Opportunity> lstoppty {get; set;}
    public List<Opportunity> lstopptyClosed {get; set;}
    public String searchString {get; set;}
    public Boolean showPage {get; set;}
    public List<AccountWrapper> wrapperList {get; set;}
    public Map<Id, String> accountMap = new Map<Id, String>();

    //Account selected by radio button
    public String selectedAccountId { get; set; }
    public List<Account> childAccounts { get; set; }

    private Set<Id> setId = new Set<Id>();
    private List<Id> accIdList = new List<Id>();

    public CountryListAcc() {
        this.childAccounts = new List<Account>();
        this.lstCon = new List<Contact>();
        this.lstContr = new List<DContract__c>();
        this.lstContrclosed = new List<DContract__c>();
        this.lstDomains = new List<Domain__c>();
        this.lstSubscriptions = new List<Accounting_Subscription__c>();
        this.lstoppty = new List<Opportunity>();
        this.lstopptyClosed = new List<Opportunity>();
        this.showPage = false;
        this.wrapperList = new List<AccountWrapper>();
        this.accountMap.clear();

        String strX = ApexPages.currentPage().getParameters().get('q');
        String accountId = ApexPages.currentPage().getParameters().get('id');

        if(strX != null && strX != '' && strX != 'null') {
            this.searchString = strX;
            search();
            if(accountId != null && accountId != '' && accountId != 'null') {
                this.selectedAccountId = accountId;
                searchByAccount();
            }
        }
    }

    public void search() {
        clearData();

        //Select records from Account according to given search string
        String searchQuery = 'SELECT Name, Id, Country__r.Name, Status__c, Parent.Name FROM Account WHERE Name LIKE \'%'+SearchString+'%\'';
        this.lstAcc = Database.query(searchQuery);

        //Create collection of wrapper class
        if(this.lstAcc.size() > 0){
            for(Account ac : this.lstAcc){
                this.wrapperList.add(new AccountWrapper(ac,false));
                this.setId.add(ac.Id);
                this.accIdList.add(ac.Id);
                this.accountMap.put(ac.Id,ac.Name);
            }
        }

        for(Account acc: [SELECT Name, Id, Country__r.Name, Status__c, Parent.Name FROM Account WHERE ParentId IN : this.accIdList]) {
            if(!this.setId.contains(acc.Id)) {
                this.wrapperList.add(new AccountWrapper(acc, true));
                this.lstAcc.add(acc);
                this.setId.add(acc.Id);
            }
        }
        this.showPage = true;
    }

    public PageReference searchButtonAction() {
        PageReference page = new PageReference('/apex/CountryList?q=' + this.searchString);
        page.setRedirect(true);
        return page;
    }

    public PageReference searchByAccountButtonAction() {
        String selectedAccountName = this.accountMap.get(this.selectedAccountId);
        PageReference page = new PageReference('/apex/CountryList?q=' + selectedAccountName + '&id=' + this.selectedAccountId);
        page.setRedirect(true);
        return page;
    }

    //Action on radiobutton
    public void searchByAccount(){
        //Get child accounts
        this.childAccounts = [Select Name,Id,Country__r.Name,Status__c,Parent.Name from account where Parent.Id =: this.selectedAccountId];

        //Create set of child accounts IDs
        Set<Id> childAccountIDs = new Set<Id>();
        if(this.childAccounts.size() > 0) {
            for(Account ac: this.childAccounts) {
                childAccountIDs.add(ac.Id);
            }
        }

       //Get all children objects by account Id

       //Contacts
        this.lstCon = [SELECT Id, Account.Name, Email, Title, Name, Country__c
                        FROM Contact
                        WHERE AccountId =: this.selectedAccountId];

        //Contracts Open
        this.lstContr = [SELECT Id, Name, Account__c, DContract__c.Account__r.Name,
                                     Contract_Start_Date__c, Contract_End_Date__c, Project_Manager__c,
                                     Project_Manager__r.Name, Status__c, Short_Description__c
                          FROM DContract__c
                          WHERE Account__c =: this.selectedAccountId AND Status__c != 'Complete' ];

        //Contracts Closed
        this.lstContrclosed = [SELECT Id, Name, Account__c, DContract__c.Account__r.Name,
                                     Contract_Start_Date__c, Contract_End_Date__c, Project_Manager__c,
                                     Project_Manager__r.Name, Status__c, Short_Description__c
                                FROM DContract__c
                                WHERE Account__c =: this.selectedAccountId AND Status__c = 'Complete' ];

        //Domains
        this.lstDomains = [SELECT Id, Name, Account__c, Account__r.Name, Project_Length__c, InternalProp_commcare_edition__c, Lifetime_MRR__c,
                                    is_active__c, Is_Inside_Sales__c
                            FROM Domain__c WHERE Account__c =: this.selectedAccountId];

        //Opportunities Open
        this.lstoppty = [SELECT Id, Name,Account.Name, Description, Country__c,Country__r.Name, StageName
                            FROM Opportunity
                            WHERE AccountId =: this.selectedAccountId AND
                                (StageName = 'Stage 1 - Connect' OR StageName = 'Stage 2 - Talking' OR StageName = 'Stage 3 - Prospect' OR
                                StageName = 'Stage 4 - Proposal Development' OR StageName = 'Stage 5 - Submitted' OR StageName = 'Stage 6 - In Negotiations' OR
                                StageName = 'On Hold')];

        //Opportunities Closed
        this.lstopptyClosed = [SELECT Id, Name, Account.Name, Description, Country__c, Country__r.Name, StageName
                                FROM Opportunity
                                WHERE AccountId =: this.selectedAccountId AND (StageName = 'Closed - Lost' OR StageName = 'Closed - Won')];

        //Get all child objects by child accounts IDs

        //Contacts
        List<Contact> lstConChild = [SELECT Id, Account.Name, Email, Title, Name, Country__c
                                        FROM Contact
                                        WHERE AccountId IN: childAccountIDs];
        this.lstCon.addAll(lstConChild);

        //Contracts Open    
        List<DContract__c> lstContrChild =   [SELECT Id, Name, Account__c, DContract__c.Account__r.Name,
                                                         Contract_Start_Date__c, Contract_End_Date__c, Project_Manager__c,
                                                         Project_Manager__r.Name, Status__c, Short_Description__c
                                                FROM DContract__c
                                                WHERE Account__c IN: childAccountIDs AND Status__c != 'Complete'];
        this.lstContr.addAll(lstContrChild);

       //Contracts Closed
        List<DContract__c> lstContrclosedChild = [SELECT Id, Name,Account__c, DContract__c.Account__r.Name,
                                                             Contract_Start_Date__c, Contract_End_Date__c, Project_Manager__c,
                                                             Project_Manager__r.Name, Status__c, Short_Description__c
                                                    FROM DContract__c
                                                    WHERE Account__c IN: childAccountIDs AND Status__c = 'Complete'];
        this.lstContrclosed.addAll(lstContrclosedChild);

        //Domains
        List<Domain__c> lstDomainChilds = [SELECT Id, Name, Account__c, Account__r.Name, Project_Length__c, InternalProp_commcare_edition__c, Lifetime_MRR__c,
                                                    is_active__c, Is_Inside_Sales__c
                                            FROM Domain__c WHERE Account__c IN: childAccountIDs];
        this.lstDomains.addAll(lstDomainChilds);

        // Subscriptions
        this.lstSubscriptions = [SELECT Id, Name, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name,
                                        date_start__c, date_end__c, Software_Plan_Edition__c, accounting_software_monthly_fee__c,
                                        service_type__c
                                    FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c IN: this.lstDomains AND is_active__c = true];

        //Opportunities Open
        List<Opportunity> lstopptyChild = [SELECT Id, Name, Account.Name, Description, Country__c,Country__r.Name, StageName
                                      FROM Opportunity
                                      WHERE AccountId IN: childAccountIDs AND
                                             (StageName = 'Stage 1 - Connect' OR StageName = 'Stage 2 - Talking' OR StageName = 'Stage 3 - Prospect' OR
                                              StageName = 'Stage 4 - Proposal Development' OR StageName = 'Stage 5 - Submitted' OR StageName = 'Stage 6 - In Negotiations' OR
                                              StageName = 'On Hold')];
        this.lstoppty.addAll(lstopptyChild);

        //Opportunities Closed
        List<Opportunity> lstopptyClosedChild = [SELECT Id, Name, Account.Name, Description, Country__c, Country__r.Name, StageName
                                                    FROM Opportunity
                                                    WHERE AccountId IN: childAccountIDs AND
                                                    (StageName = 'Closed - Lost' OR StageName = 'Closed - Won')];
        this.lstopptyClosed.addAll(lstopptyClosedChild);
    }

    private void clearData() {
        this.wrapperList.clear();
        this.childAccounts.clear();
        this.lstCon.clear();
        this.lstContrclosed.clear();
        this.lstDomains.clear();
        this.lstSubscriptions.clear();
        this.lstoppty.clear();
        this.lstopptyClosed.clear();
    }

    public class AccountWrapper {

        public Account acc {get; set;}
        public Boolean child {get; set;}

        public AccountWrapper(Account c,Boolean ch) {
            this.acc = c;
            this.child = ch;
        }
    }
}