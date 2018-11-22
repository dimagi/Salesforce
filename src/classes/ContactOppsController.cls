public class ContactOppsController {

    private List<Account> accts;
    private Contact cntact;
    private List<String> children;

    public ContactOppsController(ApexPages.StandardController controller) {
        this.cntact = (Contact)controller.getRecord();
    }

    public List<Account> getAccts() {
        Contact con = [SELECT Id, Account.Id, Account.ParentId FROM Contact WHERE Id =: cntact.Id];
        if (con.Account == null)
            return null;

        children = this.getChildAccounts(con.Account);
        accts = [SELECT id, Name, Country__c FROM Account];
        return accts;
    }

    public List<String> getChildAccounts(Account parentAccount) {
        List<String> testing;
        Account pAcct = [SELECT id from Account where id = :parentAccount.Id];
        testing.add(pAcct.Id);
        return testing;
    }
}