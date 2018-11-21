public  class PROAllProjectsComponentController {

    public String employeeEmail { get; set; }
    public DimagiToolsController pageController { get; set; }

    public String projectId { get; set; }
    public List<Contract_Contact__c> contractContacts { get; set; }
    public List<Contract_Contact__c> contractContactsProject { get; set; }
    public String removeEmailId { get; set; }
    public Id removeContactId { get; set; }
    public DContract__c project { get; set; }
    public List<Project_Report_Out__c> LastRepotOuts { get; set; }
    public boolean enableAddButton{ get; set; }
    public String selectedProjectId { get; set; }
    private List<Contract_Contact__c> deleteContactList = new List<Contract_Contact__c>();

    public PROAllProjectsComponentController() {
        
    }

    public List<DimagiToolsController.PROProject> getProjectsList() {
        if (!this.pageController.getAccessGranted()) {
            return null;
        }
        List<DimagiToolsController.PROProject> proList = new List<DimagiToolsController.PROProject>();
        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Percent_through_Contract__c, Percent_through_SOW_deliverables__c
                                    FROM DContract__c
                                    WHERE Requires_Report_Out__c = 'Yes'
                                    ORDER BY Name];

        if (contracts.size() > 0 && this.selectedProjectId == null) {
            if (this.projectId != null && this.projectId != 'null' && this.projectId != ' ') {
                this.projectId = '' + this.projectId;
                this.selectedProjectId = this.projectId;
                this.projectId = null;
            } else {
                this.selectedProjectId = contracts[0].Id;
            }
            fillProjectDetails();
        }

        for (DContract__c dc : contracts) {
            DimagiToolsController.PROProject prObj = new DimagiToolsController.PROProject();
            prObj.Contract = dc;
            if (selectedProjectId != null && selectedProjectId != '') {
                prObj.cssClass = dc.id == selectedProjectId ? 'bgColorCls' : '';
            }
            proList.add(prObj);
        }

        return proList;
    }

    public void fillProjectDetails() {
        if (!this.pageController.getAccessGranted()) {
            return;
        }
        this.deleteContactList.clear();
        this.contractContacts = new List<Contract_Contact__c>();

        List<DContract__c> contractList = [SELECT Id, Project_Manager__c, Backstop__c, Field_Manager__c, In_Charge_Of_Report_Out__c FROM DContract__c
                                                 WHERE Id =: this.selectedProjectId];

        if (contractList != null && contractList.size() > 0) {
            this.project = contractList[0];
        }

        this.contractContactsProject = [SELECT Id, Contact__c, Contract__c, Type__c, Email__c FROM Contract_Contact__c WHERE Contract__c =: selectedProjectId AND Type__c NOT in('Person','Email')];
        this.contractContacts = [SELECT Id, Contact__c, Contract__c, Type__c, Email__c  FROM Contract_Contact__c WHERE Contract__c =: selectedProjectId AND Type__C in ('Person', 'Email') ORDER BY Type__c DESC];
        this.lastRepotOuts = [SELECT id,Name,status__c,Contract__r.Name,Contract__r.Last_Report_Out_Date__c,Report_Out_Date__c  FROM Project_Report_Out__c
                         WHERE Contract__C =: selectedProjectId ORDER BY Report_Out_Date__c DESC];
        this.enableAddButton = true;
    }

    public PageReference saveProjectOnly() {
        PageReference page = null;
        if (!this.pageController.isTokenValid()) {
            return page;
        }
        saveProjectData();
        return page;
    }

    public PageReference saveProject() {
        PageReference page = null;
        if (!this.pageController.isTokenValid()) {
            return page;
        }
        saveProjectData();
        saveContactData();

        return page;
    }

    public void saveContact() {
        if (!this.pageController.isTokenValid()) {
            return;
        }
        saveContactData();
    }

    public Boolean validateProject() {
        if (this.selectedProjectId == null || this.selectedProjectId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }
        return true;
    }

    public void removeContact() {
        if (this.contractContacts.size() > 0) {
            Integer removeIndex = -1;
            for (Integer index = 0; index < this.contractContacts.size(); index++) {
                Contract_Contact__c ct = this.contractContacts[index];
                if (ct.Contact__c == this.removeContactId) {
                    if (ct.id != null) {
                        this.deleteContactList.add(ct);
                    }

                    removeIndex = index;
                    break;
                }
            }

            if (removeIndex == -1) {
                for (Integer index = 0; index < this.contractContacts.size(); index++) {
                    Contract_Contact__c ct = this.contractContacts[index];
                    if (ct.Type__c == 'Person' && ct.Contact__c == null) {
                        removeIndex = index;
                        break;
                    }
                }
            }

            if (removeIndex != -1) {
                this.contractContacts.remove(removeIndex);
            }
        }
    }

    public void removeEmail() {
        if (this.contractContacts.size() > 0) {
            Integer removeIndex = -1;

            for (Integer index = 0; index < this.contractContacts.size(); index++) {
                Contract_Contact__c ct = this.contractContacts[index];
                if (ct.Email__c == this.removeEmailId) {
                    if (ct.id != null) {
                        this.deleteContactList.add(ct);
                    }

                    removeIndex = index;
                    break;
                }
            }

            if (removeIndex == -1) {
                for (Integer index = 0; index < this.contractContacts.size(); index++) {
                    Contract_Contact__c ct = this.contractContacts[index];
                    if (ct.Type__c == 'Email' && ct.Email__c == null) {
                        removeIndex = index;
                        break;
                    }
                }
            }

            if (removeIndex != -1) {
                this.contractContacts.remove(removeIndex);
            }
        }
    }

    public void addContact() {
        addToContractContacts('Person');
    }

    public void addEmail() {
        addToContractContacts('Email');
    }

    public void addMe() {
        List<Contact> contList = [SELECT Id,Name FROM Contact WHERE Email =: this.employeeEmail];

        if (contList.size() > 0) {
            Contract_Contact__c contractContact = new Contract_Contact__c();
            contractContact.Contract__c = selectedProjectId;
            contractContact.Type__C = 'Person';
            contractContact.Contact__C = contList[0].id;
            this.contractContacts.add(contractContact);
        }
    }


    private void saveProjectData() {
        if (validateProject()) {
            try {
                update this.project;
            } catch (DmlException ex) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getDmlMessage(0)));
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            }

            this.contractContactsProject = [SELECT Id, Contact__c, Contract__c, Type__c, Email__c FROM Contract_Contact__c
                                            WHERE Contract__C =: this.selectedProjectId AND Type__c NOT IN('Person','Email')];
        }
    }

    private void saveContactData() {
        List<Integer> removeIndex = new List<Integer>();
        if (this.contractContacts != null) {
            for (Integer index = 0; index < this.contractContacts.size(); index++) {
                Contract_Contact__c contContact = this.contractContacts[index];
                if (contContact.Contact__c != null || contContact.Email__c != null) {
                     upsert contContact;
                } else {
                    if (contContact.Id != null) {
                        removeIndex.add(index);
                        delete contContact;
                    }
                }
            }
        }

        for (Integer index = 0 ;index < removeIndex.size(); index++) {
            this.contractContacts.remove(removeIndex[index]);
        }

        if (this.deleteContactList.size() > 0) {
            delete this.deleteContactList;
            this.deleteContactList.clear();
        }
    }

    private void addToContractContacts(String contactType) {
        Contract_Contact__c contractContact = new Contract_Contact__c();
        contractContact.Contract__c = selectedProjectId;
        contractContact.Type__C = contactType;
        this.contractContacts.add(contractContact);
    }
}