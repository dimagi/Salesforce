@IsTest
public class SendEmailWithReplyToTest {

    @IsTest
    static void testSendEmails_SingleEmail() {
        List<SendEmailWithReplyTo.EmailRequest> requests = new List<SendEmailWithReplyTo.EmailRequest>();

        SendEmailWithReplyTo.EmailRequest req = new SendEmailWithReplyTo.EmailRequest();
        req.toAddress = 'test@example.com';
        req.ccAddress = 'cc@example.com';
        req.senderDisplayName = 'Test Sender';
        req.replyToAddress = 'replyto@example.com';
        req.subject = 'Test Subject';
        req.body = '<p>Hello!</p>';
        req.isHtml = true;

        requests.add(req);

        Test.startTest();
        SendEmailWithReplyTo.sendEmails(requests);
        Test.stopTest();
    }

    @IsTest
    static void testSendEmails_MultipleEmails_Batched() {
        List<SendEmailWithReplyTo.EmailRequest> requests = new List<SendEmailWithReplyTo.EmailRequest>();

        for (Integer i = 0; i < 25; i++) {
            SendEmailWithReplyTo.EmailRequest req = new SendEmailWithReplyTo.EmailRequest();
            req.toAddress = 'user' + i + '@example.com';
            req.ccAddress = 'cc' + i + '@example.com';
            req.senderDisplayName = 'Batch Sender';
            req.replyToAddress = 'reply@example.com';
            req.subject = 'Batch Email #' + i;
            req.body = 'Hello from batch #' + i;
            req.isHtml = false;
            requests.add(req);
        }

        Test.startTest();
        SendEmailWithReplyTo.sendEmails(requests);
        Test.stopTest();
    }

    @IsTest
    static void testSendEmails_SkipEmptyToAddress() {
        List<SendEmailWithReplyTo.EmailRequest> requests = new List<SendEmailWithReplyTo.EmailRequest>();

        SendEmailWithReplyTo.EmailRequest req1 = new SendEmailWithReplyTo.EmailRequest();
        req1.toAddress = '';
        req1.ccAddress = 'cc@example.com';
        req1.senderDisplayName = 'Skip Test';
        req1.replyToAddress = 'reply@example.com';
        req1.subject = 'Should Skip';
        req1.body = 'This should be skipped';
        req1.isHtml = false;

        requests.add(req1);

        Test.startTest();
        SendEmailWithReplyTo.sendEmails(requests);
        Test.stopTest();
    }
}