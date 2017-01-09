global class hqInt_MainClass {

    private Integer offsetParameter;
    private CommcareToSalesforceSettings__c serverSettings;

    public hqInt_MainClass(CommcareToSalesforceSettings__c serverSettings) {
        this.serverSettings = serverSettings;
    }

    global void mainMethod(Integer offsetParameter, CommcareToSalesforceSettings__c serverSettings) {
        this.offsetParameter = offsetParameter;
        HTTPResponse res = requestMethod();

        String response = res.getBody();
        System.debug('--- res --- ' + response);
        response = ReplaceReservedWords(response);

        processJson(response);
    }

    /**
     * Method Name : requestMethod
     * Purpose : Http Callout to CommCareHQ
     **/
    public HTTPResponse requestMethod() {
        /**Integer limitParameter = this.serverSettings.API_Limit_Parameter__c != null ? Integer.valueOf(serverSettings.API_Limit_Parameter__c)
                            : 10;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(this.serverSettings.Server_URL__c + 'project_space_metadata/?limit=' + String.valueOf(limitParameter)
                        + '&offset=' + String.valueOf(this.offsetParameter));
        req.setMethod('GET');

        // Specify the required user name and password to access the endpoint
        // As well as the header and header information

        String username = this.serverSettings.CommCare_User_Name__c;
        String password = this.serverSettings.CommCare_Password__c;

        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setTimeout(120000);

        // Create a new http object to send the request object
        // A response object is generated as a result of the request

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('--- status --' + res.getStatusCode());
        if(res.getStatusCode() != 200) {
            Exception e = new CalloutException();
            e.setMessage('Http request error, cannot fetch Domains data. Http status : ' + res.getStatusCode() + ' Body : ' + res.getBody());
            throw e;
        }

*/
        return null;
    }

    /**
     * Method Name : processJson
     * Purpose : Process Json response and perform DML 
     **/
    private void processJson(String jsonString) {
        /**List <HqIntModelProjectSpaceMetadata> projectSpaceMetadataList = new List <HqIntModelProjectSpaceMetadata>();
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
                        HqIntModelProjectSpaceMetadata projectSpaceMetadata = (HqIntModelProjectSpaceMetadata)parser.readValueAs(HqIntModelProjectSpaceMetadata.class);
                        projectSpaceMetadataList.add(projectSpaceMetadata);
                   }
                }
            }
        }

        //Set for holding the external id field for domain object. It is used to fetch existing internal prop & deployment rec & delete those.
        Set<String> setDomainId = new Set<String>();

        //Below for loop is used to create sobject out of model object
        for (HqIntModelProjectSpaceMetadata projectSpaceMetadata : projectSpaceMetadataList) {
            Domain__c domainRec = projectSpaceMetadata.domain_properties.createDbObject(projectSpaceMetadata.calculated_properties, this.serverSettings.Name);
            domainRec.offset__c = this.offsetParam;
            listDomainRec.add(domainRec);
            setDomainId.add(domainRec.id__c);

            Internal_Properties__c InternalPropRec = projectSpaceMetadata.domain_properties.internal.createDbObject(this.serverSettings.Name);
            listInternalPropRec.add(InternalPropRec);

            Deployment__c deploymentRec = projectSpaceMetadata.domain_properties.deployment.createDbObject(this.serverSettings.Name);
            listDeploymentRec.add(deploymentRec);
        }

        System.debug('----this.offsetParam---' + this.offsetParam);
        //insert the sobjects except domain sobject
        insert listInternalPropRec;
        insert listDeploymentRec;

        List <Internal_Properties__c> listInternalPropToBeDeleted = new List <Internal_Properties__c>();
        List <Deployment__c> listDeploymentToBeDeleted = new List <Deployment__c>();

        //fetch exisiting sf id of deployment and internal prop for deletion.
        for (Domain__c domain : [SELECT Id, Internal_Properties__c, Deployment__c from Domain__c WHERE id__c in :setDomainId AND ServerName__c =: this.serverSettings.Name]) {
            if(domain.Internal_Properties__c != null) {
                Internal_Properties__c InternalPropRec = new Internal_Properties__c(Id = domain.Internal_Properties__c);
                listInternalPropToBeDeleted.add(InternalPropRec);
            }
            if(domain.Deployment__c != null) {
                Deployment__c deploymentRec = new Deployment__c(Id = domain.Deployment__c);
                listDeploymentToBeDeleted.add(deploymentRec);
            }
        }

        //delete existing int prop and deployment records
        delete listInternalPropToBeDeleted;
        delete listDeploymentToBeDeleted;

        //populate the lookup fields on domain obect
        for (Integer i = 0; i < listDeploymentRec.size(); i++) {
            listDomainRec[i].Internal_Properties__c = listInternalPropRec[i].Id;
            listDomainRec[i].Deployment__c = listDeploymentRec[i].Id;
        }

        //Finally do an upsert on the domain record list
        upsert listDomainRec;*/
    }

    /**
     * Method Name : ReplaceReservedWords
     * Purpose : In json string, some fields will be reserved / not allowed keywords. This method will replace those with alternate names
     **/
    private string ReplaceReservedWords(String body) {
       body = body.replaceAll('"_id"\\s*:', '"x_id":');
       body = body.replaceAll('"public"\\s*:', '"x_Public":');
       body = body.replaceAll('"date"\\s*:', '"x_date":');
       return body;
    }
}