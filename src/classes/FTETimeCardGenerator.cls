public class FTETimeCardGenerator {

    public static final String NEW_LINE = '\n';

    private Integer fteYear;
    private Integer employeeMonth;
    private Id employeeId;
    private FTEMonthTimeCard unassignedHours;
    private Map<Id, FTEMonthTimeCard> fteContractMap;
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
        this.fteContractMap = new Map<Id, FTEMonthTimeCard>();
        this.contractMap = new Map<Id, FTEMonthTimeCard>();

        List<Time_Card__c> fteCards = new List<Time_Card__c>();
        for (Time_Card__c timeCard : timeCards) {
            System.debug('Client order : ' + timeCard.Client__r.Name);
            addLoggedTime(timeCard);
            if (timeCard.FTE_Contract__c != null) {
                fteCards.add(timeCard);
            }
        }

        fteCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name, Total__c, FTE_hours__c, FTE_Contract__r.CreatedDate, Client__r.CreatedDate,
                                        FTE_Contract__c, FTE_Contract__r.Name, FTE_Contract__r.FTE_Tracker__c, Date__c
                                        FROM Time_Card__c WHERE Id IN: fteCards ORDER BY Client__r.FTE_Tracker__c ASC, FTE_Contract__r.CreatedDate, Client__r.CreatedDate];

        for (Time_Card__c timeCard : fteCards) {
            System.debug('Client order : ' + timeCard.Client__r.Name + ' ' + timeCard.FTE_Contract__r.CreatedDate + ' ' + timeCard.Client__r.CreatedDate);
        }

        while(fteCards.size() > 0) {
            fteCards = moveTimeCardTime(fteCards);
        }

        // Generate list for UI and csv file
        return getResult();
    }

    public List<Time_Card__c> moveTimeCardTime(List<Time_Card__c> fteCards) {
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Boolean timeMoved = false;
        for (Time_Card__c fteCard : fteCards) {
            Decimal hoursHelper = fteCard.FTE_hours__c;

            if (fteCard.Client__r.FTE_Tracker__c != 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c == 'Yes') { // From Unassigned to Assigned
                FTEMonthTimeCard monthCard = this.contractMap.get(fteCard.Client__c);
                FTEMonthTimeCard monthCardTag = this.fteContractMap.get(fteCard.FTE_Contract__c);

                if (monthCardTag == null) {
                    this.fteContractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCardTag = this.fteContractMap.get(fteCard.FTE_Contract__c);
                }

                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCard.hours[i] < hoursHelper ? monthCard.hours[i] : hoursHelper;
                    if (hoursToMove > 0) {
                        timeMoved = true;
                    }

                    monthCardTag.hours[i] += hoursToMove;
                    monthCardTag.totalHours += hoursToMove;

                    monthCard.hours[i] -= hoursToMove;
                    monthCard.totalHours -= hoursToMove;

                    unassignedHours.hours[i] -= hoursToMove;
                    unassignedHours.totalHours -= hoursToMove;

                    hoursHelper -= hoursToMove;
                    fteCard.FTE_hours__c -= hoursToMove;

                    this.totalUnassigned -= hoursToMove;
                    this.total += hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } else if (fteCard.Client__r.FTE_Tracker__c == 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c != 'Yes') { //From Assigned to Unassigned
                FTEMonthTimeCard monthCard = this.fteContractMap.get(fteCard.Client__c);
                FTEMonthTimeCard monthCardTag = this.contractMap.get(fteCard.FTE_Contract__c);

                if (monthCardTag == null) {
                    this.contractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCardTag = this.contractMap.get(fteCard.FTE_Contract__c);
                }

                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCard.hours[i] < hoursHelper ? monthCard.hours[i] : hoursHelper;
                    if (hoursToMove > 0) {
                        timeMoved = true;
                    }

                    monthCardTag.hours[i] += hoursToMove;
                    monthCardTag.totalHours += hoursToMove;

                    monthCard.hours[i] -= hoursToMove;
                    monthCard.totalHours -= hoursToMove;

                    unassignedHours.hours[i] += hoursToMove;
                    unassignedHours.totalHours += hoursToMove;

                    hoursHelper -= hoursToMove;
                    fteCard.FTE_hours__c -= hoursToMove;

                    this.totalUnassigned += hoursToMove;
                    this.total -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }
            } else if (fteCard.Client__r.FTE_Tracker__c == 'Yes' && fteCard.FTE_Contract__r.FTE_Tracker__c == 'Yes') {
                FTEMonthTimeCard monthCard = this.fteContractMap.get(fteCard.Client__c);
                FTEMonthTimeCard monthCardTag = this.fteContractMap.get(fteCard.FTE_Contract__c);

                if (monthCardTag == null) {
                    this.fteContractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCardTag = this.fteContractMap.get(fteCard.FTE_Contract__c);
                }

                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCard.hours[i] < hoursHelper ? monthCard.hours[i] : hoursHelper;
                    if (hoursToMove > 0) {
                        timeMoved = true;
                    }
                    monthCard.hours[i] -= hoursToMove;
                    monthCard.totalHours -= hoursToMove;

                    monthCardTag.hours[i] += hoursToMove;
                    monthCardTag.totalHours += hoursToMove;

                    hoursHelper -= hoursToMove;
                    fteCard.FTE_hours__c -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }

                if (hoursHelper > 0) {
                    timeCards.add(fteCard);
                }
            } else { //From Unassigned to Unassigned
                FTEMonthTimeCard monthCard = this.contractMap.get(fteCard.Client__c);
                FTEMonthTimeCard monthCardTag = this.contractMap.get(fteCard.FTE_Contract__c);

                if (monthCardTag == null) {
                    this.contractMap.put(fteCard.FTE_Contract__c, new FTEMonthTimeCard(fteCard.FTE_Contract__r.Name, this.monthDays));
                    monthCardTag = this.contractMap.get(fteCard.FTE_Contract__c);
                }

                for (Integer i = 0; i < this.monthDays; i++) {
                    Decimal hoursToMove = monthCard.hours[i] < hoursHelper ? monthCard.hours[i] : hoursHelper;
                    if (hoursToMove > 0) {
                        timeMoved = true;
                    }
                    monthCard.hours[i] -= hoursToMove;
                    monthCard.totalHours -= hoursToMove;

                    monthCardTag.hours[i] += hoursToMove;
                    monthCardTag.totalHours += hoursToMove;

                    hoursHelper -= hoursToMove;
                    fteCard.FTE_hours__c -= hoursToMove;
                    if (hoursHelper <= 0) {
                        break;
                    }
                }

                if (hoursHelper > 0) {
                    timeCards.add(fteCard);
                }
            }
        }

        return timeMoved == true ? timeCards : new List<Time_Card__c>();
    }

    public void generateCsv() {
        if (this.fileName == null) {
            return;
        }

        List<FTEMonthTimeCard> result = getResult();
        String csvEmptyRowPart1 = '""\t""';
        String csvEmptyRowPart2 = '';
        for (FTEMonthTimeCard monthData : result) { // build dynamic empty row based on columns
           csvEmptyRowPart2 += '\t""';
        }

        this.csvFile = '"Employee Name"\t';
        this.csvFile += '"' + this.employeeName + '"';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += '"Month-Year:"\t';
        this.csvFile += '"' + this.monthYearText + '"';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += '"Report Type:"\t"Hours by Project"\t';
        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
        this.csvFile += csvEmptyRowPart1 + csvEmptyRowPart2 + NEW_LINE;

        this.csvFile += '""\t""\t"Projects:"';
        for (Integer i = 0 ; i < result.size() - 1; i++) {
             this.csvFile += '\t""';
        }
        this.csvFile += NEW_LINE;

        this.csvFile += '"Day of Week:"\t';
        this.csvFile += '"Day of Month"';
        for (FTEMonthTimeCard monthData : result) {
             this.csvFile += '\t"' + monthData.name + '"';
        }
        this.csvFile += NEW_LINE;

        for (Integer day = 1; day <= this.monthDays; day++) {
            this.csvFile += '"' + DateTime.newInstance(this.fteYear, this.monthDays, day).format('EEEE') + '"\t"' + day + '"';
            for (FTEMonthTimeCard monthData : result) {
                this.csvFile += '\t"' + monthData.hours[day - 1] + '"';
            }
            this.csvFile += NEW_LINE;
        }

        this.csvFile += '"Total Project Hours:"\t""';
        for (FTEMonthTimeCard monthData : result) {
             this.csvFile += '\t"' + monthData.totalHours + '"';
        }

        this.csvFile += csvEmptyRowPart2 + NEW_LINE;
    }

    private void addCsvCell(String val, Integer countValue,  Integer limitValue) {
         if (countValue != limitValue) {
            this.csvFile += '"' + val + '"\t';
        } else {
            this.csvFile += '"' + val + '"'+ NEW_LINE;
        }
    }

    private List<FTEMonthTimeCard> getResult() {
        // Generate list for UI and csv file
        List<FTEMonthTimeCard> result = this.fteContractMap.values();
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
            if (!this.fteContractMap.containsKey(tc.Client__c)) {
                this.fteContractMap.put(tc.Client__c, new FTEMonthTimeCard(tc.Client__r.Name, this.monthDays));
            }
            FTEMonthTimeCard monthCard = this.fteContractMap.get(tc.Client__c);
            setHoursValue(monthCard, day, tc.Total__c);
            this.total += tc.Total__c;
        } else {
            if (!this.contractMap.containsKey(tc.Client__c)) { // we use additional map as a helper to move hours from contract
                this.contractMap.put(tc.Client__c, new FTEMonthTimeCard(tc.Client__r.Name, this.monthDays));
            }
            FTEMonthTimeCard monthCard = this.contractMap.get(tc.Client__c);
            setHoursValue(monthCard, day, tc.Total__c);
            setHoursValue(unassignedHours, day, tc.Total__c);
            this.totalUnassigned += tc.Total__c;
        }
    }

    private void setHoursValue(FTEMonthTimeCard monthData, Integer day, Decimal value) {
            if (monthData.hours[day - 1] != null) {
                monthData.hours[day - 1] += value;
            } else {
                monthData.hours[day - 1] = value;
            }
            monthData.totalHours += value;
    }
}