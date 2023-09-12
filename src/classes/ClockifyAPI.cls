public class ClockifyAPI {  
    public String url;
    public Integer totalCount;
    public String XApikey;
    public String startRange{set; get;} 
    public String endRange{set; get;}
    public Clockify_Settings__c clockifySettings ;
    
    public ClockifyAPI(){
        clockifySettings = Clockify_Settings__c.getInstance();
        this.url = clockifySettings.URL__c;
        this.XApikey = clockifySettings.XApikey__c;
        this.totalCount = null;
        this.startRange = null;
        this.endRange = null;       
    }
    public Integer getTotalCount(){
        Boolean success = false;
        Integer requests = 0;
        HTTPResponse response = null;
        while (!success && requests < 3) {
            try {
                response = getCallOutResponseContents(1,1);
                success = true;
            }
            catch(Exception e){                
                requests++;
                System.debug('--requests' + requests);
            }
        }
        try{
            String responseBody = response.getBody().replace('"end":', '"end_Z":');
            ClockifyModel ClockifyData = ClockifyModel.parse(responseBody);
        
            this.totalCount =  ClockifyData.totals[0].entriesCount;
            System.debug('Total Entries Count : ' +this.totalCount);
            return this.totalCount;
        }
        catch(Exception ex){
            StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script', 0, 'Cannot fetch total count. Line: ' + ex.getLineNumber() + ' Message: ' + ex.getMessage());
            return 0;
        }
    }
    public list<Time_Card__c> getTimeEntries(HTTPResponse response){
        list<Time_Card__c> timeCardList = new list<Time_Card__c>();
        try{  
            System.debug('response###' +response);            
            
            String responseBody = response.getBody().replace('"end":', '"end_Z":');
            
            ClockifyModel ClockifyData = ClockifyModel.parse(responseBody);
            System.debug('ClockifyData.timeentries.size()'+ClockifyData.timeentries.size());
        
            Map<String,Id> EmployeeEmailIdMap = getEmployeeEmailIdMap(ClockifyData.timeentries);
            Map<String,Id> ClientNameIdMap = getClientNameIdMap(ClockifyData.timeentries);
            Decimal secondsDuration = 0;
            
            for(Integer i = 0 ; i<ClockifyData.timeentries.size(); i++){
                Time_Card__c tcard = new Time_Card__c();
                if(ClockifyData.timeentries[i].tags.size()>0){
                    if(ClientNameIdMap.containsKey(ClockifyData.timeentries[i].tags[0].name)){
                        tcard.Client__c = ClientNameIdMap.get(ClockifyData.timeentries[i].tags[0].name);
                    }
                }
                if(EmployeeEmailIdMap.containsKey(ClockifyData.timeentries[i].userEmail)){
                    tcard.Employee__c = EmployeeEmailIdMap.get(ClockifyData.timeentries[i].userEmail);
                }else{
                    StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, clockifyData.timeentries[i].userName, i+1, 'User does not exist'+'-'+clockifyData.timeentries[i].userName);
                }
                tcard.Time_Entry_ID__c = ClockifyData.timeentries[i].x_id;
                tcard.Area__c = ClockifyData.timeentries[i].taskName;
                String timeEntryDesc = ClockifyData.timeentries[i].description;
                tcard.Case__c = String.isNotBlank(timeEntryDesc) ? (timeEntryDesc.length() > 255 ? timeEntryDesc.subString(0, 255) : timeEntryDesc.subString(0, timeEntryDesc.length())) : '';
                tcard.Date__c = Date.valueOf(ClockifyData.timeentries[i].timeInterval.end_Z);
                secondsDuration = ClockifyData.timeentries[i].timeInterval.duration;
                tcard.FTE_hours__c = ClockifyData.timeentries[i].timeInterval.duration != null ? secondsDuration.divide(3600, 2): 0; //seconds to hours
                tcard.Project__c = ClockifyData.timeentries[i].projectName;
                tcard.Task_ID__c = String.valueOf(ClockifyData.timeentries[i].taskId);
                tcard.Total__c = ClockifyData.timeentries[i].timeInterval.duration != null ? secondsDuration.divide(3600, 2): 0; //seconds to hours
                if(tcard.Employee__c != null){
                    timeCardList.add(tcard);
                }else{
                    continue;
                }
            }   
        }catch(Exception e){           
            System.debug('ex--' + e.getStackTraceString());
            System.debug('ex--' + e.getMessage());
            StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script - time entry failed', 0, e.getMessage() + ' ' + e.getStackTraceString());
        }
        return timeCardList;        
    }
    public HTTPResponse getCallOutResponseContents(Integer page, Integer pageSize){
        System.debug('Page , pageSize :' +page+','+pageSize);
        String totalsParam = pageSize == 1 ? 'CALCULATE' : 'EXCLUDE' ;
        Http httpObject = new Http(); 
        HttpRequest request = new HttpRequest();
        HTTPResponse response;

        request.setEndpoint(this.url);        
        request.setHeader('X-Api-Key', this.XApikey);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', '*/*');
        request.setHeader('Accept-Encoding', 'gzip, deflate, br');
        request.setHeader('Connection', 'keep-alive');
        request.setMethod('POST');
        request.setBody('{"dateRangeStart": \"'+ startRange +'\", ' +
                        ' "dateRangeEnd": \"'+ endRange +'\", ' +
                        ' "detailedFilter":  '+
                        '        { ' +
                        '            "page":'+page +',' +
                        '            "pageSize":'+pageSize+',' +
                        '            "auditFilter": {'+
                        '                   "withoutProject":'+ false+','+
                        '                   "withoutTask": '+false+','+
                        '                   "durationShorter":' +true+
                        '                            },'+
                        '                       "options": {' + 
                        '                      "totals":  \"'+ totalsParam +'\" ' + 
                        '                                }'+
                        '         }'+
                        '    }');
        request.setTimeout(120000);
       
        try{
            response = httpObject.send(request);
        }catch(Exception e){           
            System.debug('ex--' + e.getStackTraceString());
            System.debug('ex--' + e.getMessage());
            StatusLoggerUtils.logError(StatusLoggerUtils.CLOCKIFY_LOGGER, 'Clockify Sync Script-Send Request', 0, e.getMessage() + ' ' + e.getStackTraceString());
        }
      
        System.debug(response.getBody());
       
        return response;
    }
    private Map<String,Id> getEmployeeEmailIdMap(List<ClockifyModel.timeentries> timeentries){
        Map<String,Id> EmployeeEmailIdMap = new Map<String,Id>();
        List<String> timeEntryEmails = new List<String>();
        for(Integer i = 0; i<timeentries.size(); i++){
            timeEntryEmails.add(timeentries[i].userEmail);
        }
        for(SFDC_Employee__c employee : [SELECT Id , Name, Email_Address__c  FROM SFDC_Employee__c WHERE Email_Address__c IN:timeEntryEmails]){
            EmployeeEmailIdMap.put(employee.Email_Address__c, employee.Id);
        }        
        return EmployeeEmailIdMap;
    }
    private Map<String,Id> getClientNameIdMap(List<ClockifyModel.timeentries> timeentries){
        Map<String,Id> ClientNameIdMap = new Map<String,Id>();
        List<String> tagNames = new List<String>();
        for(Integer i = 0; i<timeentries.size(); i++){
            for(Integer t = 0; t<timeentries[i].tags.size(); t++){
                tagNames.add(timeentries[i].tags[t].name);
            }
        }
        for(DContract__c contract : [SELECT Id , Name FROM DContract__c WHERE Name IN:tagNames]){
            ClientNameIdMap.put(contract.Name, contract.Id);
        }  
        return ClientNameIdMap;
    }
}