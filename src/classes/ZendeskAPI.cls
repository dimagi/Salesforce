/**
 * Zendesk API class for fetching data form Dimagi Zendesk
 */
public class ZendeskAPI {


    private Dimagi_Zendesk_Settings__c settings;

    public ZendeskAPI(Dimagi_Zendesk_Settings__c settings) {
        this.settings = settings;
    }

    public HttpResponse httpGet(String queryString) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.Zendesk_Endpoint__c + '?query=' + queryString);
        req.setMethod('GET');

        Blob headerValue = Blob.valueOf(settings.Username__c + ':' + settings.Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('Zendesk sync Error. Http status : ' + res.getStatusCode() + ' Body : ' + res.toString());
            throw e;
        }

        return res;
    }
}