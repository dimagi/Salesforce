/**
 * Controller for FTE_Project_List_View, allows to manage FTE contracts.
 */
public class FTEProjectListController {

    public List<DContract__c> fteContractList { get; set;}
    public List<DContract__c> fteContractSearchList { get; set;}

    public List<DContract__c> finalFteContracts {get; set;}
    public List<DContract__c> toAddContracts {get; set;}
    public List<DContract__c> toRemoveContracts {get; set;}

    public Id contractId { get; set;}
    public String searchError { get; set;}
    public String seachProjectName { get; set;}
    public Boolean projectListUpdated { get; set;}
    public JobWrapper workCardJobStatus {get; set;}

    public FTEProjectListController() {
        this.seachProjectName = '';
        this.searchError = '';
        this.fteContractSearchList = new List<DContract__c>();
        this.toAddContracts = new List<DContract__c>();
        this.toRemoveContracts = new List<DContract__c>();
        this.projectListUpdated = false;
    }

    public void initProjectList() {
        loadWorkCardJobStatus();
    }

    public void updateFteContracts() {
        for (DContract__c dc : this.toAddContracts) {
            dc.FTE_Tracker__c = 'Yes';
        }
        for (DContract__c dc : this.toRemoveContracts) {
            dc.FTE_Tracker__c = 'No';
        }
        List<DContract__c> forUpdate = new List<DContract__c>();
        forUpdate.addAll(this.toAddContracts);
        forUpdate.addAll(this.toRemoveContracts);
        if (forUpdate.size() > 0) {
            update forUpdate;
        }
        this.toAddContracts.clear();
        this.toRemoveContracts.clear();
        this.projectListUpdated = false;
        loadWorkCardJobStatus();
    }

    public List<DContract__c> getListToSubmit() {
        if (this.fteContractList == null) {
           this.fteContractList = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c
                                                 WHERE FTE_Tracker__c = 'Yes' ORDER BY Name];
        }

        return this.fteContractList;
    }

    public void searchProject() {
        if (this.seachProjectName != null && this.seachProjectName != '') {
            String seachProjectNameExpr = seachProjectName + '%';
            this.fteContractSearchList = [SELECT Id, Name, Status__c FROM DContract__c WHERE Id NOT IN : this.fteContractList
                    AND Name LIKE: seachProjectNameExpr LIMIT 20];

            if(this.fteContractSearchList.size() == 0) {
                this.searchError = 'No projects were found.';
            } else {
                this.searchError = '';
            }
        } else {
            this.fteContractSearchList.clear();
            this.searchError = 'Name cannot be empty';
        }
    }

    public void addProjectToFteTracker() {
        if (this.contractId != null) {
            List<DContract__c> recordsFromDb = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c WHERE Id =: this.contractId];
            if (recordsFromDb.size() > 0) {
                DContract__c newFteContract = recordsFromDb.get(0);
                Boolean aleradyAdded = false;
                for (DContract__c cc : fteContractList) {
                    if (cc.Id == newFteContract.Id) {
                        aleradyAdded = true;
                        break;
                    }
                }
                if (!aleradyAdded) {
                    this.fteContractList.add(newFteContract);
                    this.toAddContracts.add(newFteContract);
                }

                //check removed list
                Integer index = -1;
                for (Integer i = 0 ; i < this.toRemoveContracts.size(); i++) {
                    if (this.toRemoveContracts.get(i).Id == this.contractId) {
                        index = i;
                        break;
                    }
                }
                if (index > -1) {
                    this.toRemoveContracts.remove(index);
                }
            }
            this.projectListUpdated = true;
        }
        this.contractId = null;
    }

    public void removeProjectFromFteTracker() {
        if (this.contractId != null) {
            Integer index = -1;
            for (Integer i = 0; i < fteContractList.size(); i++) {
                if (fteContractList.get(i).Id == this.contractId) {
                    index = i;
                    break;
                }
            }
            if (index > -1) {
                DContract__c contractToRem = fteContractList.get(index);
                fteContractList.remove(index);
                this.toRemoveContracts.add(contractToRem);
            }

            //check added list
            index = -1;
            for (Integer i = 0 ; i < this.toAddContracts.size(); i++) {
                if (this.toAddContracts.get(i).Id == this.contractId) {
                    index = i;
                    break;
                }
            }
            if (index > -1) {
                this.toAddContracts.remove(index);
            }
            this.projectListUpdated = true;
        }
        this.contractId = null;
    }

    public PageReference goToEmployeeListView() {
        return Page.FTE_Employee_List_View;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageref.getParameters().put('contractId', this.contractId);
        return pageref;
    }

   public void loadWorkCardJobStatus() {
        this.workCardJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }
}