/**
 * Helper class, used to help create correct tables in FTE UI.
 */
public class FTEEmployeeTime {
    public String name { get; set;}
    public Id objId { get; set;}
    public List<Decimal> hoursArray { get; set;}
    public List<Decimal> daysArray { get; set;}
    public List<String> cssStyle { get; set;}
    public String nameCss { get; set;}

    public FTEEmployeeTime (String name, Id objId) {
        this.name = name;
        this.objId = objId;
        this.hoursArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                                        'fteCell', 'fteCell', '', ''};
        this.nameCss = 'fteProjectCell';
    }

    public void calculateDays() {
        for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
            this.daysArray[i] = FTETrackerHelper.roundtoDays(this.hoursArray[i]);
        }
        this.daysArray[13] =  this.daysArray[13].setScale(2);
    }

    public void sumHoursAndCost(FTEEmployeeTime empTime) {
        for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
            this.hoursArray[i] += empTime.hoursArray[i];
        }
        this.daysArray[13] += empTime.daysArray[13];
    }
}