/**
 *
 */
public class SalaryHistoryRecord {

    private Decimal value;
    private Date valueDate;

    public SalaryHistoryRecord(Decimal val, Date valDate) {
        this.value = val;
        this.valueDate = valDate;
    }

    public Decimal getValue() {
        return this.value;
    }

    public Date getValueDate() {
        return this.valueDate;
    }
}