/**
 * Zendesk synchronizer class used for fetch and add custom data from zendesk API.
 */
public class ZendeskSynchronizer {

    /**
     * Fetch and add records with # of tickets created in given motnh data from zendesk API. Created data used in Global Metrics graphs.
     */
    public static void fetchZendeskTicketCount(Integer year, Integer month) {
        Dimagi_Zendesk_Settings__c settings = Dimagi_Zendesk_Settings__c.getOrgDefaults();
        ZendeskAPI zendeskAPI = new ZendeskAPI(settings);
        List<String> softwarePlans = settings.Plan_List__c != null ? settings.Plan_List__c.split(',') : new List<String>();

        Date monthDate = Date.newInstance(year, month, Date.daysInMonth(year, month));
        Date startDate = Date.newInstance(year, month, 1).addDays(-1);
        Date endDate = Date.newInstance(year, month, Date.daysInMonth(year, month)).addDays(1);

        String queryString = 'type:ticket%20' +
                             'created>' + startDate.year() + '-' + startDate.month() + '-' + startDate.day() + '%20' +
                             'created<' + endDate.year() + '-' + endDate.month() + '-' + endDate.day() + '%20';

        List<Zendesk_Tickets_Statistics__c> newData = new List<Zendesk_Tickets_Statistics__c>();

        try {
            for (String plan : softwarePlans) {
                HttpResponse response = zendeskAPI.httpGet(queryString + 'plan:' + plan);
                JSONParser parser = JSON.createParser(SFUtils.replaceCountWords(response.getBody()));
                ZendeskModels.ZendeskSearchModel planData = (ZendeskModels.ZendeskSearchModel) parser.readValueAs(ZendeskModels.ZendeskSearchModel.class);
                newData.add(new Zendesk_Tickets_Statistics__c(Plan__c = plan, Number_of_Tickets_Created__c = planData.x_count, Date__c = monthDate));
            }

            if (newData.size() > 0) {
                insert newData;
                StatusLoggerUtils.logInfo(StatusLoggerUtils.ZENDESK_LOGGER, 'Zendesk # of ticekts created', newData.size(), 'Finished Zendesk Sync');
            }
        } catch (Exception e) {
            System.debug('Zendesk Error : ' + e.getMessage());
            StatusLoggerUtils.logError(StatusLoggerUtils.ZENDESK_LOGGER, 'Cannot fetch Zendesk # of tickets created', 0, e.getMessage());
        }

        if (!Test.isRunningTest()) {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.ZENDESK_LOGGER,  BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
    }

    /**
     * @future method for fetchZendeskTicketCount.
     */
    @future(callout=true)
    public static void fetchZendeskTicketCountFuture(Integer year, Integer month) {
        fetchZendeskTicketCount(year, month);
    }
}