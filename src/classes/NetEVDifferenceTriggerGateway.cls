/**
 * Helper class for retrieving old Pipeline_Snapshot__c records to create NetEVDiff records.
 */
public class NetEVDifferenceTriggerGateway {

    public static final String NEW_OPP = 'New Opp EV';
    public static final String INCREASED = 'Increased EV';
    public static final String DECREASED = 'Decreased EV';
    public static final String NO_CHANGE = 'No Change';
    public static final String LOST = 'Closed Opp - Lost / No Go';
    public static final String WON = 'Closed Opp - Won';

    public NetEVDifferenceTriggerGateway() {}

    /**
     * Used by Pipeline_Snapshot__c trigger. Creates new NetDiff records for given snapshots from one month
     * (It creates only for NEW_OPP, INCREASED, DECREASED, NO_CHANGE other detla types are handled by batch job).
     */
    public void processLastMonthSnapshots(List<Pipeline_Snapshot__c> triggerSnapshots) {
        if (triggerSnapshots.size() == 0) {
            return;
        }
        Set<Id> opps = new Set<Id>();
        Date currentDate = triggerSnapshots[0].Month_Date__c;
        Date firstDate = currentDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(Date.daysInMonth(currentDate.year() , currentDate.month())).addDays(-1);
        List<Pipeline_Snapshot__c> snapshots = new List<Pipeline_Snapshot__c>();
        // For now we don't want Total
        for(Pipeline_Snapshot__c snapshot : triggerSnapshots) {
            if (!String.isBlank(snapshot.Opportunity__c) && snapshot.Stage__c != 'Total') {
                opps.add(snapshot.Opportunity__c);
                snapshots.add(snapshot);
            }
        }

        Map<Id, Pipeline_Snapshot__c> priorMonthSnapshotRecords = getPriorMonthSnapshots(currentDate, opps);
        List<Pipeline_Snapshot_EV_DIff__c> snapShotDiffs = new List<Pipeline_Snapshot_EV_DIff__c>();
        List<Pipeline_Snapshot_EV_DIff__c> oldDiffs = [SELECT Id, Pipeline_Snapshot__c FROM Pipeline_Snapshot_EV_DIff__c WHERE Month_Date__c >=: firstDate
                            AND Month_Date__c <=: lastDate];
        Set<Id> pipelineSnapshotsToSkip = new Set<Id>();
        for (Pipeline_Snapshot_EV_DIff__c evDiff : oldDiffs) {
            pipelineSnapshotsToSkip.add(evDiff.Pipeline_Snapshot__c);
        }

        for (Pipeline_Snapshot__c lastMonthSnapshot : snapshots) {
            // We don't want duplicates for Snapshots
            if (pipelineSnapshotsToSkip.contains(lastMonthSnapshot.Id)) {
                continue;
            }

            Pipeline_Snapshot__c priorMonthSnapShot = priorMonthSnapshotRecords.get(lastMonthSnapshot.Opportunity__c);
            Pipeline_Snapshot_EV_DIff__c snapShotsDiff = new Pipeline_Snapshot_EV_DIff__c();
            snapShotsDiff.Name = lastMonthSnapshot.Name;
            snapShotsDiff.Month_Date__c = lastMonthSnapshot.Month_Date__c;
            snapShotsDiff.Pipeline_Snapshot__c = lastMonthSnapshot.Id;
            snapShotsDiff.Opportunity_Name__c = lastMonthSnapshot.Opportunity_Name__c;
            snapShotsDiff.Opportunity__c = lastMonthSnapshot.Opportunity__c;

            if (priorMonthSnapShot != null) {
                snapShotsDiff = calculateDiff(snapShotsDiff, lastMonthSnapshot, priorMonthSnapShot);
                snapShotsDiff.Delta_Type__c = getDeltaType(snapShotsDiff);
            } else {
                snapShotsDiff.Delta_Type__c = NEW_OPP;
                snapShotsDiff.DIFF_12_Month_Cash_Minus_Expense_Income__c = lastMonthSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? lastMonthSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c: 0;
                snapShotsDiff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = lastMonthSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ?  lastMonthSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c: 0;
                snapShotsDiff.DIFF_24_Month_Cash_Minus_Expense_Income__c = lastMonthSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? lastMonthSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c: 0;
                snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c = lastMonthSnapshot.Opportunity_Amount_Minus_Expense_Income__c != null ? lastMonthSnapshot.Opportunity_Amount_Minus_Expense_Income__c: 0;
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = lastMonthSnapshot.Expected_Value_Minus_Expense__c != null ? lastMonthSnapshot.Expected_Value_Minus_Expense__c: 0;
                snapShotsDiff.Monthly_Recurring_Revenue_MRR__c = lastMonthSnapshot.Monthly_Recurring_Revenue_MRR__c != null ? lastMonthSnapshot.Monthly_Recurring_Revenue_MRR__c: 0;
                snapShotsDiff.Expected_Monthly_Recurring_Revenue_MRR__c = lastMonthSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? lastMonthSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c: 0;
                snapShotsDiff.Diff_Buffer_EV__c = lastMonthSnapshot.Buffer_EV__c;
            }

            snapShotDiffs.add(snapShotsDiff);
        }

        if (snapShotDiffs.size() > 0) {
            insert snapShotDiffs;
        }
    }

