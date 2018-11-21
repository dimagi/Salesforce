public with sharing class CountryAccounts {

    public CountryAccounts(ApexPages.StandardController controller) {}

    /**
     * Return Open Accounts.
     */
    public Account[] getOpenAccounts() {
        Account[] openAccountList;
        openAccountList = [SELECT Name, Id, Phone, Country__c FROM Account];
        return openAccountList;
    }
}