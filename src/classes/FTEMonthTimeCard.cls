public class FTEMonthTimeCard {

    public String name {get; set;}
    public Decimal[] hours {get; set;}

    public FTEMonthTimeCard() {}

    public FTEMonthTimeCard(String name, Integer monthDays) {
        this.name = name;
        this.hours = new Decimal[monthDays];
        for (Integer i = 0; i < monthDays; i++) {
            this.hours[i] = 0.00;
        }
    }
}