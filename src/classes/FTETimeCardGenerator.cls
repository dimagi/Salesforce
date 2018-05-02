public class FTETimeCardGenerator {

    public static final String CSV_LONG_EMPTY_ROW = '"","","","","","","","","","","","","","","","",""';
    public static final String CSV_SHORT_EMPTY_ROW = '"","","","","","","","","","","","","","",""';
    public static final String NEW_LINE = '\n';

    private Integer fteYear;
    private Integer employeeMonth;
    private Id employeeId;
    private FTEMonthTimeCard unassignedHours;
    private Map<Id, FTEMonthTimeCard> contractMap;

    public String fileName {get; set;}
    public String csvFile {get; set;}

    private Decimal total = 0;
    private Decimal totalUnassigned = 0;
    private Map<Id, String> contractNameMap;
    private Integer monthDays;
    private String monthYearText;
    private String employeeName;

    public FTETimeCardGenerator(Integer fteYear, Integer employeeMonth, Id employeeId) {
        this.employeeMonth = employeeMonth;
        this.employeeId = employeeId;
        this.fteYear = fteYear;
    }

    public List<FTEMonthTimeCard> generateMonthTimeCards() {
        SFDC_Employee__c employee = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Id =: employeeId LIMIT 1];
        this.employeeName = employee.Name;
        this.monthYearText = DateTime.newInstance(this.fteYear, this.employeeMonth, 1).format('MMMM yyyy');
        this.fileName = employee.Name.replaceAll(' ', '_') + '_' + this.monthYearText.replaceAll(' ', '_') + '.csv';

        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name, Total__c, FTE_hours__c,
                                        FTE_Contract__c, FTE_Contract__r.Name, FTE_Contract__r.FTE_Tracker__c, Date__c
                                        FROM Time_Card__c WHERE Employee__c =: this.employeeId AND Client__c != null
                                        AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.employeeMonth
                                        ORDER BY Client__r.Name];

        this.monthDays = Date.daysInMonth(this.fteYear, employeeMonth);
        this.unassignedHours = new FTEMonthTimeCard('Overhead', this.monthDays);
        this.contractMap = new Map<Id, FTEMonthTimeCard>();

        List<Time_Card__c> fteCards = new List<Time_Card__c>();
        for (Time_Card__c timeCard : timeCards) {
            addLoggedTime(timeCard);
            if (timeCard.FTE_Contract__c != null) {
                fteCards.add(timeCard);
            }
        }

        //we want do this in separate loop to know how much hours we can move for given day
        //it will allow us to avoid negative hours
        for (Time_Card__c fteCard : fteCards) {
            if (fteCard.Client__r.FTE_Tracker__c != 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c == 'Yes') { // From Unassigned to Assigned
                FTEMonthTimeCard monthCard = this.contractMap.get(fteCard.FTE_Contract__c);
                if (monthCard == null) {
                    this.contractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCard = this.contractMap.get(fteCard.FTE_Contract__c);
                }
                Decimal hoursHelper = fteCard.FTE_hours__c;
                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = unassignedHours.hours[i] < hoursHelper ? unassignedHours.hours[i] : hoursHelper;
                    monthCard.hours[i] += hoursToMove;
                    unassignedHours.hours[i] -= hoursToMove;
                    hoursHelper -= hoursToMove;
                    this.totalUnassigned -= hoursToMove;
                    this.total += hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } else if (fteCard.Client__r.FTE_Tracker__c == 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c != 'Yes') { //From Assigned to Unassigned
                FTEMonthTimeCard monthCard = this.contractMap.get(fteCard.Client__c);
                Decimal hoursHelper = fteCard.FTE_hours__c;
                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCard.hours[i] < hoursHelper ? monthCard.hours[i] : hoursHelper;
                    monthCard.hours[i] -= hoursToMove;
                    unassignedHours.hours[i] += hoursToMove;
                    hoursHelper -= hoursToMove;
                    this.totalUnassigned += hoursToMove;
                    this.total -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } else if (fteCard.Client__r.FTE_Tracker__c == 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c == 'Yes') {
                FTEMonthTimeCard monthCardFrom = this.contractMap.get(fteCard.Client__c);
                FTEMonthTimeCard monthCardTo = this.contractMap.get(fteCard.FTE_Contract__c);
                if (monthCardTo == null) {
                    this.contractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCardTo = this.contractMap.get(fteCard.FTE_Contract__c);
                }
                Decimal hoursHelper = fteCard.FTE_hours__c;
                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCardFrom.hours[i] < hoursHelper ? monthCardFrom.hours[i] : hoursHelper;
                    monthCardFrom.hours[i] -= hoursToMove;
                    monthCardTo.hours[i] += hoursToMove;
                    hoursHelper -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } //From Unassigned to Unassigned is not important, we have sum as Overhead
        }

        // Generate list for UI and csv file
        List<FTEMonthTimeCard> result = this.contractMap.values();
        for (FTEMonthTimeCard resRecord : result) {
            for (Integer i = 0; i < this.monthDays; i++) {
                resRecord.hours[i] = resRecord.hours[i].setScale(2);
            }
        }
        for (Integer i = 0; i < this.monthDays; i++) {
            unassignedHours.hours[i] = unassignedHours.hours[i].setScale(2);
        }
        result.add(unassignedHours);
        return result;
    }

    private void addLoggedTime(Time_Card__c tc) {
        Integer day = tc.Date__c.day();
        if (tc.Client__r.FTE_Tracker__c == 'Yes') {
            if (!this.contractMap.containsKey(tc.Client__c)) {
                this.contractMap.put(tc.Client__c, new FTEMonthTimeCard(tc.Client__r.Name, this.monthDays));
            }
            FTEMonthTimeCard monthCard = this.contractMap.get(tc.Client__c);
            if (monthCard.hours[day - 1] != null) {
                monthCard.hours[day - 1] += tc.Total__c;
            } else {
                monthCard.hours[day - 1] = tc.Total__c;
            }
            this.total += tc.Total__c;
        } else {
            if (unassignedHours.hours[day - 1] != null) {
                unassignedHours.hours[day - 1] += tc.Total__c;
            } else {
                unassignedHours.hours[day - 1] = tc.Total__c;
            }
            this.totalUnassigned += tc.Total__c;
        }
    }

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer day) {
        if (fteTracker == true) {
            if (!this.contractMap.containsKey(clientId)) {
                this.contractMap.put(clientId, new FTEMonthTimeCard(clientName, this.monthDays));
            }
            FTEMonthTimeCard motnhCard = this.contractMap.get(clientId);
            if (motnhCard.hours[day - 1] != null) {
                motnhCard.hours[day - 1] += loggedHours;
            } else {
                motnhCard.hours[day - 1] = loggedHours;
            }
            this.total += loggedHours;
        } else {
            if (unassignedHours.hours[day - 1] != null) {
                unassignedHours.hours[day - 1] += loggedHours;
            } else {
                unassignedHours.hours[day - 1] = loggedHours;
            }
            this.totalUnassigned += loggedHours;
        }
    }

    public void generateCsv() {
        if (this.fileName == null) {
            return;
        }
        this.csvFile = CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Employee Name",';
        this.csvFile += '"' + this.employeeName + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Period of Time",';
        this.csvFile += '"' + this.monthYearText + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Projects",';
        for (Integer i = 1; i <= 16; i++) {
             addCsvCell(String.valueOf(i), i, 16);
        }

        for (Id contractId : contractMap.keySet()) {
            FTEMonthTimeCard record = contractMap.get(contractId);
            this.csvFile += '"' + record.name + '",';
            for (Integer i = 0; i < 16; i++) {
                addCsvCell(record.hours[i] != null ? String.valueOf(record.hours[i]).replaceFirst('/.', ',') : '0', i, 15);
            }
        }
        this.csvFile += '"Overhead",';
        for (Integer i = 0; i < 16; i++) {
            addCsvCell(unassignedHours.hours[i] != null ? String.valueOf(unassignedHours.hours[i]).replaceFirst('/.', ',') : '0', i, 15);
        }

        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Projects",';
        for (Integer i = 17; i <= monthDays; i++) {
             addCsvCell(String.valueOf(i), i, monthDays);
        }

        for (Id contractId : contractMap.keySet()) {
            FTEMonthTimeCard record = contractMap.get(contractId);
            this.csvFile += '"' + record.name + '",';
            for (Integer i = 16; i < monthDays; i++) {
                addCsvCell(record.hours[i] != null ? String.valueOf(record.hours[i]).replaceFirst('/.', ',') : '0', i, monthDays - 1);
            }
        }
        this.csvFile += '"Overhead",';
        for (Integer i = 16; i < monthDays; i++) {
            addCsvCell(unassignedHours.hours[i] != null ? String.valueOf(unassignedHours.hours[i]).replaceFirst('/.', ',') : '0', i, monthDays - 1);
        }

        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Total Project Hours",';
        this.csvFile += '"' + total.setScale(2) + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Total Overhead Hours",';
        this.csvFile += '"' + totalUnassigned.setScale(2) + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
    }

    private void addCsvCell(String val, Integer countValue,  Integer limitValue) {
         if (countValue != limitValue) {
            this.csvFile += '"' + val + '",';
        } else {
            this.csvFile += '"' + val + '"'+ NEW_LINE;
        }
    }
}