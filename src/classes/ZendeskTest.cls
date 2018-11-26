@isTest
public class ZendeskTest {

     @testSetup
     public static void setUpTestData() {
         Dimagi_Zendesk_Settings__c settings = Dimagi_Zendesk_Settings__c.getOrgDefaults();
         settings.Username__c = 'test@username.com';
         settings.Password__c = 'hidden_password';
         settings.Zendesk_Endpoint__c = 'https://test.zendesk.com/api/v2/search.json';
         settings.Plan_List__c = 'Enterprise,Advanced,Pro,Standard,Community,Staff,ICDS';
         insert settings;
     }

    @isTest
    public static void shouldSyncAllPlans() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZendeskAPIMock());
        ZendeskSynchronizer.fetchZendeskTicketCount(2018, 9);
        Test.stopTest();
        assertZendeskData(Date.newInstance(2018, 9, 30));
    }

    @isTest
    public static void shouldSyncAllPlansWithFuture() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZendeskAPIMock());
        ZendeskSynchronizer.fetchZendeskTicketCountFuture(2018, 9);
        Test.stopTest();
        assertZendeskData(Date.newInstance(2018, 9, 30));
    }

    @isTest
    public static void shouldSetProperDate() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZendeskAPIMock());
        ZendeskScheduler zendeskScheduler = new ZendeskScheduler();
        zendeskScheduler.execute(null);
        Test.stopTest();
        Date testDate = Date.today().addDays(-1);
        Date expectedDate = Date.newInstance(testDate.year(), testDate.month(), Date.daysInMonth(testDate.year(), testDate.month()));
        assertZendeskData(expectedDate); // it is scheduled at 1st of each month
    }

    @isTest
    public static void shouldThrowErrorException() {
        Boolean wasException = false;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZendeskAPIMock(500));

        ZendeskAPI zendeskAPI = new ZendeskAPI(Dimagi_Zendesk_Settings__c.getOrgDefaults());
        try {
            zendeskAPI.httpGet('test query string');
        } catch(Exception e) {
            wasException = true;
        }
        Test.stopTest();

        System.assert(wasException);
    }

    @isTest
    public static void shouldHandleError() {
        Boolean wasException = false;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZendeskAPIMock(500));
        ZendeskSynchronizer.fetchZendeskTicketCount(2018, 9);
        Test.stopTest();

        System.assert([SELECT Id FROM Status_Log__c WHERE Name =: StatusLoggerUtils.ZENDESK_LOGGER AND Status__c =: StatusLoggerUtils.ERROR_LOG].size() == 1);
    }

    private static void assertZendeskData(Date testDate) {
        System.assertEquals(7, [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c].size());

        Zendesk_Tickets_Statistics__c zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Enterprise'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(12, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Advanced'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(5, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Pro'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(10, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Standard'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(22, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Community'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(15, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'Staff'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(3, zendeskStats.Number_of_Tickets_Created__c);

        zendeskStats = [SELECT Id, Number_of_Tickets_Created__c, Date__c FROM Zendesk_Tickets_Statistics__c WHERE Plan__c = 'ICDS'];
        System.assertEquals(testDate, zendeskStats.Date__c);
        System.assertEquals(1, zendeskStats.Number_of_Tickets_Created__c);
    }

    public class ZendeskAPIMock implements HttpCalloutMock {

        private Integer httpStatus;

        public ZendeskAPIMock() {
            this(200);
        }

        public ZendeskAPIMock(Integer httpStatus) {
            this.httpStatus = httpStatus;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.httpStatus);
            String endpoint = req.getEndpoint();
            System.debug('Zendesk Sync Endpoint : ' + endpoint);
            String body;

            if (this.httpStatus == 500) {
                body = 'Internal server error';
            } else if (req.getEndpoint().endsWith('plan:Enterprise')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":12}';
            } else if (req.getEndpoint().endsWith('plan:Advanced')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":5}';
            } else if (req.getEndpoint().endsWith('plan:Pro')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":10}';
            } else if (req.getEndpoint().endsWith('plan:Standard')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":22}';
            } else if (req.getEndpoint().endsWith('plan:Community')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":15}';
            } else if (req.getEndpoint().endsWith('plan:Staff')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":3}';
            } else if (req.getEndpoint().endsWith('plan:ICDS')) {
                body = '{"results":[{"url":"https://test.zendesk.com/api/v2/tickets/11.json","id":11,"external_id":null,"via":{"channel":"email","source":{"from":{"address":"tt.tt@tt.org","name":"Test Name"},"to":{"name":"TT","address":"comsupport0@test.com"},"rel":null}},"created_at":"2018-10-18T08:33:14Z","updated_at":"2018-10-18T08:34:17Z","type":"incident","subject":"(<no domain>)","raw_subject":"(<no domain>)","description":"test\ngg\n\nMessage:\n\n\n\n\ndatetime: 2018-10-18 08:33:0.","priority":"normal","status":"open","recipient":"ss-test@test.com","requester_id":1,"submitter_id":1,"assignee_id":1,"organization_id":1,"group_id":1,"collaborator_ids":[],"follower_ids":[],"email_cc_ids":[],"forum_topic_id":null,"problem_id":5176,"has_incidents":false,"is_public":true,"due_at":null,"tags":["1_enterprise","data_exports","english","saas"],"custom_fields":[{"id":66,"value":"1_enterprise"},{"id":1,"value":"data_exports"},{"id":8,"value":"saas"},{"id":66,"value":null},{"id":9,"value":"english"},{"id":9,"value":null},{"id":9,"value":null}],"satisfaction_rating":{"score":"unoffered"},"sharing_agreement_ids":[],"fields":[{"id":7,"value":"1_enterprise"},{"id":6,"value":"data_exports"},{"id":5,"value":"saas"},{"id":4,"value":null},{"id":3,"value":"english"},{"id":2,"value":null},{"id":1,"value":null}],"followup_ids":[],"brand_id":9,"allow_channelback":false,"allow_attachments":true,"result_type":"ticket"}],"facets":null,"next_page":null,"previous_page":null,"count":1}';
            }

            System.debug('Mock body : ' + body);
            res.setBody(body);
            return res;
        }
    }
}