/**
 * SF Dimagi Utils
 */
public class SFUtils {

    /**
     * Replace count word from given JSON file.
     */
    public static String replaceCountWords(String myString) {
       myString = myString.replaceAll('\n', '\\\\n');
       myString = myString.replaceAll('"count":', '"x_count":');
       return myString;
    }

    /**
     * Builds HTTP request parameters from given map, use only '='.
     */
    public static String buildURLParams(Map<String, String> parameters) {
        List<String> strParams = new List<String>();
        for (String paramKey : parameters.keySet()) {
            strParams.add(paramKey + '=' + parameters.get(paramKey));
        }
        return String.join(strParams, '&');
    }



    /**
     * Count working days from startDate to endDate. Does not include holidays.
     */
    public static Integer getWorkingDays(Date startDate, Date endDate) {
        Integer workingDays = 0;
        if(startDate == null || endDate == null) {
            return 0;
        } else {
            Integer difference = startDate.daysBetween(endDate);
            if (difference > 14) {
                DateTime dtStartHelper = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day());
                DateTime dtEndHelper = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day());
                // we count first and last week
                while (dtStartHelper.format('E') != 'Mon') {
                    String dayName = dtStartHelper.format('E');
                    if (dayName != 'Sat' && dayName != 'Sun') {
                        workingDays++;
                    }
                    dtStartHelper = dtStartHelper.addDays(1);
                }
                while (dtEndHelper.format('E') != 'Mon') {
                    String dayName = dtEndHelper.format('E');
                    if (dayName != 'Sat' && dayName != 'Sun') {
                        workingDays++;
                    }
                    dtEndHelper = dtEndHelper.addDays(-1);
                }
                workingDays++;
                Date blockStart = Date.newInstance(dtStartHelper.year(), dtStartHelper.month(), dtStartHelper.day());
                Date blockEnd = Date.newInstance(dtEndHelper.year(), dtEndHelper.month(), dtEndHelper.day());

                Integer weeks = Math.floor(blockStart.daysBetween(blockEnd) / 7).intValue();
                workingDays = workingDays + (weeks * 5);
            } else if (difference > 0) {
                DateTime dtHelper = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day());
                for (Integer i = 0; i <= difference; i++) {
                    String dayName = dtHelper.format('E');
                    if (dayName != 'Sat' && dayName != 'Sun') {
                        workingDays++;
                    }
                    dtHelper = dtHelper.addDays(1);
                }
            }
        }
        return workingDays;
    }

}