/**
 * Schedules fetching custom data from zendesk API.
 */
public class ZendeskScheduler implements Schedulable {

    public ZendeskScheduler() {
    }

    public void execute(SchedulableContext sc) {
        Date currrentDate = Date.today().addDays(-1); // we schedule it at 1st each month
        ZendeskSynchronizer.fetchZendeskTicketCountFuture(currrentDate.year(), currrentDate.month());
    }
}