public class HQSyncProcessors {

    public class HQSyncSoftwareProductRateProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);

            List<Accounting_SoftwareProductRate__c> softwareProductRateList = new List<Accounting_SoftwareProductRate__c>();
            List<HQSyncModels.AccountingSoftwareProductRate> softwareProductRateModelList = new List<HQSyncModels.AccountingSoftwareProductRate>();
            List<String> ids = new List<String>();


            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    HQSyncModels.AccountingSoftwareProductRate softwareProductRate = (HQSyncModels.AccountingSoftwareProductRate) parser.readValueAs(HQSyncModels.AccountingSoftwareProductRate.class);
                    softwareProductRateModelList.add(softwareProductRate);
                    ids.add(softwareProductRate.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_SoftwareProductRate__c sfp : [SELECT Id, id__c FROM Accounting_SoftwareProductRate__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            for (HQSyncModels.AccountingSoftwareProductRate sfp : softwareProductRateModelList) {
                Accounting_SoftwareProductRate__c obj = sfp.createDbObject(serverName);
                if (externalIdMap.containsKey(obj.id__c)) {
                    obj.Id = externalIdMap.get(obj.id__c);
                }
                softwareProductRateList.add(obj);
            }

            upsert softwareProductRateList;
            return softwareProductRateList.size();
        }
    }

    public class HQSyncSoftwarePlanProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingSoftwarePlan obj;
            List<Accounting_Softwareplan__c> listSobjectSoftwarePlan = new List<Accounting_Softwareplan__c>();
            List<String> ids = new List<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingSoftwarePlan)parser.readValueAs(HQSyncModels.AccountingSoftwarePlan.class);
                    listSobjectSoftwarePlan.add(obj.createDbObject(serverName));
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Softwareplan__c sfp : [SELECT Id, id__c FROM Accounting_Softwareplan__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }
    
            for (Accounting_Softwareplan__c sfp : listSobjectSoftwarePlan) {
                if (externalIdMap.containsKey(sfp.id__c)) {
                    sfp.Id = externalIdMap.get(sfp.id__c);
                }
            }

            upsert listSobjectSoftwarePlan;
            return listSobjectSoftwarePlan.size();
        }
    }

    public class HQSyncSoftwarePlanVersionProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingSoftwarePlanVersion obj;
            List<HQSyncModels.AccountingSoftwarePlanVersion> listModelObj = new List<HQSyncModels.AccountingSoftwarePlanVersion>();
            List<Accounting_SoftwarePlanVersion__c> listSobject = new List<Accounting_SoftwarePlanVersion__c>();
            Set<String> planIdSet = new Set<String>();
            Set<String> productRateIdSet = new Set<String>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingSoftwarePlanVersion)parser.readValueAs(HQSyncModels.AccountingSoftwarePlanVersion.class);
                    listModelObj.add(obj);
                    if (obj.plan != null) {
                        planIdSet.add(obj.plan);
                    }
                    if (obj.product_rates != null && obj.product_rates.size() > 0) {
                        productRateIdSet.add(obj.product_rates[0]);
                    }
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_SoftwarePlanVersion__c sfp : [SELECT Id, id__c FROM Accounting_SoftwarePlanVersion__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            Map<String, Id> mapJsonIdToSfId = new Map<String, Id>();
            for (Accounting_Softwareplan__c softwarePlan : [SELECT Id, id__c FROM Accounting_Softwareplan__c WHERE id__c in :planIdSet AND Server_Name__c = : serverName]) {
                mapJsonIdToSfId.put(softwarePlan.id__c, softwarePlan.Id);
            }

            Map<String, Id> mapProductRate = new Map<String, Id>();
            for (Accounting_SoftwareProductRate__c productRate : [SELECT Id, id__c FROM Accounting_SoftwareProductRate__c WHERE id__c in :productRateIdSet AND Server_Name__c = : serverName]) {
                mapProductRate.put(productRate.id__c, productRate.Id);
            }

            for (HQSyncModels.AccountingSoftwarePlanVersion softwarePlanVersion : listModelObj) {
                Id planid;
                if (mapJsonIdToSfId.containsKey(softwarePlanVersion.plan)) {
                    planid = mapJsonIdToSfId.get(softwarePlanVersion.plan);
                }

                Id productaRateId;
                if (softwarePlanVersion.product_rates != null && softwarePlanVersion.product_rates.size() > 0
                        && mapProductRate.containsKey(softwarePlanVersion.product_rates[0])) {
                    productaRateId = mapProductRate.get(softwarePlanVersion.product_rates[0]);
                }

                Accounting_SoftwarePlanVersion__c sobj = softwarePlanVersion.createDbObject(planid, productaRateId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncBillingAccountProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingBillingAccount obj;
            List<HQSyncModels.AccountingBillingAccount> listModelObj = new List<HQSyncModels.AccountingBillingAccount>();
            List<Accounting_Billingaccount__c> listSobject = new List<Accounting_Billingaccount__c>();
            Set<String> planIdSet = new Set<String>();
            Set<String> setAccountId = new Set<String>();
            Map<String, String> mapAccJsonIdToContactSfId = new Map<String, String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingBillingAccount) parser.readValueAs(HQSyncModels.AccountingBillingAccount.class);
                    setAccountId.add(obj.Id);
                    listModelObj.add(obj);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_BillingAccount__c sfp : [SELECT Id, id__c FROM Accounting_BillingAccount__c WHERE id__c IN: setAccountId AND Server_Name__c =: serverName]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            for (Accounting_BillingContactInfo__c billingContact : [SELECT Id, accountid__c FROM Accounting_BillingContactInfo__c WHERE accountid__c in :setAccountId AND Server_Name__c =: serverName]) {
                mapAccJsonIdToContactSfId.put(billingContact.accountid__c, billingContact.Id);
            }

            for (HQSyncModels.AccountingBillingAccount billingAccount : listModelObj) {
                Id billingContactId;
                if (mapAccJsonIdToContactSfId.containsKey(billingAccount.id)) {
                    billingContactId = mapAccJsonIdToContactSfId.get(billingAccount.id);
                }

                Accounting_Billingaccount__c sobj = billingAccount.createDbObject(billingContactId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }


    public class HQSyncSubscriptionProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingSubscription obj;
            List<HQSyncModels.AccountingSubscription> listModelObj = new List<HQSyncModels.AccountingSubscription>();
            List<Accounting_Subscription__c> listSobject = new List<Accounting_Subscription__c>();
            Set<String> parentObjectAccountIdSet = new Set<String>(); //PARENT=Account
            Set<String> parentObjectPlanVerIdSet = new Set<String>(); //PARENT=Plan Version
            Set<String> parentObjectSubscriberIdSet = new Set<String>(); //PARENT=Subscriber
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingSubscription) parser.readValueAs(HQSyncModels.AccountingSubscription.class);
                    if (obj.account != null) {
                        parentObjectAccountIdSet.add(obj.account);
                    }
                    if (obj.plan_version != null) {
                        parentObjectPlanVerIdSet.add(obj.plan_version);
                    }
                    if (obj.subscriber != null) {
                        parentObjectSubscriberIdSet.add(obj.subscriber);
                    }
                    ids.add(obj.id);
                    listModelObj.add(obj);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Subscription__c sfp : [SELECT Id, id__c FROM Accounting_Subscription__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            Map<String,Id> mapJsonIdToSfIdForAccount = new Map<String,Id>();
            for (Accounting_Billingaccount__c parentObj : [SELECT Id, id__c FROM Accounting_Billingaccount__c WHERE id__c in :parentObjectAccountIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfIdForAccount.put(parentObj.id__c, parentObj.Id);
            }

            Map <String, Id> mapJsonIdToSfIdForPlanVer = new Map<String, Id>();
            for (Accounting_SoftwarePlanVersion__c parentObj : [SELECT Id, id__c FROM Accounting_SoftwarePlanVersion__c WHERE id__c in :parentObjectPlanVerIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfIdForPlanVer.put(parentObj.id__c, parentObj.Id);
            }

            Map <String, Accounting_Subscriber__c> mapJsonIdToSfIdForSubscriber = new Map<String, Accounting_Subscriber__c>();
            for (Accounting_Subscriber__c parentObj : [SELECT Id,id__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE id__c in :parentObjectSubscriberIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfIdForSubscriber.put(parentObj.id__c, parentObj);
            }

            for (HQSyncModels.AccountingSubscription subscription  : listModelObj) {

                Id parentObjectAccountId;
                Id parentObjectPlanVerId;
                Id parentObjectSubscriberId;
                Id domainId;

                if (mapJsonIdToSfIdForAccount.containsKey(subscription.account)) {
                    parentObjectAccountId = mapJsonIdToSfIdForAccount.get(subscription.account);
                }
                if (mapJsonIdToSfIdForPlanVer.containsKey(subscription.plan_version)) {
                    parentObjectPlanVerId = mapJsonIdToSfIdForPlanVer.get(subscription.plan_version);
                }
                if (mapJsonIdToSfIdForSubscriber.containsKey(subscription.subscriber)) {
                    parentObjectSubscriberId = mapJsonIdToSfIdForSubscriber.get(subscription.subscriber).Id;
                    domainId = mapJsonIdToSfIdForSubscriber.get(subscription.subscriber).domain_lookup__c;
                }

                Accounting_Subscription__c sobj = subscription.createDbObject(parentObjectAccountId, parentObjectPlanVerId, parentObjectSubscriberId,
                                                                                domainId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncCustomerInvoiceProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            Set <String> parentObjectIdSet = new Set <String>(); //PARENT=Billing Account
            Set<String> ids = new Set<String>();
            Set<String> softwarePlanVersions = new Set<String>();
            List<Accounting_Invoice__c> listSobject = new List<Accounting_Invoice__c>();
            List<HQSyncModels.AccountingCustomerInvoice> listModelObj = new List <HQSyncModels.AccountingCustomerInvoice>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    // Read entire invoice object, including its array of line items.
                    HQSyncModels.AccountingCustomerInvoice obj = (HQSyncModels.AccountingCustomerInvoice) parser.readValueAs(HQSyncModels.AccountingCustomerInvoice.class);
                    if(obj.account != null) {
                        parentObjectIdSet.add(obj.account);
                    }
                    listModelObj.add(obj);
                    ids.add(obj.id);
                    if (String.isNotBlank(obj.plan_versions)) {
                        for (String planVersionId : obj.plan_versions.split(',')) {
                            softwarePlanVersions.add(planVersionId);
                        }
                    }
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Invoice__c sfp : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c IN: ids AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.CUSTOMER_INVOICE]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            Map<String, Accounting_Billingaccount__c> mapBillingAccount = new Map <String, Accounting_Billingaccount__c>();
            Set<String> domainNames = new Set<String>();
            for (Accounting_Billingaccount__c parentObj : [SELECT Id, id__c, created_by_domain__c FROM Accounting_Billingaccount__c WHERE id__c in :parentObjectIdSet AND Server_Name__c =: serverName]) {
                mapBillingAccount.put(parentObj.id__c, parentObj);
                if (parentObj.created_by_domain__c != null && parentObj.created_by_domain__c != '') {
                    domainNames.add(parentObj.created_by_domain__c);
                }
            }

            Map<String, Accounting_SoftwarePlanVersion__c> softwarePlanVersionMap = new Map<String, Accounting_SoftwarePlanVersion__c>();
            for (Accounting_SoftwarePlanVersion__c spv : [SELECT Id,  id__c, Software_Product_Rate__r.monthly_fee__c FROM Accounting_SoftwarePlanVersion__c
                                                            WHERE id__c IN: softwarePlanVersions AND Server_Name__c =: serverName]) {
                softwarePlanVersionMap.put(spv.id__c, spv);
            }

            Map<String, Domain__c> mapDomains = new Map<String, Domain__c>();
            for (Domain__c domain : [SELECT Id, Name, id__c FROM Domain__c WHERE Server_Name__c =: serverName AND Name IN: domainNames]) {
                mapDomains.put(domain.Name, domain);
            }

            for (HQSyncModels.AccountingCustomerInvoice invoice : listModelObj) {
                Id parentId;
                Accounting_Billingaccount__c parentObj;
                if(invoice.account != null && mapBillingAccount.containsKey(invoice.account)) {
                    parentObj = mapBillingAccount.get(invoice.account);
                    parentId = parentObj.Id;
                }

                Id domainId;
                if (invoice.account != null && parentObj != null && parentObj.created_by_domain__c != null) {
                    Domain__c  domainObj = mapDomains.get(parentObj.created_by_domain__c);
                    domainId = domainObj != null ? domainObj.Id : null;
                }

                Accounting_Invoice__c sobj = invoice.createDbObject(parentId, domainId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }

                Decimal monthlyFee = 0;
                if (String.isNotBlank(invoice.plan_versions)) {
                    for (String planVersionId : invoice.plan_versions.split(',')) {
                        if (softwarePlanVersionMap.containsKey(planVersionId)) {
                            Accounting_SoftwarePlanVersion__c spv = softwarePlanVersionMap.get(planVersionId);
                            monthlyFee += spv.Software_Product_Rate__r.monthly_fee__c != null ? spv.Software_Product_Rate__r.monthly_fee__c : 0;
                        }
                    }
                }

                sobj.Customer_Invoice_Monthly_fee__c = monthlyFee;
                listSobject.add(sobj);
            }

            upsert listSobject;

            return listSobject.size();
        }
    }

    public class HQSyncInvoiceProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingInvoice obj;
            List <HQSyncModels.AccountingInvoice> listModelObj = new List <HQSyncModels.AccountingInvoice>();
            List <Accounting_Invoice__c> listSobject = new List <Accounting_Invoice__c>();
            Set <String> parentObjectIdSet = new Set <String>(); //PARENT=Subscription
            Map <String, Accounting_Subscription__c> mapJsonIdToSfId = new Map <String, Accounting_Subscription__c>();
            Set <String> setFeatureRates = new Set <String>();
            Map <String, String> mapSubscriptionJsonIdToFeatureRatesJsonId = new Map <String, String>();
            Map <String, String> mapFeatureRateJsonIdToSfId = new Map <String, String>();
            List <Accounting_FeatureRateForInvoice__c> listFeatureRateForInvoice = new List <Accounting_FeatureRateForInvoice__c>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    // Read entire invoice object, including its array of line items.
                    obj = (HQSyncModels.AccountingInvoice) parser.readValueAs(HQSyncModels.AccountingInvoice.class);
                    if(obj.subscription != null) {
                        parentObjectIdSet.add(obj.subscription);
                    }
                    listModelObj.add(obj);
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Invoice__c sfp : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c IN: ids AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.SUBSCRIPTION_INVOICE]) {
                externalIdMap.put(sfp.id__c, sfp.Id);
            }

            Map <String, String> mapASubscriptionJsonIdToDomainId = new Map <String, String>();
            for (Accounting_Subscription__c parentObj : [SELECT Id, Accounting_Subscriber__r.domain_lookup__c, id__c, plan_version__r.FeatureRates__c, account__c,
                                                         plan_version__r.Accounting_SoftwarePlan__r.edition__c
                                                         FROM Accounting_Subscription__c WHERE id__c in :parentObjectIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfId.put(parentObj.id__c, parentObj);
                if (String.isNotBlank(parentObj.plan_version__r.FeatureRates__c)) {
                    setFeatureRates.addAll(parentObj.plan_version__r.FeatureRates__c.split(','));
                    mapSubscriptionJsonIdToFeatureRatesJsonId.put(parentObj.id__c, parentObj.plan_version__r.FeatureRates__c);
                }
                if (parentObj.Accounting_Subscriber__r.domain_lookup__c != null) {
                    mapASubscriptionJsonIdToDomainId.put(parentObj.id__c, parentObj.Accounting_Subscriber__r.domain_lookup__c);
                }
            }

            for(Accounting_Featurerate__c featureRate : [SELECT id, id__c FROM Accounting_Featurerate__c WHERE id__c in :setFeatureRates AND Server_Name__c =: serverName]) {
                mapFeatureRateJsonIdToSfId.put(featureRate.id__c, featureRate.id);
            }

            for (HQSyncModels.AccountingInvoice invoice : listModelObj) {
                Id parentId;
                String softPlan = '';
                if(mapJsonIdToSfId.containsKey(invoice.subscription)) {
                    Accounting_Subscription__c subObj = mapJsonIdToSfId.get(invoice.subscription);
                    parentId = subObj.Id;
                    softPlan = subObj.plan_version__r.Accounting_SoftwarePlan__r.edition__c;
                }

                Id domainId;
                if (mapASubscriptionJsonIdToDomainId.containsKey(invoice.subscription)) {
                    domainId = mapASubscriptionJsonIdToDomainId.get(invoice.subscription);
                }

                Accounting_Invoice__c sobj = invoice.createDbObject(parentId, domainId, softPlan, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;

            //prepare a map of Accid to invid
            Map <String, String> mapAccIdToInvId = new Map <String, String>();
            for(Accounting_Invoice__c invoice : [SELECT id ,Accounting_Subscription__r.account__c FROM Accounting_Invoice__c WHERE Id in : listSobject
                                                 AND Accounting_Subscription__r.account__c != null AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.SUBSCRIPTION_INVOICE]) {
                mapAccIdToInvId.put(invoice.Accounting_Subscription__r.account__c, invoice.Id);
            }

            //using the above map of Accid to invid, preapre a map of invid to paymentrecid.
            Map <String, List<String>> mapInvIdToPymntRecIdList = new Map <String, List<String>>();
            for (Accounting_Paymentrecord__c paymentRec : [SELECT id, payment_method__r.account__c FROM Accounting_Paymentrecord__c
                                                           WHERE payment_method__r.account__c in :mapAccIdToInvId.keySet() AND Server_Name__c =: serverName]) {
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

            delete [SELECT id FROM Accounting_PaymentsForInvoice__c WHERE Invoice__c in :listSobject];
            insert listPymtForInvoice;

            return listSobject.size();
        }
    }

    public class HQSyncSubscriberProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingSubscriber obj;
            List <HQSyncModels.AccountingSubscriber> listModelObj = new List <HQSyncModels.AccountingSubscriber>();
            List <Accounting_Subscriber__c> listSobject = new List <Accounting_Subscriber__c>();
            Set <String> parentObjectIdSet = new Set <String>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingSubscriber) parser.readValueAs(HQSyncModels.AccountingSubscriber.class);
                    if(obj.domain != null) {
                        if (obj.domain.length() > 80) {
                            obj.domain = obj.domain.subString(0, 80);
                        }
                        parentObjectIdSet.add(obj.domain);
                    }
                    listModelObj.add(obj);
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Subscriber__c af : [SELECT Id, id__c FROM Accounting_Subscriber__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            for (Domain__c parentObj : [SELECT Id, Name FROM Domain__c WHERE Name in :parentObjectIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfId.put(parentObj.Name, parentObj.Id);
            }

            for (HQSyncModels.AccountingSubscriber subscriber : listModelObj) {
                Id parentId;
                if(mapJsonIdToSfId.containsKey(subscriber.domain)) {
                    parentId = mapJsonIdToSfId.get(subscriber.domain);
                }

                Accounting_Subscriber__c sobj = subscriber.createDbObject(parentId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncFeatureProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingFeature obj;
            List <Accounting_feature__c> listSobject = new List<Accounting_feature__c>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingFeature) parser.readValueAs(HQSyncModels.AccountingFeature.class);
                    listSobject.add(obj.createDbObject(serverName));
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_feature__c af : [SELECT Id, id__c FROM Accounting_feature__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            for (Accounting_feature__c af : listSobject) {
                if (externalIdMap.containsKey(af.id__c)) {
                    af.Id = externalIdMap.get(af.id__c);
                }
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncFeatureRateProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingFeatureRate obj;
            List <HQSyncModels.AccountingFeatureRate> listModelObj = new List <HQSyncModels.AccountingFeatureRate>();
            List <Accounting_Featurerate__c> listSobject = new List <Accounting_Featurerate__c>();
            Set <String> parentObjectIdSet = new Set <String>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingFeatureRate) parser.readValueAs(HQSyncModels.AccountingFeatureRate.class);
                    if(obj.feature != null) {
                        parentObjectIdSet.add(obj.feature);
                    }
                    listModelObj.add(obj);
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
            for (accounting_feature__c parentObj : [SELECT Id, id__c FROM accounting_feature__c WHERE id__c in :parentObjectIdSet AND Server_Name__c =: serverName]) {
                mapJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Featurerate__c af : [SELECT Id, id__c FROM Accounting_Featurerate__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            for (HQSyncModels.AccountingFeatureRate featureRate : listModelObj) {
                Id parentId;
                if(mapJsonIdToSfId.containsKey(featureRate.feature)) {
                    parentId = mapJsonIdToSfId.get(featureRate.feature);
                }
                Accounting_Featurerate__c sobj = featureRate.createDbObject(parentId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncBillingContactInfoProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingBillingContactInfo obj;
            List <Accounting_BillingContactInfo__c> listSobject = new List <Accounting_BillingContactInfo__c>();
            List <HQSyncModels.AccountingBillingContactInfo> modelList = new List<HQSyncModels.AccountingBillingContactInfo>();
            Set<String> ids = new set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingBillingContactInfo) parser.readValueAs(HQSyncModels.AccountingBillingContactInfo.class);
                    ids.add(obj.account);
                    modelList.add(obj);
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_BillingContactInfo__c af : [SELECT Id, accountid__c FROM Accounting_BillingContactInfo__c WHERE accountid__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.accountid__c, af.Id);
            }

            for (HQSyncModels.AccountingBillingContactInfo billC : modelList) {
                Accounting_BillingContactInfo__c sobj = billC.createDbObject(serverName);
                if (externalIdMap.containsKey(sobj.accountid__c)) {
                    sobj.Id = externalIdMap.get(sobj.accountid__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncLineItemProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingLineItem obj;
            List<HQSyncModels.AccountingLineItem> listModelObj = new List <HQSyncModels.AccountingLineItem>();
            List<Accounting_LineItems__c> listSobject = new List <Accounting_LineItems__c>();
            Set<String> parentInvoiceObjectIdSet = new Set<String>();
            Set<String> parentCustomerInvoiceObjectIdSet = new Set<String>();
            Set<String> parentFeatureObjectIdSet = new Set<String>();
            Set<String> ids = new Set<String>();
            List<String> badLineItems = new List<String>(); // TODO remove in future

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingLineItem)parser.readValueAs(HQSyncModels.AccountingLineItem.class);
                    if(obj.invoice != null) {
                        parentInvoiceObjectIdSet.add(obj.invoice);
                    }
                    if (obj.customer_invoice != null) {
                        parentCustomerInvoiceObjectIdSet.add(obj.customer_invoice);
                    }
                    if(obj.feature_rate != null) {
                        parentFeatureObjectIdSet.add(obj.feature_rate);
                    }

                    if (obj.invoice != null && obj.customer_invoice != null) {
                        badLineItems.add(obj.id);
                    }

                    listModelObj.add(obj);
                    ids.add(obj.id);

                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_LineItems__c af : [SELECT Id, id__c FROM Accounting_LineItems__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            Map <String, Id> mapInvoiceJsonIdToSfId = new Map <String, Id>();
            for (Accounting_Invoice__c parentObj : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c in :parentInvoiceObjectIdSet AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.SUBSCRIPTION_INVOICE]) {
                mapInvoiceJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            Map <String, Id> mapCustomerInvoiceJsonIdToSfId = new Map <String, Id>();
            for (Accounting_Invoice__c parentObj : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c in :parentCustomerInvoiceObjectIdSet AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.CUSTOMER_INVOICE]) {
                mapCustomerInvoiceJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            Map <String, Id> mapFeatureRateJsonIdToSfId = new Map <String, Id>();
            for (Accounting_Featurerate__c parentObj : [SELECT Id, id__c FROM Accounting_Featurerate__c WHERE id__c in :parentFeatureObjectIdSet AND Server_Name__c =: serverName]) {
                mapFeatureRateJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            for (HQSyncModels.AccountingLineItem lineItem : listModelObj) {
                Id parentInvoiceSfId;
                Id parentFeatureRateSfId;

                if(mapInvoiceJsonIdToSfId.containsKey(lineItem.invoice)) {
                    parentInvoiceSfId = mapInvoiceJsonIdToSfId.get(lineItem.invoice);
                } else if (mapCustomerInvoiceJsonIdToSfId.containsKey(lineItem.customer_invoice)) {
                    parentInvoiceSfId = mapCustomerInvoiceJsonIdToSfId.get(lineItem.customer_invoice);
                }

                if(mapFeatureRateJsonIdToSfId.containsKey(lineItem.feature_rate)) {
                    parentFeatureRateSfId = mapFeatureRateJsonIdToSfId.get(lineItem.feature_rate);
                }

                if(parentInvoiceSfId != null) {
                    Accounting_LineItems__c sobj = lineItem.createDbObject(parentInvoiceSfId, parentFeatureRateSfId, serverName);
                    if (externalIdMap.containsKey(sobj.id__c)) {
                        sobj.Id = externalIdMap.get(sobj.id__c);
                    }
                    listSobject.add(sobj);
                }
            }

            upsert listSobject;

            if (badLineItems.size() > 0 && !Test.isRunningTest()) { // TODO remove in future
                EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Duplicated invoice relation',
                                                'We have duplicated invoice relations in line items : ' + String.join(badLineItems, ', '));
            }

            return listSobject.size();
        }
    }

    public class HQSyncPaymentMethodProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            JSONParser parser = HQSyncUtils.createParser(jsonString);
            HQSyncModels.AccountingPaymentMethod obj;
            List <HQSyncModels.AccountingPaymentMethod> listModelObj = new List <HQSyncModels.AccountingPaymentMethod>();
            List <Accounting_PaymentMethod__c> listSobject = new List <Accounting_PaymentMethod__c>();
            Set <String> parentBillingAccJsonIdSet = new Set <String>();
            Set <String> parentBillingAccAdminJsonIdSet = new Set <String>();
            Set<String> ids = new Set<String>();

            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    obj = (HQSyncModels.AccountingPaymentMethod) parser.readValueAs(HQSyncModels.AccountingPaymentMethod.class);
                    if(obj.account != null) {
                        parentBillingAccJsonIdSet.add(obj.account);
                    }
                    if(obj.billing_admin != null) {
                        parentBillingAccAdminJsonIdSet.add(obj.billing_admin);
                    }
                    listModelObj.add(obj);
                    ids.add(obj.id);
                    parser.skipChildren();
                }
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_PaymentMethod__c af : [SELECT Id, id__c FROM Accounting_PaymentMethod__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            Map <String, Id> mapBillingAccJsonIdToSfId = new Map <String, Id>();
            for (Accounting_BillingAccount__c parentObj : [SELECT Id, id__c FROM Accounting_BillingAccount__c WHERE id__c in :parentBillingAccJsonIdSet AND Server_Name__c =: serverName]) {
                mapBillingAccJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            Map <String, Id> mapBillingAccAdminJsonIdToSfId = new Map <String, Id>();
            for (Accounting_BillingAccountAdmin__c parentObj : [SELECT Id, id__c FROM Accounting_BillingAccountAdmin__c WHERE id__c in :parentBillingAccAdminJsonIdSet AND Server_Name__c =: serverName]) {
                mapBillingAccAdminJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            for (HQSyncModels.AccountingPaymentMethod paymentMethod : listModelObj) {
                Id parentBillingAccSfId;
                Id parentBillingAccAdminSfId;

                if(mapBillingAccJsonIdToSfId.containsKey(paymentMethod.account)) {
                    parentBillingAccSfId = mapBillingAccJsonIdToSfId.get(paymentMethod.account);
                }
                if(mapBillingAccAdminJsonIdToSfId.containsKey(paymentMethod.billing_admin)) {
                    parentBillingAccAdminSfId = mapBillingAccAdminJsonIdToSfId.get(paymentMethod.billing_admin);
                }
                Accounting_PaymentMethod__c sobj = paymentMethod.createDbObject(parentBillingAccSfId, parentBillingAccAdminSfId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncPaymentRecordProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            List <HQSyncModels.AccountingPaymentRecord> listModelObj = new List <HQSyncModels.AccountingPaymentRecord>();
            List <Accounting_Paymentrecord__c> listSobject = new List <Accounting_Paymentrecord__c>();
            Set <String> setParentObjectJsonId = new Set <String>();
            Set<String> ids = new Set<String>();

            HQSyncModels.AccountingPaymentRecordWrapper obj = (HQSyncModels.AccountingPaymentRecordWrapper) JSON.deserialize(jsonString, HQSyncModels.AccountingPaymentRecordWrapper.class);
            listModelObj = obj.objects;

            for (HQSyncModels.AccountingPaymentRecord paymentRecord : listModelObj) {
                if(paymentRecord.payment_method != null) {
                    setParentObjectJsonId.add(paymentRecord.payment_method);
                }
                ids.add(paymentRecord.id);
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_Paymentrecord__c af : [SELECT Id, id__c FROM Accounting_Paymentrecord__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
            for (Accounting_PaymentMethod__c parentObj : [SELECT Id, id__c FROM Accounting_PaymentMethod__c WHERE id__c in :setParentObjectJsonId
                                                                AND Server_Name__c =: serverName]) {
                mapJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }
            for (HQSyncModels.AccountingPaymentRecord paymentRecord : listModelObj) {
                Id parentId;
                if(mapJsonIdToSfId.containsKey(paymentRecord.payment_method)) {
                    parentId = mapJsonIdToSfId.get(paymentRecord.payment_method);
                }
                Accounting_Paymentrecord__c sobj = paymentRecord.createDbObject(parentId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncSubscriptionAdjustmentProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            List <HQSyncModels.AccountingSubscriptionAdjustment> listModelObj = new List <HQSyncModels.AccountingSubscriptionAdjustment>();
            List <Accounting_SubscriptionAdjustment__c> listSobject = new List <Accounting_SubscriptionAdjustment__c>();
            Set <String> setParentObjectJsonId = new Set <String>();
            Set<String> ids = new Set<String>();

            HQSyncModels.AccountingSubscriptionAdjustmentWrapper obj = (HQSyncModels.AccountingSubscriptionAdjustmentWrapper) JSON.deserialize(jsonString, HQSyncModels.AccountingSubscriptionAdjustmentWrapper.class);
            listModelObj = obj.objects;

            for (HQSyncModels.AccountingSubscriptionAdjustment subscriptionAdjustment : listModelObj) {
                if(subscriptionAdjustment.subscription != null) {
                    setParentObjectJsonId.add(subscriptionAdjustment.subscription);
                }
                ids.add(subscriptionAdjustment.id);
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_SubscriptionAdjustment__c af : [SELECT Id, id__c FROM Accounting_SubscriptionAdjustment__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            Map <String, Id> mapJsonIdToSfId = new Map <String, Id>();
            for (Accounting_Subscription__c parentObj : [SELECT Id, id__c FROM Accounting_Subscription__c WHERE id__c in :setParentObjectJsonId AND Server_Name__c =: serverName]) {
                mapJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            }

            for (HQSyncModels.AccountingSubscriptionAdjustment subscriptionAdjustment : listModelObj) {
                Id parentid;
                if(subscriptionAdjustment.subscription != null) {
                    parentid = mapJsonIdToSfId.get(subscriptionAdjustment.subscription);
                }
                Accounting_SubscriptionAdjustment__c sobj = subscriptionAdjustment.createDbObject(parentid, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncCreditLineProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            List <HQSyncModels.AccountingCreditLine> listModelObj = new List <HQSyncModels.AccountingCreditLine>();
            List <Accounting_CreditLine__c> listSobject = new List <Accounting_CreditLine__c>();
            Set <String> setParentSubscriptionJsonId = new Set <String>();
            Set <String> setParentAccountJsonId = new Set <String>();
            Set <String> ids = new Set <String>();

            HQSyncModels.AccountingCreditLineWrapper obj = (HQSyncModels.AccountingCreditLineWrapper) JSON.deserialize(jsonString, HQSyncModels.AccountingCreditLineWrapper.class);
            listModelObj = obj.objects;

            for (HQSyncModels.AccountingCreditLine creditLine : listModelObj) {
                if(creditLine.subscription != null) {
                    setParentSubscriptionJsonId.add(creditLine.subscription);
                }
                if(creditLine.account != null) {
                    setParentAccountJsonId.add(creditLine.account);
                }
                ids.add(creditLine.id);
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_CreditLine__c af : [SELECT Id, id__c FROM Accounting_CreditLine__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            Map <String,Id> mapSubscriptionJsonIdToSfId = new Map <String,Id>();
            for (Accounting_Subscription__c parentObj : [SELECT Id, id__c FROM Accounting_Subscription__c WHERE id__c in :setParentSubscriptionJsonId AND Server_Name__c =: serverName]) {
                mapSubscriptionJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            }
            Map <String, Id> mapAccountJsonIdToSfId = new Map <String, Id>();
            for (Accounting_BillingAccount__c parentObj : [SELECT Id,id__c FROM Accounting_BillingAccount__c WHERE id__c in :setParentAccountJsonId AND Server_Name__c =: serverName]) {
                mapAccountJsonIdToSfId.put(parentObj.id__c,parentObj.Id);
            }

            for (HQSyncModels.AccountingCreditLine creditLine : listModelObj) {
                Id parentSubscriptionSfId;
                if(creditLine.subscription != null && mapSubscriptionJsonIdToSfId.containsKey(creditLine.subscription)) {
                    parentSubscriptionSfId =  mapSubscriptionJsonIdToSfId.get(creditLine.subscription);
                }
                Id parentAccountSfId;
                if(creditLine.account != null && mapAccountJsonIdToSfId.containsKey(creditLine.account)) {
                    parentAccountSfId =  mapAccountJsonIdToSfId.get(creditLine.account);
                }

                Accounting_CreditLine__c sobj = creditLine.createDbObject(parentAccountSfId, parentSubscriptionSfId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }

    public class HQSyncCreditAdjustmentProcessor implements HQSyncDataProcessor {

        public Integer processJSON(String jsonString, String serverName) {
            List <HQSyncModels.AccountingCreditAdjustment> listModelObj = new List<HQSyncModels.AccountingCreditAdjustment>();
            List <Accounting_CreditAdjustment__c> listSobject = new List<Accounting_CreditAdjustment__c>();
            Map <String, String> mapCreditLineJsonIdToSfId = new Map<String, String>();
            Map <String, String> mapLineItemJsonIdToSfId = new Map<String, String>();
            Map <String, String> mapInvoiceJsonIdToSfId = new Map<String, String>();
            Map <String, String> mapPaymentRecJsonIdToSfId = new Map<String, String>();
            Set <String> ids = new Set<String>();

            HQSyncModels.AccountingCreditAdjustmentWrapper obj = (HQSyncModels.AccountingCreditAdjustmentWrapper) JSON.deserialize(jsonString, HQSyncModels.AccountingCreditAdjustmentWrapper.class);
            listModelObj = obj.objects;

            for (HQSyncModels.AccountingCreditAdjustment creditAdjustment : listModelObj) {
                if(creditAdjustment.credit_line != null) {
                    mapCreditLineJsonIdToSfId.put(creditAdjustment.credit_line, null);
                }
                if(creditAdjustment.line_item != null) {
                    mapLineItemJsonIdToSfId.put(creditAdjustment.line_item, null);
                }
                if(creditAdjustment.invoice != null) {
                    mapInvoiceJsonIdToSfId.put(creditAdjustment.invoice, null);
                }
                if(creditAdjustment.payment_record != null) {
                    mapPaymentRecJsonIdToSfId.put(creditAdjustment.payment_record, null);
                }
                if(creditAdjustment.related_credit != null) {
                    mapCreditLineJsonIdToSfId.put(creditAdjustment.related_credit, null);
                }
                ids.add(creditAdjustment.id);
            }

            Map<String, Id> externalIdMap = new Map<String, Id>();
            for (Accounting_CreditAdjustment__c af : [SELECT Id, id__c FROM Accounting_CreditAdjustment__c WHERE id__c IN: ids AND Server_Name__c =: serverName]) {
                externalIdMap.put(af.id__c, af.Id);
            }

            for (Accounting_CreditLine__c parentObj : [SELECT Id, id__c FROM Accounting_CreditLine__c WHERE id__c in :mapCreditLineJsonIdToSfId.keySet() AND Server_Name__c =: serverName]) {
                mapCreditLineJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }
            for (Accounting_LineItems__c parentObj : [SELECT Id, id__c FROM Accounting_LineItems__c WHERE id__c in :mapLineItemJsonIdToSfId.keySet() AND Server_Name__c =: serverName]) {
                mapLineItemJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }
            for (Accounting_Invoice__c parentObj : [SELECT Id, id__c FROM Accounting_Invoice__c WHERE id__c in :mapInvoiceJsonIdToSfId.keySet() AND Server_Name__c =: serverName AND Invoice_Type__c =: HQSyncUtils.SUBSCRIPTION_INVOICE]) {
                mapInvoiceJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }
            for (Accounting_Paymentrecord__c parentObj : [SELECT Id, id__c FROM Accounting_Paymentrecord__c WHERE id__c in :mapPaymentRecJsonIdToSfId.keySet() AND Server_Name__c =: serverName]) {
                mapPaymentRecJsonIdToSfId.put(parentObj.id__c, parentObj.Id);
            }

            for (HQSyncModels.AccountingCreditAdjustment creditAdjustment : listModelObj) {
                Id creditLineSfId;
                Id lineItemSfId;
                Id invoiceSfId;
                Id paymentRecSfId;
                Id relatedCreditLineSfId;

                if(creditAdjustment.credit_line != null && mapCreditLineJsonIdToSfId.containsKey(creditAdjustment.credit_line)) {
                    creditLineSfId =  mapCreditLineJsonIdToSfId.get(creditAdjustment.credit_line);
                }
                if(creditAdjustment.line_item != null && mapLineItemJsonIdToSfId.containsKey(creditAdjustment.line_item)) {
                    lineItemSfId =  mapLineItemJsonIdToSfId.get(creditAdjustment.line_item);
                }
                if(creditAdjustment.invoice != null && mapInvoiceJsonIdToSfId.containsKey(creditAdjustment.invoice)) {
                    invoiceSfId =  mapInvoiceJsonIdToSfId.get(creditAdjustment.invoice);
                }
                if(creditAdjustment.payment_record != null && mapPaymentRecJsonIdToSfId.containsKey(creditAdjustment.payment_record)) {
                    paymentRecSfId =  mapPaymentRecJsonIdToSfId.get(creditAdjustment.payment_record);
                }
                if(creditAdjustment.related_credit != null && mapCreditLineJsonIdToSfId.containsKey(creditAdjustment.related_credit)) {
                    relatedCreditLineSfId =  mapCreditLineJsonIdToSfId.get(creditAdjustment.related_credit);
                }
                Accounting_CreditAdjustment__c sobj = creditAdjustment.createDbObject(creditLineSfId, invoiceSfId, lineItemSfId, paymentRecSfId,
                                                                                        relatedCreditLineSfId, serverName);
                if (externalIdMap.containsKey(sobj.id__c)) {
                    sobj.Id = externalIdMap.get(sobj.id__c);
                }
                listSobject.add(sobj);
            }

            upsert listSobject;
            return listSobject.size();
        }
    }
}