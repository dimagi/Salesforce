/**
 * BillingRateController used for manage Billing Rates used for caclulating time card costs for COntracts
 */
public class BillingRateController {

    public List<Project_Billing_Rate__c> billingRates {get; set;}
    public Project_Billing_Rate__c newBillingRate {get; set;}

    public Boolean requiredRefresh {get; set;}
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

        this.newBillingRate = new Project_Billing_Rate__c(Date__c = Date.newInstance(2000, 1, 1), Name = '', Custom_1__c = 0, Overhead__c = 0,
                                                            G_A__c = 0, Fringe__c = 0, Fee__c = 0, Custom_2__c = 0, Custom_3__c = 0);
        List<Project_Billing_Rate_Update__c> updatesList = [SELECT Id, Name, From_Range__c, To_Range__c FROM Project_Billing_Rate_Update__c];
        if (updatesList.size() > 0) {
            this.requiredRefresh = true;
        }
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
        pageRef.setRedirect(true);
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlEncode(this.billingRateName, 'UTF-8'));
        return pageRef;
    }

    public void initManageRate() {
        this.billingRateName = ApexPages.currentPage().getParameters().get('billingRateName');
        if (this.billingRateName != null) {
            this.billingRateName = EncodingUtil.urlDecode(this.billingRateName, 'UTF-8');
        }
        if (this.billingRateName == null || this.billingRateName == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Rate Name cannot be empty'));
            return;
        }

        this.rateHistoryList = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName ORDER BY Date__c];
        if (rateHistoryList.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find Billing Rate'));
            return;
        }
        this.newBillingRate = new Project_Billing_Rate__c(Date__c = Date.today(), Name = this.billingRateName, Custom_1__c = 0, Overhead__c = 0,
                                                            G_A__c = 0, Fringe__c = 0, Fee__c = 0, Custom_2__c = 0, Custom_3__c = 0);
        this.requiredRefresh = false;
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
        handleInsert();
        initManageRate();
    }

    public PageReference goToRateListView() {
        PageReference pageRef = Page.Billing_Rates_List;
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference goToRateUpdateView() {
        PageReference pageRef = Page.Billing_Rate_Upsert;
        pageRef.setRedirect(true);
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlEncode(this.billingRateName, 'UTF-8'));
        pageRef.getParameters().put('billingRateId', this.billingRateId);
        return pageRef;
    }

    public void initUpdateRate() {
        String upbillingRateId = ApexPages.currentPage().getParameters().get('billingRateId');
        if (upbillingRateId != null && upbillingRateId InstanceOf Id) {
            this.billingRateId = upbillingRateId;
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Rate Id cannot be empty'));
            return;
        }

        this.billingRateName = ApexPages.currentPage().getParameters().get('billingRateName');
        if (this.billingRateName != null) {
            this.billingRateName = EncodingUtil.urlDecode(this.billingRateName, 'UTF-8');
        }
        if (this.billingRateName == null || this.billingRateName == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Rate Name cannot be empty'));
            return;
        }

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
        handleUpdate();
        update this.newBillingRate;
        return goToRateView();
    }

    public PageReference deleteRateRow() {
        if ([SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName].size() > 1) {
            handleDelete();
            delete this.newBillingRate; // We don't want remove rate to avoid some bugs in future
        }
        return goToRateView();
    }

    public void handleInsert() {
        Project_Billing_Rate__c nextRow = getNext();
        Project_Billing_Rate__c beforeRow = getBefore();
        Date fromDate = beforeRow != null ? this.newBillingRate.Date__c : Date.newInstance(2000, 1, 1);
        Date toDate = nextRow != null ? nextRow.Date__c : Date.today();
        insert new Project_Billing_Rate_Update__c(Name = this.billingRateName, From_Range__c = fromDate, To_Range__c = toDate);
    }

    public void handleUpdate() {
        Project_Billing_Rate__c nextRow = getNext();
        Project_Billing_Rate__c beforeRow = getBefore();
        Project_Billing_Rate__c oldValue = [SELECT Id, Date__c FROM Project_Billing_Rate__c WHERE Id =: this.newBillingRate.Id];

        Date fromDate = null;

        if (oldValue.Date__c != this.newBillingRate.Date__c) {
            if (oldValue.Date__c > this.newBillingRate.Date__c) {
                fromDate = this.newBillingRate.Date__c;
            } else {
                fromDate = oldValue.Date__c;
            }
        } else {
            fromDate = beforeRow != null ? this.newBillingRate.Date__c : Date.newInstance(2000, 1, 1);
        }

        Date toDate = nextRow != null ? nextRow.Date__c : Date.today();
        insert new Project_Billing_Rate_Update__c(Name = this.billingRateName, From_Range__c = fromDate, To_Range__c = toDate);
    }

    public void handleDelete() {
        Project_Billing_Rate__c nextRow = getNext();
        Project_Billing_Rate__c beforeRow = getBefore();
        Date fromDate = beforeRow != null ? this.newBillingRate.Date__c : Date.newInstance(2000, 1, 1);
        Date toDate = nextRow != null ? nextRow.Date__c : Date.today();
        insert new Project_Billing_Rate_Update__c(Name = this.billingRateName, From_Range__c = fromDate, To_Range__c = toDate);
    }

    public void runRecalculationBatchJob() {
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name='TimeCardCalculator' OR Name = 'BatchCalculateTotalHoursOfTimeCard' OR Name = 'BatchUpdateContractServicesSpend'
                                                                OR Name = 'BatchRecalculateTimeCardCost' LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Time Card Calculator is running right now, cannot schedule two jobs at the same time. Please try again after few minutes.'));
            return;
        }

        List<Project_Billing_Rate_Update__c> updatesList = [SELECT Id, Name, From_Range__c, To_Range__c FROM Project_Billing_Rate_Update__c];

        if (updatesList.size() > 0) {
            Database.executeBatch(new TimeCardCalculator(updatesList), 200);
            delete updatesList;
        }

        this.requiredRefresh = false;
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Recalculations Job was scheduled.'));
    }

    public Project_Billing_Rate__c getNext() {
        List<Project_Billing_Rate__c> rateFromDB = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName ORDER BY Date__c];
        Integer index = -1;
        for (Integer i = 0; i < rateFromDB.size(); i++) {
            if (rateFromDB.get(i).Id == this.newBillingRate.Id) {
                index = i;
            }
        }
        if (index != -1 && index + 1 < rateFromDB.size()) {
            return rateFromDB.get(index + 1);
        }
        return null;
    }

    public Project_Billing_Rate__c getBefore() {
        List<Project_Billing_Rate__c> rateFromDB = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c
                                                FROM Project_Billing_Rate__c WHERE Name =: this.billingRateName ORDER BY Date__c];
        Integer index = -1;
        for (Integer i = 0; i < rateFromDB.size(); i++) {
            if (rateFromDB.get(i).Id == this.newBillingRate.Id) {
                index = i;
            }
        }
        if (index > 0) {
            return rateFromDB.get(index - 1);
        }
        return null;
    }
}