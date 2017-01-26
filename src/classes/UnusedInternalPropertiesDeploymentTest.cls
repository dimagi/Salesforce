@isTest
public class UnusedInternalPropertiesDeploymentTest {

    static testMethod void shouldDeleteDeploymentRecords() {
        Test.startTest();
        Id deploymentObj1 = createDeployment('Dep_1');
        Id deploymentObj2 = createDeployment('Dep_2');
        Id deploymentObj3 = createDeployment('Dep_3');
        Id deploymentObj4 = createDeployment('Dep_4');
        Id deploymentObj5 = createDeployment('Dep_5');
        Id intProp1 = createInternalProperties('IntP_1');
        Id intProp2 = createInternalProperties('IntP_2');

        createDomainObject(1, deploymentObj1, intProp1);
        createDomainObject(5, deploymentObj5, intProp2);

        Database.executeBatch(new UnusedDeploymentDeleteBatch());
        Test.stopTest();

        List<Deployment__c> deps = [SELECT Id FROM Deployment__c];
        System.assertEquals(2, deps.size());
    }

    static testMethod void shouldDeleteInternalPropertiesRecords() {
        Test.startTest();
        Id deploymentObj1 = createDeployment('Dep_1');
        Id deploymentObj2 = createDeployment('Dep_2');
        Id deploymentObj3 = createDeployment('Dep_3');
        Id intProp1 = createInternalProperties('IntP_1');
        Id intProp2 = createInternalProperties('IntP_2');
        Id intProp3 = createInternalProperties('IntP_3');
        Id intProp4 = createInternalProperties('IntP_4');
        Id intProp5 = createInternalProperties('IntP_5');

        createDomainObject(1, deploymentObj1, intProp1);
        createDomainObject(2, deploymentObj2, intProp2);
        createDomainObject(3, deploymentObj3, intProp3);

        List<Internal_Properties__c> intPropsInDB = [SELECT Id FROM Internal_Properties__c];
        System.assertEquals(5, intPropsInDB.size());
        Database.executeBatch(new UnusedInternalPropertiesDeleteBatch());
        Test.stopTest();

        List<Internal_Properties__c> intProps = [SELECT Id FROM Internal_Properties__c];
        System.assertEquals(3, intProps.size());
    }

    static private Id createDeployment(String name) {
        Deployment__c deploymentObj = new Deployment__c(country__c = name);
        insert deploymentObj;
        return deploymentObj.Id;
    }

    static private Id createInternalProperties(String name) {
        Internal_Properties__c intProp = new Internal_Properties__c(area__c = name);
        insert intProp;
        return intProp.Id;
    }

    static private void createDomainObject(Integer i, Id dep, Id intProp) {
        hqInt_Model_DomainClass d = new hqInt_Model_DomainClass();
        d.x_id = 'domain_' + i;
        d.Name = 'domain_name_' + i;
        d.tags = new List<String> { ' ' };
        Domain__c domainFromDb = d.createDbObject(null, 'CommCareHQ');
        domainFromDb.Deployment__c = dep;
        domainFromDb.Internal_Properties__c = intProp;
        insert domainFromDb;
    }
}