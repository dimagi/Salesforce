/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;
    private Integer countInvoice;
    private Integer countAll;
    private integer countFeature;


    /**
     * Script code for removing wrong EV Diffs.
     */
    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
        this.countInvoice = 0;
        this.countFeature = 0;
        this.countAll = 0;
    }

    public List<Integer> start(Database.BatchableContext context) {
        Integer totalCount = null;

        try {
            HTTPResponse res = request(1, 0);
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total_count') {
                    parser.nextToken();
                    totalCount = parser.getIntegerValue();
                    break;
                }
            }
        } catch(Exception e) {
            Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
                    EmailHelper.sendEmailFromException(new String[] {'tstalka@soldevelo.com'}, 'Commcare sync status line items ERROR', 'ERROR : ', e);
            System.debug('Error : ' + e);
        }

        if (totalCount == null) {
            return new List<Integer>();
        }

        List<Integer> listOffset = new List<Integer>();
        for(Integer i = 0; i <= totalCount / 30; i++) {
          listOffset.add(i * 30);
        }
        if(Test.isRunningTest()) {
            listOffset = new List<Integer>{0};
        }

        return listOffset;
    }

    public void execute(Database.BatchableContext context, List<Integer> scope) {
        String jsonString = request(30, scope.get(0)).getBody();

        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_LineItem obj;
        List<hqInt_ModelClass.Accounting_LineItem> listModelObj = new List <hqInt_ModelClass.Accounting_LineItem>();
        List<Accounting_LineItems__c> listSobject = new List <Accounting_LineItems__c>();
        Set<String> parentInvoiceObjectIdSet = new Set<String>();
        Set<String> parentFeatureObjectIdSet = new Set<String>();
        Set<String> ids = new Set<String>();

        while (parser.nextToken() != null)  {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                        obj = (hqInt_ModelClass.Accounting_LineItem)parser.readValueAs(hqInt_ModelClass.Accounting_LineItem.class);
                        if(obj.invoice != null) {
                            parentInvoiceObjectIdSet.add(obj.invoice);
                        }
                        if(obj.feature_rate != null) {
                            parentFeatureObjectIdSet.add(obj.feature_rate);
                        }
                        listModelObj.add(obj);
                        ids.add(obj.id);
                        parser.skipChildren();
                    }
                }
            }
        }

        this.countInvoice += parentInvoiceObjectIdSet.size();
        this.countFeature += parentFeatureObjectIdSet.size();
        this.countAll += listModelObj.size();
    }

    public HTTPResponse request(Integer size, Integer offset) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(generateEndPointUrl(offset, 'https://www.commcarehq.org/hq/admin/api/global/accounting_line_items/', size, '2018-08-01'));
        req.setMethod('GET');

        String username = 'lwyszomirski@soldevelo.com';
        String password = 'S0ldevelo2SF';

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        Http http = new Http();
        System.debug('Endpoint: ' + req.getEndpoint());
        HTTPResponse res = http.send(req);
        System.debug('--- status --' + res.getStatusCode());
        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('Http request error, cannot fetch Accounting data. Http status : ' + res.getStatusCode() + ' Body : ' + res.getBody());
            throw e;
        }

        return res;
    }

    private String generateEndPointUrl(Integer offsetParam, String objectUrl, Integer limitParam, String dateModifiedParam) {
        return objectUrl + '?format=json&offset='+String.valueOf(OffsetParam)
                    + '&limit=' + String.valueOf(limitParam) + '&last_modified__gte=' + dateModifiedParam;
    }

    public void finish(Database.BatchableContext context) {
        EmailHelper.sendEmail(new String[] {'tstalka@soldevelo.com'}, 'Commcare sync status line items', 'Cannot fetch total count for Accountings : countInvoice - ' + this.countInvoice + ' countFeature - '
            + this.countFeature + ' countAll - ' + this.countAll);
    }
}