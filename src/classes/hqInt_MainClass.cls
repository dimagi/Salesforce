global class hqInt_MainClass {

    public Integer offsetParam;

    global void mainMethod(integer offsetParameter) {
        offsetParam = offsetParameter;
        HTTPResponse res = requestMethod(Integer.valueOf(CommcareToSalesforceSettings__c.getInstance('ApiLimitParameter').Value__c),offsetParameter);

        String response = res.getBody();
        System.debug('--- res --- ' + response);
        response = ReplaceReservedWords(response);

        processJson(response);
    }

    /**
     * Method Name : requestMethod
     * Purpose : Http Callout to CommCareHQ
     **/
    public HTTPResponse requestMethod(integer limitParameter,integer offsetParameter) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.commcarehq.org/hq/admin/api/global/project_space_metadata/?limit='+ String.valueOf(limitParameter) + '&offset=' + String.valueOf(offsetParameter));
        req.setMethod('GET');

        // Specify the required user name and password to access the endpoint
        // As well as the header and header information

        String username = CommcareToSalesforceSettings__c.getInstance('CommCareUserName').Value__c;
        String password = CommcareToSalesforceSettings__c.getInstance('CommCarePassword').Value__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        // Create a new http object to send the request object
        // A response object is generated as a result of the request

        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('--- status --' + res.getStatusCode());
        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('Http request error, cannot fetch Domains data. Http status : ' + res.getStatusCode() + ' Body : ' + res.getBody());
            throw e;
        }

        return res;
    }

    /**
     * Method Name : processJson
     * Purpose : Process Json response and perform DML 
     **/
    private String processJson(String jsonString) {
        List <HqIntModelProjectSpaceMetadata> projectSpaceMetadataList = new List <HqIntModelProjectSpaceMetadata>();
        List <Domain__c> listDomainRec = new List <Domain__c>();
        List <hqInt_Model_DeploymentClass> listDeploymentObj = new List <hqInt_Model_DeploymentClass>();
        List <Deployment__c> listDeploymentRec = new List <Deployment__c>();
        List <Internal_Properties__c> listInternalPropRec = new List <Internal_Properties__c>();

        //Process Response
        JSONParser parser = JSON.createParser(jsonString);

        // Skip meta
        while (parser.nextToken() != null) {
            // Start at the array of invoices.
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'objects') {
                // Objects array
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        // Read entire invoice object, including its array of line items.
                        HqIntModelProjectSpaceMetadata projectSpaceMetadata = (HqIntModelProjectSpaceMetadata)parser.readValueAs(HqIntModelProjectSpaceMetadata.class);
                        projectSpaceMetadataList.add(projectSpaceMetadata);
                        system.debug('---projectSpaceMetadata---' + projectSpaceMetadata);
                    }
                }
            }
        }

        //Set for holding the external id field for domain object. It is used to fetch existing internal prop & deployment rec & delete those.
        Set <String> setDomainId = new Set <String>();

        //Below for loop is used to create sobject out of model object
        for (HqIntModelProjectSpaceMetadata projectSpaceMetadata : projectSpaceMetadataList) {
            Domain__c domainRec = projectSpaceMetadata.domain_properties.createDbObject(projectSpaceMetadata.calculated_properties);
            domainRec.offset__c = offsetParam;
            listDomainRec.add(domainRec);
            setDomainId.add(domainRec.id__c);

            Internal_Properties__c InternalPropRec = projectSpaceMetadata.domain_properties.internal.createDbObject();
            listInternalPropRec.add(InternalPropRec);

            Deployment__c deploymentRec = projectSpaceMetadata.domain_properties.deployment.createDbObject();
            listDeploymentRec.add(deploymentRec);
               
        }
        System.debug('----offsetParam---'+offsetParam);
        //insert the sobjects except domain sobject
        insert listInternalPropRec;
        insert listDeploymentRec;

        List <Internal_Properties__c> listInternalPropToBeDeleted = new List <Internal_Properties__c>();
        List <Deployment__c> listDeploymentToBeDeleted = new List <Deployment__c>();

        //fetch exisiting sf id of deployment and internal prop for deletion.
        for (Domain__c domain : [SELECT id,Internal_Properties__c,Deployment__c from Domain__c WHERE id__c in :setDomainId]) {
            if(domain.Internal_Properties__c != null) {
                Internal_Properties__c 	InternalPropRec = new Internal_Properties__c(id=domain.Internal_Properties__c);
                listInternalPropToBeDeleted.add(InternalPropRec);
            }
            if(domain.Deployment__c != null) {
                Deployment__c deploymentRec = new Deployment__c(id=domain.Deployment__c);
                listDeploymentToBeDeleted.add(deploymentRec);
            }
        }
        //delete existing int prop and deployment records
        delete listInternalPropToBeDeleted;
        delete listDeploymentToBeDeleted;

        //populate the lookup fields on domain obect
        for (integer i=0;i<listDeploymentRec.size();i++) {
            listDomainRec[i].Internal_Properties__c = listInternalPropRec[i].id;
            listDomainRec[i].Deployment__c = listDeploymentRec[i].id;
        }

        //Finally do an upsert on the domain record list
        upsert listDomainRec id__c;

        return null;
    }

    /**
     * Method Name : ReplaceReservedWords
     * Purpose : In json string, some fields will be reserved / not allowed keywords. This method will replace those with alternate names
     **/
    private string ReplaceReservedWords(string myString) {
       myString = myString.replaceAll('"_id"\\s*:', '"x_id":');
       myString = myString.replaceAll('"public"\\s*:', '"x_Public":');
       myString = myString.replaceAll('"date"\\s*:', '"x_date":');
       //myString = myString.replaceAll('"currency"\\s*:', '"x_currency":');
       return myString;
    }
}