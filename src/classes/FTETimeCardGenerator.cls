public class FTETimeCardGenerator {
    
    public static final String NEW_LINE = '\n';
    
    private Integer fteYear;
    private Integer employeeMonth;
    private Id employeeId;
    private FTEMonthTimeCard unassignedHours;
    private Map<Id, FTEMonthTimeCard> fteContractMap;
    private Map<Id, FTEMonthTimeCard> contractMap;
    
    public Map<Id, FTEMonthTimeCard> fteWorkCardContractMap;
    public String fileName {get; set;}
    public String csvFile {get; set;}
    
    private Decimal total = 0;
    private Decimal totalUnassigned = 0;
    private Decimal oveHeadTotal = 0;
    private Map<Id, String> contractNameMap;
    private Integer monthDays;
    private String monthYearText;
    private String employeeName;
    
    public FTETimeCardGenerator(Integer fteYear, Integer employeeMonth, Id employeeId) {
        this.employeeMonth = employeeMonth;
        this.employeeId = employeeId;
        this.fteYear = fteYear;
    }
    
    public List<FTEMonthTimeCard> generateMonthWorkCards() {
        //  System.debug('----');
        SFDC_Employee__c employee = [SELECT Id, Name FROM SFDC_Employee__c WHERE Id =: employeeId LIMIT 1];
        this.employeeName = employee.Name;
        this.monthYearText = DateTime.newInstance(this.fteYear, this.employeeMonth, 1).format('MMMM yyyy');
        this.fileName = employee.Name.replaceAll(' ', '_') + '_' + this.monthYearText.replaceAll(' ', '_') + '.csv';
        
        this.monthDays = Date.daysInMonth(this.fteYear, employeeMonth);
        this.unassignedHours = new FTEMonthTimeCard('Overhead', this.monthDays);
        this.fteWorkCardContractMap = new Map<Id, FTEMonthTimeCard>();
        
        List<FTE_Work_Card__c> fteWorkCards = new List<FTE_Work_Card__c>();
        
        String queryStr = 'SELECT Id, Name,Contract__r.Name, Month_' + this.employeeMonth + '__c, Total__c, Year__c FROM FTE_Work_Card__c WHERE Employee__c =: employeeId AND Year__c =: fteYear ORDER BY Contract__r.Name';
        
        
        fteWorkCards = Database.query(queryStr);
        for (FTE_Work_Card__c fteWorkCard : fteWorkCards) {
            Decimal value = (Decimal) fteWorkCard.get('Month_'+ this.employeeMonth + '__c');
            oveHeadTotal += value;
            // System.debug('Results: '+fteWorkCard);
            addWorkCardLoggedTime(fteWorkCard, this.employeeMonth);
            
        }
        
        List<DContract__C> contracts = [Select Id from DContract__C where name= 'Abt Associates:VC IDIQ'];
        FTEMonthTimeCard monthCard =  this.fteWorkCardContractMap.get(contracts.get(0).Id);
        //  System.debug(monthCard);
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
        
        this.csvFile += '"","","Projects:"';
        for (Integer i = 0 ; i < result.size() - 1; i++) {
            this.csvFile += ',""';
        }
        this.csvFile += NEW_LINE;
        
        this.csvFile += '"Day of Week:",';
        this.csvFile += '"Day of Month"';
        for (FTEMonthTimeCard monthData : result) {
            this.csvFile += ',"' + monthData.name + '"';
        }
        this.csvFile += NEW_LINE;
        
        for (Integer day = 1; day <= this.monthDays; day++) {
            this.csvFile += '"' + DateTime.newInstance(this.fteYear, this.monthDays, day).format('EEEE') + '","' + day + '"';
            for (FTEMonthTimeCard monthData : result) {
                this.csvFile += ',"' + monthData.hours[day - 1] + '"';
            }
            this.csvFile += NEW_LINE;
        }
        
        this.csvFile += '"Total Project Hours:",""';
        for (FTEMonthTimeCard monthData : result) {
            this.csvFile += ',"' + monthData.totalHours + '"';
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
        Integer workingDays = FTEWorkCardTriggerHandler.getMonthWorkingDays(this.employeeMonth,this.fteYear);
        List<FTEMonthTimeCard> result = this.fteWorkCardContractMap.values();
        
        for (FTEMonthTimeCard resRecord : result) {
            for (Integer i = 0; i < this.monthDays; i++) {
                resRecord.hours[i] = resRecord.hours[i].setScale(2);
                unassignedHours.hours[i] += resRecord.hours[i].setScale(2); //-new line
                
            }
        }
        for (Integer i = 0; i < this.monthDays; i++) {
            
            if((('Saturday').equals(DateTime.newInstance(this.fteYear, this.employeeMonth, i+1).format('EEEE'))))
            {
                unassignedHours.hours[i] = unassignedHours.hours[i] > 0 ? (0-unassignedHours.hours[i]) : 0;
                
            } else if((('Sunday').equals(DateTime.newInstance(this.fteYear, this.employeeMonth, i+1).format('EEEE')))){
                
                unassignedHours.hours[i] = unassignedHours.hours[i] > 0 ? (0-unassignedHours.hours[i]) : 0;
                
            } else {
                unassignedHours.hours[i] = 8- unassignedHours.hours[i]; //-new line                
                //   unassignedHours.hours[i] = (((22-oveHeadTotal)/workingDays)*8).setScale(2);
            }
            // unassignedHours.totalHours = ((22-oveHeadTotal)*8).setScale(2);
            unassignedHours.totalHours += unassignedHours.hours[i]; //--new line
            // unassignedHours.totalHours = 176 - unassignedHours.totalHours; //-new line
        }
        
        unassignedHours.totalHours =  unassignedHours.totalHours.round(System.RoundingMode.HALF_UP); 
        
        result.add(unassignedHours);
        return result;
    }
    
    // TODO: Get Monthly working days and asisgn them to this.monthDays
    private void addWorkCardLoggedTime(FTE_Work_Card__c wc, Integer employeeMonth) {
        Decimal monthTotalHours = (Decimal) wc.get('Month_' + employeeMonth + '__c');
        //System.debug('monthTotalHours: '+monthTotalHours);
        
        if (!this.fteWorkCardContractMap.containsKey(wc.Contract__c)) {
            this.fteWorkCardContractMap.put(wc.Contract__c, new FTEMonthTimeCard(wc.Contract__r.Name, this.monthDays));
        }
        FTEMonthTimeCard monthCard = this.fteWorkCardContractMap.get(wc.Contract__c);
        setWorkCardHoursValue(monthCard, monthTotalHours, wc.Contract__c);
        this.total += monthTotalHours;
        //System.debug('total: '+total);
        
    }
    
    private void setWorkCardHoursValue(FTEMonthTimeCard monthData, Decimal monthTotalHours, Id contractId) {
        List<FTE_Day_Card__c> dayCardsFromDb = [SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__c =: contractId AND Employee__c =:this.employeeId
                                                AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.employeeMonth];
        
        Integer workingDays = FTEWorkCardTriggerHandler.getMonthWorkingDays(this.employeeMonth,this.fteYear);
        if (dayCardsFromDb.size() > 0 && monthTotalHours > 0) {
            //  System.debug(monthTotalHours + ' ' + dayCardsFromDb.get(0).Work_Card_Total_Hours__c );
            // Start check Work_Card_Total_Hours__c updated or not.
            Decimal newDcHours = 0;
            Boolean isMonthTotalHoursUpdated = false;
            List<FTE_Day_Card__c> dayCardsToBeUpdated = new  List<FTE_Day_Card__c> ();
            if((dayCardsFromDb.get(0).Work_Card_Total_Hours__c != null) && (monthTotalHours != dayCardsFromDb.get(0).Work_Card_Total_Hours__c)){
                system.debug('isMonthTotalHoursUpdated :');
                newDcHours = (monthTotalHours/workingDays)*8;
                System.debug('newDcHours--' + newDcHours);
                isMonthTotalHoursUpdated = true;
            }            
            // - End
            
            Map<Date, FTE_Day_Card__c> dayCardsMap = new Map<Date, FTE_Day_Card__c>();
            for(FTE_Day_Card__c dc: dayCardsFromDb){
                // Start - Update day cards with new day card hours                                  
                //   if(isMonthTotalHoursUpdated && (dc.hours__c != 0))  {
                //system.debug('dc.date__c :'+dc.date__c);
                String dayOfWeek = DateTime.newInstance(dc.date__c.Year(), dc.date__c.Month(), dc.date__c.Day()).format('EEEE');
                //	system.debug('dayOfWeek :'+dayOfWeek );
                if(isMonthTotalHoursUpdated)  { 
                    if(dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday'){
                        dc.hours__c = newDcHours;
                    } else {
                        dc.hours__c = 0;
                    }
                    //  system.debug('dc.hours__c : '+dc.hours__c);                    
                    dc.Work_Card_Total_Hours__c = monthTotalHours;
                    dc.Available_Hours__c = 0;
                    dayCardsToBeUpdated.add(dc);
                }   
                // - End 
                if(!dayCardsMap.containsKey(dc.Date__c)){
                    dayCardsMap.put(dc.Date__c, dc);
                }
            }
            //System.debug('monthData.hours.size()' + monthData.hours.size());
            for(Integer i = 0; i<monthData.hours.size(); i++){
                Date dayCardDate = Date.newInstance(this.fteYear, this.employeeMonth, i+1);
                // System.debug(dayCardDate + '-----' + dayCardsMap.get(dayCardDate));
                FTE_Day_Card__c temp = dayCardsMap.get(dayCardDate);
                
                monthData.hours[i] = temp.hours__c;
                // System.debug(i+'----'+monthData.hours[i] );
                // monthData.totalHours += temp.hours__c;          // Nov 5th     
                monthData.workCardTotalHours = temp.Work_Card_Total_Hours__c.setScale(2);
            }
            //  monthData.totalHours = monthData.totalHours.round(System.RoundingMode.HALF_UP); 
            monthData.totalHours = (monthTotalHours*8) - dayCardsMap.values().get(0).Available_Hours__c; 
            
            if(isMonthTotalHoursUpdated) {
                update dayCardsToBeUpdated;
            }
            
        } else if(monthTotalHours > 0) {
            List<FTE_Day_Card__c> dayCardsToBeInserted = new List<FTE_Day_Card__c>();
            for(Integer i = 0; i<monthData.hours.size(); i++){
                // System.debug(DateTime.newInstance(this.fteYear, this.employeeMonth, i).format('EEEE'));
                if((('Saturday').equals(DateTime.newInstance(this.fteYear, this.employeeMonth, i+1).format('EEEE'))))
                {
                    monthData.hours[i] = 0;
                    FTE_Day_Card__c dayCardSat = new FTE_Day_Card__c(Contract__c = contractId, Employee__c = this.employeeId, hours__c = 0, Available_Hours__c = 0,
                                                                     Work_Card_Total_Hours__c = monthTotalHours.setScale(2), Date__c = Date.newInstance(this.fteYear, this.employeeMonth, i+1));
                    dayCardsToBeInserted.add(dayCardSat);
                } else if((('Sunday').equals(DateTime.newInstance(this.fteYear, this.employeeMonth, i+1).format('EEEE')))) {
                    monthData.hours[i] = 0;
                    FTE_Day_Card__c dayCardSun = new FTE_Day_Card__c(Contract__c = contractId, Employee__c = this.employeeId, hours__c = 0, Available_Hours__c = 0,
                                                                     Work_Card_Total_Hours__c = monthTotalHours.setScale(2), Date__c = Date.newInstance(this.fteYear, this.employeeMonth, i+1));
                    dayCardsToBeInserted.add(dayCardSun);
                } else {
                    monthData.hours[i] = (monthTotalHours/workingDays)*8;
                    FTE_Day_Card__c dayCard = new FTE_Day_Card__c(Contract__c = contractId, Employee__c = this.employeeId, hours__c = (monthTotalHours/workingDays)*8, Available_Hours__c = 0,
                                                                  Work_Card_Total_Hours__c = monthTotalHours.setScale(2), Date__c = Date.newInstance(this.fteYear, this.employeeMonth, i+1));
                    dayCardsToBeInserted.add(dayCard);
                }
            }
            // System.debug(dayCardsToBeInserted.size());
            monthData.totalHours = (monthTotalHours*8).setScale(2); 
            monthData.workCardTotalHours = monthTotalHours*8;
            System.debug(monthData.workCardTotalHours);
            insert dayCardsToBeInserted;
        } else if(monthTotalHours == 0.0) {
            delete dayCardsFromDb;
        }
    }
    
    public void updateFteDayCard(String contractName, Integer day, Decimal inputHours) {
        
        /*    FTE_Day_Card__c dayCardFromDb = [SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: contractName AND Employee__c =:this.employeeId
AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.employeeMonth AND DAY_IN_MONTH(Date__c) =: day LIMIT 1];
dayCardFromDb.hours__c = inputHours;
System.debug(dayCardFromDb.hours__c);
update dayCardFromDb;
*/
        List<FTE_Day_Card__c> dayCardFromDb = [SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: contractName AND Employee__c =:this.employeeId
                                               AND CALENDAR_YEAR(Date__c) =: this.fteYear AND CALENDAR_MONTH(Date__c) =: this.employeeMonth];
        Map<Date, FTE_Day_Card__c> dayCardsMap = new Map<Date, FTE_Day_Card__c>();
        
        for(FTE_Day_Card__c dc : dayCardFromDb){
            if(!dayCardsMap.containsKey(dc.Date__c)){
                dayCardsMap.put(dc.Date__c, dc);
            }
        } 
        Date dayCardDate = Date.newInstance(this.fteYear, this.employeeMonth, day);
        FTE_Day_Card__c singleDayCard = dayCardsMap.get(dayCardDate);
        
        Decimal diff;
        if(inputHours < singleDayCard.hours__c) {
            diff = singleDayCard.hours__c-inputHours;
            for(FTE_Day_Card__c dc : dayCardFromDb){
                dc.Available_Hours__c += diff;
                dc.Available_Hours__c= dc.Available_Hours__c.setScale(2); // Nov 5th
            }
            update dayCardFromDb;
        } else if(inputHours > singleDayCard.hours__c){
            diff = inputHours-singleDayCard.hours__c;
            for(FTE_Day_Card__c dc : dayCardFromDb){
                dc.Available_Hours__c -= diff;
                dc.Available_Hours__c= dc.Available_Hours__c.setScale(2);  // Nov 5th
            }
            update dayCardFromDb;
        }
        
        //System.debug(dayCardFromDb.hours__c);
        singleDayCard.hours__c = inputHours;
        update singleDayCard;      
    }
}