/**
 * Helper class for FTE Tracker.
 */
public class FTETrackerHelper {

    public static Decimal roundtoDays(Decimal hours) {
        Decimal totalDays = (hours / 8.0).intValue();
        Decimal restValue = hours - (totalDays * 8);
        return totalDays + (0.25 * (restValue / 2.0).setScale(0, System.RoundingMode.HALF_UP));
    }

    public static JobWrapper loadWorkCardJobStatus() { // We want block FTE Tracker until all Work Cards will be generated from time cards
        JobWrapper workCardJobStatus = new JobWrapper(false);
        ApexClass[] batchClassArray = [SELECT Id, Name FROM ApexClass WHERE Name='FTEGenerateEmployeesWorkCardBatch' OR Name = 'FTEHoursUploadBatch'];
        AsyncApexJob[] batchClassJobList = [SELECT Id, ApexClassID, JobItemsProcessed, TotalJobItems, CreatedDate FROM AsyncApexJob WHERE ApexClassID IN: batchClassArray
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            workCardJobStatus.isRunning = true;
            workCardJobStatus.jobName = batchClassArray[0].Id == batchClassJobList[0].ApexClassID ? (batchClassArray[0].Name == 'FTEHoursUploadBatch' ? 'CSV Upload Batch' : 'FTE Working Card Batch' )
                                            : (batchClassArray[1].Name == 'FTEHoursUploadBatch' ? 'CSV Upload Batch' : 'FTE Working Card Batch' );
            workCardJobStatus.jobItemsProcessed = batchClassJobList[0].JobItemsProcessed;
            workCardJobStatus.totalJobItems = batchClassJobList[0].TotalJobItems;
        } else {
            workCardJobStatus.isRunning = false;
        }
        return workCardJobStatus;
    }

    public static Integer getNetworkDays(Date hireDate, Integer fteYear) {
        if (hireDate != null && hireDate.year() == fteYear) {
            Integer workingDaysResult = SFUtils.getWorkingDays(hireDate, Date.newInstance(fteYear, 12 ,31));
            return workingDaysResult <= 230 ? workingDaysResult : 230;
        }
        return 230;
    }

    /**
     * Code from : https://salesforce.stackexchange.com/questions/11805/blob-is-not-a-valid-utf-8-string-error/25421
     *             https://gist.github.com/nxtr/bca4984cd3753261995c421711729629
     * @param input    Blob data representing correct string in @inCharset encoding
     * @param inCharset    encoding of the Blob data (for example 'ISO 8859-2')
     */
    public static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i) {
            bytes[i] =  hex.mid(i << 1, 2);
        }
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }

    public static List<SelectOption> getYearsData() {
        List<SelectOption> tData = new List<SelectOption>();
        Integer currentYear = Date.today().year();
        tData.add(new SelectOption(String.valueOf(currentYear + 2), String.valueOf(currentYear + 2)));
        tData.add(new SelectOption(String.valueOf(currentYear + 1), String.valueOf(currentYear + 1)));
        tData.add(new SelectOption(String.valueOf(currentYear), String.valueOf(currentYear)));
        tData.add(new SelectOption(String.valueOf(currentYear - 1), String.valueOf(currentYear - 1)));
        return tData;
    }
}