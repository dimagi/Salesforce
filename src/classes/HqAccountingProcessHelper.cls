/**
 * Helper used to call Http request and process Accounting JSON.
 */
public class HqAccountingProcessHelper {

    private CommcareToSalesforceSettings__c serverSettings;
    private Integer limitParameter;
    private String endPoint;
    private String lastRunDate;
    private String suffix;
    private String serverNameId;

    public HqAccountingProcessHelper(CommcareToSalesforceSettings__c serverSettings, String suffix) {
        this.serverSettings = serverSettings;
        this.limitParameter = this.serverSettings.API_Limit_Parameter__c != null ? Integer.valueOf(serverSettings.API_Limit_Parameter__c)
                                : 10;
        this.suffix = suffix;
        this.endPoint = this.serverSettings.Server_URL__c + suffix;
        this.lastRunDate = this.serverSettings.Last_Run_Date__c != null ?  this.serverSettings.Last_Run_Date__c.year() + '-' + this.serverSettings.Last_Run_Date__c.month() + '-'
                                                    + this.serverSettings.Last_Run_Date__c.day() : '1990-1-1';
        this.serverNameId = this.serverSettings.Name.replaceAll(' ', '-');
    }

    /**
     * Returns total Accounting number from HQ server.
     */
    public Integer getTotalCount() {
        Integer totalCount = 0;

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
            EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'Commcare sync Error', 'Cannot fetch total count for Accountings : '
                                                + this.serverSettings.Name + ' ' + this.suffix, e);
            HqBatchJobHelper.endDomainJob();
            throw e;
        }

        return totalCount;
    }

    /**
     * Fetchs data from HQ and saves in DB.
     */
    public Integer processAccounting(Integer offset) {
        HTTPResponse res = request(offset);
        String response = res.getBody(); 
        return processJson(response);
    }

    public HTTPResponse request(Integer offset) {
        return request(this.limitParameter, offset);
    }

    private HTTPResponse request(Integer size, Integer offset) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(generateEndPointUrl(offset, this.endPoint, size, this.lastRunDate));
        req.setMethod('GET');

        String username = this.serverSettings.CommCare_User_Name__c;
        String password = this.serverSettings.CommCare_Password__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('--- status --' + res.getStatusCode());
        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('Http request error, cannot fetch Accounting data. Http status : ' + res.getStatusCode() + ' Body : ' + res.getBody());
            throw e;
        }

        return res;
    }

    private Integer processJson(String jsonString) {
        if (this.suffix.endsWith('software_product_rate/')) {
            return processSoftwareProductRate(jsonString);
        } else if(this.suffix.endsWith('software_plan/')) {
            return processSoftwarePlan(jsonString);
        } else if(this.suffix.endsWith('software_plan_versions/')) {
            return processSoftwarePlanVersion(jsonString);
        } else if(this.suffix.endsWith('billing_account/')) {
            return processBillingAccount(jsonString);
        } else if(this.suffix.endsWith('subscription/')) {
            return processSubscription(jsonString);
        } else if(this.suffix.endsWith('invoice/')) {
            return processInvoice(jsonString);
        } else if(this.suffix.endsWith('subscriber/')) {
            return processSubscriber(jsonString);
        } else if(this.suffix.endsWith('accounting_features/')) {
            return processFeature(jsonString);
        } else if(this.suffix.endsWith('accounting_feature_rates/')) {
            return processFeatureRate(jsonString);
        } else if(this.suffix.endsWith('billing_contact_info/')) {
            return processBillingContactInfo(jsonString);
        } else if(this.suffix.endsWith('accounting_line_items/')) {
            return processLineItem(jsonString);
        } else if(this.suffix.endsWith('accounting_payment_method/')) {
            return processPaymentMethod(jsonString);
        } else if(this.suffix.endsWith('payment_record/')) {
            return processPaymentRecord(jsonString);
        } else if(this.suffix.endsWith('billing_account_admin/')) {
            return processBillingAccountAdmin(jsonString);
        } else if(this.suffix.endsWith('subscription_and_adjustment/')) {
            return processSubscriptionAdjustment(jsonString);
        } else if(this.suffix.endsWith('credit_line/')) {
            return processCreditLine(jsonString);
        } else if(this.suffix.endsWith('credit_adjustment/')) {
            return processCreditAdjustment(jsonString);
        }

        return 0;
    }

    private String replaceReservedWords(String myString) {
       myString = myString.replaceAll('"_id"\\s*:', '"x_id":');
       myString = myString.replaceAll('"public"\\s*:', '"x_Public":');
       myString = myString.replaceAll('"date"\\s*:', '"x_date":');
       return myString;
    }

    private String generateEndPointUrl(Integer offsetParam, String objectUrl, Integer limitParam, String dateModifiedParam) {
        return objectUrl + '?format=json&offset='+String.valueOf(OffsetParam)
                    + '&limit=' + String.valueOf(limitParam) + '&last_modified__gte=' + dateModifiedParam;
    }

    private Integer processSoftwareProductRate(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        List<Accounting_SoftwareProductRate__c> softwareProductRateList = new List<Accounting_SoftwareProductRate__c>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {

                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        hqInt_ModelClass.Accounting_SoftwareProductRate softwareProductRate = (hqInt_ModelClass.Accounting_SoftwareProductRate) parser.readValueAs(hqInt_ModelClass.Accounting_SoftwareProductRate.class);
                        System.debug('--softwareProductRate--' + softwareProductRate);

                        softwareProductRateList.add(softwareProductRate.createDbObject(this.serverSettings.Name));
                        parser.skipChildren();
                    }
                }
            }
        }

        upsert softwareProductRateList id__c;
        return softwareProductRateList.size();
    }

    private Integer processSoftwarePlan(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_SoftwarePlan obj;
        List<hqInt_ModelClass.Accounting_SoftwarePlan> listModelSoftwarePlan = new List<hqInt_ModelClass.Accounting_SoftwarePlan>();
        List<Accounting_Softwareplan__c> listSobjectSoftwarePlan = new List<Accounting_Softwareplan__c>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---'+ parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_SoftwarePlan)parser.readValueAs(hqInt_ModelClass.Accounting_SoftwarePlan.class);
                        listModelSoftwarePlan.add(obj);
                        parser.skipChildren();
                    }
                }
            }
        }

        for (hqInt_ModelClass.Accounting_SoftwarePlan softwarePlan : listModelSoftwarePlan) {
            Accounting_Softwareplan__c softwarePlanC = softwarePlan.createDbObject(this.serverSettings.Name);
            listSobjectSoftwarePlan.add(softwarePlanC);
        }

        upsert listSobjectSoftwarePlan id__c;
        return listSobjectSoftwarePlan.size();
    }

    private Integer processSoftwarePlanVersion(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_SoftwarePlanVersion obj;
        List<hqInt_ModelClass.Accounting_SoftwarePlanVersion> listModelObj = new List<hqInt_ModelClass.Accounting_SoftwarePlanVersion>();
        List<Accounting_SoftwarePlanVersion__c> listSobject = new List<Accounting_SoftwarePlanVersion__c>();
        Set<String> planIdSet = new Set<String>();
        Set<String> productRateIdSet = new Set<String>();
        

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText--' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_SoftwarePlanVersion)parser.readValueAs(hqInt_ModelClass.Accounting_SoftwarePlanVersion.class);
                        listModelObj.add(obj);

                        if (obj.plan != null) {
                            planIdSet.add(obj.plan + this.serverNameId);
                        }
                        if (obj.product_rates != null && obj.product_rates.size() > 0) {
                            productRateIdSet.add(obj.product_rates[0] + this.serverNameId);
                        }
                        parser.skipChildren();
                    }
                }
            }
        }

        Map<String, Id> mapJsonIdToSfId = new Map<String, Id>();
        for (Accounting_Softwareplan__c softwarePlan : [SELECT Id, id__c FROM Accounting_Softwareplan__c WHERE id__c in :planIdSet]) {
            mapJsonIdToSfId.put(softwarePlan.id__c, softwarePlan.Id);
        }

        Map<String, Id> mapProductRate = new Map<String, Id>();
        for (Accounting_SoftwareProductRate__c productRate : [Select Id, id__c From Accounting_SoftwareProductRate__c Where id__c in :productRateIdSet]) {
            mapProductRate.put(productRate.id__c, productRate.Id);
        }

        for (hqInt_ModelClass.Accounting_SoftwarePlanVersion softwarePlanVersion : listModelObj) {
            Id planid;
            if (mapJsonIdToSfId.containsKey(softwarePlanVersion.plan + this.serverNameId)) {
                planid = mapJsonIdToSfId.get(softwarePlanVersion.plan + this.serverNameId);
            }

            Id productaRateId;
            if (softwarePlanVersion.product_rates != null && softwarePlanVersion.product_rates.size() > 0
                    && mapProductRate.containsKey(softwarePlanVersion.product_rates[0] + this.serverNameId)) {
                productaRateId = mapProductRate.get(softwarePlanVersion.product_rates[0] + this.serverNameId);
            }

            Accounting_SoftwarePlanVersion__c sobj = softwarePlanVersion.createDbObject(planid, productaRateId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processBillingAccount(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_BillingAccount obj;
        List<hqInt_ModelClass.Accounting_BillingAccount> listModelObj = new List<hqInt_ModelClass.Accounting_BillingAccount>();
        List<Accounting_Billingaccount__c> listSobject = new List<Accounting_Billingaccount__c>();
        Set<String> planIdSet = new Set<String>();
        Set<String> setAccountId = new Set<String>();
        Map<String, String> mapAccJsonIdToContactSfId = new Map<String, String>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText--' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_BillingAccount)parser.readValueAs(hqInt_ModelClass.Accounting_BillingAccount.class);
                        setAccountId.add(obj.Id + this.serverNameId);
                        listModelObj.add(obj);
                        parser.skipChildren();
                    }
                }
            }
        }

        System.debug('--setAccountId--' + setAccountId);
        for (Accounting_BillingContactInfo__c billingContact : [SELECT Id, accountid__c FROM Accounting_BillingContactInfo__c WHERE accountid__c in :setAccountId]) {
            mapAccJsonIdToContactSfId.put(billingContact.accountid__c, billingContact.Id);
        }

        for (hqInt_ModelClass.Accounting_BillingAccount billingAccount : listModelObj) {
            Id billingContactId;
            if (mapAccJsonIdToContactSfId.containsKey(billingAccount.id + this.serverNameId)) {
                billingContactId = mapAccJsonIdToContactSfId.get(billingAccount.id + this.serverNameId);
            }

            Accounting_Billingaccount__c sobj = billingAccount.createDbObject(billingContactId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processSubscription(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_Subscription obj;
        List<hqInt_ModelClass.Accounting_Subscription> listModelObj = new List<hqInt_ModelClass.Accounting_Subscription>();
        List<Accounting_Subscription__c> listSobject = new List<Accounting_Subscription__c>();
        Set<String> parentObjectAccountIdSet = new Set<String>(); //PARENT=Account
        Set<String> parentObjectPlanVerIdSet = new Set<String>(); //PARENT=Plan Version
        Set<String> parentObjectSubscriberIdSet = new Set<String>(); //PARENT=Subscriber

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText--' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                        obj = (hqInt_ModelClass.Accounting_Subscription)parser.readValueAs(hqInt_ModelClass.Accounting_Subscription.class);
                        if (obj.account != null) {
                            parentObjectAccountIdSet.add(obj.account + this.serverNameId);
                        }
                        if (obj.plan_version != null) {
                            parentObjectPlanVerIdSet.add(obj.plan_version + this.serverNameId);
                        }
                        if (obj.subscriber != null) {
                            parentObjectSubscriberIdSet.add(obj.subscriber + this.serverNameId);
                        }

                        listModelObj.add(obj);
                        parser.skipChildren();
                    }
                }
            }
        }

        Map<String,Id> mapJsonIdToSfIdForAccount = new Map<String,Id>();
        for (Accounting_Billingaccount__c parentObj : [SELECT Id, id__c FROM Accounting_Billingaccount__c WHERE id__c in :parentObjectAccountIdSet]) {
            mapJsonIdToSfIdForAccount.put(parentObj.id__c, parentObj.Id);
        }

        Map <String, Id> mapJsonIdToSfIdForPlanVer = new Map<String, Id>();
        for (Accounting_SoftwarePlanVersion__c parentObj : [SELECT Id, id__c FROM Accounting_SoftwarePlanVersion__c WHERE id__c in :parentObjectPlanVerIdSet]) {
            mapJsonIdToSfIdForPlanVer.put(parentObj.id__c, parentObj.Id);
        }

        Map <String, Accounting_Subscriber__c> mapJsonIdToSfIdForSubscriber = new Map<String, Accounting_Subscriber__c>();
        for (Accounting_Subscriber__c parentObj : [SELECT Id,id__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE id__c in :parentObjectSubscriberIdSet]) {
            mapJsonIdToSfIdForSubscriber.put(parentObj.id__c, parentObj);
        }

        for (hqInt_ModelClass.Accounting_Subscription subscription  : listModelObj) {

            Id parentObjectAccountId;
            Id parentObjectPlanVerId;
            Id parentObjectSubscriberId;
            Id domainId;

            if (mapJsonIdToSfIdForAccount.containsKey(subscription.account + this.serverNameId)) {
                parentObjectAccountId = mapJsonIdToSfIdForAccount.get(subscription.account + this.serverNameId);
            }
            if (mapJsonIdToSfIdForPlanVer.containsKey(subscription.plan_version + this.serverNameId)) {
                parentObjectPlanVerId = mapJsonIdToSfIdForPlanVer.get(subscription.plan_version + this.serverNameId);
            }
            if (mapJsonIdToSfIdForSubscriber.containsKey(subscription.subscriber + this.serverNameId)) {
                parentObjectSubscriberId = mapJsonIdToSfIdForSubscriber.get(subscription.subscriber + this.serverNameId).Id;
                domainId = mapJsonIdToSfIdForSubscriber.get(subscription.subscriber + this.serverNameId).domain_lookup__c;
            }

            Accounting_Subscription__c sobj = subscription.createDbObject(parentObjectAccountId, parentObjectPlanVerId, parentObjectSubscriberId,
                                                                            domainId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processInvoice(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_Invoice obj;
        List <hqInt_ModelClass.Accounting_Invoice> listModelObj = new List <hqInt_ModelClass.Accounting_Invoice>();
        List <Accounting_Invoice__c> listSobject = new List <Accounting_Invoice__c>();
        Set <String> parentObjectIdSet = new Set <String>(); //PARENT=Subscription
        Map <String, Id> mapJsonIdToSfId = new Map <String,Id>();
        Set <String> setFeatureRates = new Set <String>();
        Map <String, String> mapSubscriptionJsonIdToFeatureRatesJsonId = new Map <String, String>();
        Map <String, String> mapFeatureRateJsonIdToSfId = new Map <String, String>();
        List <Accounting_FeatureRateForInvoice__c> listFeatureRateForInvoice = new List <Accounting_FeatureRateForInvoice__c>();

        while (parser.nextToken() != null) {
            // Start at the array of invoices.
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects')  {
                while (parser.nextToken() != null) {
                    System.debug('--getText---'+ parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire invoice object, including its array of line items.
                        obj = (hqInt_ModelClass.Accounting_Invoice) parser.readValueAs(hqInt_ModelClass.Accounting_Invoice.class);
                        if(obj.subscription != null) {
                            parentObjectIdSet.add(obj.subscription + this.serverNameId);
                        }
                        listModelObj.add(obj);
                        parser.skipChildren();

                        System.debug('--invoiceObj--' + obj);
                    }
                }
            }
        }

        Map <String, String> mapASubscriptionJsonIdToDomainId = new Map <String, String>();
        for (Accounting_Subscription__c parentObj : [SELECT Id, Accounting_Subscriber__r.domain_lookup__c, id__c, plan_version__r.FeatureRates__c, account__c
                                                     FROM Accounting_Subscription__c WHERE id__c in :parentObjectIdSet]) {
            mapJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            if (String.isNotBlank(parentObj.plan_version__r.FeatureRates__c)) {
                setFeatureRates.addAll(parentObj.plan_version__r.FeatureRates__c.split(','));
                mapSubscriptionJsonIdToFeatureRatesJsonId.put(parentObj.id__c, parentObj.plan_version__r.FeatureRates__c);
            }
            if (parentObj.Accounting_Subscriber__r.domain_lookup__c != null) {
                mapASubscriptionJsonIdToDomainId.put(parentObj.id__c, parentObj.Accounting_Subscriber__r.domain_lookup__c);
            }
        }

        for(Accounting_Featurerate__c featureRate : [SELECT id, id__c FROM Accounting_Featurerate__c WHERE id__c in :setFeatureRates]) {
            mapFeatureRateJsonIdToSfId.put(featureRate.id__c, featureRate.id);
        }

        System.debug('--mapFeatureRateJsonIdToSfId--'+mapFeatureRateJsonIdToSfId);
        System.debug('--mapFeatureRateJsonIdToSfIdSIZE--'+mapFeatureRateJsonIdToSfId.keyset().size());

        for (hqInt_ModelClass.Accounting_Invoice invoice : listModelObj) {
            Id parentId;
            if(mapJsonIdToSfId.containsKey(invoice.subscription + this.serverNameId)) {
                parentId = mapJsonIdToSfId.get(invoice.subscription + this.serverNameId);
            }

            Id domainId;
            if (mapASubscriptionJsonIdToDomainId.containsKey(invoice.subscription + this.serverNameId)) {
                domainId = mapASubscriptionJsonIdToDomainId.get(invoice.subscription + this.serverNameId);
            }

            Accounting_Invoice__c sobj = invoice.createDbObject(parentId, domainId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;

        //prepare a map of Accid to invid
        Map <String, String> mapAccIdToInvId = new Map <String, String>();
        for(Accounting_Invoice__c invoice : [SELECT id ,Accounting_Subscription__r.account__c FROM Accounting_Invoice__c WHERE Id in : listSobject
                                             AND Accounting_Subscription__r.account__c != null]) {
            mapAccIdToInvId.put(invoice.Accounting_Subscription__r.account__c, invoice.Id);
        }

        //using the above map of Accid to invid, preapre a map of invid to paymentrecid.
        Map <String, List<String>> mapInvIdToPymntRecIdList = new Map <String, List<String>>();
        for (Accounting_Paymentrecord__c paymentRec : [SELECT id, payment_method__r.account__c FROM Accounting_Paymentrecord__c
                                                       WHERE payment_method__r.account__c in :mapAccIdToInvId.keySet() ]) {
            if (mapAccIdToInvId.containsKey(paymentRec.payment_method__r.account__c)) {
                Id invId = mapAccIdToInvId.get(paymentRec.payment_method__r.account__c);
                if (mapInvIdToPymntRecIdList.containsKey(invId)) {
                    mapInvIdToPymntRecIdList.get(invId).add(paymentRec.id);
                } else {
                    List <String> paymentRecIdList = new List <String> {paymentRec.id};
                    mapInvIdToPymntRecIdList.put(invId, paymentRecIdList);
                }
            }
        }

        List <Accounting_PaymentsForInvoice__c> listPymtForInvoice = new List<Accounting_PaymentsForInvoice__c>();
        for (Integer i = 0; i < listSobject.size(); i++) {
            if (mapSubscriptionJsonIdToFeatureRatesJsonId.containsKey(listModelObj[i].subscription)) {
                for (String featureRateJsonId : mapSubscriptionJsonIdToFeatureRatesJsonId.get(listModelObj[i].subscription).split(',')) {

                    if (mapFeatureRateJsonIdToSfId.containsKey(featureRateJsonId)) {
                        Accounting_FeatureRateForInvoice__c featureRateForInvoice = new Accounting_FeatureRateForInvoice__c();
                        featureRateForInvoice.FeatureRate__c = mapFeatureRateJsonIdToSfId.get(featureRateJsonId);
                        featureRateForInvoice.Invoice__c = listSobject[i].id;

                        listFeatureRateForInvoice.add(featureRateForInvoice);
                    }
                }
            }

            //Prepare the list of PaymentForInvioce junction object
            if (mapInvIdToPymntRecIdList.containsKey(listSobject[i].id)) {
                for (String pymtRecId : mapInvIdToPymntRecIdList.get(listSobject[i].id)) {
                    Accounting_PaymentsForInvoice__c pymtForInvoice = new Accounting_PaymentsForInvoice__c();
                    pymtForInvoice.Invoice__c = listSobject[i].id;
                    pymtForInvoice.PaymentRec__c = pymtRecId;
                    listPymtForInvoice.add(pymtForInvoice);
                }
            }
        }

        delete [SELECT id FROM Accounting_FeatureRateForInvoice__c WHERE Invoice__c in :listSobject];
        insert listFeatureRateForInvoice;

        System.debug('--listFeatureRateForInvoice--'+listFeatureRateForInvoice);
        System.debug('--listFeatureRateForInvoiceSIZE--'+listFeatureRateForInvoice.size());

        delete [SELECT id FROM Accounting_PaymentsForInvoice__c WHERE Invoice__c in :listSobject];
        insert listPymtForInvoice;

        System.debug('--listPymtForInvoice--'+listPymtForInvoice);
        System.debug('--listPymtForInvoiceSIZE--'+listPymtForInvoice.size());

        return listSobject.size();
    }

    private Integer processSubscriber(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_Subscriber obj;
        List <hqInt_ModelClass.Accounting_Subscriber> listModelObj = new List <hqInt_ModelClass.Accounting_Subscriber>();
        List <Accounting_Subscriber__c> listSobject = new List <Accounting_Subscriber__c>();
        Set <String> parentObjectIdSet = new Set <String>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {

                    System.debug('--getText---' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_Subscriber)parser.readValueAs(hqInt_ModelClass.Accounting_Subscriber.class);
                        if(obj.domain != null) {
                            parentObjectIdSet.add(obj.domain);
                        }
                        listModelObj.add(obj);
                        parser.skipChildren();
                    }
                }
            }
        }

        System.debug('--domainnames--'+parentObjectIdSet);
        Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();

        for (Domain__c parentObj : [SELECT Id, Name FROM Domain__c WHERE Name in :parentObjectIdSet AND Server_Name__c =: this.serverSettings.Name]) {
            mapJsonIdToSfId.put(parentObj.Name, parentObj.Id);
        }

        System.debug('--map of json id to sf id---' + mapJsonIdToSfId);
        for (hqInt_ModelClass.Accounting_Subscriber subscriber : listModelObj) {
            Id parentId;
            if(mapJsonIdToSfId.containsKey(subscriber.domain)) {
                parentId = mapJsonIdToSfId.get(subscriber.domain);
            }
            System.debug('--parentid--' + parentid);
            Accounting_Subscriber__c sobj = subscriber.createDbObject(parentId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processFeature(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_Feature obj;
        List <accounting_feature__c> listSobject = new List<accounting_feature__c>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---'+ parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_Feature)parser.readValueAs(hqInt_ModelClass.Accounting_Feature.class);
                        listSobject.add(obj.createDbObject(this.serverSettings.Name));
                        parser.skipChildren();
                    }
                }
            }
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processFeatureRate(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_FeatureRate obj;
        List <hqInt_ModelClass.Accounting_FeatureRate> listModelObj = new List <hqInt_ModelClass.Accounting_FeatureRate>();
        List <Accounting_Featurerate__c> listSobject = new List <Accounting_Featurerate__c>();
        Set <String> parentObjectIdSet = new Set <String>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    system.debug('--getText---' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_FeatureRate)parser.readValueAs(hqInt_ModelClass.Accounting_FeatureRate.class);
                        if(obj.feature != null) {
                            parentObjectIdSet.add(obj.feature + this.serverNameId);
                        }

                        listModelObj.add(obj);
                        parser.skipChildren();

                        System.debug('--newobj---' + obj);
                    }
                }
            }
        }

        Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
        for (accounting_feature__c parentObj : [SELECT Id, id__c FROM accounting_feature__c WHERE id__c in :parentObjectIdSet]) {
            mapJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }

        for (hqInt_ModelClass.Accounting_FeatureRate featureRate : listModelObj) {
            Id parentId;
            if(mapJsonIdToSfId.containsKey(featureRate.feature + this.serverNameId)) {
                parentId = mapJsonIdToSfId.get(featureRate.feature + this.serverNameId);
            }
            Accounting_Featurerate__c sobj = featureRate.createDbObject(parentId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processBillingContactInfo(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_BillingContactInfo obj;
        List <Accounting_BillingContactInfo__c> listSobject = new List <Accounting_BillingContactInfo__c>();

        while (parser.nextToken() != null)  {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---'+ parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        obj = (hqInt_ModelClass.Accounting_BillingContactInfo) parser.readValueAs(hqInt_ModelClass.Accounting_BillingContactInfo.class);
                        listSobject.add(obj.createDbObject(this.serverSettings.Name));
                    }
                }
            }
        }

        upsert listSobject accountid__c;
        return listSobject.size();
    }

    private Integer processLineItem(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_LineItem obj;
        List <hqInt_ModelClass.Accounting_LineItem> listModelObj = new List <hqInt_ModelClass.Accounting_LineItem>();
        List <Accounting_LineItems__c> listSobject = new List <Accounting_LineItems__c>();
        Set <String> parentInvoiceObjectIdSet = new Set <String>();
        Set <String> parentFeatureObjectIdSet = new Set <String>();

        while (parser.nextToken() != null)  {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                        obj = (hqInt_ModelClass.Accounting_LineItem)parser.readValueAs(hqInt_ModelClass.Accounting_LineItem.class);
                        if(obj.invoice != null) {
                            parentInvoiceObjectIdSet.add(obj.invoice + this.serverNameId);
                        }
                        if(obj.feature_rate != null) {
                            parentFeatureObjectIdSet.add(obj.feature_rate + this.serverNameId);
                        }
                        listModelObj.add(obj);
                        parser.skipChildren();
                    }
                }
            }
        }

        Map <String, Id> mapInvoiceJsonIdToSfId = new Map <String, Id>();
        for (Accounting_Invoice__c parentObj : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c in :parentInvoiceObjectIdSet]) {
            mapInvoiceJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        Map <String, Id> mapFeatureRateJsonIdToSfId = new Map <String, Id>();
        for (Accounting_Featurerate__c parentObj : [SELECT Id, id__c FROM Accounting_Featurerate__c WHERE id__c in :parentFeatureObjectIdSet]) {
            mapFeatureRateJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        for (hqInt_ModelClass.Accounting_LineItem lineItem : listModelObj) {
            Id parentInvoiceSfId;
            Id parentFeatureRateSfId;
            if(mapInvoiceJsonIdToSfId.containsKey(lineItem.invoice + this.serverNameId)) {
                parentInvoiceSfId = mapInvoiceJsonIdToSfId.get(lineItem.invoice + this.serverNameId);
            }
            if(mapFeatureRateJsonIdToSfId.containsKey(lineItem.feature_rate + this.serverNameId)) {
                parentFeatureRateSfId = mapFeatureRateJsonIdToSfId.get(lineItem.feature_rate + this.serverNameId);
            }
            if(parentInvoiceSfId != null) {
                Accounting_LineItems__c sobj = lineItem.createDbObject(parentInvoiceSfId, parentFeatureRateSfId, this.serverSettings.Name);
                listSobject.add(sobj);
            }
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processPaymentMethod(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        hqInt_ModelClass.Accounting_PaymentMethod obj;
        List <hqInt_ModelClass.Accounting_PaymentMethod> listModelObj = new List <hqInt_ModelClass.Accounting_PaymentMethod>();
        List <Accounting_PaymentMethod__c> listSobject = new List <Accounting_PaymentMethod__c>();
        Set <String> parentBillingAccJsonIdSet = new Set <String>();
        Set <String> parentBillingAccAdminJsonIdSet = new Set <String>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                while (parser.nextToken() != null) {
                    System.debug('--getText---' + parser.getText());
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                        obj = (hqInt_ModelClass.Accounting_PaymentMethod)parser.readValueAs(hqInt_ModelClass.Accounting_PaymentMethod.class);
                        if(obj.account != null) {
                            parentBillingAccJsonIdSet.add(obj.account + this.serverNameId);
                        }
                        if(obj.billing_admin != null) {
                            parentBillingAccAdminJsonIdSet.add(obj.billing_admin + this.serverNameId);
                        }
                        listModelObj.add(obj);
                        parser.skipChildren();
                        System.debug('--newobj---' + obj);
                    }
                }
            }
        }

        Map <String, Id> mapBillingAccJsonIdToSfId = new Map <String, Id>();
        for (Accounting_BillingAccount__c parentObj : [SELECT Id, id__c FROM Accounting_BillingAccount__c WHERE id__c in :parentBillingAccJsonIdSet]) {
            mapBillingAccJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }

        Map <String, Id> mapBillingAccAdminJsonIdToSfId = new Map <String, Id>();
        for (Accounting_BillingAccountAdmin__c parentObj : [SELECT Id,id__c FROM Accounting_BillingAccountAdmin__c WHERE id__c in :parentBillingAccAdminJsonIdSet]) {
            mapBillingAccAdminJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
 
        for (hqInt_ModelClass.Accounting_PaymentMethod paymentMethod : listModelObj) {
            Id parentBillingAccSfId;
            Id parentBillingAccAdminSfId;

            if(mapBillingAccJsonIdToSfId.containsKey(paymentMethod.account + this.serverNameId)) {
                parentBillingAccSfId = mapBillingAccJsonIdToSfId.get(paymentMethod.account + this.serverNameId);
            }
            if(mapBillingAccAdminJsonIdToSfId.containsKey(paymentMethod.billing_admin + this.serverNameId)) {
                parentBillingAccAdminSfId = mapBillingAccAdminJsonIdToSfId.get(paymentMethod.billing_admin + this.serverNameId);
            }
            Accounting_PaymentMethod__c sobj = paymentMethod.createDbObject(parentBillingAccSfId, parentBillingAccAdminSfId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processPaymentRecord(String jsonString) {
        List <hqInt_ModelClass.Accounting_PaymentRecord> listModelObj = new List <hqInt_ModelClass.Accounting_PaymentRecord>();
        List <Accounting_Paymentrecord__c> listSobject = new List <Accounting_Paymentrecord__c>();
        Set <String> setParentObjectJsonId = new Set <String>();

        hqInt_ModelClass.WRP_Accounting_PaymentRecord obj = (hqInt_ModelClass.WRP_Accounting_PaymentRecord) JSON.deserialize(jsonString, hqInt_ModelClass.WRP_Accounting_PaymentRecord.class);
        listModelObj = obj.objects;

        for (hqInt_ModelClass.Accounting_PaymentRecord paymentRecord : listModelObj) {
            if(paymentRecord.payment_method != null) {
                setParentObjectJsonId.add(paymentRecord.payment_method + this.serverNameId);
            }
        }

        Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
        for (Accounting_PaymentMethod__c parentObj : [SELECT Id, id__c FROM Accounting_PaymentMethod__c WHERE id__c in :setParentObjectJsonId]) {
            mapJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        for (hqInt_ModelClass.Accounting_PaymentRecord paymentRecord : listModelObj) {
            Id parentId;
            if(mapJsonIdToSfId.containsKey(paymentRecord.payment_method + this.serverNameId)) {
                parentId = mapJsonIdToSfId.get(paymentRecord.payment_method + this.serverNameId);
            }
            Accounting_Paymentrecord__c sobj = paymentRecord.createDbObject(parentId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processBillingAccountAdmin(String jsonString) {
        List <hqInt_ModelClass.Accounting_BillingAccountAdmin> listModelObj = new List <hqInt_ModelClass.Accounting_BillingAccountAdmin>();
        List <Accounting_BillingAccountAdmin__c> listSobject = new List <Accounting_BillingAccountAdmin__c>();

        hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin obj = (hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin) JSON.deserialize(jsonString, hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin.class);
        listModelObj = obj.objects;

        for (hqInt_ModelClass.Accounting_BillingAccountAdmin billingAccountAdmin : listModelObj) {
            Accounting_BillingAccountAdmin__c sobj = billingAccountAdmin.createDbObject(this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processSubscriptionAdjustment(String jsonString) {
        List <hqInt_ModelClass.Accounting_SubscriptionAdjustment> listModelObj = new List <hqInt_ModelClass.Accounting_SubscriptionAdjustment>();
        List <Accounting_SubscriptionAdjustment__c> listSobject = new List <Accounting_SubscriptionAdjustment__c>();
        Set <String> setParentObjectJsonId = new Set <String>();

        hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment obj = (hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment.class);
        listModelObj = obj.objects;

        for (hqInt_ModelClass.Accounting_SubscriptionAdjustment subscriptionAdjustment : listModelObj) {
            if(subscriptionAdjustment.subscription != null) {
                setParentObjectJsonId.add(subscriptionAdjustment.subscription + this.serverNameId);
            }
        }

        Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
        for (Accounting_Subscription__c parentObj : [Select Id, id__c From Accounting_Subscription__c Where id__c in :setParentObjectJsonId]) {
            mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
        }

        for (hqInt_ModelClass.Accounting_SubscriptionAdjustment subscriptionAdjustment : listModelObj) {
            Id parentid;
            if(subscriptionAdjustment.subscription != null) {
                parentid = mapJsonIdToSfId.get(subscriptionAdjustment.subscription + this.serverNameId);
            }
            Accounting_SubscriptionAdjustment__c sobj = subscriptionAdjustment.createDbObject(parentid, this.serverSettings.Name);

            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processCreditLine(String jsonString) {
        List <hqInt_ModelClass.Accounting_CreditLine> listModelObj = new List <hqInt_ModelClass.Accounting_CreditLine>();
        List <Accounting_CreditLine__c> listSobject = new List <Accounting_CreditLine__c>();
        Set <String> setParentSubscriptionJsonId = new Set <String>();
        Set <String> setParentAccountJsonId = new Set <String>();

        hqInt_ModelClass.WRP_Accounting_CreditLine obj = (hqInt_ModelClass.WRP_Accounting_CreditLine)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_CreditLine.class);
        listModelObj = obj.objects;

        for (hqInt_ModelClass.Accounting_CreditLine creditLine : listModelObj) {
            if(creditLine.subscription != null) {
                setParentSubscriptionJsonId.add(creditLine.subscription + this.serverNameId);
            }
            if(creditLine.account != null) {
                setParentAccountJsonId.add(creditLine.account + this.serverNameId);
            }
        }

        Map <String,Id> mapSubscriptionJsonIdToSfId = new Map <String,Id>();
        for (Accounting_Subscription__c parentObj : [Select Id, id__c From Accounting_Subscription__c Where id__c in :setParentSubscriptionJsonId]) {
            mapSubscriptionJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
        }
        Map <String, Id> mapAccountJsonIdToSfId = new Map <String, Id>();
        for (Accounting_BillingAccount__c parentObj : [Select Id,id__c From Accounting_BillingAccount__c Where id__c in :setParentAccountJsonId]) {
            mapAccountJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
        }

        for (hqInt_ModelClass.Accounting_CreditLine creditLine : listModelObj) {
            Id parentSubscriptionSfId;
            if(creditLine.subscription != null && mapSubscriptionJsonIdToSfId.containsKey(creditLine.subscription + this.serverNameId)) {
                parentSubscriptionSfId =  mapSubscriptionJsonIdToSfId.get(creditLine.subscription + this.serverNameId);
            }
            Id parentAccountSfId;
            if(creditLine.account != null && mapAccountJsonIdToSfId.containsKey(creditLine.account + this.serverNameId)) {
                parentAccountSfId =  mapAccountJsonIdToSfId.get(creditLine.account + this.serverNameId);
            }

            Accounting_CreditLine__c sobj = creditLine.createDbObject(parentAccountSfId, parentSubscriptionSfId, this.serverSettings.Name);
            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

    private Integer processCreditAdjustment(String jsonString) {
        List <hqInt_ModelClass.Accounting_CreditAdjustment> listModelObj = new List<hqInt_ModelClass.Accounting_CreditAdjustment>();
        List <Accounting_CreditAdjustment__c> listSobject = new List<Accounting_CreditAdjustment__c>();
        Map <String, String> mapCreditLineJsonIdToSfId = new Map<String, String>();
        Map <String, String> mapLineItemJsonIdToSfId = new Map<String, String>();
        Map <String, String> mapInvoiceJsonIdToSfId = new Map<String, String>();
        Map <String, String> mapPaymentRecJsonIdToSfId = new Map<String, String>();

        hqInt_ModelClass.WRP_Accounting_CreditAdjustment obj = (hqInt_ModelClass.WRP_Accounting_CreditAdjustment) JSON.deserialize(jsonString, hqInt_ModelClass.WRP_Accounting_CreditAdjustment.class);
        listModelObj = obj.objects;

        for (hqInt_ModelClass.Accounting_CreditAdjustment creditAdjustment : listModelObj) {
            if(creditAdjustment.credit_line != null) {
                mapCreditLineJsonIdToSfId.put(creditAdjustment.credit_line + this.serverNameId, null);
            }
            if(creditAdjustment.line_item != null) {
                mapLineItemJsonIdToSfId.put(creditAdjustment.line_item + this.serverNameId, null);
            }
            if(creditAdjustment.invoice != null) {
                mapInvoiceJsonIdToSfId.put(creditAdjustment.invoice + this.serverNameId, null);
            }
            if(creditAdjustment.payment_record != null) {
                mapPaymentRecJsonIdToSfId.put(creditAdjustment.payment_record + this.serverNameId, null);
            }
            if(creditAdjustment.related_credit != null) {
                mapCreditLineJsonIdToSfId.put(creditAdjustment.related_credit + this.serverNameId, null);
            }
        }

        for (Accounting_CreditLine__c parentObj : [Select Id, id__c From Accounting_CreditLine__c Where id__c in :mapCreditLineJsonIdToSfId.keySet()]) {
            mapCreditLineJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        for (Accounting_LineItems__c parentObj : [Select Id, id__c From Accounting_LineItems__c Where id__c in :mapLineItemJsonIdToSfId.keySet()]) {
            mapLineItemJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        for (Accounting_Invoice__c parentObj : [Select Id, id__c From Accounting_Invoice__c Where id__c in :mapInvoiceJsonIdToSfId.keySet()]) {
            mapInvoiceJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }
        for (Accounting_Paymentrecord__c parentObj : [Select Id, id__c From Accounting_Paymentrecord__c Where id__c in :mapPaymentRecJsonIdToSfId.keySet()]) {
            mapPaymentRecJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
        }

        for (hqInt_ModelClass.Accounting_CreditAdjustment creditAdjustment : listModelObj) {
            Id creditLineSfId;
            Id lineItemSfId;
            Id invoiceSfId;
            Id paymentRecSfId;
            Id relatedCreditLineSfId;

            if(creditAdjustment.credit_line != null && mapCreditLineJsonIdToSfId.containsKey(creditAdjustment.credit_line + this.serverNameId)) {
                creditLineSfId =  mapCreditLineJsonIdToSfId.get(creditAdjustment.credit_line + this.serverNameId);
            }
            if(creditAdjustment.line_item != null && mapLineItemJsonIdToSfId.containsKey(creditAdjustment.line_item + this.serverNameId)) {
                lineItemSfId =  mapLineItemJsonIdToSfId.get(creditAdjustment.line_item + this.serverNameId);
            }
            if(creditAdjustment.invoice != null && mapInvoiceJsonIdToSfId.containsKey(creditAdjustment.invoice + this.serverNameId)) {
                invoiceSfId =  mapInvoiceJsonIdToSfId.get(creditAdjustment.invoice + this.serverNameId);
            }
            if(creditAdjustment.payment_record != null && mapPaymentRecJsonIdToSfId.containsKey(creditAdjustment.payment_record + this.serverNameId)) {
                paymentRecSfId =  mapPaymentRecJsonIdToSfId.get(creditAdjustment.payment_record + this.serverNameId);
            }
            if(creditAdjustment.related_credit != null && mapCreditLineJsonIdToSfId.containsKey(creditAdjustment.related_credit + this.serverNameId)) {
                relatedCreditLineSfId =  mapCreditLineJsonIdToSfId.get(creditAdjustment.related_credit + this.serverNameId);
            }
            Accounting_CreditAdjustment__c sobj = creditAdjustment.createDbObject(creditLineSfId, invoiceSfId, lineItemSfId, paymentRecSfId,
                                                                                    relatedCreditLineSfId, this.serverSettings.Name);

            listSobject.add(sobj);
        }

        upsert listSobject id__c;
        return listSobject.size();
    }

}