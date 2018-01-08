/**
 * BillingRateController used for manage Billing Rates used for caclulating time card costs for COntracts
 */
public class BillingRateController {

    public List<Project_Billing_Rate__c> billingRates {get; set;}
    public Project_Billing_Rate__c newBillingRate {get; set;}
    public String billingRateName {get; set;}

    public BillingRateController() {
        
    }

    public void setViewData() {
        
    }

    public void initManageRates() {
        this.billingRates = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c FROM Project_Billing_Rate__c];
        this.newBillingRate = new Project_Billing_Rate__c(Date__c = Date.newInstance(2000, 01, 01), Name = '', Custom_1__c = 0, Overhead__c = 0, G_A__c = 0, Fringe__c = 0, Fee__c = 0, Custom_2__c = 0, Custom_3__c = 0);
    }

    public void saveNewRate() {
        if ([SELECT Id FROM Project_Billing_Rate__c WHERE Name =: this.newBillingRate.Name].size() > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Billing Rate already exist.'));
            return;
        }
        if (this.newBillingRate.Date__c == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Effective Data cannot be empty.'));
            return;
        }
        if (this.newBillingRate.Name == '' || this.newBillingRate.Name == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Name cannot be empty.'));
            return;
        }
        insert this.newBillingRate;
        initManageRates();
    }

    public PageReference goToRateView() {
        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.setRedirect(false);
        return pageRef;
    }

    public void initManageRate() {
        
    }

    public void initAddNewRate() {
        
    }

    public void initUpdateRate() {
        
    }

    public void initAddNewRateHistory() {
        
    }
}