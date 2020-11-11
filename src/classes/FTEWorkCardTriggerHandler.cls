public class FTEWorkCardTriggerHandler {
    private Integer monthDays;
    
    public static void handleAfterInsert(List<FTE_Work_Card__c> workCards) {        
        List<FTE_Day_Card__c> dayCardsToBeInserted = new List<FTE_Day_Card__c>();
        for(FTE_Work_Card__c wc: workCards){
            for(Integer i=1; i<=12; i++){
                Decimal monthValue = (Decimal) wc.get('Month_'+ i + '__c');
                if(monthValue > 0) {
                    Integer year = (Integer) wc.Year__c;
                    Integer monthDays =  Date.daysInMonth(year, i);
                    Integer workingDays = getMonthWorkingDays(i, year);
                    
                    for (Integer j = 1; j <= monthDays; j++) {                        
                        if(('Saturday').equals(DateTime.newInstance(year, i, j).format('EEEE')))
                        {
                            FTE_Day_Card__c dayCardSat = new FTE_Day_Card__c(Contract__c = wc.Contract__c, Employee__c = wc.Employee__c, hours__c = 0, Available_Hours__c = 0,
                                                                             Work_Card_Total_Hours__c = monthValue, Date__c = Date.newInstance(year, i, j));
                            dayCardsToBeInserted.add(dayCardSat);
                        } else if(('Sunday').equals(DateTime.newInstance(year, i, j).format('EEEE'))) {
                            FTE_Day_Card__c dayCardSun = new FTE_Day_Card__c(Contract__c = wc.Contract__c, Employee__c = wc.Employee__c, hours__c = 0, Available_Hours__c = 0,
                                                                             Work_Card_Total_Hours__c = monthValue, Date__c = Date.newInstance(year, i, j));
                            dayCardsToBeInserted.add(dayCardSun);
                        } else {
                            FTE_Day_Card__c dayCard = new FTE_Day_Card__c(Contract__c = wc.Contract__c, Employee__c = wc.Employee__c, hours__c = (monthValue/workingDays)*8, Available_Hours__c = 0,
                                                                          Work_Card_Total_Hours__c = monthValue, Date__c = Date.newInstance(year, i, j));
                            dayCardsToBeInserted.add(dayCard);
                        }
                    }
                }
            }            
        }
        insert dayCardsToBeInserted;
        
    }
    
    public static Integer getMonthWorkingDays(Integer month, Integer year){
        Integer workingDays= 0;
        Integer monthDays =  Date.daysInMonth(year, month);
        for(Integer k=1; K<=monthDays; k++){
            
            if(('Saturday').equals(DateTime.newInstance(year, month, k).format('EEEE')))
            {
            } else if(('Sunday').equals(DateTime.newInstance(year, month, k).format('EEEE')))
            {
            } else {
                workingDays = workingDays+1;                
            }
        }
        return workingDays;
    }
}