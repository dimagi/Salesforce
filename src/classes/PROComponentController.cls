public class PROComponentController {

    public String employeeEmail { get; set; }
    public DimagiToolsController pageController { get; set; }

    public String lastPROId { get; set; }
    public Boolean showDevWork { get; set; }
    public String status{ get; set; }
    public String toMeetSchedule { get; set; }
    public String stayWithinScope { get; set; }
    public String reportContractId { get; set; }
    public String currentSystemUsage { get; set; }
    public String partnerRelationship { get; set; }
    public Decimal proTabContractPercntgethroughSOW { get; set; }
    public Project_Report_Out__c pro { get; set; }
    public DContract__c proTabContract { get; set; }
    public Map<Id, DContract__C> contractIdName { get; set; }
    public List<SelectOption> statusList {
        get {
            return SFUtils.getPicklistValues(new Project_Report_Out__c(), 'Status__c');
        }
        set;
    }
    public Project_Report_Out__c submittedPro { get; set; }
    public Boolean editMode { get; set; }

    private Id submitedPROId;

    public PROComponentController() {
        this.contractIdName = new Map<Id, DContract__C> {};
        this.editMode = true;
    }

    public void loadProjectReport() {
        this.pro = new Project_Report_Out__c();
        this.proTabContract = this.contractIdName.get(this.reportContractId);
        this.proTabContractPercntgethroughSOW = this.proTabContract.Percent_through_SOW_deliverables__c != null ?
                                                    Integer.valueOf(this.proTabContract.Percent_through_SOW_deliverables__c) :
                                                    Integer.valueOf(this.proTabContract.Percent_through_Contract__c);

        List<Project_Report_Out__c> prlist = new List<Project_Report_Out__c>(
                                                                [SELECT Id, PM_email__c, Cap_planning_GDoc__c, Key_Accomplishments_Last_Two_Weeks__c,
                                                                 Key_Next_Steps_next_2_weeks__c, Client_Facing__c, Requires_Developer_Work__c, Ability_to_meet_Schedule__c,
                                                                 Ability_to_stay_within_Scope__c, Current_System_Usage__c, Partner_Relationship__c,
                                                                 Issues_Questions_Notables__c, Resource_Planning__c, Contract__r.Requires_Developer_Work__c,
                                                                 Project_Dashboard__c FROM Project_Report_Out__c
                                                                 WHERE Contract__c =: this.reportContractId ORDER BY LastModifiedDate DESC LIMIT 1]
                                                            );
        this.pro.PM_email__c = this.employeeEmail;

        if (!prlist.isEmpty()) {
            this.lastPROId = prlist[0].Id;
            this.showDevWork = prlist[0].Contract__r.Requires_Developer_Work__c;
            this.toMeetSchedule = prlist[0].Ability_to_meet_Schedule__c;
            this.stayWithinScope = prlist[0].Ability_to_stay_within_Scope__c;
            this.currentSystemUsage = prlist[0].Current_System_Usage__c;
            this.partnerRelationship = prlist[0].Partner_Relationship__c;

            this.pro.Report_Out_Date__c = System.today();
            this.pro.Key_Accomplishments_Last_Two_Weeks__c = prlist[0].Key_Accomplishments_Last_Two_Weeks__c;
            this.pro.Key_Next_Steps_next_2_weeks__c = prlist[0].Key_Next_Steps_next_2_weeks__c;
            this.pro.Issues_Questions_Notables__c = prlist[0].Issues_Questions_Notables__c;
            this.pro.Client_Facing__c = prlist[0].Client_Facing__c;
            this.pro.Requires_Developer_Work__c = prlist[0].Requires_Developer_Work__c;
            this.pro.Project_Dashboard__c = prlist[0].Project_Dashboard__c;
            this.pro.Resource_Planning__c = '----';
            this.pro.Cap_planning_GDoc__c = prlist[0].Cap_planning_GDoc__c;
        } else {
            DContract__c contractObj = [SELECT Id, Requires_Developer_Work__c FROM DContract__c
                                        WHERE Id =: this.reportContractId LIMIT 1];
            this.showDevWork = contractObj.Requires_Developer_Work__c;
            this.toMeetSchedule = null;
            this.stayWithinScope = null;
            this.currentSystemUsage = null;
            this.partnerRelationship = null;

            this.lastPROId = null;
            this.pro.Report_Out_Date__c = System.today();
            this.pro.Key_Accomplishments_Last_Two_Weeks__c = null;
            this.pro.Key_Next_Steps_next_2_weeks__c = null;
            this.pro.Issues_Questions_Notables__c = null;
            this.pro.Client_Facing__c = null;
            this.pro.Requires_Developer_Work__c = null;
            this.pro.Project_Dashboard__c = null;
            this.pro.Resource_Planning__c = '----';
            this.pro.Cap_planning_GDoc__c = null;
        }
    }

    public List<DimagiToolsController.PROProject> getProContracts() {
        if (!this.pageController.getAccessGranted()) {
            return null;
        }
        List<DimagiToolsController.PROProject> proList = new List<DimagiToolsController.PROProject>();

        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c, Last_Report_Out_Date__c, Last_Report_Out_Status__c,
                                    Percent_through_SOW_deliverables__c , Percent_through_Contract__c, Margin_by_Contract_Dates__c,
                                    Margin_by_SOW_Completed__c, Expected_Margin__c, Execution_Efficiency__c
                                    FROM DContract__c
                                    WHERE Requires_Report_Out__c = 'Yes' AND (
                                        (In_Charge_Of_Report_Out__c = 'Project Manager' AND Project_Manager__r.Email =: this.employeeEmail) OR
                                        (In_Charge_Of_Report_Out__c = 'Field Manager' AND Field_Manager__r.Email =: this.employeeEmail) OR
                                        (In_Charge_Of_Report_Out__c = 'Backstop' AND Backstop__r.Email =: this.employeeEmail)
                                        OR Owner.Email =: this.employeeEmail)
                                   ORDER BY Name];

        if (contracts.size() > 0 && this.reportContractId == null) {
            this.reportContractId = contracts[0].id;
            this.proTabContract = contracts[0];
            this.proTabContractPercntgethroughSOW = contracts[0].Percent_through_SOW_deliverables__c != null ? Integer.valueOf(contracts[0].Percent_through_SOW_deliverables__c) :
                                                                    Integer.valueOf(contracts[0].Percent_through_Contract__c);
            for(DContract__c dc : contracts) {
                contractIdName.put(dc.Id, dc);
            }
            loadProjectReport();
        }

        for (DContract__c dc : contracts) {
            DimagiToolsController.PROProject prObj = new DimagiToolsController.PROProject();
            prObj.contract = dc;
            if(this.reportContractId != null && this.reportContractId != '') {
                prObj.cssClass = dc.Id == this.reportContractId ? 'bgColorCls' : '';
            }
            proList.add(prObj);
        }
        return proList;
    }

    public Boolean validData() {
        if (this.reportContractId == null || this.reportContractId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        if (this.status == null || this.status == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Status cannot be blank'));
            return false;
        }
        if (this.pro.PM_email__c == null || this.pro.PM_email__c == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Email cannot be blank'));
            return false;
        }
        if (this.pro.Report_Out_Date__c == null ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Report out Date cannot be blank'));
            return false;
        }
        if (this.proTabContractPercntgethroughSOW == null ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, '% Deliverables Completed'));
            return false;
        }
        return true;
    }

    public PageReference save() {
        if (!this.pageController.isTokenValid()) {
            return null;
        }
        PageReference page = null;
        try {
            if (validData()) {
                List<Project_Report_Out__c> proList = new List<Project_Report_Out__c>([SELECT Id, Name, Last_Report_ID__c, Contract_Snapshot__c, Contract__c,
                                                                                       Status__c, Ability_to_meet_Schedule__c, Ability_to_stay_within_Scope__c,
                                                                                       Current_System_Usage__c, Partner_Relationship__c, User_Name__c,
                                                                                       Key_Accomplishments_Last_Two_Weeks__c, Key_Next_Steps_next_2_weeks__c,
                                                                                       Issues_Questions_Notables__c, Client_Facing__c, Requires_Developer_Work__c,
                                                                                       Project_Dashboard__c, Resource_Planning__c, Cap_planning_GDoc__c, PM_email__c
                                                                                       FROM Project_Report_Out__c
                                                                                       WHERE Contract__c =: this.reportContractId AND Report_Out_Date__c =: this.pro.Report_Out_Date__c LIMIT 1]);

                Project_Report_Out__c proToUpdate = createPROToUpdate(proList.isEmpty() ? null : proList[0]);
                DContract__c dcontract = [SELECT Id, Name, Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c, Budget_Used__c, of_Services_budget_for_GS__c, Total_Costs__c, Services_Spend__c,
                                          Execution_Efficiency__c, Expected_Buffer__c, Direct_Costs_Total_Expenses__c, Net_Income_based_on_SOW_Completed__c, Product_Spend__c,Buffer_by_SOW_Completed__c,
                                          GS_Execution_Budget__c, GS_Services_Completed__c, GS_Net_Income_to_Date__c, GS_Net_Income_to_Date_Handover__c, GS_Services_Completed_Handover__c,
                                          Project_Quality_Overall_Status__c, Customer_Satisfaction_of_services__c, GS_Project_Services_Budget_Handoff__c FROM DContract__c WHERE Id =: this.reportContractId];


                dcontract.Percent_through_SOW_deliverables__c = this.proTabContractPercntgethroughSOW;
                PRO_Contract_Snapshot__c proContractSnapshot = createProSnapshot(proToUpdate.Contract_Snapshot__c == null ? null : proToUpdate.Contract_Snapshot__c, dcontract);

                Decimal percent = 0;
                if (this.status == 'Green') {
                    percent = 1;
                } else if (this.status == 'Yellow') {
                    percent = 0.5;
                }
                Decimal projectQuality = percent * (dcontract.GS_Execution_Budget__c != null ? dcontract.GS_Execution_Budget__c : 0);
                proContractSnapshot.Project_Quality_Overall_Status__c = projectQuality;
                dcontract.Project_Quality_Overall_Status__c = projectQuality;

                percent = 0;
                if (this.partnerRelationship == 'Green') {
                    percent = 1;
                } else if (this.partnerRelationship == 'Yellow') {
                    percent = 0.5;
                }
                Decimal customerSatisfaction = percent * (dcontract.GS_Execution_Budget__c != null ? dcontract.GS_Execution_Budget__c : 0);
                proContractSnapshot.Customer_Satisfaction_of_services__c = customerSatisfaction;
                dcontract.Customer_Satisfaction_of_services__c = customerSatisfaction;

                PROEmailContractSnoozeHelper.resetEmailReminder(this.reportContractId);
                upsert proContractSnapshot Id;
                proToUpdate.Contract_Snapshot__c = proContractSnapshot.Id;
                upsert proToUpdate Id;
                update dcontract;

                sendReportEmail(proToUpdate.Id);
                this.submitedPROId = proToUpdate.Id;
                this.editMode = false;
            }
        } catch(DmlException ex) {
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getDmlMessage(0)));
             if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'PRO errors', 'PRO save error', ex);
             }
        } catch (Exception e) {
            System.debug(e);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'There was an error trying to save. Please try again.'));
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'PRO errors', 'PRO save error', e);
            }
        }
        return page;
    }

    public void sendReportEmail(Id proId){
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Project_Report_Out_VF' LIMIT 1].Id;
        List<Contact> contactList = new List<Contact>();
        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE 
                                              Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];

        List<Contract_Contact__c> contractContactList= [SELECT Id, Contact__c, Email__c, Type__c, Contact__r.Email, Contact__r.Id, Contact__r.Name, Contract__c
                                                        FROM Contract_Contact__c WHERE Contract__C =: this.reportContractId];
        List<String> emailList = new List<String>();
        for (Contract_Contact__c conContact : contractContactList) {
            if (conContact.Type__c != 'Email') {
                if (conContact.Contact__r != null) {
                    contactList.add(conContact.Contact__r);
                }
                if (conContact.Contact__r != null && conContact.Contact__r.Email != null && conContact.Contact__r.Email.containsIgnoreCase('dimagi.com')) {
                    emailList.add(conContact.Contact__r.Email);
                }
            } else {
                emailList.add(conContact.Email__c);
            }
        }

        if (contactList.size() > 0 && !Test.isRunningTest()) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTemplateId(templateId);
            msg.setTargetObjectId(contactList[0].Id);
            msg.setToAddresses(emailList);
            msg.setWhatId(proId);
            msg.setSaveAsActivity(false);
            msg.setOrgWideEmailAddressId(orgWideAddress.Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });
        }
    }

    public PageReference submitAnother() {
        this.editMode = true;
        this.submitedPROId = null;
        this.submittedPro = null;
        loadProjectReport();
        return null;
    }

    public void loadSubmittedPro() {
        if(this.submitedPROId != null) {
            submittedPro = [SELECT id,Name,Resource_Planning__c,Status__c,
                      Ability_to_meet_Schedule__c,Ability_to_stay_within_Scope__c,
                      Current_System_Usage__c,Partner_Relationship__c,
                      Key_Accomplishments_Last_Two_Weeks__c,
                      Key_Next_Steps_next_2_weeks__c,Issues_Questions_Notables__c,
                      Client_Facing__c,Requires_Developer_Work__c,Project_Dashboard__c
                      FROM Project_Report_Out__c
                      WHERE Id =: this.submitedPROId];
        }
    }

    private Project_Report_Out__c createPROToUpdate(Project_Report_Out__c currentPRO) {
        pro.Contract__c = this.reportContractId;
        if (currentPRO != null) { // we must update PRO
            currentPRO.Name = this.contractIdName.get(this.pro.Contract__c).Name + ' - [' + this.pro.Report_Out_Date__c.format() + ']';
            currentPRO.Status__c = status;
            currentPRO.Ability_to_meet_Schedule__c = this.toMeetSchedule;
            currentPRO.Ability_to_stay_within_Scope__c = this.stayWithinScope;
            currentPRO.Current_System_Usage__c = this.currentSystemUsage;
            currentPRO.Partner_Relationship__c = this.partnerRelationship;
            currentPRO.User_Name__C = this.employeeEmail;
            currentPRO.Report_Out_Date__c = this.pro.Report_Out_Date__c;
            currentPRO.Key_Accomplishments_Last_Two_Weeks__c = this.pro.Key_Accomplishments_Last_Two_Weeks__c;
            currentPRO.Key_Next_Steps_next_2_weeks__c = this.pro.Key_Next_Steps_next_2_weeks__c;
            currentPRO.Issues_Questions_Notables__c = this.pro.Issues_Questions_Notables__c;
            currentPRO.Client_Facing__c = this.pro.Client_Facing__c;
            currentPRO.Requires_Developer_Work__c = this.pro.Requires_Developer_Work__c;
            currentPRO.Project_Dashboard__c = this.pro.Project_Dashboard__c;
            currentPRO.Resource_Planning__c = this.pro.Resource_Planning__c;
            currentPRO.Cap_planning_GDoc__c = this.pro.Cap_planning_GDoc__c;
            currentPRO.PM_email__c = this.pro.PM_email__c;

            return currentPRO;
        } else {
            this.pro.Last_Report_ID__C = this.lastPROId;
            this.pro.Name = contractIdName.get(this.pro.Contract__c).Name + ' - [' + this.pro.Report_Out_Date__c.format() + ']';
            this.pro.Status__c = this.status;
            this.pro.Ability_to_meet_Schedule__c = this.toMeetSchedule;
            this.pro.Ability_to_stay_within_Scope__c = this.stayWithinScope;
            this.pro.Current_System_Usage__c = this.currentSystemUsage;
            this.pro.Partner_Relationship__c = this.partnerRelationship;
            this.pro.User_Name__C = employeeEmail;

            return this.pro;
        }
    }

    private PRO_Contract_Snapshot__c createProSnapshot(Id currentSnapshot, DContract__c dcontract) {
        PRO_Contract_Snapshot__c proContractSnapshot = new PRO_Contract_Snapshot__c();
        if (currentSnapshot != null) { // we must update snapshot
            proContractSnapshot.Id = currentSnapshot;
        }
        if (dcontract != null) {
            dcontract.recalculateFormulas();
        }

        return SnapshotHelper.fillPROSnapshot(pro.Report_Out_Date__c, proContractSnapshot, dcontract, SnapshotHelper.getLastPROSnapshot(dcontract, currentSnapshot));
    }
}