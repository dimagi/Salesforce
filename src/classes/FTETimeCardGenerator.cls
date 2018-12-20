public class FTETimeCardGenerator {

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
        SFDC_Employee__c employee = [SELECT Id, Name FROM SFDC_Employee__c WHERE Id =: employeeId LIMIT 1];
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
                    monthCard.totalHours += hoursToMove;
                    unassignedHours.totalHours -= hoursToMove;
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
                    monthCard.totalHours -= hoursToMove;
                    unassignedHours.totalHours += hoursToMove;
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
                    monthCardFrom.totalHours -= hoursToMove;
                    monthCardTo.totalHours += hoursToMove;
                    hoursHelper -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } //From Unassigned to Unassigned is not important, we have sum as Overhead
        }

        // Generate list for UI and csv file
        return getResult();
    }

    public void generateCsv() {
        if (this.fileName == null) {
            return;
        }

        List<FTEMonthTimeCard> result = getResult();
        String csvEmptyRowPart1 = '"",""';
        String csvEmptyRowPart2 = '';
        for (FTEMonthTimeCard monthData : result) { // build dynamic empty row based on columns
           csvEmptyRowPart2 += ',""';
        }

        this.csvFile = '"Employee Name",';
        this.csvFile += '"' + this.employeeName + '"';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += '"Month-Year:",';
        this.csvFile += '"' + this.monthYearText + '"';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += '"Report Type:","Hours by Project",';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += csvEmptyRowPart1 + csvEmptyRowPart2 + NEW_LINE;

        this.csvFile += '"Projects:",""';
        for (FTEMonthTimeCard monthData : result) {
             this.csvFile += ',"' + monthData.name + '"';
        }
        this.csvFile += NEW_LINE;

        this.csvFile += '"Total Project Hours:",""';
        for (FTEMonthTimeCard monthData : result) {
             this.csvFile += ',"' + monthData.totalHours + '"';
        }
        this.csvFile += NEW_LINE;
        this.csvFile += csvEmptyRowPart1 + csvEmptyRowPart2 + NEW_LINE;

        this.csvFile += '"Day of Week:",';
        this.csvFile += '"Day of Month"';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;

        for (Integer day = 1; day <= this.monthDays; day++) {
            this.csvFile += '"' + DateTime.newInstance(this.fteYear, this.monthDays, day).format('EEEE') + '","' + day + '"';
            for (FTEMonthTimeCard monthData : result) {
                this.csvFile += ',"' + monthData.hours[day - 1] + '"';
            }
            this.csvFile += NEW_LINE;
        }
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
    }

    private void addCsvCell(String val, Integer countValue,  Integer limitValue) {
         if (countValue != limitValue) {
            this.csvFile += '"' + val + '",';
        } else {
            this.csvFile += '"' + val + '"'+ NEW_LINE;
        }
    }

    private List<FTEMonthTimeCard> getResult() {
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
            monthCard.totalHours += tc.Total__c;
            this.total += tc.Total__c;
        } else {
            if (unassignedHours.hours[day - 1] != null) {
                unassignedHours.hours[day - 1] += tc.Total__c;
            } else {
                unassignedHours.hours[day - 1] = tc.Total__c;
            }
            unassignedHours.totalHours += tc.Total__c;
            this.totalUnassigned += tc.Total__c;
        }
    }
}