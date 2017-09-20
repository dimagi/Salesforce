public class FTEMonthTimeCard {

    public String name {get; set;}
    public Integer monthDays {get; set;}
    public Decimal[] hours {get; set;}

    public FTEMonthTimeCard() {}

    public FTEMonthTimeCard(String name, Integer monthDays) {
        this.name = name;
        this.hours = new Decimal[monthDays];
    }
}