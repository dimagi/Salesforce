/**
 * Controller for FTE Tracker views.
 */
public class FTETrackerController {

    private Id testEmployeeId = 'a0Tm0000001h6iy';

    public SFDC_Employee__c employee { get; set;}
    public Integer currentYear { get; set;}
    public Date yearBegin { get; set;}
    public Date yearEnd { get; set;}

    public FTETrackerController () {
        Date currentDate = Date.today(); // settings?
        this.yearBegin = Date.newInstance(currentDate.year(), 1, 1);
        this.yearEnd = Date.newInstance(currentDate.year(), 12, 31);
        this.currentYear = currentDate.year();
    }

    /**
     * Employee view
     */
 
    public EmployeeTime unassigned { get; set;}
    public Map<Id, EmployeeTime> assignedMap { get; set;}
    public List<EmployeeTime> contractsTime { get; set;}
    public Map<Id, EmployeeTime> unassignedMap { get; set;}

    public void loadEmployeeTimeHistory() {
        // Load employee logged time this year
        this.employee = [SELECT Id, Name FROM SFDC_Employee__c WHERE Id =: testEmployeeId LIMIT 1];
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND Date__c >=: this.yearBegin AND Date__c <=: this.yearEnd
                                        ORDER BY Date__c];

        this.assignedMap = new Map<Id, EmployeeTime>();
        this.unassignedMap = new Map<Id, EmployeeTime>();
        this.unassigned = new EmployeeTime('Unassigned', null);
        EmployeeTime tmpHelper;
        for (Time_Card__c timeCard : timeCards) {
            Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
            Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);

