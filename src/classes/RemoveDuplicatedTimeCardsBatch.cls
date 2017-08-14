/**
 * Batch Job removes all duplicated time cards.
 */
public class RemoveDuplicatedTimeCardsBatch implements Database.Batchable<TimeCardContainer> {

    private Date startDate;
    private Date endDate;

    public RemoveDuplicatedTimeCardsBatch(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public List<TimeCardContainer> start(Database.BatchableContext context) {
        AggregateResult[] resultTimeCards = [SELECT Employee__c, Date__c, Case__c FROM Time_Card__c
                                         WHERE Date__c >=: this.startDate AND Date__c <=: this.endDate
                                         GROUP BY Employee__c,  Date__c, Case__c
                                         HAVING Count(Id) > 1];
        List<TimeCardContainer> scope = new List<TimeCardContainer>();
        for (AggregateResult ar : resultTimeCards) {
            scope.add(new TimeCardContainer((String) ar.get('Case__c'), (Date) ar.get('Date__c'), (Id) ar.get('Employee__c')));
        }
        return scope;
    }

    public void execute(Database.BatchableContext context, List<TimeCardContainer> scope) {
        List<Time_Card__c> timeCardsToRemove = new List<Time_Card__c>();
        for (TimeCardContainer tcData : scope) {
            List<Time_Card__c> duplicatedTimeCardsList = [SELECT Id FROM Time_Card__c WHERE Employee__c =: tcData.employeeId AND Case__c =: tcData.caseName AND Date__c =: tcData.tcDate
                                                          ORDER BY LastModifiedDate DESC];
            if (duplicatedTimeCardsList.size() > 1) {
                duplicatedTimeCardsList.remove(0);
                timeCardsToRemove.addAll(duplicatedTimeCardsList);
            }
        }
        if (timeCardsToRemove.size() > 0) {
            delete timeCardsToRemove;
        }
    }

    public void finish(Database.BatchableContext context) {

    }

    public class TimeCardContainer {

        private String caseName;
        private Date tcDate;
        private Id employeeId;

        public TimeCardContainer(String caseName, Date tcDate, Id employeeId) {
            this.caseName = caseName;
            this.tcDate = tcDate;
            this.employeeId = employeeId;
        }

        public String getCaseName() {
            return this.caseName;
        }

        public Date getTcDate() {
            return this.tcDate;
        }

        public Id getEmployeeId() {
            return this.employeeId;
        }
    }
}