/**
 * Custom SF loggers, it store data in DB and send email notifications.
 * TODO : Add styles to html table in email, like color.
 */
public class StatusLoggerUtils {

    public static final String INFO_LOG = 'INFO';               // Status about jobs/future/sync/code execution
    public static final String ERROR_LOG = 'ERROR';             // Something was wrong, unexpected
    public static final String WARNING_LOG = 'WARN';            // Something need check in future
    public static final String LOGGER_SUBJECT = 'SF Logger : '; // SF logger subject prefix

    /**
     * Predefined loggers used in apex code. Use it to find logger usage.
     */
    public static final String HQ_SYNC_LOGGER = 'HQ_LOGGER';
    public static final String MALT_SYNC_LOGGER = 'MALT_LOGGER';
    public static final String GIR_SYNC_LOGGER = 'GIR_LOGGER';
    public static final String RENEWAL_LOGGER = 'RENEWAL_LOGGER';
    public static final String DOMAIN_SNP_LOGGER = 'DOMAIN_SNP_LOGGER';
    public static final String TIME_CARD_LOGGER = 'TIME_CARD_LOGGER';
    public static final String ZENDESK_LOGGER = 'ZENDESK_LOGGER';
    public static final String AEE_LOGGER = 'AGGREGATE_EXECUTION_EFFICIENCY_LOGGER';
    public static final String CASE_CREATE_LOGGER = 'SF_FB_CASE_LOGGER';

    /**
     * Logs INFO row for given log name.
     */
    public static void logInfo(String loggerName, String rowTitle, Integer counter, String message) {
        log(loggerName, rowTitle, counter, message, INFO_LOG);
    }

    /**
     * Logs WARNING row for given log name.
     */
    public static void logWarning(String loggerName, String rowTitle, Integer counter, String message) {
        log(loggerName, rowTitle, counter, message, WARNING_LOG);
    }

    /**
     * Logs ERROR row for given log name.
     */
    public static void logError(String loggerName, String rowTitle, Integer counter, String message) {
        log(loggerName, rowTitle, counter, message, ERROR_LOG);
    }

    /**
     * Logs data for given log name.
     */
    public static void log(String loggerName, String rowTitle, Integer counter, String message, String status) {
        String logMessage = message;
        if (message.length() > 255) {
            logMessage = logMessage.subString(0, 255);
        }
        insert new Status_Log__c(Name = loggerName, Title__c = rowTitle,
                                 Counter__c = counter, Message__c = logMessage,
                                 Date__c = DateTime.now(), Status__c = status);
    }

    /**
     * Returns true if errors was logged for given log name.
     */
    public static Boolean errorsForLogger(String logName) {
        return [SELECT Count() FROM Status_Log__c WHERE Name =: logName AND Status__c =: ERROR_LOG] > 0;
    }

    /**
     * Returns true if errors was logged for given log name and title.
     */
    public static Boolean errorsForLoggerWithTitle(String logName, String title) {
        return [SELECT Count() FROM Status_Log__c WHERE Name =: logName AND Status__c =: ERROR_LOG AND Title__c =: title] > 0;
    }

    /**
     * Returns true if errors was logged for given log name and different then given title.
     */
    public static Boolean errorsForLoggerWithoutTitle(String logName, String title) {
        return [SELECT Count() FROM Status_Log__c WHERE Name =: logName AND Status__c =: ERROR_LOG AND Title__c !=: title] > 0;
    }

    /**
     * Send email to default reciepients for given log name. After sanding an emails it removes logs with given log name from DB.
     */
    public static void sendLog(String logName) {
        sendLog(logName, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
    }

    /**
     * Send email to reciepients for given log name. After sanding an emails it removes logs with given log name from DB.
     */
    public static void sendLog(String logName, List<String> reciepients) {
        if (Test.isRunningTest()) {
            return;
        }

        List<Status_Log__c> logsInfo = [SELECT Title__c, Counter__c, Message__c, Date__c FROM Status_Log__c WHERE Name =: logName AND Status__c =: INFO_LOG ORDER BY Date__c DESC];
        List<Status_Log__c> logsWarns = [SELECT Title__c, Counter__c, Message__c, Date__c FROM Status_Log__c WHERE Name =: logName AND Status__c =: WARNING_LOG ORDER BY Date__c DESC];
        List<Status_Log__c> logsError = [SELECT Title__c, Counter__c, Message__c, Date__c FROM Status_Log__c WHERE Name =: logName AND Status__c =: ERROR_LOG ORDER BY Date__c DESC];

        String body = '<div><br/>INFO :<br/><table border="1">';
        body += '<tr style="font-weight:bold"><td>Name</td><td>Message</td><td>Num</td><td>Date</td></tr>';

        for (Status_Log__c log : logsInfo) {
            body += '<tr><td>' + log.Title__c + '</td><td>' + log.Message__c + '</td><td>' + log.Counter__c + '</td><td>' + log.Date__c + '</td></tr>';
        }

        body += '</table>';
        body += '<br/>WARNINGS :<br/><table border="1">';
        body += '<tr style="font-weight:bold"><td>Name</td><td>Message</td><td>Num</td><td>Date</td></tr>';

        for (Status_Log__c log : logsWarns) {
            body += '<tr><td>' + log.Title__c + '</td><td>' + log.Message__c + '</td><td>' + log.Counter__c + '</td><td>' + log.Date__c + '</td></tr>';
        }

        body += '</table>';
        body += '<br/>ERRORS :<br/><table border="1">';
        body += '<tr style="font-weight:bold"><td>Name</td><td>Message</td><td>Num</td><td>Date</td></tr>';

        for (Status_Log__c log : logsError) {
            body += '<tr><td>' + log.Title__c + '</td><td>' + log.Message__c + '</td><td>' + log.Counter__c + '</td><td>' + log.Date__c + '</td></tr>';
        }

        body += '</table></div>';
        body += '<br/>Send date : ' + DateTime.now() + '<br/>';

        EmailHelper.sendEmail(reciepients, LOGGER_SUBJECT + logName, body);
        clearData(logsInfo);
        clearData(logsWarns);
        clearData(logsError);
    }

    private static void clearData(List<Status_Log__c> dataList) {
        if (dataList.size() > 0) {
            delete dataList;
        }
    }
}