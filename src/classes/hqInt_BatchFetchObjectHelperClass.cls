// Class Name : hqInt_BatchFetchObjectHelperClass


//Author : AP
//Test
public class hqInt_BatchFetchObjectHelperClass 
{
    public integer fetchTotalCount(Integer offset, String objectUrl, Integer apiLimitParameter,String dateModifiedParam)
    {
        integer totalCount;
        String endPointUrl = this.generateEndPointUrl(offset,objectUrl,apiLimitParameter,dateModifiedParam);
        HttpRequest req = new HttpRequest();
        system.debug('--endpointurl--'+endPointUrl);
        req.setEndpoint(endPointUrl);
        req.setMethod('GET'); 

        // Specify the required user name and password to access the endpoint 

        // As well as the header and header information 

 
        String username = CommcareToSalesforceSettings__c.getInstance('CommCareUserName').Value__c;
        String password = CommcareToSalesforceSettings__c.getInstance('CommCarePassword').Value__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' +
        EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        // Create a new http object to send the request object 

        // A response object is generated as a result of the request   


        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('---status--'+res.getStatusCode());
        if(res.getStatusCode() != 200)
            throw new CustomException();

        JSONParser parser = JSON.createParser(res.getBody());
        system.debug('--responsebody--');
        while (parser.nextToken() != null) 
        {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'total_count') 
            {
                parser.nextToken();
                totalCount = parser.getIntegerValue();
                break;
            }
        }
        return totalCount;                          
    }

    /**
     * 
     * Method Name : fetchAndInsertRecords  
     * Purpose : 
     * 
     **/
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public integer fetchAndInsertRecords(Integer offset, String objectUrl, Integer apiLimitParameter,String dateModifiedParam)
    {
        String response;
        HTTPResponse res = requestMethod(offset,objectUrl,apiLimitParameter,dateModifiedParam);
        response = res.getBody(); 
        System.debug('---res---'+ response);
        //response = ReplaceReservedWords(response);
        integer successCount = processJson(response,objectUrl); 
        return successCount;
    }


    /**
     * 
     * Method Name : requestMethod  
     * Purpose : Http Callout to CommCareHQ 
     * 
     **/
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public HTTPResponse requestMethod(integer offset,String objectUrl,integer apiLimitParameter,String dateModifiedParam)
    {

        String endPointUrl = this.generateEndPointUrl(offset,objectUrl,apiLimitParameter,dateModifiedParam);
        //format=json;
        system.debug('endpoint---'+endPointUrl);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod('GET');

        // Specify the required user name and password to access the endpoint 

        // As well as the header and header information 


        String username = CommcareToSalesforceSettings__c.getInstance('CommCareUserName').Value__c;
        String password = CommcareToSalesforceSettings__c.getInstance('CommCarePassword').Value__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' +
        EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        // Create a new http object to send the request object 

        // A response object is generated as a result of the request   


        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('---res---'+ res.getBody());
        system.debug('---status--'+res.getStatusCode());
        if(res.getStatusCode() != 200)
            throw new CustomException('Bad Response Status : '+res.getStatusCode());
        return res;
        
    }
    
    /**
     * 
     * Method Name : processJson
     * Purpose : Process Json response and perform DML 
     * 
     **/
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
     /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private integer processJson(String jsonString,String objectUrl)
    {
        
        if(objectUrl.endsWith('software_plan/'))
        {

            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_SoftwarePlan obj;
            list <hqInt_ModelClass.Accounting_SoftwarePlan> listModelSoftwarePlan = new list <hqInt_ModelClass.Accounting_SoftwarePlan>();
            list <Accounting_Softwareplan__c> listSobjectSoftwarePlan = new list <Accounting_Softwareplan__c>();

            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_SoftwarePlan)parser.readValueAs(hqInt_ModelClass.Accounting_SoftwarePlan.class);
                            listModelSoftwarePlan.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
                    
            
            for(hqInt_ModelClass.Accounting_SoftwarePlan obj1 : listModelSoftwarePlan)
            {
                Accounting_Softwareplan__c softwarePlan = obj1.createDbObject();
                listSobjectSoftwarePlan.add(softwarePlan);
            }

            ////////////////////// PERFORM UPSERT OPERATION on DOMAIN Obj /////////////////////////
            
            upsert listSobjectSoftwarePlan id__c;
            

            return listSobjectSoftwarePlan.size();  
        }
        else if(objectUrl.endsWith('software_plan_versions/'))
        {

            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_SoftwarePlanVersion obj;
            list <hqInt_ModelClass.Accounting_SoftwarePlanVersion> listModelObj = new list <hqInt_ModelClass.Accounting_SoftwarePlanVersion>();
            list <Accounting_SoftwarePlanVersion__c> listSobject = new list <Accounting_SoftwarePlanVersion__c>();
            set <String> planIdSet = new set <String>();

            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_SoftwarePlanVersion)parser.readValueAs(hqInt_ModelClass.Accounting_SoftwarePlanVersion.class);
                            listModelObj.add(obj);
                            if(obj.plan != null)
                                planIdSet.add(obj.plan);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();

            for(Accounting_Softwareplan__c softwarePlan : [Select Id,id__c From Accounting_Softwareplan__c Where id__c in :planIdSet])
            {
                mapJsonIdToSfId.put(softwarePlan.id__c,softwarePlan.Id);        
            }

            for(hqInt_ModelClass.Accounting_SoftwarePlanVersion obj1 : listModelObj)
            {
                id planid;
                if(mapJsonIdToSfId.containsKey(obj1.plan))
                    planid = mapJsonIdToSfId.get(obj1.plan);
                Accounting_SoftwarePlanVersion__c sobj = obj1.createDbObject(planid);
                listSobject.add(sobj);
            }

            ////////////////////// PERFORM UPSERT OPERATION on DOMAIN Obj /////////////////////////
            
            upsert listSobject id__c;
            
            
            //Extra Step to update the child object - Feature Rates
            //for(hqInt_ModelClass.Accounting_SoftwarePlanVersion obj1 : listModelObj)
           // {
             //   if(obj1.feature_rates !=null && obj1.feature_rates.size() > 0)
               // {
                    
                //}//
            //}

            return listSobject.size();  
        }
        else if(objectUrl.endsWith('billing_account/'))
        {
            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_BillingAccount obj;
            list <hqInt_ModelClass.Accounting_BillingAccount> listModelObj = new list <hqInt_ModelClass.Accounting_BillingAccount>();
            list <Accounting_Billingaccount__c> listSobject = new list <Accounting_Billingaccount__c>();
            set <String> planIdSet = new set <String>();
            set <String> setAccountId = new set <String>();
            map <String,String> mapAccJsonIdToContactSfId = new map <String,String>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_BillingAccount)parser.readValueAs(hqInt_ModelClass.Accounting_BillingAccount.class);
                            setAccountId.add(obj.id);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            system.debug('--setAccountId---'+setAccountId);
            for(Accounting_BillingContactInfo__c billingContact : [SELECT id,accountid__c FROM Accounting_BillingContactInfo__c WHERE accountid__c in :setAccountId])
            {
                mapAccJsonIdToContactSfId.put(billingContact.accountid__c,billingContact.id);
            }
            system.debug('--mapAccJsonIdToContactSfId---'+mapAccJsonIdToContactSfId);           
            
            
            for(hqInt_ModelClass.Accounting_BillingAccount obj1 : listModelObj)
            {
                id billingContactId;
                if(mapAccJsonIdToContactSfId.containsKey(obj1.id))
                    billingContactId = mapAccJsonIdToContactSfId.get(obj1.id);
                Accounting_Billingaccount__c sobj = obj1.createDbObject(billingContactId);
                listSobject.add(sobj);
            }

            ////////////////////// PERFORM UPSERT OPERATION on DOMAIN Obj /////////////////////////
            
            upsert listSobject id__c;
            

            return listSobject.size();
        }
        else if(objectUrl.endsWith('subscription/'))
        {
            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_Subscription obj;
            list <hqInt_ModelClass.Accounting_Subscription> listModelObj = new list <hqInt_ModelClass.Accounting_Subscription>();
            list <Accounting_Subscription__c> listSobject = new list <Accounting_Subscription__c>();
            set <String> parentObjectAccountIdSet = new set <String>(); //PARENT=Account
            set <String> parentObjectPlanVerIdSet = new set <String>(); //PARENT=Plan Version
            set <String> parentObjectSubscriberIdSet = new set <String>(); //PARENT=Subscriber

            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_Subscription)parser.readValueAs(hqInt_ModelClass.Accounting_Subscription.class);
                            if(obj.account != null)
                                parentObjectAccountIdSet.add(obj.account);
                            if(obj.plan_version != null)
                                parentObjectPlanVerIdSet.add(obj.plan_version);
                            if(obj.subscriber != null)
                                parentObjectSubscriberIdSet.add(obj.subscriber);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }

            map <String,Id> mapJsonIdToSfIdForAccount = new map <String,Id>();

            for(Accounting_Billingaccount__c parentObj : [Select Id,id__c From Accounting_Billingaccount__c Where id__c in :parentObjectAccountIdSet])
            {
                mapJsonIdToSfIdForAccount.put(parentObj.id__c,parentObj.Id);        
            }

            map <String,Id> mapJsonIdToSfIdForPlanVer = new map <String,Id>();

            for(Accounting_SoftwarePlanVersion__c parentObj : [Select Id,id__c From Accounting_SoftwarePlanVersion__c Where id__c in :parentObjectPlanVerIdSet])
            {
                mapJsonIdToSfIdForPlanVer.put(parentObj.id__c,parentObj.Id);        
            }

            map <String,Id> mapJsonIdToSfIdForSubscriber = new map <String,Id>();

            for(Accounting_Subscriber__c parentObj : [Select Id,id__c From Accounting_Subscriber__c Where id__c in :parentObjectSubscriberIdSet])
            {
                mapJsonIdToSfIdForSubscriber.put(parentObj.id__c,parentObj.Id);     
            }

            for(hqInt_ModelClass.Accounting_Subscription obj1 : listModelObj)
            {
                id parentObjectAccountId;
                id parentObjectPlanVerId;
                id parentObjectSubscriberId;
                if(mapJsonIdToSfIdForAccount.containsKey(obj1.account))
                    parentObjectAccountId = mapJsonIdToSfIdForAccount.get(obj1.account);
                if(mapJsonIdToSfIdForPlanVer.containsKey(obj1.plan_version))
                    parentObjectPlanVerId = mapJsonIdToSfIdForPlanVer.get(obj1.plan_version);   
                if(mapJsonIdToSfIdForSubscriber.containsKey(obj1.subscriber))
                    parentObjectSubscriberId = mapJsonIdToSfIdForSubscriber.get(obj1.subscriber);   

                Accounting_Subscription__c sobj = obj1.createDbObject(parentObjectAccountId,parentObjectPlanVerId,parentObjectSubscriberId);
                listSobject.add(sobj);
            }

            ////////////////////// PERFORM UPSERT OPERATION on DOMAIN Obj /////////////////////////
            
            upsert listSobject id__c;
            

            return listSobject.size();
        }
        else if(objectUrl.endsWith('invoice/'))
        {
            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_Invoice obj;
            list <hqInt_ModelClass.Accounting_Invoice> listModelObj = new list <hqInt_ModelClass.Accounting_Invoice>();
            list <Accounting_Invoice__c> listSobject = new list <Accounting_Invoice__c>();
            set <String> parentObjectIdSet = new set <String>(); //PARENT=Subscription
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();
            set <String> setFeatureRates = new set <String>();
            map <String,String> mapSubscriptionJsonIdToFeatureRatesJsonId = new map <String,String>();
            map <String,String> mapFeatureRateJsonIdToSfId = new map <String,String>();
            list <Accounting_FeatureRateForInvoice__c> listFeatureRateForInvoice = new list <Accounting_FeatureRateForInvoice__c>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_Invoice)parser.readValueAs(hqInt_ModelClass.Accounting_Invoice.class);
                            system.debug('--INV.subscription--'+obj.subscription);
                            if(obj.subscription != null)
                                parentObjectIdSet.add(obj.subscription);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            map <String,String> mapASubscriptionJsonIdToDomainId = new map <String,String>(); 
            for(Accounting_Subscription__c parentObj : [Select Id,Accounting_Subscriber__r.domain_lookup__c,id__c,plan_version__r.FeatureRates__c,account__c From Accounting_Subscription__c Where id__c in :parentObjectIdSet])
            {
                mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
                if(String.isNotBlank(parentObj.plan_version__r.FeatureRates__c))
                {
                    setFeatureRates.addAll(parentObj.plan_version__r.FeatureRates__c.split(','));   
                    mapSubscriptionJsonIdToFeatureRatesJsonId.put(parentObj.id__c,parentObj.plan_version__r.FeatureRates__c);
                }
                if(parentObj.Accounting_Subscriber__r.domain_lookup__c != null)
                {
					mapASubscriptionJsonIdToDomainId.put(parentObj.id__c,parentObj.Accounting_Subscriber__r.domain_lookup__c);		            		    	
                }
            }
            
            system.debug('--SetFeatureRates--'+setFeatureRates);
            system.debug('--SetFeatureRatesSIZE--'+setFeatureRates.size());
            system.debug('--mapSubscriptionJsonIdToFeatureRatesJsonId--'+mapSubscriptionJsonIdToFeatureRatesJsonId);
            system.debug('--mapSubscriptionJsonIdToFeatureRatesJsonIdSIZE--'+mapSubscriptionJsonIdToFeatureRatesJsonId.keyset().size());
            
            for(Accounting_Featurerate__c featureRate : [SELECT id,id__c FROM Accounting_Featurerate__c WHERE id__c in :setFeatureRates])
                mapFeatureRateJsonIdToSfId.put(featureRate.id__c,featureRate.id);
            system.debug('--mapFeatureRateJsonIdToSfId--'+mapFeatureRateJsonIdToSfId);
            system.debug('--mapFeatureRateJsonIdToSfIdSIZE--'+mapFeatureRateJsonIdToSfId.keyset().size());
            
            for(hqInt_ModelClass.Accounting_Invoice obj1 : listModelObj)
            {
                id parentId;
                if(mapJsonIdToSfId.containsKey(obj1.subscription))
                {
                    parentId = mapJsonIdToSfId.get(obj1.subscription);
                }
                id domainId;
                if(mapASubscriptionJsonIdToDomainId.containsKey(obj1.subscription))
                {
                	domainId = mapASubscriptionJsonIdToDomainId.get(obj1.subscription); 	
                }
                Accounting_Invoice__c sobj = obj1.createDbObject(parentId,domainId);
                listSobject.add(sobj); 
            }

            ////////////////////// PERFORM UPSERT OPERATION on INVOICE Obj /////////////////////////
            
            upsert listSobject id__c;
            
            //prepare a map of Accid to invid
            map <String,String> mapAccIdToInvId = new map <String,String>();
            for(Accounting_Invoice__c invoice : [SELECT id,Accounting_Subscription__r.account__c FROM Accounting_Invoice__c WHERE id in : listSobject AND Accounting_Subscription__r.account__c != null])
            {
                mapAccIdToInvId.put(invoice.Accounting_Subscription__r.account__c,invoice.id);                  
            }
            
            //using the above map of Accid to invid, preapre a map of invid to paymentrecid.
            map <String,list <String>> mapInvIdToPymntRecIdList = new map <String,list<String>>(); 
            for(Accounting_Paymentrecord__c paymentRec : [SELECT id,payment_method__r.account__c FROM Accounting_Paymentrecord__c WHERE payment_method__r.account__c in :mapAccIdToInvId.keySet() ])
            {
                if(mapAccIdToInvId.containsKey(paymentRec.payment_method__r.account__c))
                {
                    id invId = mapAccIdToInvId.get(paymentRec.payment_method__r.account__c);
                    if(mapInvIdToPymntRecIdList.containsKey(invId))
                    {
                        mapInvIdToPymntRecIdList.get(invId).add(paymentRec.id);
                    }   
                    else
                    {
                        list <String> paymentRecIdList = new list <String>{paymentRec.id};
                        mapInvIdToPymntRecIdList.put(invId,paymentRecIdList);
                    }
                }               
            }
            
            list <Accounting_PaymentsForInvoice__c> listPymtForInvoice = new list <Accounting_PaymentsForInvoice__c>();
            for(integer i=0;i<listSobject.size();i++)
            {
                if(mapSubscriptionJsonIdToFeatureRatesJsonId.containsKey(listModelObj[i].subscription))
                {
                    for(String featureRateJsonId : mapSubscriptionJsonIdToFeatureRatesJsonId.get(listModelObj[i].subscription).split(','))
                    {
                        if(mapFeatureRateJsonIdToSfId.containsKey(featureRateJsonId))
                        {
                            Accounting_FeatureRateForInvoice__c featureRateForInvoice = new Accounting_FeatureRateForInvoice__c();
                            featureRateForInvoice.FeatureRate__c = mapFeatureRateJsonIdToSfId.get(featureRateJsonId);
                            featureRateForInvoice.Invoice__c = listSobject[i].id;
                            listFeatureRateForInvoice.add(featureRateForInvoice);
                        }
                    }
                }
                //Prepare the list of PaymentForInvioce junction object
                if(mapInvIdToPymntRecIdList.containsKey(listSobject[i].id))
                {
                    for(String pymtRecId : mapInvIdToPymntRecIdList.get(listSobject[i].id))
                    {
                        Accounting_PaymentsForInvoice__c pymtForInvoice = new Accounting_PaymentsForInvoice__c();
                        pymtForInvoice.Invoice__c = listSobject[i].id;
                        pymtForInvoice.PaymentRec__c = pymtRecId;
                        listPymtForInvoice.add(pymtForInvoice);     
                    }
                }
            }
            
            delete [SELECT id FROM Accounting_FeatureRateForInvoice__c WHERE Invoice__c in :listSobject];
            insert listFeatureRateForInvoice;
            
            system.debug('--listFeatureRateForInvoice--'+listFeatureRateForInvoice);
            system.debug('--listFeatureRateForInvoiceSIZE--'+listFeatureRateForInvoice.size());
            
            delete [SELECT id FROM Accounting_PaymentsForInvoice__c WHERE Invoice__c in :listSobject];
            insert listPymtForInvoice;
            
            system.debug('--listPymtForInvoice--'+listPymtForInvoice);
            system.debug('--listPymtForInvoiceSIZE--'+listPymtForInvoice.size());
            
            return listSobject.size();
        }
        else if(objectUrl.endsWith('subscriber/')) 
        {
            //Accounting_SoftwarePlan
            //Process Response
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_Subscriber obj;
            list <hqInt_ModelClass.Accounting_Subscriber> listModelObj = new list <hqInt_ModelClass.Accounting_Subscriber>();
            list <Accounting_Subscriber__c> listSobject = new list <Accounting_Subscriber__c>();
            set <String> parentObjectIdSet = new set <String>(); 

            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_Subscriber)parser.readValueAs(hqInt_ModelClass.Accounting_Subscriber.class);
                            if(obj.domain != null)
                                parentObjectIdSet.add(obj.domain);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            system.debug('--domainnames--'+parentObjectIdSet);
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();

            for(Domain__c parentObj : [Select Id,name From Domain__c Where name in :parentObjectIdSet])
            {
                mapJsonIdToSfId.put(parentObj.name,parentObj.Id);      
            }
            system.debug('--map of json id to sf id---'+mapJsonIdToSfId);
            for(hqInt_ModelClass.Accounting_Subscriber obj1 : listModelObj)
            {
                id parentId;
                if(mapJsonIdToSfId.containsKey(obj1.domain))
                    parentId = mapJsonIdToSfId.get(obj1.domain);
                system.debug('--parentid--'+parentid);    
                Accounting_Subscriber__c sobj = obj1.createDbObject(parentId);
                listSobject.add(sobj);
            }
            system.debug('--subscriberobj---'+listSobject[0]);
            ////////////////////// PERFORM UPSERT OPERATION on DOMAIN Obj /////////////////////////
            
            upsert listSobject id__c;
            

            return listSobject.size();
        }
        else if(objectUrl.endsWith('accounting_features/'))
        {
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_Feature obj;
            list <hqInt_ModelClass.Accounting_Feature> listModelObj = new list <hqInt_ModelClass.Accounting_Feature>();
            list <accounting_feature__c> listSobject = new list <accounting_feature__c>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_Feature)parser.readValueAs(hqInt_ModelClass.Accounting_Feature.class);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            for(hqInt_ModelClass.Accounting_Feature obj1 : listModelObj)
            {
                accounting_feature__c sobj = obj1.createDbObject();
                listSobject.add(sobj);
            }
            upsert listSobject id__c;
 
            return listSobject.size();
        }
        else if(objectUrl.endsWith('accounting_feature_rates/'))
        {
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_FeatureRate obj;
            list <hqInt_ModelClass.Accounting_FeatureRate> listModelObj = new list <hqInt_ModelClass.Accounting_FeatureRate>();
            list <Accounting_Featurerate__c> listSobject = new list <Accounting_Featurerate__c>();
            set <String> parentObjectIdSet = new set <String>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_FeatureRate)parser.readValueAs(hqInt_ModelClass.Accounting_FeatureRate.class);
                            if(obj.feature != null)
                                parentObjectIdSet.add(obj.feature);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();
            for(accounting_feature__c parentObj : [Select Id,id__c From accounting_feature__c Where id__c in :parentObjectIdSet])
                mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
            
            for(hqInt_ModelClass.Accounting_FeatureRate obj1 : listModelObj)
            {
                id parentId;
                if(mapJsonIdToSfId.containsKey(obj1.feature))
                    parentId = mapJsonIdToSfId.get(obj1.feature);
                Accounting_Featurerate__c sobj = obj1.createDbObject(parentId);
                listSobject.add(sobj);
            }
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        else if(objectUrl.endsWith('billing_contact_info/'))
        {
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_BillingContactInfo obj;
            list <hqInt_ModelClass.Accounting_BillingContactInfo> listModelObj = new list <hqInt_ModelClass.Accounting_BillingContactInfo>();
            list <Accounting_BillingContactInfo__c> listSobject = new list <Accounting_BillingContactInfo__c>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_BillingContactInfo)parser.readValueAs(hqInt_ModelClass.Accounting_BillingContactInfo.class);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            
            for(hqInt_ModelClass.Accounting_BillingContactInfo obj1 : listModelObj)
            {
                Accounting_BillingContactInfo__c sobj = obj1.createDbObject();
                listSobject.add(sobj);
            }
            
            upsert listSobject accountid__c;
                
            return listSobject.size();
        }
        else if(objectUrl.endsWith('accounting_line_items/'))
        {
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_LineItem obj;
            list <hqInt_ModelClass.Accounting_LineItem> listModelObj = new list <hqInt_ModelClass.Accounting_LineItem>();
            list <Accounting_LineItems__c> listSobject = new list <Accounting_LineItems__c>();
            set <String> parentInvoiceObjectIdSet = new set <String>();
            set <String> parentFeatureObjectIdSet = new set <String>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_LineItem)parser.readValueAs(hqInt_ModelClass.Accounting_LineItem.class);
                            if(obj.invoice != null)
                                parentInvoiceObjectIdSet.add(obj.invoice);
                            if(obj.feature_rate != null)
                                parentFeatureObjectIdSet.add(obj.feature_rate);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            map <String,Id> mapInvoiceJsonIdToSfId = new map <String,Id>();
            for(Accounting_Invoice__c parentObj : [Select Id,id__c From Accounting_Invoice__c Where id__c in :parentInvoiceObjectIdSet])
                mapInvoiceJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
            
            map <String,Id> mapFeatureRateJsonIdToSfId = new map <String,Id>();
            for(Accounting_Featurerate__c parentObj : [Select Id,id__c From Accounting_Featurerate__c Where id__c in :parentFeatureObjectIdSet])
                mapFeatureRateJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
            
            for(hqInt_ModelClass.Accounting_LineItem obj1 : listModelObj)
            {
                id parentInvoiceSfId;
                id parentFeatureRateSfId;
                if(mapInvoiceJsonIdToSfId.containsKey(obj1.invoice))
                    parentInvoiceSfId = mapInvoiceJsonIdToSfId.get(obj1.invoice);
                if(mapFeatureRateJsonIdToSfId.containsKey(obj1.feature_rate))
                    parentFeatureRateSfId = mapFeatureRateJsonIdToSfId.get(obj1.feature_rate);
                if(parentInvoiceSfId != null)
                {
                    Accounting_LineItems__c sobj = obj1.createDbObject(parentInvoiceSfId,parentFeatureRateSfId);
                    listSobject.add(sobj);
                }
            }
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        else if(objectUrl.endsWith('accounting_payment_method/'))
        {
            JSONParser parser = JSON.createParser(jsonString);
            hqInt_ModelClass.Accounting_PaymentMethod obj;
            list <hqInt_ModelClass.Accounting_PaymentMethod> listModelObj = new list <hqInt_ModelClass.Accounting_PaymentMethod>();
            list <Accounting_PaymentMethod__c> listSobject = new list <Accounting_PaymentMethod__c>();
            set <String> parentBillingAccJsonIdSet = new set <String>();
            set <String> parentBillingAccAdminJsonIdSet = new set <String>();
            
            while (parser.nextToken() != null) 
            {
                // Start at the array of invoices.
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') 
                {
                    while (parser.nextToken() != null) 
                    {
                        system.debug('--getText---'+ parser.getText());
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            // Read entire invoice object, including its array of line items.
                            obj = (hqInt_ModelClass.Accounting_PaymentMethod)parser.readValueAs(hqInt_ModelClass.Accounting_PaymentMethod.class);
                            if(obj.account != null)
                                parentBillingAccJsonIdSet.add(obj.account);
                            if(obj.billing_admin != null)
                                parentBillingAccAdminJsonIdSet.add(obj.billing_admin);
                            listModelObj.add(obj);
                            parser.skipChildren();
                            //break;
                            system.debug('--newobj---' + obj);
                        }
                    }
                }
            }
            
            map <String,Id> mapBillingAccJsonIdToSfId = new map <String,Id>();
            for(Accounting_BillingAccount__c parentObj : [Select Id,id__c From Accounting_BillingAccount__c Where id__c in :parentBillingAccJsonIdSet])
                mapBillingAccJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
            
            
            map <String,Id> mapBillingAccAdminJsonIdToSfId = new map <String,Id>();
            for(Accounting_BillingAccountAdmin__c parentObj : [Select Id,id__c From Accounting_BillingAccountAdmin__c Where id__c in :parentBillingAccAdminJsonIdSet])
                mapBillingAccAdminJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            
            for(hqInt_ModelClass.Accounting_PaymentMethod obj1 : listModelObj)
            {
                id parentBillingAccSfId;
                id parentBillingAccAdminSfId;
                
                if(mapBillingAccJsonIdToSfId.containsKey(obj1.account))
                    parentBillingAccSfId = mapBillingAccJsonIdToSfId.get(obj1.account);
                if(mapBillingAccAdminJsonIdToSfId.containsKey(obj1.billing_admin))
                    parentBillingAccAdminSfId = mapBillingAccAdminJsonIdToSfId.get(obj1.billing_admin);
                    
                Accounting_PaymentMethod__c sobj = obj1.createDbObject(parentBillingAccSfId,parentBillingAccAdminSfId);
                listSobject.add(sobj);
            }
            
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        else if(objectUrl.endsWith('payment_record/'))
        {
            list <hqInt_ModelClass.Accounting_PaymentRecord> listModelObj = new list <hqInt_ModelClass.Accounting_PaymentRecord>();
            list <Accounting_Paymentrecord__c> listSobject = new list <Accounting_Paymentrecord__c>();
            set <String> setParentObjectJsonId = new set <String>();
            
            hqInt_ModelClass.WRP_Accounting_PaymentRecord obj = (hqInt_ModelClass.WRP_Accounting_PaymentRecord)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_PaymentRecord.class);
            listModelObj = obj.objects;
            
            for(hqInt_ModelClass.Accounting_PaymentRecord obj1 : listModelObj)
            {
                if(obj1.payment_method != null)
                    setParentObjectJsonId.add(obj1.payment_method);
            }
            
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();
            for(Accounting_PaymentMethod__c parentObj : [Select Id,id__c From Accounting_PaymentMethod__c Where id__c in :setParentObjectJsonId])
                mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);      
            
            for(hqInt_ModelClass.Accounting_PaymentRecord obj1 : listModelObj)
            {
                id parentId;
                if(mapJsonIdToSfId.containsKey(obj1.payment_method))
                    parentId = mapJsonIdToSfId.get(obj1.payment_method);
                Accounting_Paymentrecord__c sobj = obj1.createDbObject(parentId);
                listSobject.add(sobj);
            }
            
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        else if(objectUrl.endsWith('billing_account_admin/'))
        {
            list <hqInt_ModelClass.Accounting_BillingAccountAdmin> listModelObj = new list <hqInt_ModelClass.Accounting_BillingAccountAdmin>();
            list <Accounting_BillingAccountAdmin__c> listSobject = new list <Accounting_BillingAccountAdmin__c>();
            
            hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin obj = (hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_BillingAccountAdmin.class);
            listModelObj = obj.objects;
                        
            for(hqInt_ModelClass.Accounting_BillingAccountAdmin obj1 : listModelObj)
            {
                Accounting_BillingAccountAdmin__c sobj = obj1.createDbObject();
                listSobject.add(sobj);
            }
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        ////////////////////////////////////////////////////////////////////////////////////////////////////
        else if(objectUrl.endsWith('subscription_and_adjustment/'))
        {
            list <hqInt_ModelClass.Accounting_SubscriptionAdjustment> listModelObj = new list <hqInt_ModelClass.Accounting_SubscriptionAdjustment>();
            list <Accounting_SubscriptionAdjustment__c> listSobject = new list <Accounting_SubscriptionAdjustment__c>();
            set <String> setParentObjectJsonId = new set <String>();
            
            hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment obj = (hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_SubscriptionAdjustment.class);
            listModelObj = obj.objects;
            
            for(hqInt_ModelClass.Accounting_SubscriptionAdjustment obj1 : listModelObj)
            {
                if(obj1.subscription != null)
                    setParentObjectJsonId.add(obj1.subscription);
            }
            
            map <String,Id> mapJsonIdToSfId = new map <String,Id>();
            for(Accounting_Subscription__c parentObj : [Select Id,id__c From Accounting_Subscription__c Where id__c in :setParentObjectJsonId])
                mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);     
            
            for(hqInt_ModelClass.Accounting_SubscriptionAdjustment obj1 : listModelObj)
            {
                id parentid;
                if(obj1.subscription != null)
                    parentid =  mapJsonIdToSfId.get(obj1.subscription);

                Accounting_SubscriptionAdjustment__c sobj = obj1.createDbObject(parentid);
                
                listSobject.add(sobj);
            }
            upsert listSobject id__c; 
 
            return listSobject.size();
        }
        ////////////////////////////////////////////////////////////////////////////////////////////////////
        else if(objectUrl.endsWith('credit_line/'))
        {
            list <hqInt_ModelClass.Accounting_CreditLine> listModelObj = new list <hqInt_ModelClass.Accounting_CreditLine>();
            list <Accounting_CreditLine__c> listSobject = new list <Accounting_CreditLine__c>();
            set <String> setParentSubscriptionJsonId = new set <String>();
            set <String> setParentAccountJsonId = new set <String>();
            
            hqInt_ModelClass.WRP_Accounting_CreditLine obj = (hqInt_ModelClass.WRP_Accounting_CreditLine)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_CreditLine.class);
            listModelObj = obj.objects;
            
            for(hqInt_ModelClass.Accounting_CreditLine obj1 : listModelObj)
            {
                if(obj1.subscription != null)
                    setParentSubscriptionJsonId.add(obj1.subscription);
                if(obj1.account != null)
                    setParentAccountJsonId.add(obj1.account);    
            }
            
            map <String,Id> mapSubscriptionJsonIdToSfId = new map <String,Id>();
            for(Accounting_Subscription__c parentObj : [Select Id,id__c From Accounting_Subscription__c Where id__c in :setParentSubscriptionJsonId])
                mapSubscriptionJsonIdToSfId.put(parentObj.id__c,parentObj.Id);     
            map <String,Id> mapAccountJsonIdToSfId = new map <String,Id>();
            for(Accounting_BillingAccount__c parentObj : [Select Id,id__c From Accounting_BillingAccount__c Where id__c in :setParentAccountJsonId])
                mapAccountJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            
            for(hqInt_ModelClass.Accounting_CreditLine obj1 : listModelObj)
            {
                id parentSubscriptionSfId;
                if(obj1.subscription != null && mapSubscriptionJsonIdToSfId.containsKey(obj1.subscription))
                    parentSubscriptionSfId =  mapSubscriptionJsonIdToSfId.get(obj1.subscription);
				id parentAccountSfId;
				if(obj1.account != null && mapAccountJsonIdToSfId.containsKey(obj1.account))
                    parentAccountSfId =  mapAccountJsonIdToSfId.get(obj1.account);
                    
                Accounting_CreditLine__c sobj = obj1.createDbObject(parentAccountSfId,parentSubscriptionSfId);
                
                listSobject.add(sobj);
            }
            upsert listSobject id__c;  
 
            return listSobject.size();
        }
        ////////////////////////////////////////////////////////////////////////////////////////////////////
        
        else if(objectUrl.endsWith('credit_adjustment/'))
        {
            
            list <hqInt_ModelClass.Accounting_CreditAdjustment> listModelObj = new list <hqInt_ModelClass.Accounting_CreditAdjustment>();
            list <Accounting_CreditAdjustment__c> listSobject = new list <Accounting_CreditAdjustment__c>();
            map <String,String> mapCreditLineJsonIdToSfId = new map <String,String>(); 
            map <String,String> mapLineItemJsonIdToSfId = new map <String,String>();
            map <String,String> mapInvoiceJsonIdToSfId = new map <String,String>();
            map <String,String> mapPaymentRecJsonIdToSfId = new map <String,String>();
            
            hqInt_ModelClass.WRP_Accounting_CreditAdjustment obj = (hqInt_ModelClass.WRP_Accounting_CreditAdjustment)JSON.deserialize(jsonString,hqInt_ModelClass.WRP_Accounting_CreditAdjustment.class);
            listModelObj = obj.objects;
            
            for(hqInt_ModelClass.Accounting_CreditAdjustment obj1 : listModelObj)
            {
                if(obj1.credit_line != null)
					mapCreditLineJsonIdToSfId.put(obj1.credit_line,null);
				if(obj1.line_item != null) 
					mapLineItemJsonIdToSfId.put(obj1.line_item,null);
				if(obj1.invoice != null)  
					mapInvoiceJsonIdToSfId.put(obj1.invoice,null);
				if(obj1.payment_record != null)
					mapPaymentRecJsonIdToSfId.put(obj1.payment_record,null);		
				if(obj1.related_credit != null)
					mapCreditLineJsonIdToSfId.put(obj1.related_credit,null);
            } 
            
            for(Accounting_CreditLine__c parentObj : [Select Id,id__c From Accounting_CreditLine__c Where id__c in :mapCreditLineJsonIdToSfId.keySet()])
                mapCreditLineJsonIdToSfId.put(parentObj.id__c,parentObj.Id);     
            for(Accounting_LineItems__c parentObj : [Select Id,id__c From Accounting_LineItems__c Where id__c in :mapLineItemJsonIdToSfId.keySet()])
                mapLineItemJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            for(Accounting_Invoice__c parentObj : [Select Id,id__c From Accounting_Invoice__c Where id__c in :mapInvoiceJsonIdToSfId.keySet()])
                mapInvoiceJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            for(Accounting_Paymentrecord__c parentObj : [Select Id,id__c From Accounting_Paymentrecord__c Where id__c in :mapPaymentRecJsonIdToSfId.keySet()])
                mapPaymentRecJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            
            
            for(hqInt_ModelClass.Accounting_CreditAdjustment obj1 : listModelObj)
            {
                id creditLineSfId;
                id lineItemSfId;
                id invoiceSfId; 
                id paymentRecSfId;
                id relatedCreditLineSfId;
                
                if(obj1.credit_line != null && mapCreditLineJsonIdToSfId.containsKey(obj1.credit_line))
                    creditLineSfId =  mapCreditLineJsonIdToSfId.get(obj1.credit_line);

				if(obj1.line_item != null && mapLineItemJsonIdToSfId.containsKey(obj1.line_item))
                    lineItemSfId =  mapLineItemJsonIdToSfId.get(obj1.line_item);
                
                if(obj1.invoice != null && mapInvoiceJsonIdToSfId.containsKey(obj1.invoice))
                    invoiceSfId =  mapInvoiceJsonIdToSfId.get(obj1.invoice);
                    
                if(obj1.payment_record != null && mapPaymentRecJsonIdToSfId.containsKey(obj1.payment_record))
                    paymentRecSfId =  mapPaymentRecJsonIdToSfId.get(obj1.payment_record);
                    
                if(obj1.related_credit != null && mapCreditLineJsonIdToSfId.containsKey(obj1.related_credit))
                    relatedCreditLineSfId =  mapCreditLineJsonIdToSfId.get(obj1.related_credit);
                                
                Accounting_CreditAdjustment__c sobj = obj1.createDbObject(creditLineSfId,invoiceSfId,lineItemSfId,paymentRecSfId,relatedCreditLineSfId);
                
                listSobject.add(sobj);
            }
            upsert listSobject id__c;  
 			
 			return listSobject.size();
        }
        
        return null;
    } 
    
    /**
     * 
     * Method Name : ReplaceReservedWords
     * Purpose : In json string, some fields will be reserved / not allowed keywords. This method will replace those with alternate names
     * 
     **/
    private string ReplaceReservedWords(string myString) 
    {
 
       myString = myString.replaceAll('"_id"\\s*:', '"x_id":');
       myString = myString.replaceAll('"public"\\s*:', '"x_Public":');
       myString = myString.replaceAll('"date"\\s*:', '"x_date":');
       //myString = myString.replaceAll('"currency"\\s*:', '"x_currency":');
       return myString;
    }

    public string generateEndPointUrl(Integer offsetParam,String objectUrl,  Integer limitParam, String dateModifiedParam)
    {
        string endpointUrl = objectUrl + '?format=json&offset='+String.valueOf(OffsetParam) + '&limit=' + String.valueOf(limitParam) + '&last_modified__gte=' + dateModifiedParam;   
        return endpointUrl;
    }

    /**
     *
     *
     * Method Name : runNextBatch
     * Purpose : Determines the next batch class & runs it.
     * @ Param batchToBeRun : Next Batch Number to be run
     *
     *
     **/
     public static void runNextBatch(Integer batchToBeRun)
     {
        Boolean lastBatch=false;
        
        //Before running batches, initialize the job start date
        if(!test.isRunningTest() && batchToBeRun == 1)
        {
            CommcareToSalesforceSettings__c jobStartDateSetting = CommcareToSalesforceSettings__c.getInstance('JOBSTARTDATE');
            jobStartDateSetting.Value__c = System.now().format('yyyy-MM-dd');
            update jobStartDateSetting;
        }
        
		//if(batchToBeRun == 1) Database.executeBatch(new hqInt_BatchFetchObjectLineItem(batchToBeRun),1);
        //if(batchToBeRun == 2) Database.executeBatch(new hqInt_BatchFetchObjectCreditAdjustment(batchToBeRun),1);
        //if(batchToBeRun == 3) Database.executeBatch(new hqInt_BatchFetchObjectPaymentRec(batchToBeRun),1);
        //if(batchToBeRun == 1) Database.executeBatch(new hqInt_BatchFetchObjectAcctingInvoice(batchToBeRun),1);
          


        if(batchToBeRun == 1)
            Database.executeBatch(new hqInt_BatchFetchObjectFeature(batchToBeRun),1);
        //if(batchToBeRun == 2)
        //    Database.executeBatch(new hqInt_BatchFetchObjectBillingAccAdmin(batchToBeRun),1);    
        if(batchToBeRun == 2)
            Database.executeBatch(new hqInt_BatchFetchObjectSoftwarePlan(batchToBeRun),1);
        if(batchToBeRun == 3)
            Database.executeBatch(new hqInt_BatchFetchObjectSubscriber(batchToBeRun),1);
        
        if(batchToBeRun == 4)
            Database.executeBatch(new hqInt_BatchFetchObjectFeatureRate(batchToBeRun),1);                       
        if(batchToBeRun == 5)
            Database.executeBatch(new hqInt_BatchFetchObjectSoftwarePlanVer(batchToBeRun),1);
        if(batchToBeRun == 6)
            Database.executeBatch(new hqInt_BatchFetchObjectPaymentMethod(batchToBeRun),1);
        if(batchToBeRun == 7)
            Database.executeBatch(new hqInt_BatchFetchObjectBillingContactInfo(batchToBeRun),1);
            
        if(batchToBeRun == 8)
            Database.executeBatch(new hqInt_BatchFetchObjectPaymentRec(batchToBeRun),1);
        if(batchToBeRun == 9)
            Database.executeBatch(new hqInt_BatchFetchObjectBillingAccount(batchToBeRun),1);
        if(batchToBeRun == 10)
            Database.executeBatch(new hqInt_BatchFetchObjectSubscription(batchToBeRun),1);
        if(batchToBeRun == 11)
            Database.executeBatch(new hqInt_BatchFetchObjectAcctingInvoice(batchToBeRun),1);

        if(batchToBeRun == 12)
            Database.executeBatch(new hqInt_BatchFetchObjectLineItem(batchToBeRun),1);
        if(batchToBeRun == 13)
            Database.executeBatch(new hqInt_BatchFetchObjectSubcriptionAdj(batchToBeRun),1);
        if(batchToBeRun == 14)
            Database.executeBatch(new hqInt_BatchFetchObjectCreditLine(batchToBeRun),1);
        if(batchToBeRun == 15)
        {
            Database.executeBatch(new hqInt_BatchFetchObjectCreditAdjustment(batchToBeRun),1);
            lastBatch = true;            	
        }
            
        
        if(lastBatch)
        {
            CommcareToSalesforceSettings__c lastRunDateSetting = CommcareToSalesforceSettings__c.getInstance('LastRunDate');
            CommcareToSalesforceSettings__c jobStartDateSetting = CommcareToSalesforceSettings__c.getInstance('JOBSTARTDATE');
            lastRunDateSetting.Value__c = jobStartDateSetting.Value__c;
            update lastRunDateSetting;
        }   

     }
}