            // "Moved from" part
            calculateLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.month());
            // If no FTE Tag values we don't need to process moved hours
            if (timeCard.FTE_Contract__c == null || movedTime == 0) {
                continue;
            }
            // "Moved to" part
            calculateLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.month());
        }
        this.contractsTime = new List<EmployeeTime>();
        if (this.assignedMap.size() > 0) {
             this.contractsTime = this.assignedMap.values();
             this.contractsTime.add(this.unassigned);
        }
    }

    public void setViewData() {
        // We need this empty method to set values before loading new view.
    }

    public PageReference goToAssignView() {
        PageReference pageRef = Page.FTE_Unassign_Days_View;
        if (String.isBlank(this.contractId)) {
            pageRef = Page.FTE_Assign_Days_View;
        }

        pageRef.setRedirect(false); 
        return pageRef;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageRef.setRedirect(false); 
        return null;//return pageRef;
    }

    public class EmployeeTime {

        public EmployeeTime (String contractName, Id contractId) {
            this.contractName = contractName;
            this.contractId = contractId;
            this.dataArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        }

        public String contractName { get; set;}
        public Id contractId { get; set;}
        public List<Decimal> dataArray { get; set;}
    }

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month) {
        EmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.dataArray[month - 1] += loggedHours;
            tmpHelper.dataArray[12] += loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new EmployeeTime(clientName, clientId));
            }
            tmpHelper.dataArray[month - 1] += loggedHours;
            tmpHelper.dataArray[12] += loggedHours;
            tmpHelper = this.unassignedMap.get(clientId);
            tmpHelper.dataArray[month - 1] += loggedHours;
            tmpHelper.dataArray[12] += loggedHours;
        }
    }

    /**
     * Unassign/Assign hours/days view
     */

    public List<DContract__c> fteContracts { get; set;}
    public List<SelectOption> fteContractsOptions { get;set; }
    public Id selectedFteContract { get; set;}
    public Decimal fteHours { get; set;}
    public Id contractId { get; set;}
    public String contractName { get; set;}
    public Integer employeeMonth { get; set;}
    public Decimal fteHoursMax { get; set;}
    public Boolean assignViewError { get; set;}

    public void loadEmployeeMonth() {
        this.assignViewError = false;
        this.fteHours = 0;
        if (this.employeeMonth != null) {
            this.fteHoursMax = unassigned.dataArray[this.employeeMonth];
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            this.fteHoursMax = 0;
        }
        this.fteContracts = [SELECT Id, Name FROM DContract__c WHERE FTE_Tracker__c = 'Yes'];
        this.fteContractsOptions = new List<SelectOption>();
        for (DContract__c con : this.fteContracts) {
            this.fteContractsOptions.add(new SelectOption(con.Id, con.Name));
        }
    }

    public void loadEmployeeUnassMonth() {
        this.assignViewError = false;
        this.fteHours = 0;
        if (this.employeeMonth != null && this.contractId != null) {
            this.contractName = this.assignedMap.get(this.contractId).contractName;
            this.fteHoursMax = this.assignedMap.get(this.contractId).dataArray[this.employeeMonth];
            String message = '';
            for (Id key : this.assignedMap.keySet()) {
                message += key + ' ' + this.assignedMap.get(key).contractName + ' ; ';
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load contract month'));
            this.assignViewError = true;
            this.fteHoursMax = 0;
        }
    }

    public PageReference moveTimeToUnassigned() {
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return null;
        }

        if (this.fteHoursMax < this.fteHours || this.fteHours < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return null;
        }

        if (String.isEmpty(this.contractId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return null;
        }

        if (this.fteHours == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return null;
        }

        try {
            Date monthStart = Date.newInstance(this.currentYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.currentYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.currentYear, this.employeeMonth + 1));
            Decimal hoursToUnassign = this.fteHours;
            Boolean stopUpdating = false;

            List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
            List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                        Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
                                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                        Date__c FROM Time_Card__c
                                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                        AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                        AND FTE_Contract__c =: this.contractId
                                                        AND Date__c >=: monthStart AND Date__c <=: endMonth];

            // If we have moved hours from unassigned to assigned we want take these hours back.
            for (Time_Card__c tc : timeCardsFromDB) {
                Decimal movedHours = tc.FTE_Hours__c;
                Decimal hours = movedHours > hoursToUnassign ? hoursToUnassign : movedHours;
                if (hours > 0) { // we try remove tag from tc
                    tc.FTE_hours__c = tc.FTE_hours__c - hours;
                    hoursToUnassign -= hours;
                    if (tc.FTE_hours__c <= 0) {
                        tc.FTE_Contract__c = null;
                    }
                    timeCardsToUpdate.add(tc);
                    if (hoursToUnassign <= 0) {
                        stopUpdating = true;
                        break;
                    }
                }
            }

            // If we already have tag from assigned we want take more hours from that tag, we need only one time card we can move hours to one contract
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__c =: this.contractId AND FTE_Contract__c != null
                                                AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c = '')
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Time 1 cards: ' + timeCardsFromDB.size()));

                if (timeCardsFromDB.size() > 0) {
                    Time_Card__c tc = timeCardsFromDB.get(0);
                    tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + hoursToUnassign : hoursToUnassign;
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
                }
            }

            // If we don't have any tag we need add new one in time card
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__c =: this.contractId
                                                AND FTE_Contract__c = null
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];
                if (timeCardsFromDB.size() > 0) {
                    Time_Card__c tc = timeCardsFromDB.get(0);
                    tc.FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].contractId;
                    tc.FTE_hours__c = hoursToUnassign;
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
                }
            }

            // If we don't have any empty time card we need create a empty one to move hours
            if (stopUpdating == false) {
                    Time_Card__c tc = new Time_Card__c(Client__c = this.contractId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                       FTE_only__c = true, Total__c = 0, FTE_hours__c = hoursToUnassign,
                                                       FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].contractId);
                    timeCardsToUpdate.add(tc);
                    stopUpdating = true;
            }

            upsert timeCardsToUpdate;
            if (this.assignViewError == false) {
                return goToEmployeeView();
            }
        } catch (Exception e) {
            this.assignViewError = true;
        }

        return null;
    }

    public PageReference moveTimeFromUnassigned() {
        this.assignViewError = false;
        if (this.employeeMonth == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot load month number'));
            this.assignViewError = true;
            return null;
        }

        if (this.fteHoursMax < this.fteHours || this.fteHours < 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Too much hours to assign / hours cannot be negative'));
            this.assignViewError = true;
            return null;
        }

        if (String.isEmpty(this.selectedFteContract)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find FTE Contract'));
            this.assignViewError = true;
            return null;
        }

        if (this.fteHours == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot move 0 hours'));
            this.assignViewError = true;
            return null;
        }

        try {
            Date monthStart = Date.newInstance(this.currentYear, this.employeeMonth + 1, 1);
            Date endMonth = Date.newInstance(this.currentYear, this.employeeMonth + 1,
                                         Date.daysInMonth(this.currentYear, this.employeeMonth + 1));
            Decimal hoursToAssign = this.fteHours;
            Boolean stopUpdating = false;

            List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
            List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND Client__r.FTE_Tracker__c = 'Yes' AND FTE_Hours__c > 0
                                                AND Client__c =: this.selectedFteContract AND FTE_Contract__c != null
                                                AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c  = '')
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

            // If we have moved hours from assigned to unassigned we want take these hours back.
            for (Time_Card__c tc : timeCardsFromDB) {
                Decimal freeHours = this.unassignedMap.get(tc.FTE_Contract__c).dataArray[this.employeeMonth];
                Decimal movedHours = tc.FTE_Hours__c;
                Decimal hours = movedHours > freeHours ? freeHours : movedHours;
                if (hours > 0) { // we try remove tag from tc
                    Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                    tc.FTE_hours__c = tc.FTE_hours__c - toAssign;
                    hoursToAssign -= toAssign;
                    this.unassignedMap.get(tc.FTE_Contract__c).dataArray[this.employeeMonth] -= toAssign;
                    if (tc.FTE_hours__c <= 0) {
                        tc.FTE_Contract__c = null;
                    }
                    timeCardsToUpdate.add(tc);
                    if (hoursToAssign <= 0) {
                        stopUpdating = true;
                        break;
                    }
                }
            }

             Set<Id> emptyContracts = new Set<Id>();
            // If we already have tag from unassigned we want take more hours from that tag
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c, FTE_Available_Hours__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                AND FTE_Contract__c =: this.selectedFteContract
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

                for (Time_Card__c tc : timeCardsFromDB) {
                    Decimal hours = this.unassignedMap.get(tc.Client__c).dataArray[this.employeeMonth];
                    if (hours > 0) { // we try move hours to this client tag
                        Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                        tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                        hoursToAssign -= toAssign;
                        timeCardsToUpdate.add(tc);
                        if (hoursToAssign <= 0) {
                            stopUpdating = true;
                            break;
                        }
                        emptyContracts.add(tc.Client__c);
                    } else {
                        emptyContracts.add(tc.Client__c);
                    }
                }
            }

            // if we still need hours we will take time cards without any tag and add tag there
            if (stopUpdating == false) {
                timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                AND (FTE_Contract__c = null OR FTE_Contract__c = '') AND Client__c NOT IN: emptyContracts
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

                for (Time_Card__c tc : timeCardsFromDB) {
                    Decimal hours = this.unassignedMap.get(tc.Client__c).dataArray[this.employeeMonth];
                    if (hours > 0) {
                        Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                        tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                        tc.FTE_Contract__c = this.selectedFteContract;
                        hoursToAssign -= toAssign;
                        timeCardsToUpdate.add(tc); 
                        if (hoursToAssign <= 0) {
                            stopUpdating = true;
                            break;
                        }
                        emptyContracts.add(tc.Client__c);
                    } else {
                        emptyContracts.add(tc.Client__c);
                    }
                }
            }

            // If we have available time we need create empty time card with tag
            if (stopUpdating == false) {
                for (Id conId : this.unassignedMap.keySet()) {
                    if (!emptyContracts.contains(contractId)) {
                        Decimal hours = this.unassignedMap.get(conId).dataArray[this.employeeMonth];
                        if (hours > 0) {
                            Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                            Time_Card__c tc = new Time_Card__c(Client__c = conId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                               FTE_only__c = true, Total__c = 0, FTE_hours__c = toAssign,
                                                               FTE_Contract__c = this.selectedFteContract);
                            hoursToAssign -= toAssign;
                            timeCardsToUpdate.add(tc); 
                            if (hoursToAssign <= 0) {
                                stopUpdating = true;
                                break;
                            }
                        }
                    }
                }
            }

            upsert timeCardsToUpdate;

            if (this.assignViewError == false) {
                return goToEmployeeView();
            }
        } catch (Exception e) {
            this.assignViewError = true;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unexpected error: ' + e.getMessage()));
        }
        return null;
    }

    public PageReference goToEmployeeView() {
        clearViewData();
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.setRedirect(false); 
        return pageRef;
    }

    private void clearViewData() {
        this.contractId = null;
        this.fteHoursMax = 0;
        this.employeeMonth = null;
    }

    private Integer getContractIndex() {
        Integer upperLimit = this.unassignedMap.size();
        if (upperLimit == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find unassigned contract'));
            return 0;
        }
        Integer rand = Math.round(Math.random()*1000);
        return Math.mod(rand, upperLimit);
    }
    // TODO DEL
    public void removeAllTags() {
        List<Time_Card__c> tagsTC = [SELECT Id, FTE_Contract__c, FTE_hours__c, FTE_only__c FROM Time_Card__c WHERE (FTE_Contract__c != null 
                                        AND FTE_Contract__c != '') OR FTE_hours__c > 0];
        List<Time_Card__c> toUpdate = new List<Time_Card__c>();
        List<Time_Card__c> toRemove = new List<Time_Card__c>();

        for (Time_Card__c tc : tagsTC) {
            if (tc.FTE_only__c == true) {
                toRemove.add(tc);
            } else {
                tc.FTE_hours__c = 0;
                tc.FTE_Contract__c = null;
                toUpdate.add(tc);
            }
        }

        if (toRemove.size() > 0) {
            delete toRemove;
        }
        if (toUpdate.size() > 0) {
            update toUpdate;
        }
        loadEmployeeTimeHistory();
    }
}