/**
 * FTETimeManager for loading Employee time and managing it.
 */
public class FTETimeManager {

    private SFDC_Employee__c employee;
    private Integer fteYear;

    public Integer employeeNetworkDays { get; set;}

    public FTEEmployeeTime unassigned { get; set;}
    public Map<Id, FTEEmployeeTime> assignedMap { get; set;}
    public Map<Id, FTEEmployeeTime> unassignedMap { get; set;}

    public FTETimeManager(SFDC_Employee__c employee, Integer fteYear) {
        this.employee = employee;
        this.fteYear = fteYear;

        this.assignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassigned = new FTEEmployeeTime('Unassigned', null); // Sum of all unassigned employee contracts
    }

    public void loadEmployeeTime() {
        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Time_Card_Salary__c, Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND CALENDAR_YEAR(Date__c) =: this.fteYear
                                            ORDER BY Client__r.Name];

        FTEEmployeeTime tmpHelper;
        for (Time_Card__c timeCard : timeCards) {
            calculateLoggedTime(timeCard); // sum hours and moved hours
        }
    }

    public void moveTimeToUnassigned(Decimal fteHours, Integer month, Id contractId) {
        Date monthStart = Date.newInstance(this.fteYear, month, 1);
        Date endMonth = Date.newInstance(this.fteYear, month, Date.daysInMonth(this.fteYear, month));

        Decimal hoursToUnassign = fteHours;
        Boolean stopUpdating = false;

        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                    Total__c, FTE_hours__c, FTE_Contract__c,
                                                    FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                    Date__c FROM Time_Card__c
                                                    WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                    AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                    AND FTE_Contract__c =: contractId
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

        // If we already have tag from assigned we want take more hours from that tag,
        // we need only one time card we can move hours to one contract
        if (stopUpdating == false) {
            timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND Client__c =: contractId AND FTE_Contract__c != null
                                            AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c = '')
                                            AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];

            if (timeCardsFromDB.size() > 0) {
                Time_Card__c tc = timeCardsFromDB.get(0);
                tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + hoursToUnassign : hoursToUnassign;
                timeCardsToUpdate.add(tc);
                stopUpdating = true;
            }
        }

        // If we don't have any tag we need add one in time cards
        if (stopUpdating == false) {
            timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND Client__c =: contractId
                                            AND FTE_Contract__c = null
                                            AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];

            if (timeCardsFromDB.size() > 0) {
                Time_Card__c tc = timeCardsFromDB.get(0);
                tc.FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].objId;
                tc.FTE_hours__c = hoursToUnassign;
                timeCardsToUpdate.add(tc);
                stopUpdating = true;
            }
        }

        // If we don't have any empty time card we need create a empty one to move hours 
        if (stopUpdating == false) {
            Time_Card__c tc = new Time_Card__c(Client__c = contractId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                   FTE_only__c = true, Total__c = 0, FTE_hours__c = hoursToUnassign,
                                                   FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].objId);
            timeCardsToUpdate.add(tc);
            stopUpdating = true;
        }

        upsert timeCardsToUpdate;
    }

    public Decimal moveTimeToAssigned(Decimal fteHours, Integer month, Id contractId) {
        Date monthStart = Date.newInstance(this.fteYear, month, 1);
        Date endMonth = Date.newInstance(this.fteYear, month, Date.daysInMonth(this.fteYear, month));

        Decimal hoursToAssign = fteHours;
        Boolean stopUpdating = false;

        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND Client__r.FTE_Tracker__c = 'Yes' AND FTE_Hours__c > 0
                                            AND Client__c =: contractId AND FTE_Contract__c != null
                                            AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c  = '')
                                            AND Date__c >=: monthStart AND Date__c <=: endMonth];

        Set<Id> emptyContracts = new Set<Id>();
        // If we have moved hours from assigned to unassigned we want take these hours back.
        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal freeHours = this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1];
            Decimal movedHours = tc.FTE_Hours__c;
            Decimal hours = movedHours > freeHours ? freeHours : movedHours;
            if (hours > 0) { // we try remove tag from tc
                Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                tc.FTE_hours__c = tc.FTE_hours__c - toAssign;
                hoursToAssign -= toAssign;
                this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month -1] -= toAssign;
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

        // If we already have tag from unassigned we want take more hours from that tag
        if (stopUpdating == false) {
            timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                            AND FTE_Contract__c =: contractId
                                            AND Date__c >=: monthStart AND Date__c <=: endMonth];

            for (Time_Card__c tc : timeCardsFromDB) {
                Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[month - 1];
                if (hours > 0) { // we try move hours to this client tag
                    Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                    tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                    hoursToAssign -= toAssign;
                    this.unassignedMap.get(tc.Client__c).hoursArray[month - 1] -= toAssign;
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
                Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[month - 1];
                if (hours > 0) {
                    Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                    tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                    tc.FTE_Contract__c = contractId;
                    hoursToAssign -= toAssign;
                    this.unassignedMap.get(tc.Client__c).hoursArray[month - 1] -= toAssign;
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
                    Decimal hours = this.unassignedMap.get(conId).hoursArray[month - 1];
                    if (hours > 0) {
                        Decimal toAssign = hoursToAssign > hours ? hours : hoursToAssign;
                        Time_Card__c tc = new Time_Card__c(Client__c = conId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                           FTE_only__c = true, Total__c = 0, FTE_hours__c = toAssign,
                                                           FTE_Contract__c = contractId);
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
        return hoursToAssign;
    }

    private void calculateLoggedTime(Time_Card__c timeCard) {
        Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
        Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);

        // "Moved from" part this.contractsTime.add(this.unassigned);
        sumLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.month(), timeCard.Time_Card_Salary__c);
        // If no FTE Tag values we don't need to process moved hours
        if (timeCard.FTE_Contract__c == null || movedTime == 0) {
            return;
        }
        // "Moved to" part
        sumLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.month(), timeCard.Time_Card_Salary__c);
    }

    private void sumLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month, Decimal salary) {
        FTEEmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
            }
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
            tmpHelper = this.unassignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper.hoursArray[12] += loggedHours;
            tmpHelper.daysArray[13] += (salary != null ? salary : 0) * loggedHours;
        }
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
}