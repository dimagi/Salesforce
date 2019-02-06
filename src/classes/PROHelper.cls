public class PROHelper {

    /*
        Get List of Thursday of current month.
    */
    public static List<Date> getAllThursdayOfMonth(Integer year, Integer month) {
        List<Date> thuDayDateList = new List<Date>();

        Date startDate = date.newInstance(year, month, 1);
        Date endDate = startDate.addMonths(1).addDays(-1);

        do {
            Datetime myDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = myDateTime.format('E');
            if (dayofWeek == 'Thu') {
                thuDayDateList.add(startDate);
            }
            startDate = startDate.addDays(1);
        } while (startDate <= endDate);
        return thuDayDateList;
    }

    public static Boolean isThursday(Date currentDate) {
        Datetime myDateTime = DateTime.newInstance(currentDate, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = myDateTime.format('E');
        if (dayofWeek == 'Thu') {
            return true;
        }
        return false;
    }
}