    /**
     * Method to create Closed EV Diffs, uses SF history records.
     */
    @future
    public static void processPriorMonthSnapshotsWithClosedStatusHistory(Date executeDate) {
        Date firstDate = executeDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(firstDate.year() , firstDate.month())).addDays(-1);

        Map<Id, Pipeline_Snapshot__c> priorMonthSnapshotRecords = getSnapshotsForClosedDelta(executeDate);
        Set<Id> opportunityIds = priorMonthSnapshotRecords.keySet();

        Map<Id, Decimal> amountHistory = getDecimalHistory('Amount', lastDate, opportunityIds);
        Map<Id, Decimal> durationHistory = getDecimalHistory('Duration_months__c', lastDate, opportunityIds);
        Map<Id, String> implementationHistory = getStringHistory('Implementation_Type__c', lastDate, opportunityIds);
        Map<Id, String> stageHistory = getStringHistory('StageName', lastDate, opportunityIds);
        Map<Id, Date> closeHistory = getDateHistory('CloseDate', lastDate, opportunityIds);

        List<Pipeline_Snapshot_EV_DIff__c> snapShotDiffs = new List<Pipeline_Snapshot_EV_DIff__c>();
        for (Pipeline_Snapshot__c snapshot : priorMonthSnapshotRecords.values()) {
            Pipeline_Snapshot_EV_DIff__c snapShotsDiff = new Pipeline_Snapshot_EV_DIff__c();
            String nameSuffix = ' - ' + lastDate.month() + '/' + lastDate.year();
            String namePrefix = snapshot.Opportunity_Name__c;

            if (namePrefix != null && namePrefix.length() + nameSuffix.length() > 80) {
                Integer charsToCut = namePrefix.length() - (namePrefix.length() + nameSuffix.length() - 80);
                namePrefix = namePrefix.subString(0, charsToCut);
            }

            snapShotsDiff.Name = namePrefix + nameSuffix;
            snapShotsDiff.Opportunity_Name__c = snapshot.Opportunity_Name__c;
            snapShotsDiff.Opportunity__c = snapshot.Opportunity__c;
            snapShotsDiff.Month_Date__c = lastDate;
            snapShotsDiff.Pipeline_Snapshot__c = snapshot.Id;
            snapShotsDiff.Prior_Snapshot_date__c = snapshot.Month_Date__c;

            String stage = stageHistory.containsKey(snapshot.Opportunity__c) ?  stageHistory.get(snapshot.Opportunity__c) :
                            snapshot.Opportunity__r.StageName != null ? snapshot.Opportunity__r.StageName : 'Closed';
            Decimal amount = amountHistory.containsKey(snapshot.Opportunity__c) ? amountHistory.get(snapshot.Opportunity__c) :
                                snapshot.Opportunity__r.Amount != null ? snapshot.Opportunity__r.Amount : 0;
            Decimal durationMonths = durationHistory.containsKey(snapshot.Opportunity__c) ? durationHistory.get(snapshot.Opportunity__c) :
                                snapshot.Opportunity__r.Duration_months__c != null ? snapshot.Opportunity__r.Duration_months__c : 0;
            Decimal probability = 0;
            String implementationType = implementationHistory.containsKey(snapshot.Opportunity__c) ? implementationHistory.get(snapshot.Opportunity__c) :
                                snapshot.Opportunity__r.Implementation_Type__c;
            Date closedDate = closeHistory.containsKey(snapshot.Opportunity__c) ? closeHistory.get(snapshot.Opportunity__c) :
                                snapshot.Opportunity__r.CloseDate;
            Decimal expenseIncome = snapshot.Opportunity__r.Expense_Income__c != null ? snapshot.Opportunity__r.Expense_Income__c : 0;
            Decimal mrr = (implementationType == 'Self Service' || implementationType == 'Enterprise' || implementationType == 'Managed Server')
                                    ? (durationMonths != 0 ? amount / durationMonths : 0) : 0;

            if(stage == 'Closed - Won') {
                probability = 1;
                snapShotsDiff.Delta_Type__c = WON;
                snapShotDiffs.add(snapShotsDiff);
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = (snapshot.Opportunity__r.Expected_Value_Minus_Income__c != null ? snapshot.Opportunity__r.Expected_Value_Minus_Income__c : 0)
                                     - (snapshot.Expected_Value_Minus_Expense__c != null ? snapshot.Expected_Value_Minus_Expense__c : 0);
                snapShotsDiff.Expected_Monthly_Recurring_Revenue_MRR__c = (snapshot.Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c : 0)
                                     - (snapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0);
            } else {
                snapShotsDiff.Delta_Type__c = LOST;
                snapShotDiffs.add(snapShotsDiff);
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = 0
                                     - (snapshot.Expected_Value_Minus_Expense__c != null ? snapshot.Expected_Value_Minus_Expense__c : 0);
                snapShotsDiff.Expected_Monthly_Recurring_Revenue_MRR__c = 0 -
                                     - (snapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0);
            }

            snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c = (amount - expenseIncome)
                                     - (snapshot.Opportunity_Amount_Minus_Expense_Income__c != null ? snapshot.Opportunity_Amount_Minus_Expense_Income__c : 0);
            snapShotsDiff.Monthly_Recurring_Revenue_MRR__c = mrr
                                     - (snapshot.Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Monthly_Recurring_Revenue_MRR__c : 0);

            snapShotsDiff.DIFF_12_Month_Cash_Minus_Expense_Income__c = calculateXMonthCashe(lastDate, closedDate, 12, amount, durationMonths, probability, expenseIncome)
                                     - (snapshot.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? snapshot.X12_Month_Cash_Minus_Expense_Income_EV__c : 0);
            snapShotsDiff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = calculateXMonthCashe(lastDate, closedDate, 18, amount, durationMonths, probability, expenseIncome)
                                     - (snapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? snapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0);
            snapShotsDiff.DIFF_24_Month_Cash_Minus_Expense_Income__c = calculateXMonthCashe(lastDate, closedDate, 24, amount, durationMonths, probability, expenseIncome)
                                     - (snapshot.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? snapshot.X24_Month_Cash_Minus_Expense_Income_EV__c : 0);
        }

