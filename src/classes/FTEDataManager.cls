/**
 * FTEDataManager for loading Employee time and managing it. It contains methods which allow moving time between contracts.
 */
public class FTEDataManager {

    private Boolean monthMode;
    private SFDC_Employee__c employee;
    private Integer fteMonth;
    private Integer fteYear;
    private Boolean skipWorkCard;
    private List<Time_Card__c> timeCardsToUpdate;

    public Integer employeeNetworkDays { get; set;}
    public FTEEmployeeTime unassigned { get; set;}
    public Map<Id, FTEEmployeeTime> assignedMap { get; set;}
    public Map<Id, FTEEmployeeTime> unassignedMap { get; set;}

    public FTEDataManager(Integer year, Integer month, Id employeeId, Boolean skipWorkCard) {
        this(year, employeeId, skipWorkCard);
        this.fteMonth = month;
        this.monthMode = true;
    }

    public FTEDataManager(Integer year, Id employeeId, Boolean skipWorkCard) {
        this.monthMode = false;
        this.fteYear = year;
        this.skipWorkCard = skipWorkCard;
        this.assignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassignedMap = new Map<Id, FTEEmployeeTime>();
        this.unassigned = new FTEEmployeeTime('Unassigned', null); // Sum of all unassigned employee contracts
        this.employee = [SELECT Id, Name FROM SFDC_Employee__c WHERE Id =: employeeId LIMIT 1];
    }

    public FTEDataManager(Integer year, Id employeeId) {
        this(year, employeeId, true);
    }

    /**
     * Helper method to remove negative time. Negative time can be possible when client in time cards was updated.
     */
    public void removeNegativeTime() {
        removeNegativeTime(this.fteMonth);
    }

    public void removeNegativeTime(Integer month) {
        
    }

    /**
     * Checks if time will moved to unassigned. Return true if time should be used to unassigned (removeTime should be used).
     */
    public Boolean shouldUnassign(Id contractId, Decimal thresholdHours) {
        return shouldUnassign(contractId, thresholdHours, this.fteMonth);
    }

    public Boolean shouldUnassign(Id contractId, Decimal thresholdHours, Integer month) {
        if (thresholdHours < 0) {
            return false;
        }
        Decimal availableTime = this.unassigned.hoursArray[month - 1];
        Decimal missingTime = thresholdHours;
        if (this.assignedMap.containsKey(contractId)) {
            missingTime = thresholdHours - this.assignedMap.get(contractId).hoursArray[month - 1];
        }

        if (missingTime > 0) {
            return false;
        }
        return true;
    }

    /**
     * Sets threshold time and moves hours if possible. Threshold is loaded from the uploaded CSV template
     */
    public void setTime(Id contractId, Decimal thresholdHours) {
        setTime(contractId, thresholdHours, this.fteMonth);
    }

    public void setTime(Id contractId, Decimal thresholdHours, Integer month) {
        if (thresholdHours  < 0) {
            return;
        }
        Decimal availableTime = this.unassigned.hoursArray[month - 1];
        Decimal missingTime = thresholdHours;
        if (this.assignedMap.containsKey(contractId)) {
            missingTime = thresholdHours - this.assignedMap.get(contractId).hoursArray[month - 1];
        }

        if (missingTime > 0) {
            addTime(contractId, availableTime > missingTime ? missingTime : availableTime);
        } else if (missingTime < 0) {
            removeTime(contractId, (-1) * missingTime);
        }
    }

    /**
     * Set given threshold in month and upserst template for blocking hours and future time allocation.
     */
    public void upsertTimeTemplate(Id contractId,  Decimal threshold, Integer month, Boolean reloadWorkCard) {
        List<FTE_Data_Record__c> templates = [SELECT Id, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                              Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                              FROM FTE_Data_Record__c
                                              WHERE Contract__c =: contractId AND Employee__c =: this.employee.Id AND Year__c =: this.fteYear];

        FTE_Data_Record__c template = null;
        if (templates.size() > 0) {
            template = templates.get(0);
        } else {
            template = new FTE_Data_Record__c(Contract__c = contractId, Employee__c = this.employee.Id, Year__c = this.fteYear);
        }

        SObject templateSObj = (SObject) template;
        templateSObj.put(FTETrackerHelper.getFieldName(month), threshold);
        upsert template;

        if (this.assignedMap.containsKey(contractId)) {
            this.assignedMap.get(contractId).templateArray[month - 1] = threshold;
        }

        if (reloadWorkCard == true && this.skipWorkCard == false) {
            recalculateWorkCardMonth(month);
        }
    }

