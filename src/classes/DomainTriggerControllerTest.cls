@isTest
public class DomainTriggerControllerTest {

    @testSetup
    public static void setupCustomSetting() {
        Business_Unit__c bunit = new Business_Unit__c();
        bunit.Name = 'Test';
        insert bunit; 

        Account acc1 = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc1;
        Account acc2 = new Account(Name = 'Acc 2 Test', Status__c = 'Active');
        insert acc2;
        Account acc3 = new Account(Name = 'Acc 3 NY', Status__c = 'Active');
        insert acc3;
        Opportunity opp1 = new Opportunity(Name = 'opp1', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc1.Id);
        insert opp1;
        Opportunity opp2 = new Opportunity(Name = 'opp2', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id);
        insert opp2;
        Opportunity opp3 = new Opportunity(Name = 'opp3', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id);
        insert opp3;
        Opportunity opp4 = new Opportunity(Name = 'opp4', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc3.Id);
        insert opp4;
        Opportunity opp5 = new Opportunity(Name = 'opp5', StageName = 'Stage 1 - Connect', CloseDate = Date.today().addDays(50),
                                          Implementing_Business_Unit__c = bunit.Id, AccountId = acc1.Id);
        insert opp5;


        Contact c1 = new Contact(Title = 'Test Contact 1', Department = 'Account', Email = 'test2@test.com', FirstName = 'Test 1', LastName = 'Contact');
        Contact c2 = new Contact(Title = 'Test Contact 2', Department = 'Account', Email = 'test1@test.com', FirstName = 'Test 2', LastName = 'Contact');
        insert c1;
        insert c2;

        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = c1.Id, OpportunityId = opp1.Id, IsPrimary = true);
        OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId = c2.Id, OpportunityId = opp2.Id, IsPrimary = true);
        insert ocr1;
        insert ocr2;

        HQSyncDomainModel.DomainModel d1 = new HQSyncDomainModel.DomainModel();
        d1.x_id = 'sample_external_id_1';
        d1.Name = 'd1';
        d1.tags = new List<String> { ' ' };
        Domain__c domainFromDb1 = d1.createDbObject('CommCare HQ', null);
        domainFromDb1.Opportunity__c = opp3.Id;
        domainFromDb1.date_created__c = DateTime.now().addDays(-7);
        insert domainFromDb1;
        HQSyncDomainModel.DomainModel d2 = new HQSyncDomainModel.DomainModel();
        d2.x_id = 'sample_external_id_2';
        d2.Name = 'd2';
        d2.tags = new List<String> { ' ' };
        Domain__c domainFromDb2 = d2.createDbObject('CommCare HQ', null);
        domainFromDb2.Account__c = acc2.Id;
        domainFromDb2.date_created__c = DateTime.now().addDays(-7);
        insert domainFromDb2;
        HQSyncDomainModel.DomainModel d3 = new HQSyncDomainModel.DomainModel();
        d3.x_id = 'sample_external_id_3';
        d3.Name = 'd3';
        d3.tags = new List<String> { ' ' };
        Domain__c domainFromDb3 = d3.createDbObject('CommCare HQ', null);
        domainFromDb3.Opportunity__c = opp1.Id;
        domainFromDb3.date_created__c = DateTime.now().addDays(-7);
        insert domainFromDb3;
        HQSyncDomainModel.DomainModel d4 = new HQSyncDomainModel.DomainModel();
        d4.x_id = 'sample_external_id_4';
        d4.Name = 'd4';
        d4.tags = new List<String> { ' ' };
        Domain__c domainFromDb4 = d4.createDbObject('CommCare HQ', null);
        domainFromDb4.Opportunity__c = opp4.Id;
        domainFromDb4.Account__c = acc3.Id;
        domainFromDb4.date_created__c = DateTime.now().addDays(-7);
        insert domainFromDb4;
        HQSyncDomainModel.DomainModel d5 = new HQSyncDomainModel.DomainModel();
        d5.x_id = 'sample_external_id_5';
        d5.Name = 'd5';
        d5.tags = new List<String> { ' ' };
        Domain__c domainFromDb5 = d5.createDbObject('CommCare HQ', null);
        domainFromDb5.Opportunity__c = opp1.Id;
        domainFromDb5.Account__c = acc3.Id;
        domainFromDb5.date_created__c = DateTime.now().addDays(-7);
        insert domainFromDb5;
    }

    @isTest
    public  static void shouldSetPrimaryContactAndAccountOnDomain() {
        Domain__c domainFromDb1 = [SELECT Id, Opportunity__c FROM Domain__c WHERE Name = 'd1'];
        Domain__c domainFromDb2 = [SELECT Id, Opportunity__c FROM Domain__c WHERE Name = 'd2'];
        Domain__c domainFromDb3 = [SELECT Id, Opportunity__c FROM Domain__c WHERE Name = 'd3'];
        Domain__c domainFromDb4 = [SELECT Id, Opportunity__c FROM Domain__c WHERE Name = 'd4'];
        Domain__c domainFromDb5 = [SELECT Id, Opportunity__c FROM Domain__c WHERE Name = 'd5'];

        Test.startTest();
        domainFromDb1.Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'opp1'].Id;
        domainFromDb2.Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'opp2'].Id;
        domainFromDb3.Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'opp3'].Id;
        domainFromDb4.Opportunity__c = null;
        domainFromDb5.Opportunity__c = [SELECT Id FROM Opportunity WHERE Name = 'opp5'].Id;
        List<Domain__c> toUpdate = new List<Domain__c>();
        toUpdate.add(domainFromDb1);
        toUpdate.add(domainFromDb2);
        toUpdate.add(domainFromDb3);
        toUpdate.add(domainFromDb4);
        toUpdate.add(domainFromDb5);
        update toUpdate;
        Test.stopTest();

        Domain__c assertDomain = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Name, Account__c, Account__r.Name FROM Domain__c WHERE Id =: domainFromDb1.Id];
        System.assertEquals('Test 1 Contact', assertDomain.Primary_Contact__r.Name);
        System.assertEquals('Acc 1', assertDomain.Account__r.Name);

        assertDomain = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Name, Account__c, Account__r.Name FROM Domain__c WHERE Id =: domainFromDb2.Id];
        System.assertEquals('Test 2 Contact', assertDomain.Primary_Contact__r.Name);
        System.assertEquals('Acc 2 Test', assertDomain.Account__r.Name);

        assertDomain = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Name, Account__c, Account__r.Name FROM Domain__c WHERE Id =: domainFromDb3.Id];
        System.assertEquals(null, assertDomain.Primary_Contact__c);
        System.assertEquals(null, assertDomain.Account__c);

        assertDomain = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Name, Account__c, Account__r.Name FROM Domain__c WHERE Id =: domainFromDb4.Id];
        System.assertEquals(null, assertDomain.Primary_Contact__c);
        System.assertEquals('Acc 3 NY', assertDomain.Account__r.Name);

        assertDomain = [SELECT Id, Primary_Contact__c, Primary_Contact__r.Name, Account__c, Account__r.Name FROM Domain__c WHERE Id =: domainFromDb5.Id];
        System.assertEquals(null, assertDomain.Primary_Contact__c);
        System.assertEquals('Acc 1', assertDomain.Account__r.Name);
    }

    @isTest
    public static void shouldDeactivateDuplicatedDomains() {
        insertDomain('d1', 'sample_external_id_1_d', DateTime.now().addDays(-1));
        insertDomain('d2', 'sample_external_id_2_d', DateTime.now().addDays(-8));
        insertDomain('d3', 'sample_external_id_3_d', DateTime.now().addDays(-1));
        insertDomain('d3', 'sample_external_id_3_dd', DateTime.now().addDays(-2));
        insertDomain('d3', 'sample_external_id_3_ddd', DateTime.now().addDays(-3));

        Test.startTest();
        Database.executeBatch(new DomainDeactivationBatch());
        Test.stopTest();

        System.assertEquals(5, [SELECT Id FROM Domain__c WHERE Domain_Deleted__c = true].size());
        System.assertEquals(3, [SELECT Id FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd3'].size());
        System.assertEquals(5, [SELECT Id FROM Domain__c WHERE Domain_Deleted__c = false].size());

        Domain__c assertDomain = [SELECT Id, id__c FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd1'];
        System.assertEquals('sample_external_id_1', assertDomain.id__c);
        assertDomain = [SELECT Id, Opportunity__r.Name FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd1'];
        System.assertEquals('opp3', assertDomain.Opportunity__r.Name);

        assertDomain = [SELECT Id, id__c FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd2'];
        System.assertEquals('sample_external_id_2_d', assertDomain.id__c);
        assertDomain = [SELECT Id, Account__r.Name FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd2'];
        System.assertEquals('Acc 2 Test', assertDomain.Account__r.Name);

        assertDomain = [SELECT Id, id__c FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd3' AND id__c = 'sample_external_id_3'];
        System.assertEquals('sample_external_id_3', assertDomain.id__c);
        assertDomain = [SELECT Id, id__c FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd3' AND id__c = 'sample_external_id_3_dd'];
        System.assertEquals('sample_external_id_3_dd', assertDomain.id__c);
        assertDomain = [SELECT Id, id__c FROM Domain__c WHERE Domain_Deleted__c = true AND Name = 'd3' AND id__c = 'sample_external_id_3_ddd'];
        System.assertEquals('sample_external_id_3_ddd', assertDomain.id__c);
        assertDomain = [SELECT Id, Opportunity__r.Name FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd3'];
        System.assertEquals('opp1', assertDomain.Opportunity__r.Name);
    }

    @isTest
    public static void should() {
        Domain__c d1 = [SELECT Id FROM Domain__c WHERE Name = 'd1'];
        Domain__c d2 = [SELECT Id FROM Domain__c WHERE Name = 'd2'];
        Domain__c d3 = [SELECT Id FROM Domain__c WHERE Name = 'd3'];
        Domain__c d4 = [SELECT Id FROM Domain__c WHERE Name = 'd4'];
        Domain__c d5 = [SELECT Id FROM Domain__c WHERE Name = 'd5'];
        DContract__c contract1 = new DContract__c(Name = 'Simple Contract 1');
        DContract__c contract2 = new DContract__c(Name = 'Simple Contract 2');
        DContract__c contract3 = new DContract__c(Name = 'Simple Contract 3');
        insert new List<DContract__c> { contract1, contract2, contract3 };
        insert new List<Contract_Domain__c> { new Contract_Domain__c(Contract__c = contract1.Id, Domain__c = d2.Id),
                                              new Contract_Domain__c(Contract__c = contract2.Id, DOmain__c = d2.Id) };

        Lead l1 = new Lead(FirstName = 'Tom', LastName = 'Smith', Company = 'Smith IT Company', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Working - Talking', Follow_up_calls_held__c = 1);
        Lead l2 = new Lead(FirstName = 'Tom 1', LastName = 'Smith 1', Company = 'Smith IT Company 1', Lead_Status_Reason__c = 'Working - Exploratory Call - Trying for',
                                  Status = 'Passive & Friendly', Follow_up_calls_held__c = 88);
        insert new List<Lead> { l1, l2 };

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l1.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        Accounting_Invoice__c inv1 = new Accounting_Invoice__c(id__c = '1', Server_Name__c = 'CommCare HQ', Project_Space__c = d1.Id);
        Accounting_Invoice__c inv2 = new Accounting_Invoice__c(id__c = '2', Server_Name__c = 'CommCare HQ', Project_Space__c = d2.Id);
        Accounting_Invoice__c inv3 = new Accounting_Invoice__c(id__c = '1', Server_Name__c = 'CommCare HQ', Project_Space__c = d3.Id, Invoice_Type__c = HQSyncUtils.CUSTOMER_INVOICE);
        Accounting_Invoice__c inv4 = new Accounting_Invoice__c(id__c = '2', Server_Name__c = 'CommCare HQ', Project_Space__c = d5.Id, Invoice_Type__c = HQSyncUtils.CUSTOMER_INVOICE);
        insert new List<Accounting_Invoice__c> { inv1, inv2, inv3, inv4 };

        Domain__c domainFromDb1 = insertDomain('d1', 'sample_external_id_1_d', DateTime.now().addDays(-3));
        Accounting_Subscriber__c subsc1 = new Accounting_Subscriber__c(domain__c = 'd1', Server_Name__c = 'CommCare HQ', domain_lookup__c = d1.Id);
        Accounting_Subscriber__c subsc2 = new Accounting_Subscriber__c(domain__c = 'd2', Server_Name__c = 'CommCare HQ', domain_lookup__c = d2.Id);
        Accounting_Subscriber__c subsc3 = new Accounting_Subscriber__c(domain__c = 'd1', Server_Name__c = 'CommCare HQ', domain_lookup__c = domainFromDb1.Id);
        Accounting_Subscriber__c subsc4 = new Accounting_Subscriber__c(domain__c = 'd4', Server_Name__c = 'CommCare HQ', domain_lookup__c = d4.Id);
        Accounting_Subscriber__c subsc5 = new Accounting_Subscriber__c(domain__c = 'd1', Server_Name__c = 'CommCare HQ', domain_lookup__c = d1.Id);
        insert new List<Accounting_Subscriber__c> { subsc1, subsc2, subsc3, subsc4, subsc5 };

        Accounting_Subscription__c subscr1 = new Accounting_Subscription__c(is_hidden_to_ops__c = false, is_trial__c = false, auto_generate_credits__c = true, is_active__c = true, do_not_invoice__c = false,
                                                                            Accounting_subscriber_domain__c = d1.Id, Accounting_Subscriber__c = subsc1.Id, Server_Name__c = 'CommCare HQ');
        Accounting_Subscription__c subscr2 = new Accounting_Subscription__c(is_hidden_to_ops__c = false, is_trial__c = false, auto_generate_credits__c = true, is_active__c = true, do_not_invoice__c = false,
                                                                            Accounting_subscriber_domain__c = d2.Id, Accounting_Subscriber__c = subsc2.Id, Server_Name__c = 'CommCare HQ');
        Accounting_Subscription__c subscr3 = new Accounting_Subscription__c(is_hidden_to_ops__c = false, is_trial__c = false, auto_generate_credits__c = true, is_active__c = true, do_not_invoice__c = false,
                                                                            Accounting_subscriber_domain__c = domainFromDb1.Id, Accounting_Subscriber__c = subsc3.Id, Server_Name__c = 'CommCare HQ');
        Accounting_Subscription__c subscr4 = new Accounting_Subscription__c(is_hidden_to_ops__c = false, is_trial__c = false, auto_generate_credits__c = true, is_active__c = true, do_not_invoice__c = false,
                                                                            Accounting_subscriber_domain__c = d4.Id, Accounting_Subscriber__c = subsc4.Id, Server_Name__c = 'CommCare HQ');
        Accounting_Subscription__c subscr5 = new Accounting_Subscription__c(is_hidden_to_ops__c = false, is_trial__c = false, auto_generate_credits__c = true, is_active__c = true, do_not_invoice__c = false,
                                                                            Accounting_subscriber_domain__c = d1.Id, Accounting_Subscriber__c = subsc5.Id, Server_Name__c = 'CommCare HQ');
        insert new List<Accounting_Subscription__c> { subscr1, subscr2, subscr3, subscr4, subscr5 };

        Country__c c1 = new Country__c(Name = 'country 1');
        Country__c c2 = new Country__c(Name = 'country 2');
        Country__c c3 = new Country__c(Name = 'country 3');
        insert new List<Country__c> { c1, c2, c3 };

        domainFromDb1.Country_of_deployment_salesforce__c = c3.Id;
        update domainFromDb1;
        Domain__c domainFromDb2 = insertDomain('d1', 'sample_external_id_1_dd', DateTime.now().addDays(-2));
        domainFromDb2.Lead__c = l2.Id;
        domainFromDb2.Primary_Contact__c = [SELECT Id FROM Contact WHERE Name = 'Test 2 Contact'].Id;
        update domainFromDb2;
        Domain__c domainFromDb3 = insertDomain('d1', 'sample_external_id_1_ddd', DateTime.now().addDays(-1));
        Domain__c domainFromDb4 = insertDomain('d2', 'sample_external_id_2_d', DateTime.now().addDays(-2));
        Domain__c domainFromDb5 = insertDomain('d3', 'sample_external_id_3_d', DateTime.now().addDays(-2));
        Domain__c domainFromDb6 = insertDomain('d4', 'sample_external_id_4_d', DateTime.now().addDays(-2));
        Domain__c domainFromDb7 = insertDomain('d5', 'sample_external_id_5_d', DateTime.now().addDays(-2));

        d2.Opportunity__c = [SELECT Id FROM Opportunity Where Name = 'opp3'].Id;
        d2.Lead__c = l1.Id;
        d2.Primary_Contact__c = [SELECT Id FROM Contact WHERE Name = 'Test 1 Contact'].Id;
        d2.Country_of_deployment_salesforce__c = c1.Id;
        update d2;

        Test.startTest();
        Database.executeBatch(new DomainDeactivationBatch());
        Test.stopTest();

        System.assertEquals(5, [SELECT Id FROM Domain__c WHERE Domain_Deleted__c = false].size());

        // domain 1
        Domain__c  assertDomain = [SELECT Id, id__c, Account__r.Name, Opportunity__r.Name, Lead__c, Primary_Contact__r.Name, Country_of_deployment_salesforce__c FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd1'];
        System.assertEquals('sample_external_id_1_ddd', assertDomain.id__c);
        System.assertEquals('Test 2 Contact', assertDomain.Primary_Contact__r.Name);
        System.assertEquals('opp3', assertDomain.Opportunity__r.Name);
        System.assertEquals(l2.Id, assertDomain.Lead__c);
        System.assertEquals(c3.id, assertDomain.Country_of_deployment_salesforce__c);
        System.assertEquals(1, [SELECT Id FROM Accounting_Invoice__c WHERE Project_Space__c =: domainFromDb3.Id].size());
        System.assertEquals(3, [SELECT Id FROM Accounting_Subscriber__c WHERE domain_lookup__c =: domainFromDb3.Id].size());
        System.assertEquals(3, [SELECT Id FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c =: domainFromDb3.Id].size());
        // domain 2
        assertDomain = [SELECT Id, id__c, Account__r.Name, Opportunity__r.Name, Lead__c, Primary_Contact__r.Name, Country_of_deployment_salesforce__c FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd2'];
        System.assertEquals('sample_external_id_2_d', assertDomain.id__c);
        System.assertEquals('Acc 2 Test', assertDomain.Account__r.Name);
        System.assertEquals('opp3', assertDomain.Opportunity__r.Name);
        System.assertEquals(l1.Id, assertDomain.Lead__c);
        System.assertEquals('Test 1 Contact', assertDomain.Primary_Contact__r.Name);
        System.assertEquals(c1.id, assertDomain.Country_of_deployment_salesforce__c);
        Accounting_Invoice__c inv = [SELECT Id, Project_Space__c FROM Accounting_Invoice__c WHERE Project_Space__c =: domainFromDb4.Id];
        Accounting_Subscriber__c scr = [SELECT Id, domain_lookup__c FROM Accounting_Subscriber__c WHERE domain_lookup__c =: domainFromDb4.Id];
        Accounting_Subscription__c scrp = [SELECT Id, Accounting_subscriber_domain__c FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c =: domainFromDb4.Id];
        System.assertEquals(inv2.Id, inv.Id);
        System.assertEquals(subsc2.Id, scr.Id);
        System.assertEquals(subscr2.Id, scrp.Id);
        System.assertEquals(2, [SELECT Id FROM Contract_Domain__c WHERE Domain__c =: domainFromDb4.Id AND Contract__c IN: new List<DContract__c> { contract1, contract2 }].size());

        // domain 3
        assertDomain = [SELECT Id, id__c, Account__r.Name, Opportunity__r.Name, Lead__c, Primary_Contact__r.Name, Country_of_deployment_salesforce__c FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd3'];
        System.assertEquals('sample_external_id_3_d', assertDomain.id__c);

        // domain 4
        assertDomain = [SELECT Id, id__c, Account__r.Name, Opportunity__r.Name, Lead__c, Primary_Contact__r.Name, Country_of_deployment_salesforce__c FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd4'];
        System.assertEquals('sample_external_id_4_d', assertDomain.id__c);

        // domain 5
        assertDomain = [SELECT Id, id__c, Account__r.Name, Opportunity__r.Name, Lead__c, Primary_Contact__r.Name, Country_of_deployment_salesforce__c FROM Domain__c WHERE Domain_Deleted__c = false AND Name = 'd5'];
        System.assertEquals('sample_external_id_5_d', assertDomain.id__c);
    }

    public static Domain__c insertDomain(String name, String hqId, DateTime dc) {
        HQSyncDomainModel.DomainModel d = new HQSyncDomainModel.DomainModel();
        d.x_id = hqId;
        d.Name = name;
        d.tags = new List<String> { ' ' };
        Domain__c ddb = d.createDbObject('CommCare HQ', null);
        ddb.date_created__c = dc;
        insert ddb;
        return ddb;
    }
}