        if (snapShotDiffs.size() > 0) {
            insert snapShotDiffs;
        }
    }

    /**
     * Method to create Closed EV Diffs, should be used on "fresh" data.
     */
    @future
    public static void processPriorMonthSnapshotsWithClosedStatus(Date executeDate) {
        Date firstDate = executeDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(firstDate.year() , firstDate.month())).addDays(-1);
        Map<Id, Pipeline_Snapshot__c> priorMonthSnapshotRecords = getSnapshotsForClosedDelta(executeDate);

        List<Pipeline_Snapshot_EV_DIff__c> oldDiffs = [SELECT Id, Pipeline_Snapshot__c FROM Pipeline_Snapshot_EV_DIff__c WHERE Month_Date__c >=: firstDate
                            AND Month_Date__c <=: lastDate];
        Set<Id> pipelineSnapshotsToSkip = new Set<Id>();
        for (Pipeline_Snapshot_EV_DIff__c evDiff : oldDiffs) {
            pipelineSnapshotsToSkip.add(evDiff.Pipeline_Snapshot__c);
        }

        List<Pipeline_Snapshot_EV_DIff__c> snapShotDiffs = new List<Pipeline_Snapshot_EV_DIff__c>();
        for (Pipeline_Snapshot__c snapshot : priorMonthSnapshotRecords.values()) {
            // We don't want duplicates for Snapshots
            if (pipelineSnapshotsToSkip.contains(snapshot.Id)) {
                continue;
            }

            Pipeline_Snapshot_EV_DIff__c snapShotsDiff = new Pipeline_Snapshot_EV_DIff__c();
            String nameSuffix = ' - ' + lastDate.month() + '/' + lastDate.year();
            String namePrefix = snapshot.Opportunity_Name__c;

            if (namePrefix != null && namePrefix.length() + nameSuffix.length() > 80) {
                Integer charsToCut = namePrefix.length() - (namePrefix.length() + nameSuffix.length() - 80);
                namePrefix = namePrefix.subString(0, charsToCut);
            }

            snapShotsDiff.Name = namePrefix + nameSuffix;
            snapShotsDiff.Opportunity_Name__c = snapshot.Opportunity_Name__c;
            snapShotsDiff.Opportunity__c = snapshot.Opportunity__c;
            snapShotsDiff.Month_Date__c = lastDate;
            snapShotsDiff.Pipeline_Snapshot__c = snapshot.Id;
            snapShotsDiff.Prior_Snapshot_date__c = snapshot.Month_Date__c;

            if(snapshot.Opportunity__r.StageName == 'Closed - Won') {
                snapShotsDiff.Delta_Type__c = WON;
                snapShotDiffs.add(snapShotsDiff);
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = (snapshot.Opportunity__r.Expected_Value_Minus_Income__c != null ? snapshot.Opportunity__r.Expected_Value_Minus_Income__c : 0)
                                     - (snapshot.Expected_Value_Minus_Expense__c != null ? snapshot.Expected_Value_Minus_Expense__c : 0);
                snapShotsDiff.Expected_Monthly_Recurring_Revenue_MRR__c = (snapshot.Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c : 0)
                                     - (snapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0);
                snapShotsDiff.Diff_Buffer_EV__c = snapshot.Opportunity__r.Buffer_EV__c - snapshot.Buffer_EV__c;
            } else {
                snapShotsDiff.Delta_Type__c = LOST;
                snapShotDiffs.add(snapShotsDiff);
                // If no Snapshot and not closed won then it mean it was lost or <= stage 3 so Probability should be 0% which will give us 0
                // so wn do not need calculate anything 123 * 0% = 0
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = 0
                                    - (snapshot.Expected_Value_Minus_Expense__c != null ? snapshot.Expected_Value_Minus_Expense__c : 0);
                snapShotsDiff.Expected_Monthly_Recurring_Revenue_MRR__c = 0 -
                                     - (snapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0);
                snapShotsDiff.Diff_Buffer_EV__c = 0 - snapshot.Buffer_EV__c;
            }

            snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c = (snapshot.Opportunity__r.Amount_Minus_Expense_Income__c != null ? snapshot.Opportunity__r.Amount_Minus_Expense_Income__c : 0 )
                                     - (snapshot.Opportunity_Amount_Minus_Expense_Income__c != null ? snapshot.Opportunity_Amount_Minus_Expense_Income__c : 0);
            snapShotsDiff.Monthly_Recurring_Revenue_MRR__c = (snapshot.Opportunity__r.Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Opportunity__r.Monthly_Recurring_Revenue_MRR__c : 0)
                                     - (snapshot.Monthly_Recurring_Revenue_MRR__c != null ? snapshot.Monthly_Recurring_Revenue_MRR__c : 0);
            snapShotsDiff.DIFF_12_Month_Cash_Minus_Expense_Income__c = (snapshot.Opportunity__r.X12Month_Cash_Minus_Expenses_EV__c != null ? snapshot.Opportunity__r.X12Month_Cash_Minus_Expenses_EV__c : 0)
                                     - (snapshot.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? snapshot.X12_Month_Cash_Minus_Expense_Income_EV__c : 0);
            snapShotsDiff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = (snapshot.Opportunity__r.X18_Month_Cash_Minus_Expenses_EV__c != null ? snapshot.Opportunity__r.X18_Month_Cash_Minus_Expenses_EV__c : 0)
                                     - (snapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? snapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0);
            snapShotsDiff.DIFF_24_Month_Cash_Minus_Expense_Income__c = (snapshot.Opportunity__r.X24_Month_Cash_Minus_Expense_EV__c != null ? snapshot.Opportunity__r.X24_Month_Cash_Minus_Expense_EV__c : 0)
                                     - (snapshot.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? snapshot.X24_Month_Cash_Minus_Expense_Income_EV__c : 0);
        }

        if (snapShotDiffs.size() > 0) {
            insert snapShotDiffs;
        }
    }

    /**
     * Method should be edited and used to recalculate new fields added to EV object
     */
    @future
    public static void recalculateDiffs(Date executeDate) {
        try {
            List<Pipeline_Snapshot_EV_DIff__c> evDiffs = [SELECT Id, Delta_Type__c, Month_Date__c, Diff_Buffer_EV__c, Opportunity__c, Opportunity__r.Buffer_EV__c, 
                                                      Pipeline_Snapshot__c, Pipeline_Snapshot__r.Buffer_EV__c
                                                      FROM Pipeline_Snapshot_EV_DIff__c WHERE Month_Date__c =: executeDate];
            if (evDiffs.size() == 0) {
                return;
            }

            Map<Id, Pipeline_Snapshot__c> oldSnapshots = getPriorMonthSnapshotsForDate(executeDate);

            for (Pipeline_Snapshot_EV_DIff__c evSn : evDiffs) {
                Pipeline_Snapshot__c oldSn = oldSnapshots.get(evSn.Opportunity__c);

                if (evSn.Delta_Type__c == NEW_OPP || oldSn == null) {
                    evSn.Diff_Buffer_EV__c = evSn.Pipeline_Snapshot__r.Buffer_EV__c;
                } else if (evSn.Delta_Type__c == LOST) {
                    evSn.Diff_Buffer_EV__c = 0 - oldSn.Buffer_EV__c;
                } else if (evSn.Delta_Type__c == WON) {
                    evSn.Diff_Buffer_EV__c = evSn.Opportunity__r.Buffer_EV__c - oldSn.Buffer_EV__c;
	            } else {
	                evSn.Diff_Buffer_EV__c = evSn.Pipeline_Snapshot__r.Buffer_EV__c - oldSn.Buffer_EV__c;
                }
            }

            update evDiffs;
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'Recalculate Diff Buffer EV error', 'Cannot update EV diffs', ex);
            }
        }
    }

    /**
     * Returns prior month snapshots for given date and Opportunity set.
     */
    public Map<Id, Pipeline_Snapshot__c> getPriorMonthSnapshots(Date currentDate, Set<Id> opps) {
        Date prevMonthDate = currentDate.addMonths(-1);
        Date firstDate = prevMonthDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(prevMonthDate.year() , prevMonthDate.month())).addDays(-1);

        List<Pipeline_Snapshot__c> lastMonthSnapShotsList = [SELECT Name, Opportunity__c, Opportunity__r.StageName,
                                                   Month_Date__c, Amount_Minus_Expense_Income__c, Opportunity_Name__c,
                                                   Opportunity__r.Amount, Opportunity__r.Implementation_Type__c,
                                                   Opportunity__r.Duration_months__c, 
                                                   X12_Month_Cash_Minus_Expense_Income_EV__c ,
                                                   X18_Month_Cash_Minus_Expenses_Income_EV__c,
                                                   X24_Month_Cash_Minus_Expense_Income_EV__c,
                                                   Opportunity_Amount_Minus_Expense_Income__c,
                                                   Expected_Value_Minus_Expense__c, Monthly_Recurring_Revenue_MRR__c,
                                                   Expected_Monthly_Recurring_Revenue_MRR__c, Buffer_EV__c
                                                   FROM Pipeline_Snapshot__c
                                                   WHERE Month_Date__c >= :firstDate AND Month_Date__c <= :lastDate
                                                   AND Opportunity__c in :opps AND Stage__c != 'Total'];

        Map<Id, Pipeline_Snapshot__c> lastMonthSnapShotsMap = new Map<Id, Pipeline_Snapshot__c>();
        for(Pipeline_Snapshot__c snapshotObject : lastMonthSnapShotsList) {
            lastMonthSnapShotsMap.put(snapshotObject.Opportunity__c, snapshotObject);
        }

        return lastMonthSnapShotsMap;
    }

    /**
     * Returns prior month snapshots for given date.
     */
    public static Map<Id, Pipeline_Snapshot__c> getPriorMonthSnapshotsForDate(Date currentDate) {
        Date prevMonthDate = currentDate.addMonths(-1);
        Date firstDate = prevMonthDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(prevMonthDate.year() , prevMonthDate.month())).addDays(-1);

        List<Pipeline_Snapshot__c> lastMonthSnapShotsList = [SELECT Name, Opportunity__c, Opportunity__r.StageName,
                Month_Date__c, Amount_Minus_Expense_Income__c, Opportunity_Name__c,
                X12_Month_Cash_Minus_Expense_Income_EV__c , Buffer_EV__c,
                X18_Month_Cash_Minus_Expenses_Income_EV__c,
                X24_Month_Cash_Minus_Expense_Income_EV__c,
                Opportunity_Amount_Minus_Expense_Income__c,
                Expected_Value_Minus_Expense__c, Monthly_Recurring_Revenue_MRR__c,
                Expected_Monthly_Recurring_Revenue_MRR__c,
                Opportunity__r.Buffer_EV__c,
                Opportunity__r.X12Month_Cash_Minus_Expenses_EV__c,
                Opportunity__r.X18_Month_Cash_Minus_Expenses_EV__c,
                Opportunity__r.X24_Month_Cash_Minus_Expense_EV__c,
                Opportunity__r.Amount_Minus_Expense_Income__c,
                Opportunity__r.Expected_Value_Minus_Income__c,
                Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c,
                Opportunity__r.Monthly_Recurring_Revenue_MRR__c,
                Opportunity__r.Amount, Opportunity__r.Implementation_Type__c,
                Opportunity__r.Duration_months__c, Opportunity__r.CloseDate,
                Opportunity__r.Expense_Income__c
                FROM Pipeline_Snapshot__c
                WHERE Month_Date__c >= :firstDate AND Month_Date__c <= :lastDate
                AND Source_Type__c = 'Opportunity'
                AND Opportunity__c != null
                AND Stage__c != 'Total'];

        Map<Id, Pipeline_Snapshot__c> lastMonthSnapShotsMap = new Map<Id, Pipeline_Snapshot__c>();
        for(Pipeline_Snapshot__c snapshotObject : lastMonthSnapShotsList) {
            lastMonthSnapShotsMap.put(snapshotObject.Opportunity__c, snapshotObject);
        }

        return lastMonthSnapShotsMap;
    }

    private static Decimal calculateXMonthCashe(Date executeDate, Date closeDate, Decimal moths, Decimal amount, Decimal duration,
                                                Decimal probability, Decimal expenseIncome) {
        if ((closeDate.month() + 12 * closeDate.year()) > (executeDate.month() + 12 * executeDate.year() + moths)
            || (duration == 0)
            || (closeDate < executeDate)) {
            return 0;
        } else if ((executeDate.month() + 12 * executeDate.year() + moths) > (closeDate.month() + 12 * closeDate.year() + duration)) {
            return (amount - expenseIncome) * probability;
        } else {
            return (((amount - expenseIncome) * probability) / duration) *
                    ((executeDate.month() + 12 * executeDate.year() + moths) - (closeDate.month() + 12 * closeDate.year()));
        }
    }

    private static Map<Id, Decimal>  getDecimalHistory(String fieldName, Date lastDate, Set<Id> opportunityIds) {
        Map<Id, Decimal> historyMap = new Map<Id, Decimal>();
        List<OpportunityFieldHistory> historyList = [SELECT OpportunityId, CreatedDate, Field, NewValue, OldValue FROM OpportunityFieldHistory
                                                     WHERE Field =: fieldName AND OpportunityId IN: opportunityIds
                                                     AND CreatedDate >=: lastDate ORDER BY CreatedDate];
        for (OpportunityFieldHistory ofh : historyList) {
            if (!historyMap.containsKey(ofh.OpportunityId)) {
                if (fieldName == 'Amount') {
                    String sValue = (String) ofh.OldValue;
                    historyMap.put(ofh.OpportunityId, sValue != null && sValue != '' ? Decimal.valueOf(sValue) : 0);
                } else {
                    historyMap.put(ofh.OpportunityId, ofh.OldValue != null ? (Decimal) ofh.OldValue : 0);
                }
            }
        }
        return historyMap;
    }

    private static Map<Id, String> getSageHistory(Date lastDate, Set<Id> opportunityIds) {
        Map<Id, String> historyMap = new Map<Id, String>();
        List<OpportunityFieldHistory> historyList = [SELECT OpportunityId, CreatedDate, Field, NewValue, OldValue FROM OpportunityFieldHistory
                                                     WHERE Field = 'StageName' AND OpportunityId IN: opportunityIds
                                                     AND CreatedDate >=: lastDate AND CreatedDate <=: lastDate.addMonths(1) ORDER BY CreatedDate DESC];
        for (OpportunityFieldHistory ofh : historyList) {
            if (!historyMap.containsKey(ofh.OpportunityId)) {
                historyMap.put(ofh.OpportunityId, ofh.NewValue != null ? (String) ofh.NewValue : '');
            }
        }
        return historyMap;
    }

    private static Map<Id, String> getStringHistory(String fieldName, Date lastDate, Set<Id> opportunityIds) {
        Map<Id, String> historyMap = new Map<Id, String>();
        List<OpportunityFieldHistory> historyList = [SELECT OpportunityId, CreatedDate, Field, NewValue, OldValue FROM OpportunityFieldHistory
                                                     WHERE Field =: fieldName AND OpportunityId IN: opportunityIds
                                                     AND CreatedDate >=: lastDate ORDER BY CreatedDate];
        for (OpportunityFieldHistory ofh : historyList) {
            if (!historyMap.containsKey(ofh.OpportunityId)) {
                historyMap.put(ofh.OpportunityId, ofh.OldValue != null ? (String) ofh.OldValue : '');
            }
        }
        return historyMap;
    }

    private static Map<Id, Date> getDateHistory(String fieldName, Date lastDate, Set<Id> opportunityIds) {
        Map<Id, Date> historyMap = new Map<Id, Date>();
        List<OpportunityFieldHistory> historyList = [SELECT OpportunityId, CreatedDate, Field, NewValue, OldValue FROM OpportunityFieldHistory
                                                     WHERE Field =: fieldName AND OpportunityId IN: opportunityIds
                                                     AND CreatedDate >=: lastDate ORDER BY CreatedDate];
        for (OpportunityFieldHistory ofh : historyList) {
            if (!historyMap.containsKey(ofh.OpportunityId)) {
                historyMap.put(ofh.OpportunityId, ofh.OldValue != null ? (Date) ofh.OldValue : null);
            }
        }
        return historyMap;
    }

    private static Map<Id, Pipeline_Snapshot__c> getSnapshotsForClosedDelta(Date executeDate) {
        Date currentDate = executeDate;
        Date firstDate = currentDate.toStartOfMonth();
        currentDate = firstDate.addDays(date.daysInMonth(currentDate.year() , currentDate.month())).addDays(-1);

        List<Pipeline_Snapshot__c> records = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName,
                            Month_Date__c, Amount_Minus_Expense_Income__c, Opportunity_Name__c,
                            Opportunity__r.Amount, Opportunity__r.Implementation_Type__c, Opportunity__r.Expense_Income__c,
                            Opportunity__r.Duration_months__c, Opportunity__r.CloseDate,
                            X12_Month_Cash_Minus_Expense_Income_EV__c , Buffer_EV__c,
                            X18_Month_Cash_Minus_Expenses_Income_EV__c,
                            X24_Month_Cash_Minus_Expense_Income_EV__c,
                            Opportunity_Amount_Minus_Expense_Income__c,
                            Expected_Value_Minus_Expense__c,
                            Stage__c, Monthly_Recurring_Revenue_MRR__c,
                            Expected_Monthly_Recurring_Revenue_MRR__c
                            FROM Pipeline_Snapshot__c
                            WHERE Month_Date__c >=: firstDate
                            AND Month_Date__c <=: currentDate
                            AND Source_Type__c = 'Opportunity'
                            AND Stage__c != 'Total'];

        Map<Id, Pipeline_Snapshot__c> priorMonthSnapshotRecords = getPriorMonthSnapshotsForDate(firstDate);
        for (Pipeline_Snapshot__c snapshot : records) {
            if (!String.isBlank(snapshot.Opportunity__c) && priorMonthSnapshotRecords.containsKey(snapshot.Opportunity__c)) {
                priorMonthSnapshotRecords.remove(snapshot.Opportunity__c);
            }
        }
        return priorMonthSnapshotRecords;
    }

    public Pipeline_Snapshot_EV_DIff__c calculateDiff(Pipeline_Snapshot_EV_DIff__c diff, Pipeline_Snapshot__c lastSnapshot, Pipeline_Snapshot__c priorSnapshot) {
        diff.DIFF_12_Month_Cash_Minus_Expense_Income__c = (lastSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? lastSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c : 0) - (priorSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? priorSnapshot.X12_Month_Cash_Minus_Expense_Income_EV__c : 0);
        diff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = (lastSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? lastSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0) - (priorSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? priorSnapshot.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0);
        diff.DIFF_24_Month_Cash_Minus_Expense_Income__c = (lastSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? lastSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c : 0) - (priorSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? priorSnapshot.X24_Month_Cash_Minus_Expense_Income_EV__c : 0);
        diff.DIFF_Amount_Minus_Expense_Income__c = (lastSnapshot.Opportunity_Amount_Minus_Expense_Income__c != null ? lastSnapshot.Opportunity_Amount_Minus_Expense_Income__c : 0) - (priorSnapshot.Opportunity_Amount_Minus_Expense_Income__c != null ? priorSnapshot.Opportunity_Amount_Minus_Expense_Income__c : 0);
        diff.DIFF_Expected_Value_Minus_Expense__c = (lastSnapshot.Expected_Value_Minus_Expense__c != null ? lastSnapshot.Expected_Value_Minus_Expense__c : 0) - (priorSnapshot.Expected_Value_Minus_Expense__c != null ? priorSnapshot.Expected_Value_Minus_Expense__c : 0);
        diff.Prior_Snapshot_date__c = priorSnapshot.Month_Date__c;
        diff.Monthly_Recurring_Revenue_MRR__c = (lastSnapshot.Monthly_Recurring_Revenue_MRR__c != null ? lastSnapshot.Monthly_Recurring_Revenue_MRR__c : 0) - (priorSnapshot.Monthly_Recurring_Revenue_MRR__c != null ? priorSnapshot.Monthly_Recurring_Revenue_MRR__c : 0);
        diff.Expected_Monthly_Recurring_Revenue_MRR__c = (lastSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? lastSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0) - (priorSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c != null ? priorSnapshot.Expected_Monthly_Recurring_Revenue_MRR__c : 0);
        diff.Diff_Buffer_EV__c = lastSnapshot.Buffer_EV__c - priorSnapshot.Buffer_EV__c;
        return diff;
    }

    public String getDeltaType(Pipeline_Snapshot_EV_DIff__c diffObj) {
        Decimal diff = diffObj.DIFF_Expected_Value_Minus_Expense__c;
        if(diff > 0) {
            return INCREASED;
        } else if(diff < 0) {
            return DECREASED;
        }
        return NO_CHANGE;
    }
}