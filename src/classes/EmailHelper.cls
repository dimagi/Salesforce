/**
 * Helper class for sending emails about errors.
 */
public class EmailHelper {

    public static void sendEmails(List<String> addressList, String subject, List<String> emailsBody) {
        if (Test.isRunningTest()) {
            return;
        }

        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        Messaging.Email[] mails = new Messaging.Email[]{};

        for (String body : emailsBody) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if (orgWideAddress != null) {
                mail.setOrgWideEmailAddressId(orgWideAddress.Id);
            }

            mail.setToAddresses(addressList);
            mail.setHtmlBody(body);
            mail.setSubject(subject);
            mail.setSaveAsActivity(false);
            mails.add(mail);
        }

        Messaging.sendEmail(mails);
    }

    public static void sendEmail(String address, String subject, String body) {
        sendEmails(new String[] { address }, subject, new String[] { body });
    }

    public static void sendEmail(List<String> addressList, String subject, String body) {
        sendEmails(addressList, subject, new String[] { body });
    }

    public static void sendEmails(String address, String subject, List<String> emailsBody) {
        sendEmails(new String[] { address }, subject, emailsBody);
    }

    public static void sendEmailFromException(List<String> addressList, String subject, String head, Exception ex) {
        String content = head + '<br />' +
                        'Line: ' + ex.getLineNumber() + '<br />' +
                        'Type: ' + ex.getTypeName() + '<br />' +
                        'Message: ' + ex.getMessage() + '<br />' + 
                        'Stack Trace: ' + ex.getStackTraceString() + '<br />' +
                        'Cause by: ' + ex.getCause() + '<br />';
        sendEmail(addressList, subject, content);
    }

    public static void sendEmailFromDatabaseSaveResultErrors(List<String> addressList, String subject, String head, Database.SaveResult[] srList) {
        Boolean hadErrors = false;
        List<String> errorsList = new List<String> { '<table border="1"><tr><td>Error Message</td><td>Obj ID</tr>' };
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                hadErrors = true;
                for(Database.Error err : sr.getErrors()) {
                    errorsList.add('<tr><td>' + err.getMessage() + '</td><td>' + sr.getId() + '</td></tr>');
                }
            }
        }

        if (hadErrors == true) { // send email only when we had errors
            sendEmail(addressList, subject, head + '</ br></ br>' + String.join(errorsList, '') + '</table>');
        }
    }
}