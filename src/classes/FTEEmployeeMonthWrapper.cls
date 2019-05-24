public class FTEEmployeeMonthWrapper implements Comparable {

    private Integer month;
    private Integer year;
    private Id employeeId;

    public FTEEmployeeMonthWrapper(Id employeeId, Integer month, Integer year) {
        this.employeeId = employeeId;
        this.month = month;
        this.year = year;
    }

    public Id getEmployeeId() {
        return this.employeeId;
    }

    public Integer getMonth() {
        return this.month;
    }

    public Integer getYear() {
        return this.year;
    }

    public Boolean equals(Object obj) {
        if (obj instanceof FTEEmployeeMonthWrapper) {
            FTEEmployeeMonthWrapper toCompare = (FTEEmployeeMonthWrapper) obj;
            if (this.employeeId == toCompare.getEmployeeId()
                && this.month == toCompare.getMonth()
                && this.year == toCompare.getYear()) {
                return true;
            }
        }
        return false;
    }

    public Integer hashCode() {
        return System.hashCode(String.valueOf(this.employeeId) + '-' + this.month + '-' + this.year);
    }

    public Integer compareTo(Object objToCompare) {
        String empl1 = String.valueOf(this.employeeId) + '-' + this.year;
        FTEEmployeeMonthWrapper empWrapper = ((FTEEmployeeMonthWrapper) objToCompare);
        String empl2 = String.valueOf(empWrapper.getEmployeeId() + '-' + empWrapper.getYear());
        return empl1.compareTo(empl2);
    }
}