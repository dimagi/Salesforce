public class PROEmailContractFilterHelper {

    @TestVisible
    private Date currentDate = Date.today();

    public Integer FirstNagDays{
        get; set;
    }

    public Integer SecondNagDays{
        get; set;
    }

    public Integer ThirdNagDays{
        get; set;
    }

    public Integer FourthNagDays{
        get; set;
    }

    public PROEmailContractFilterHelper() {
        FirstNagDays = 4;
        SecondNagDays = 1;
        ThirdNagDays = 3;
        FourthNagDays = 7;
    }

    public List<DContract__c> filter(List<DContract__c> contracts, PROEmailContractFilterType filterType) {
        List<DContract__c> filteredContract = new List<DContract__c>();

        if (filterType == PROEmailContractFilterType.FirstNag) {
            Date latestPRODueDate = getLatestPRODueDate();
            Date lastAllowedDate = latestPRODueDate.addDays(FirstNagDays);

            for (DContract__c contract: contracts) {
                if ((contract.Last_Report_Out_Date__c != null && contract.Last_Report_Out_Date__c < latestPRODueDate)
                        || (contract.Last_Report_Out_Date__c == null && contract.CreatedDate < latestPRODueDate)) {
                    if (this.currentDate >= lastAllowedDate && !contract.Is_First_Nag_Sent__c) {
                        if (!contract.Is_Snooze__c || contract.Is_Snooze__c && (contract.Snooze_Date__c.addDays(Integer.valueOf(contract.Snooze_Days__c)) < this.currentDate)) {
                            filteredContract.add(contract);
                        }
                    }
                }
            }
        } else if (filterType == PROEmailContractFilterType.SecondNag) {
             for(DContract__c contract: contracts){
                 if(contract.Last_Report_Out_Status__c != 'Red' && contract.Is_First_Nag_Sent__c && !contract.Is_Snooze__c && contract.First_Nag_Sent_Date__c.addDays(SecondNagDays) == this.currentDate) {
                     filteredContract.add(contract);
                 }
             }
        } else if (filterType == PROEmailContractFilterType.ThirdNag) {
             for (DContract__c contract: contracts) {
                 if (contract.Last_Report_Out_Status__c != 'Red' && contract.Is_First_Nag_Sent__c && !contract.Is_Snooze__c && contract.First_Nag_Sent_Date__c.addDays(ThirdNagDays) == this.currentDate) {
                    filteredContract.add(contract);
                 }
             }
        } else if (filterType == PROEmailContractFilterType.FourthNag) {
             for (DContract__c contract: contracts) {
                 if (contract.Last_Report_Out_Status__c != 'Red' && contract.Is_First_Nag_Sent__c && !contract.Is_Snooze__c && contract.First_Nag_Sent_Date__c.addDays(FourthNagDays) == this.currentDate) {
                     filteredContract.add(contract);
                 }
             }
        }
        return filteredContract;
    }

    /**
     * Get latest PRO Due Date.
     * PRO is due every Second and fourth Thursday.
     */
    public Date getLatestPRODueDate() {
        Date latestPRODueDate = null;

        Integer currentMonth = this.currentDate.month();
        Integer currentYear = this.currentDate.year();

        List<Date> currentMonthThursDayList = PROHelper.getAllThursDayOfMonth(currentYear, currentMonth);

        //Current Date is less then second Thursday of month, 
        //then used fourth Thursday of previous month.
        if (this.currentDate < currentMonthThursDayList[1]) {
             Date previousMonthDate = this.currentDate.addMonths(-1);
             Integer previousMonth = previousMonthDate.month();
             Integer previousYear = previousMonthDate.year();
             //Get previous Month Thursday.
             List<Date> previousMonthThursDayList = PROHelper.getAllThursDayOfMonth(previousYear, previousMonth);
             return previousMonthThursDayList[3];
        } else {
            if (this.currentDate < currentMonthThursDayList[3]) {
                latestPRODueDate = currentMonthThursDayList[1];
            } else {
                latestPRODueDate = currentMonthThursDayList[3];
            }
        }
        return latestPRODueDate;
    }
}