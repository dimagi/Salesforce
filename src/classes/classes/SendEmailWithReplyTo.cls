public class SendEmailWithReplyTo {
    public class EmailRequest {
        @InvocableVariable(required=true) public String toAddress;
        @InvocableVariable public String ccAddress;
        @InvocableVariable(required=true) public String senderDisplayName;
        @InvocableVariable(required=true) public String replyToAddress;
        @InvocableVariable(required=true) public String subject;
        @InvocableVariable(required=true) public String body;
        @InvocableVariable(required=true) public Boolean isHtml;
    }

    @InvocableMethod(label='Send Emails Safely')
    public static void sendEmails(List<EmailRequest> emailRequests) {
        if (emailRequests == null || emailRequests.isEmpty()) return;

        List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();

        for (EmailRequest req : emailRequests) {
            if (String.isBlank(req.toAddress)) continue;

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new List<String>{ req.toAddress });
            if (String.isNotBlank(req.ccAddress)) {
                msg.setCcAddresses(new List<String>{ req.ccAddress });
            }
            msg.setSenderDisplayName(req.senderDisplayName);
            msg.setReplyTo(req.replyToAddress);
            msg.setSubject(req.subject);

            if (req.isHtml) {
                msg.setHtmlBody(req.body);
            } else {
                msg.setPlainTextBody(req.body);
            }

            batch.add(msg);

            if (batch.size() == 5) {
                Messaging.sendEmail(batch, false);
                batch.clear();
            }
        }

        if (!batch.isEmpty()) {
            Messaging.sendEmail(batch, false);
        }
    }
}