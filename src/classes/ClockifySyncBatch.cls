public class ClockifySyncBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {
    public String endRange;
    public String startRange;
    public Integer maxPageSize;
    public Integer noOfPages = 0;
    public ClockifyAPI clockify;
    public Clockify_Settings__c clockifySettings;
    private Integer recordCounter;
    private Date todayDate;
    private Integer count = 0;
    public ClockifySyncBatch(){
        clockifySettings = Clockify_Settings__c.getInstance();
        maxPageSize = Integer.valueOf(clockifySettings.Page_Size__c);
        this.clockify = new ClockifyAPI();
        Date currentDate = System.today();
        Integer year = currentDate.year();
        Integer month = currentDate.month() - 6;
        Integer day = currentDate.day();
        if(month < 0){
            month = 12 + month;
            year--;
        }
        this.startRange = String.valueOf(Date.newInstance(year, month, day)) + 'T00:00:00.000Z';
        this.endRange =  String.valueOf(currentDate) + 'T23:59:59.999Z';
         // this.startRange = String.valueOf('2021-07-01T00:00:00.000Z');
        // this.endRange =  String.valueOf('2021-07-31T23:59:59.999Z');
        this.todayDate = Date.today();
        this.recordCounter = 0;
    }
    
  
    public List<Integer> start(Database.BatchableContext context) {
        
        this.clockify.startRange = this.startRange;
        this.clockify.endRange = this.endRange;
        Integer totalCount = this.clockify.getTotalCount();
        this.recordCounter = totalCount;
        if(math.mod(totalCount,this.maxPageSize) == 0) {
            this.noOfPages = Integer.valueOf(totalCount /this.maxPageSize);
        }
        else {
            this.noOfPages = Integer.valueOf(totalCount /this.maxPageSize) + 1; 
        }
        
        List<Integer> pageNum = new List<Integer>();
        for(Integer i = 1 ; i <= this.noOfPages; i++){
            pageNum.add(i);
        }
        return pageNum;
    }
    public void execute(Database.BatchableContext context, List<Integer> pageNum) {
        try{
            Boolean success = false;
            Integer requests = 0;
            HttpResponse response = null;
            List<Time_Card__c> getTimeCards = new List<Time_Card__c>();
            
            for(Integer i : pageNum){
                if(requests == 3) success = true; 
                while (!success && requests < 3) {
                    try {
                        response = clockify.getCallOutResponseContents(i, this.maxPageSize);
                        if(response != null && response.getStatusCode() != 200)
                        {  
                            requests++; 
                        }
                        else
                            success = true;
                    }
                    catch(Exception e)
                    {
                        
                        StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script- Data', 0, 'Line: ' + e.getLineNumber() +' Message: ' + e.getMessage());
                        
                        Long startingTime = System.now().getTime();
                        Integer delayInMilliseconds = 12000; // Tweleve-second delay
                        while(System.now().getTime() - startingTime < delayInMilliseconds){
                            // Do nothing until desired delay has passed
                        }
                       
                        requests++;
                    }
                }
                try{
                    if(response != null && response.getStatusCode() == 200){
                        getTimeCards = clockify.getTimeEntries(response);
                        processTimeCards(getTimeCards);

                    }
                    else
                    {
                        StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script- StatusError', 0, 'Status Code: ' + response.getStatusCode() +' Message: ' + response.getStatus());
                        
                    }
                }
                catch(Exception ex){
                    success = false;
                    StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script', 0, 'Line: ' + ex.getLineNumber() +' Message: ' + ex.getMessage());
                }
               
            }
        }
        catch(Exception ex) {
            StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script', 0, 'Line: ' + ex.getLineNumber() +'Message: ' + ex.getMessage());
        }
        
    }
    public void finish(Database.BatchableContext context) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify sync Script', this.recordCounter,
                                  'Finished Clockify Sync Job with date : ' + this.todayDate);
       /*  string str = string.valueOf(count);
         StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script - Final count', 0, 'Line: ' + str +'Message: ' + str );
        */
        
        if(!Test.isRunningTest()){
            StatusLoggerUtils.sendLog(StatusLoggerUtils.CLOCKIFY_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(',')); 
        }
        
    }
    
    public void processTimeCards (List<Time_Card__c> getTimeCards) {
        List<Time_Card__c> timeCardList = new List<Time_Card__c>();
        Map<String, Time_Card__c> timeCardMap = new  Map<String, Time_Card__c>();
     
        for(Time_Card__c tc : getTimeCards){
            timeCardMap.put(tc.Time_Entry_ID__c, tc);
        }
        for (Time_Card__c existing : [SELECT Id, Client__c, Employee__c, Area__c, Case__c, Date__c, FTE_hours__c, Project__c, Total__c, Task_ID__c, Time_Entry_ID__c FROM Time_Card__c WHERE Time_Entry_ID__c IN: timeCardMap.keySet()]){
            system.debug(timeCardMap.get(existing.Time_Entry_ID__c));
            if(timeCardMap.get(existing.Time_Entry_ID__c) != null){
                Time_Card__c tc = timeCardMap.get(existing.Time_Entry_ID__c);
                if(existing.Client__c == tc.Client__c && existing.Employee__c == tc.Employee__c && existing.Area__c == tc.Area__c && existing.Case__c == tc.Case__c && existing.Date__c == tc.Date__c && 
                   existing.FTE_hours__c == tc.FTE_hours__c && existing.Project__c == tc.Project__c && existing.Total__c == tc.Total__c && existing.Task_ID__c == tc.Task_ID__c){
                    timeCardMap.remove(existing.Time_Entry_ID__c);                   
                }else{
                    tc.Id = existing.Id;
                }
                
            } 
        }
        /*Map<String, Id> externalIdMap = new  Map<String, Id>();
for(Time_Card__c tc: [SELECT Id, Time_Entry_ID__c FROM Time_Card__c Where Time_Entry_ID__c IN: timeCardMap.keySet()]) {
externalIdMap.put(tc.Time_Entry_ID__c, tc.Id);
}
for(Time_Card__c tc : timeCardMap.values()) {
if(externalIdMap.containsKey(tc.Time_Entry_ID__c)) {
tc.Id = externalIdMap.get(tc.Time_Entry_ID__c);
}
}*/     
       
        System.debug('timeCardMap--' + timeCardMap.keySet().size()+'--'+timeCardMap.values().size());
        try{
           
            if(timeCardMap.values().size() > 0){
                upsert timeCardMap.values();
             /*   count += timeCardMap.values().size();  string all_extIds;
                integer timecardbatchsize = time_card_Ids.size();
                for(String strg : time_card_Ids){ 
                    all_extIds += strg + ',';
                }
                string sizeStr = String.valueOf(timecardbatchsize);
                if(timecardbatchsize>0){
                    StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, '', 0, 'Line: ' +  sizeStr +'Message: ' + all_extIds);  
                } */
            }
        }
        catch(Exception ex) {
            StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, '', 0, 'Line: ' + ex.getLineNumber() +'Message: ' + ex.getMessage());
            System.debug('ex--' + ex.getStackTraceString());
            System.debug('ex--' + ex.getMessage());
        }
    }
}