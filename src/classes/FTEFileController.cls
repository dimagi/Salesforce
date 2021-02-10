/**
* Controller used to generate FTE Time Cards as csv file body.
*/
public class FTEFileController extends FTEController {
    
    public Id employeeId { get; set;}
    public Integer exportMonth {get; set;}
    public Integer monthDays {get; set;}
    public Integer fteYear {get; set;}
    public Integer day { get; set;}
    public String contractName { get; set;}
    public Decimal totalHoursOfContract { get; set;}
    public String fteDays { get; set;}
    public Decimal userAvailableDays { get; set;}
    public FTETimeCardGenerator fteTimeCardGenerator { get; set;}
    
    public Integer one { get; set ; }
    public List<FTEMonthTimeCard> employeeMonthProjects { get; set; }
    public List<FTEColumnWrapper> rowList { get; set; }
    
    public String monthYearText {get; set;}
    public SFDC_Employee__c employee { get; set;}
    public String fileName {get; set;}
    public String csvFile {get; set;}
    
    private Boolean downloadPage;
    
    public FTEFileController() {
        this.one = 1;
        this.downloadPage = false;
        if (ApexPages.currentPage().getUrl().toLowerCase().contains('fte_download_file')) {
            this.downloadPage = true;
        }
        
        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }
        
        String monthString = ApexPages.currentPage().getParameters().get('month');
        if (monthString != null && monthString.isNumeric()) {
            this.exportMonth = Integer.valueOf(monthString);
        } else {
            this.exportMonth = 1; // Default January
        }
        
        this.monthDays = Date.daysInMonth(fteYear, this.exportMonth);
        this.rowList = new List<FTEColumnWrapper>();
        this.monthYearText = DateTime.newInstance(fteYear, this.exportMonth, 1).format('MMMM yyyy');
        
        String emplId = ApexPages.currentPage().getParameters().get('employeeId');
        if (emplId != null && emplId InstanceOf Id) {
            this.employeeId = (Id) emplId;
            List<SFDC_Employee__c> emplList = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
            if (emplList.size() > 0) {
                this.employee = emplList.get(0);
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            if (this.downloadPage) {
                throw new CalloutException('Cannot generate file. Employee Id is empty.');
            }
        }
        
        if (this.downloadPage) {
            FTETimeCardGenerator generator = new FTETimeCardGenerator(this.fteyear, this.exportMonth, this.employeeId);
            generator.generateMonthWorkCards();
            generator.generateCsv();
            this.fileName = generator.fileName;
            this.csvFile = generator.csvFile;
        }
    }
    
    public void loadExportTimeCards() {
        if (this.employeeId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            return;
        }
        if (exportMonth != null) {
            FTETimeCardGenerator generator = new FTETimeCardGenerator(this.fteYear, this.exportMonth, this.employeeId);
            this.employeeMonthProjects = generator.generateMonthWorkCards();
        }
        for (Integer i = 0; i < this.monthDays; i++) {
            this.rowList.add(new FTEColumnWrapper(DateTime.newInstance(this.fteYear, this.exportMonth, i+1).format('EEEE'), i));
        }
    }
    
    public PageReference goToEmployeeViewFromTimeCardView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        if (Date.today().year() != this.fteYear) {
            pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        }
        
        return pageRef;
    }
    
    public class FTEColumnWrapper {
        
        public String columnName { get; set; }
        public Integer dayNumber { get; set; }
        public Integer index { get; set; }
        
        public FTEColumnWrapper(String columnName, Integer index) {
            this.columnName = columnName;
            this.index = index;
            this.dayNumber = index + 1;
        }
    }
    
    public void unAssignDays() {
        System.debug(this.contractName+' '+this.employeeId);
        System.debug(this.totalHoursOfContract);
        System.debug(this.day + '--' + this.fteYear + '--' + this.exportMonth);
        
       /* List<FTE_Day_Card__c> dayCards = [SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: this.contractName AND Employee__c =:this.employeeId
                                          AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.exportMonth];
        System.debug(dayCards);
        
        Decimal totalHours = 0;
        Decimal workCardTotalHours = 0;
        for (FTE_Day_Card__c dc : dayCards) {
            totalHours += dc.hours__c;
            workCardTotalHours = dc.Work_Card_Total_Hours__c;
        }
        this.userAvailableDays = workCardTotalHours - totalHours;  */
        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        FTE_Day_Card__c dayCardFromDb = [SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: this.contractName AND Employee__c =:this.employeeId
                                         AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.exportMonth AND DAY_IN_MONTH(Date__c) =: this.day+1 LIMIT 1];
        system.debug('dayCardFromDb.hours__c : '+dayCardFromDb.hours__c);
        //if(fteDaysdecimal > dayCardFromDb.hours__c){
            this.userAvailableDays = dayCardFromDb.hours__c + dayCardFromDb.Available_Hours__c;
        	this.userAvailableDays = this.userAvailableDays.setScale(4);
       // }
        
    }
    
    public void updateDayCard() {
        FTETimeCardGenerator generator = new FTETimeCardGenerator(this.fteyear, this.exportMonth, this.employeeId);
        Decimal fteDaysdecimal = this.fteDays != null && this.fteDays != '' ? Decimal.valueOf(this.fteDays) : 0;
        generator.updateFteDayCard(this.contractName, this.day+1, fteDaysdecimal);

      	this.employeeMonthProjects = generator.generateMonthWorkCards();
    }
        
}