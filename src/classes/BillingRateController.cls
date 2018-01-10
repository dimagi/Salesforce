/**
 * BillingRateController used for manage Billing Rates used for caclulating time card costs for COntracts
 */
public class BillingRateController {

    public List<Project_Billing_Rate__c> billingRates {get; set;}
    public Project_Billing_Rate__c newBillingRate {get; set;}

    public Id billingRateId {get; set;}
    public String billingRateName {get; set;}
    public List<Project_Billing_Rate__c> rateHistoryList {get; set;}

    public BillingRateController() {
        
    }

    public void setViewData() {
        
    }

    public void initManageRates() {
        List<Project_Billing_Rate__c> dataBR = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c FROM Project_Billing_Rate__c];
        Set<String> names = new Set<String>();
        this.billingRates = new List<Project_Billing_Rate__c>();
        for (Project_Billing_Rate__c rate : dataBR) {
            if (!names.contains(rate.Name)) {
                this.billingRates.add(rate);
                names.add(rate.Name);
            }
        }

        this.newBillingRate = new Project_Billing_Rate__c(Date__c = Date.newInstance(2000, 01, 01), Name = '', Custom_1__c = 0, Overhead__c = 0, 
                                                            G_A__c = 0, Fringe__c = 0, Fee__c = 0, Custom_2__c = 0, Custom_3__c = 0);
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

    /**
     * Manage Rate section.
     */
    public void initManageRate() {
        if (this.billingRateName == null || this.billingRateName == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Rate Name cannot be empty'));
            return;
        }

        this.rateHistoryList = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName ORDER BY Date__c];
        this.newBillingRate = new Project_Billing_Rate__c(Date__c = Date.newInstance(2000, 01, 01), Name = this.billingRateName, Custom_1__c = 0, Overhead__c = 0,
                                                            G_A__c = 0, Fringe__c = 0, Fee__c = 0, Custom_2__c = 0, Custom_3__c = 0);
    }

    public void saveNewRateHistory() {
        if (this.newBillingRate.Date__c == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Effective Data cannot be empty.'));
            return;
        }
        if (this.newBillingRate.Name == '' || this.newBillingRate.Name == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Name cannot be empty.'));
            return;
        }
        insert this.newBillingRate;
        initManageRate();
    }

    public PageReference goToRateListView() {
        this.billingRateName = null;
        PageReference pageRef = Page.Billing_Rates_List;
        pageRef.setRedirect(false);
        return pageRef;
    }

    public PageReference goToRateUpdateView() {
        PageReference pageRef = Page.Billing_Rate_Upsert;
        pageRef.setRedirect(false);
        return pageRef;
    }

    public void initUpdateRate() {
        this.newBillingRate = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Id =: this.billingRateId];
        if (this.newBillingRate == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find record.'));
        }
    }

    public PageReference updateRateHistory() {
        if (this.newBillingRate.Date__c == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Effective Data cannot be empty.'));
            return null;
        }
        update this.newBillingRate;
        return goToRateView();
    }

    public PageReference deleteRateRow() {
        if ([SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName].size() > 1) {
            delete this.newBillingRate; // We don't want remove rate to avoid some bugs in future
        }
        return goToRateView();
    }
}