    /**
     * Set -1 in time template, it means that we remove blocking hours and future time allocation for given month and contract.
     */
    public void removeTimeTemplate(Id contractId, Integer month) {
        List<FTE_Data_Record__c> templates = [SELECT Id, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                              Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                              FROM FTE_Data_Record__c
                                              WHERE Contract__c =: contractId AND Employee__c =: this.employee.Id AND Year__c =: this.fteYear];
        if (templates.size() > 0) {
            FTE_Data_Record__c template = templates.get(0);
            SObject templateSObj = (SObject) template;
            templateSObj.put(FTETrackerHelper.getFieldName(month), -1);
            upsert template;

            if (this.assignedMap.containsKey(contractId)) {
                this.assignedMap.get(contractId).templateArray[month - 1] = -1;
            }

            if (this.skipWorkCard == false) {
                recalculateWorkCardMonth(month);
            }
        }
    }

    /**
     * Move time to assigned.
     */
    public void addTime(Id contractId, Decimal hours) {
        addTime(contractId, hours, this.fteMonth);
    }

    public void addTime(Id contractId, Decimal fteHours, Integer month) {
        Date monthStart = Date.newInstance(this.fteYear, month, 1);
        Date endMonth = Date.newInstance(this.fteYear, month, Date.daysInMonth(this.fteYear, month));
        this.timeCardsToUpdate = new List<Time_Card__c>();

        Decimal hoursToAssign = fteHours;
        Decimal availableTime = this.unassigned.hoursArray[month - 1];
        hoursToAssign = availableTime >= hoursToAssign ? hoursToAssign : availableTime;

        // Step 1. If we have time between FTE contract we want remove such tags.
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                    Total__c, FTE_hours__c, FTE_Contract__c,
                                                    FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                    Date__c FROM Time_Card__c
                                                    WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                    AND FTE_Contract__r.FTE_Tracker__c = 'Yes'
                                                    AND Client__c =: contractId
                                                    AND Date__c >=: monthStart AND Date__c <=: endMonth];
        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal movedHours = tc.FTE_Hours__c;
            Decimal hours = movedHours > hoursToAssign ? hoursToAssign : movedHours;

