public class FTEMonthTimeCard {

    public String name { get; set; }
    public Decimal[] hours { get; set; }
    public Decimal totalHours { get; set; }
    public Decimal templateExpectedTime { get; set; }

    public FTEMonthTimeCard() {}

    public FTEMonthTimeCard(String name, Integer monthDays) {
        this.name = name;
        this.totalHours = 0.00;
        this.templateExpectedTime = -1.0;
        this.hours = new Decimal[monthDays];
        for (Integer i = 0; i < monthDays; i++) {
            this.hours[i] = 0.00;
        }
    }
}