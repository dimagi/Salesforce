public class HQSyncAPI {

    private CommcareToSalesforceSettings__c serverSettings;
    private String endPoint;
    private String suffix;

    public HQSyncAPI(CommcareToSalesforceSettings__c serverSettings) {
        this(serverSettings, '');
    }

    public HQSyncAPI(CommcareToSalesforceSettings__c serverSettings, String endpointSuffix) {
        this.serverSettings = serverSettings;
        this.suffix = endpointSuffix;
        this.endPoint = this.serverSettings.Server_URL__c + (this.serverSettings.Server_URL__c.endsWith('/') ? '' : '/') + suffix;
        this.endPoint = this.endPoint + (this.endPoint.endsWith('/') ? '' : '/');
    }

    public Integer getTotalCount(Map<String, String> parameters) {
        Integer totalCount = null;
        parameters.put(HQSyncUtils.FORMAT_PARAM, HQSyncUtils.JSON_PARAM);
        parameters.put(HQSyncUtils.OFFSET_PARAM, '0');
        parameters.put(HQSyncUtils.LIMIT_PARAM, '1');
        HTTPResponse res = httpGet(parameters);
        JSONParser parser = JSON.createParser(res.getBody());

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total_count') {
                parser.nextToken();
                totalCount = parser.getIntegerValue();
                break;
            }
        }

        return totalCount;
    }

    public HTTPResponse httpGet(Map<String, String> parameters) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(this.endPoint + '?' + HQSyncUtils.buildURLParams(parameters));
        req.setMethod('GET');

        String username = this.serverSettings.CommCare_User_Name__c;
        String password = this.serverSettings.CommCare_Password__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('HQ Sync Error, cannot fetch HQ objects data. Http status : ' + res.getStatusCode() + ' Body : ' + res.getBody());
            throw e;
        }

        return res;
    }

    public void updateSyncDate(Date syncDate) {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        this.serverSettings.Last_Run_Date__c = syncDate;
        update this.serverSettings;
    }
}