            if (hours > 0) {
                tc.FTE_hours__c = tc.FTE_hours__c - hours;
                hoursToAssign -= hours;

                if (this.assignedMap.containsKey(tc.FTE_Contract__c)) {
                    this.assignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1] -= hours;
                }
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] += hours;
                }

                if (tc.FTE_hours__c <= 0) {
                    tc.FTE_Contract__c = null;
                    tc.FTE_hours__c = 0;
                }
                this.timeCardsToUpdate.add(tc);

                if (hours > 0) { // Step 2. Check description below
                    hours = assignExistingTagToUnassigned(tc.FTE_Contract__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 3. Check description below
                    hours = assignExistingTagsFromUnassigned(tc.FTE_Contract__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 4. Check description below
                    hours = assignWithNewTag(tc.FTE_Contract__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 5. Check description below
                    hours = assignWithNewTagAndTimeCard(tc.FTE_Contract__c, hours, month, monthStart);
                }

                if (hoursToAssign <= 0) {
                    hoursToAssign = 0;
                    break;
                }
            }
        }

        // Step 2. If we have moved hours from assigned to unassigned we want take these hours back.
        if (hoursToAssign > 0) {
            hoursToAssign = assignExistingTagToUnassigned(contractId, hoursToAssign, month, monthStart, endMonth);
        }

        // Step 3. If we already have tag from unassigned we want take more hours from that tag.
        if (hoursToAssign > 0) {
            hoursToAssign = assignExistingTagsFromUnassigned(contractId, hoursToAssign, month, monthStart, endMonth);
        }

        // Step 4. If we still need hours we will take time cards without any tag and add tag there.
        if (hoursToAssign > 0) {
            hoursToAssign = assignWithNewTag(contractId, hoursToAssign, month, monthStart, endMonth);
        }

        // Step 5. If we have available time we need create empty time card with tag.
        if (hoursToAssign > 0) {
            hoursToAssign = assignWithNewTagAndTimeCard(contractId, hoursToAssign, month, monthStart);
        }

        if (this.timeCardsToUpdate.size() > 0) {
            upsert this.timeCardsToUpdate;
            this.timeCardsToUpdate.clear();
        }

        if (this.skipWorkCard == false) {
            recalculateWorkCardMonth(month);
        }
    }

    /**
     * Move time to unassigned.
     */
    public void removeTime(Id contractId, Decimal hours) {
        removeTime(contractId, hours, this.fteMonth);
    }

    public void removeTime(Id contractId, Decimal fteHours, Integer month) {
        Date monthStart = Date.newInstance(this.fteYear, month, 1);
        Date endMonth = Date.newInstance(this.fteYear, month, Date.daysInMonth(this.fteYear, month));
        this.timeCardsToUpdate = new List<Time_Card__c>();

        Decimal hoursToUnassign = fteHours;
        if (this.assignedMap.containsKey(contractId)) {
            Decimal availableTime = this.assignedMap.get(contractId).hoursArray[month - 1];
            hoursToUnassign = availableTime >= hoursToUnassign ? hoursToUnassign : availableTime;
        }

        // Step 1. If we have time between FTE contract we want remove such tags.
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                    Total__c, FTE_hours__c, FTE_Contract__c,
                                                    FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                    Date__c FROM Time_Card__c
                                                    WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                    AND Client__r.FTE_Tracker__c = 'Yes'
                                                    AND FTE_Contract__c =: contractId
                                                    AND Date__c >=: monthStart AND Date__c <=: endMonth];
        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal movedHours = tc.FTE_Hours__c;
            Decimal hours = movedHours > hoursToUnassign ? hoursToUnassign : movedHours;

            if (hours > 0) {
                tc.FTE_hours__c = tc.FTE_hours__c - hours;
                hoursToUnassign -= hours;
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] -= hours;
                }
                if (this.assignedMap.containsKey(tc.Client__c)) {
                    this.assignedMap.get(tc.Client__c).hoursArray[month - 1] += hours;
                }

                if (tc.FTE_hours__c <= 0) {
                    tc.FTE_Contract__c = null;
                    tc.FTE_hours__c = 0;
                }
                this.timeCardsToUpdate.add(tc);

                if (hours > 0) { // Step 2. Check description below
                    hours = unassignExistingTagToFTE(tc.Client__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 3. Check description below
                    hours = unassignExistingTagFromFTE(tc.Client__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 4. Check description below
                    hours = unassignWithNewTag(tc.Client__c, hours, month, monthStart, endMonth);
                }

                if (hours > 0) { // Step 5. Check description below
                    hours = unassignWithNewTagAndTimeCard(tc.Client__c, hours, month, monthStart);
                }

                if (hoursToUnassign <= 0) {
                    hoursToUnassign = 0;
                    break;
                }
            }
        }

        // Step 2. If we have moved hours from unassigned to assigned we want take these hours back, we want decrease number of tags.
        if (hoursToUnassign > 0) {
            hoursToUnassign = unassignExistingTagToFTE(contractId, hoursToUnassign, month, monthStart, endMonth);
        }

        Decimal hoursMapHelper = hoursToUnassign;
        // Step 3. If we already have tag from assigned we want take more hours from that tag, we want decrease number of tags.
        if (hoursToUnassign > 0) {
            hoursToUnassign = unassignExistingTagFromFTE(contractId, hoursToUnassign, month, monthStart, endMonth);
        }

        // Step 4. If we don't have any tag we need add one in time cards.
        if (hoursToUnassign > 0) {
            hoursToUnassign = unassignWithNewTag(contractId, hoursToUnassign, month, monthStart, endMonth);
        }

        // Step 5. If we don't have any empty time card we need create a empty one to move hours.
        if (hoursToUnassign > 0) {
            hoursToUnassign = unassignWithNewTagAndTimeCard(contractId, hoursToUnassign, month, monthStart);
        }

        if (this.timeCardsToUpdate.size() > 0) {
            upsert this.timeCardsToUpdate;
            this.timeCardsToUpdate.clear();
        }

        if (this.skipWorkCard == false) {
            recalculateWorkCardMonth(month);
        }
    }

    private Decimal assignExistingTagToUnassigned(Id contractId, Decimal timeToAssign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND Client__r.FTE_Tracker__c = 'Yes' AND FTE_Hours__c > 0
                                            AND Client__c =: contractId AND FTE_Contract__c != null
                                            AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c  = '')
                                            AND Date__c >=: monthStart AND Date__c <=: endMonth];

        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal freeHours = this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1];
            Decimal movedHours = tc.FTE_Hours__c;
            Decimal hours = movedHours > freeHours ? freeHours : movedHours;

            if (hours > 0) { // we try remove tag from tc
                Decimal toAssign = timeToAssign > hours ? hours : timeToAssign;
                tc.FTE_hours__c = tc.FTE_hours__c - toAssign;
                timeToAssign -= toAssign;

                this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1] -= toAssign;
                this.unassigned.hoursArray[month - 1] -= toAssign;
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] += toAssign;
                } else {
                    FTEEmployeeTime fteData = new FTEEmployeeTime('', contractId);
                    fteData.hoursArray[month - 1] += toAssign;
                    this.assignedMap.put(contractId, fteData);
                }

                if (tc.FTE_hours__c <= 0) {
                    tc.FTE_Contract__c = null;
                }
                this.timeCardsToUpdate.add(tc);
                if (timeToAssign <= 0) {
                    timeToAssign = 0;
                    break;
                }
            }
        }

        return timeToAssign;
    }

    private Decimal assignExistingTagsFromUnassigned(Id contractId, Decimal timeToAssign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                        AND FTE_Contract__c =: contractId
                                        AND Date__c >=: monthStart AND Date__c <=: endMonth];

        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[month - 1];
            if (hours > 0) {
                Decimal toAssign = timeToAssign > hours ? hours : timeToAssign;
                tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                timeToAssign -= toAssign;

                this.unassignedMap.get(tc.Client__c).hoursArray[month - 1] -= toAssign;
                this.unassigned.hoursArray[month - 1] -= toAssign;
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] += toAssign;
                } else {
                    FTEEmployeeTime fteData = new FTEEmployeeTime('', contractId);
                    fteData.hoursArray[month - 1] += toAssign;
                    this.assignedMap.put(contractId, fteData);
                }

                this.timeCardsToUpdate.add(tc);
                if (timeToAssign <= 0) {
                    timeToAssign = 0;
                    break;
                }
            }
        }
        return timeToAssign;
    }

    private Decimal assignWithNewTag(Id contractId, Decimal timeToAssign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                        AND (FTE_Contract__c = null OR FTE_Contract__c = '') 
                                        AND Date__c >=: monthStart AND Date__c <=: endMonth];

        Set<Id> emptyContracts = new Set<Id>();
        for (Time_Card__c tc : timeCardsFromDB) {
            if (emptyContracts.contains(tc.Client__c)) {
                continue;
            }

            Decimal hours = this.unassignedMap.get(tc.Client__c).hoursArray[month - 1];
            if (hours > 0) {
                Decimal toAssign = timeToAssign > hours ? hours : timeToAssign;
                tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + toAssign : toAssign;
                tc.FTE_Contract__c = contractId;
                timeToAssign -= toAssign;

                this.unassignedMap.get(tc.Client__c).hoursArray[month - 1] -= toAssign;
                this.unassigned.hoursArray[month - 1] -= toAssign;
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] += toAssign;
                } else {
                    FTEEmployeeTime fteData = new FTEEmployeeTime('', contractId);
                    fteData.hoursArray[month - 1] += toAssign;
                    this.assignedMap.put(contractId, fteData);
                }

                this.timeCardsToUpdate.add(tc);
                if (timeToAssign <= 0) {
                    timeToAssign = 0;
                    break;
                }

                emptyContracts.add(tc.Client__c);
            } else {
                emptyContracts.add(tc.Client__c);
            }
        }

        return timeToAssign;
    }

    private Decimal assignWithNewTagAndTimeCard(Id contractId, Decimal timeToAssign, Integer month, Date monthStart) {
        for (Id conId : this.unassignedMap.keySet()) {
            Decimal hours = this.unassignedMap.get(conId).hoursArray[month - 1];
            if (hours > 0) {
                Decimal toAssign = timeToAssign > hours ? hours : timeToAssign;
                Time_Card__c tc = new Time_Card__c(Client__c = conId, Employee__c = this.employee.Id, Date__c = monthStart,
                                                   FTE_only__c = true, Total__c = 0, FTE_hours__c = toAssign,
                                                   FTE_Contract__c = contractId);
                timeToAssign -= toAssign;

                this.unassignedMap.get(conId).hoursArray[month - 1] -= toAssign;
                this.unassigned.hoursArray[month - 1] -= toAssign;
                if (this.assignedMap.containsKey(contractId)) {
                    this.assignedMap.get(contractId).hoursArray[month - 1] += toAssign;
                } else {
                    FTEEmployeeTime fteData = new FTEEmployeeTime('', contractId);
                    fteData.hoursArray[month - 1] += toAssign;
                    this.assignedMap.put(contractId, fteData);
                }

                this.timeCardsToUpdate.add(tc);
                if (timeToAssign <= 0) {
                    break;
                }
            }
        }
        return 0;
    }

    private Decimal unassignExistingTagToFTE(Id contractId, Decimal timeToUnassign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                                Total__c, FTE_hours__c, FTE_Contract__c,
                                                FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                                Date__c FROM Time_Card__c
                                                WHERE Employee__c =: this.employee.Id AND Client__c != null
                                                AND (Client__r.FTE_Tracker__c = 'No' OR Client__r.FTE_Tracker__c = '')
                                                AND FTE_Contract__c =: contractId
                                                AND Date__c >=: monthStart AND Date__c <=: endMonth];

        for (Time_Card__c tc : timeCardsFromDB) {
            Decimal movedHours = tc.FTE_Hours__c;
            Decimal hours = movedHours > timeToUnassign ? timeToUnassign : movedHours;

            if (hours > 0) {
                tc.FTE_hours__c = tc.FTE_hours__c - hours;
                timeToUnassign -= hours;

                this.assignedMap.get(contractId).hoursArray[month - 1] -= hours;
                this.unassignedMap.get(tc.Client__c).hoursArray[month - 1] += hours;
                this.unassigned.hoursArray[month - 1] += hours;

                if (tc.FTE_hours__c <= 0) {
                    tc.FTE_Contract__c = null;
                    tc.FTE_hours__c = 0;
                }

                this.timeCardsToUpdate.add(tc);
                if (timeToUnassign <= 0) {
                    timeToUnassign = 0;
                    break;
                }
            }
        }
        return timeToUnassign;
    }

    private Decimal unassignExistingTagFromFTE(Id contractId, Decimal timeToUnassign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                        Total__c, FTE_hours__c, FTE_Contract__c,
                                        FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                        Date__c FROM Time_Card__c
                                        WHERE Employee__c =: this.employee.Id AND Client__c != null
                                        AND Client__c =: contractId AND FTE_Contract__c != null
                                        AND (FTE_Contract__r.FTE_Tracker__c = 'No' OR FTE_Contract__r.FTE_Tracker__c = '')
                                        AND Date__c >=: monthStart AND Date__c <=: endMonth LIMIT 1];
        if (timeCardsFromDB.size() > 0) {
            Time_Card__c tc = timeCardsFromDB.get(0);
            tc.FTE_hours__c = tc.FTE_hours__c != null ? tc.FTE_hours__c + timeToUnassign : timeToUnassign;
            this.timeCardsToUpdate.add(tc);

            this.assignedMap.get(contractId).hoursArray[month - 1] -= timeToUnassign;
            this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1] += timeToUnassign;
            this.unassigned.hoursArray[month - 1] += timeToUnassign;

            timeToUnassign = 0;
        }

        return timeToUnassign;
    }

    private Decimal unassignWithNewTag(Id contractId, Decimal timeToUnassign, Integer month, Date monthStart, Date endMonth) {
        List<Time_Card__c> timeCardsFromDB = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
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
            tc.FTE_hours__c = timeToUnassign;
            this.timeCardsToUpdate.add(tc);

            this.assignedMap.get(contractId).hoursArray[month - 1] -= timeToUnassign;
            this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1] += timeToUnassign;
            this.unassigned.hoursArray[month - 1] += timeToUnassign;

            timeToUnassign = 0;
        }

        return timeToUnassign;
    }

    private Decimal unassignWithNewTagAndTimeCard(Id contractId, Decimal timeToUnassign, Integer month, Date monthStart) {
        Time_Card__c tc = new Time_Card__c(Client__c = contractId, Employee__c = this.employee.Id, Date__c = monthStart,
                                               FTE_only__c = true, Total__c = 0, FTE_hours__c = timeToUnassign,
                                               FTE_Contract__c = this.unassignedMap.values()[getContractIndex()].objId);
        this.timeCardsToUpdate.add(tc);

        this.assignedMap.get(contractId).hoursArray[month - 1] -= timeToUnassign;
        this.unassignedMap.get(tc.FTE_Contract__c).hoursArray[month - 1] += timeToUnassign;
        this.unassigned.hoursArray[month - 1] += timeToUnassign;

        return 0;
    }

    /**
     * Loads employee time for given year / month
     */
    public void loadEmployeeTime() {
        List<Time_Card__c> timeCards = null;
        if (this.monthMode == true) { // only one month data
            timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.fteMonth
                                            ORDER BY Client__r.Name];
        } else { // year data used mostly by the UI
            timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name,
                                            Total__c, FTE_hours__c, FTE_Contract__c,
                                            FTE_Contract__r.FTE_Tracker__c, FTE_Contract__r.Name,
                                            Date__c FROM Time_Card__c
                                            WHERE Employee__c =: this.employee.Id AND Client__c != null
                                            AND CALENDAR_YEAR(Date__c) =: this.fteYear
                                            ORDER BY Client__r.Name];
        }

        FTEEmployeeTime tmpHelper;
        for (Time_Card__c timeCard : timeCards) {
            calculateLoggedTime(timeCard); // sum hours and moved hours
        }
    }

    /**
     * Loads time templates for given year and employee.
     */
    public void loadTemplateTime() {
        Integer monthIndex = 1;
        Integer maxMonth = 12;
        if (this.monthMode == true) {
            monthIndex = this.fteMonth;
            maxMonth = this.fteMonth;
        }
        for (FTE_Data_Record__c futureTemplate : [SELECT Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c
                                                  WHERE Employee__c =: this.employee.Id AND Year__c =: this.fteYear AND Contract__r.FTE_Tracker__c = 'Yes']) {
            SObject templateSObj = (SObject) futureTemplate;

            for (Integer month = monthIndex; month <= maxMonth; month++) {
                Decimal monthValue = (Decimal) templateSObj.get(FTETrackerHelper.getFieldName(month));
                if (monthValue == -1) {
                    continue;
                }

                if (!this.assignedMap.containsKey(futureTemplate.Contract__c)) {
                    this.assignedMap.put(futureTemplate.Contract__c, new FTEEmployeeTime(futureTemplate.Contract__r.Name, futureTemplate.Contract__c));
                }

                FTEEmployeeTime tmpHelper = this.assignedMap.get(futureTemplate.Contract__c);

                if (tmpHelper.templateArray[month - 1] == -1) {
                    tmpHelper.templateArray[month - 1] = 0;
                }
                tmpHelper.templateArray[month - 1] += monthValue;
            }
        }
    }

    /**
     * Recalculates Employee Work Month. Work Card object is used by the Employee List View for better performance.
     */
    public void recalculateWorkCardMonth(Integer month) {
        List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id, Total__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                    Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                    Month_Future_1__c, Month_Future_2__c, Month_Future_3__c, Month_Future_4__c, Month_Future_5__c, Month_Future_6__c,
                                                    Month_Future_7__c, Month_Future_8__c, Month_Future_9__c, Month_Future_10__c, Month_Future_11__c, Month_Future_12__c,
                                                    Month_Blocked_1__c, Month_Blocked_2__c, Month_Blocked_3__c, Month_Blocked_4__c, Month_Blocked_5__c, Month_Blocked_6__c,
                                                    Month_Blocked_7__c, Month_Blocked_8__c, Month_Blocked_9__c, Month_Blocked_10__c, Month_Blocked_11__c, Month_Blocked_12__c
                                                    FROM FTE_Work_Card__c WHERE Employee__c =: this.employee.Id AND Year__c =: this.fteYear];
        if (employeeWorkCards.size() > 0) {
            FTE_Work_Card__c cardToUpdate = employeeWorkCards.get(0);
            SObject workCardSObj = (SObject) cardToUpdate;

            Decimal oldValue = (Decimal) workCardSObj.get(FTETrackerHelper.getFieldName(month));
            Decimal oldTotal = (Decimal) workCardSObj.get('Total__c');
            workCardSObj.put(FTETrackerHelper.getFieldTemplateFutureName(month), false);
            workCardSObj.put(FTETrackerHelper.getFieldTemplateBlockedName(month), false);

            Decimal newValue = 0;

            for (Id contractId : this.assignedMap.keySet()) {
                FTEEmployeeTime emplTime = this.assignedMap.get(contractId);
                Decimal templateTime = (emplTime.templateArray[month - 1] != -1 ? emplTime.templateArray[month - 1] * 8 : -1);
                Decimal loggedTime = emplTime.hoursArray[month - 1];
                Decimal finalResult = 0;

                if (templateTime != -1 && templateTime > loggedTime) {
                    newValue += templateTime;
                    workCardSObj.put(FTETrackerHelper.getFieldTemplateFutureName(month), true); // UI metadata, increase performance
                } else if (templateTime != -1 && templateTime == loggedTime) {
                    newValue += loggedTime;
                    workCardSObj.put(FTETrackerHelper.getFieldTemplateBlockedName(month), true); // UI metadata increase performance
                } else {
                    newValue += loggedTime;
                }
            }

            newValue = FTETrackerHelper.roundtoDays(newValue);
            workCardSObj.put(FTETrackerHelper.getFieldName(month), newValue);
            workCardSObj.put('Total__c', (oldTotal - oldValue + newValue));
            update cardToUpdate;
        }
    }

    private void calculateLoggedTime(Time_Card__c timeCard) {
        Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
        Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);

        // "Moved from" part this.contractsTime.add(this.unassigned);
        sumLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.month());
        // If no FTE Tag values we don't need to process moved hours
        if (timeCard.FTE_Contract__c == null || movedTime == 0) {
            return;
        }
        // "Moved to" part
        sumLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.month());
    }

    private void sumLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer month) {
        FTEEmployeeTime tmpHelper = this.unassigned;
        if (fteTracker == true) {
            if (!this.assignedMap.containsKey(clientId)) {
                this.assignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
            }
            tmpHelper = this.assignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
        } else {
            if (!this.unassignedMap.containsKey(clientId)) {
                this.unassignedMap.put(clientId, new FTEEmployeeTime(clientName, clientId));
            }
            tmpHelper.hoursArray[month - 1] += loggedHours;
            tmpHelper = this.unassignedMap.get(clientId);
            tmpHelper.hoursArray[month - 1] += loggedHours;
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