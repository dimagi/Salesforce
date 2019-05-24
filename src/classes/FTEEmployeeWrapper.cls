public class FTEEmployeeWrapper {

    public Id employeeId { get; set; }
    public Integer year { get; set; }

    public FTEEmployeeWrapper(Id employeeId, Integer year) {
        this.employeeId = employeeId;
        this.year = year;
    }

    public Integer hashCode() {
        return System.hashCode(String.valueOf(this.employeeId) + '-' + this.year);
    }

    public Boolean equals(Object obj) {
        if (obj instanceof FTEEmployeeWrapper) {
            FTEEmployeeWrapper toCompare = (FTEEmployeeWrapper) obj;
            if (this.employeeId == toCompare.employeeId
                && this.year == toCompare.year) {
                return true;
            }
        }
        return false;
    }
}