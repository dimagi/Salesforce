/**
 * Helper class, used to help create correct tables in FTE UI.
 */
public class FTEEmployeeTime {

    public String name { get; set; }
    public Boolean merged { get; set; }
    public Id objId { get; set; }
    public List<Decimal> hoursArray { get; set; }
    public List<Decimal> daysArray { get; set; }
    public List<Decimal> templateArray { get; set; }

    public List<String> cssStyle { get; set; }
    public String nameCss { get; set; }

    public FTEEmployeeTime (String name, Id objId) {
        this.merged = false;
        this.name = name;
        this.objId = objId;
        this.hoursArray = new Decimal [] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        this.daysArray = new Decimal [] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        this.templateArray = new Decimal [] { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 }; // Uploaded csv template array, used to merge data an show on UI time projection
        this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                                        'fteCell', 'fteCell', '', '' };
        this.nameCss = 'fteProjectCell';
    }

    public void calculateDaysAndTotal() {
        Decimal totalValue = 0;
        if (this.merged == false) {
            for (Integer i = 0; i < 12; i++) {
                Decimal templateValue = (this.templateArray[i] != -1 ? this.templateArray[i] * 8 : -1);
                Decimal hoursValue = this.hoursArray[i];
                Decimal finalValue = 0;

                if (templateValue == -1) {
                    finalValue = hoursValue;
                } else {
                    if (templateValue > hoursValue) {
                        finalValue = templateValue;
                        this.cssStyle[i] += ' future';
                    } else {
                        finalValue = hoursValue;
                        this.cssStyle[i] += ' blocked';
                    }
                }

                this.daysArray[i] = FTETrackerHelper.roundtoDays(finalValue);
                totalValue += finalValue;
            }
        } else {
            for (Integer i = 0; i < 12; i++) { // in merge method css and total was already calculated
                this.daysArray[i] = FTETrackerHelper.roundtoDays(this.hoursArray[i]);
                totalValue += this.hoursArray[i];
            }
        }
        this.daysArray[12] = FTETrackerHelper.roundtoDays(totalValue);
    }

    public void mergeEmployeeTime(FTEEmployeeTime empTime) {
        for (Integer i = 0; i < 12; i++) {
            Decimal template1Hours = 8;
            Decimal template2Hours = 8;
            Decimal templateValue1 = (this.templateArray[i] != -1 ? this.templateArray[i] * (this.merged == true ? 1 : 8): -1);
            Decimal templateValue2 = (empTime.templateArray[i] != -1 ? empTime.templateArray[i] * (empTime.merged == true ? 1 : 8): -1);
            Decimal hoursValue1 = this.hoursArray[i];
            Decimal hoursValue2 = empTime.hoursArray[i];

            setStyle(i, hoursValue1, templateValue1);
            setStyle(i, hoursValue2, templateValue2);

            if (templateValue1 > -1 && templateValue2 > -1) {

                this.hoursArray[i] = templateValue1 + templateValue2;
                this.templateArray[i] = templateValue1 + templateValue2;

            } else if (templateValue1 == -1 && templateValue2 > -1) {

                this.hoursArray[i] = hoursValue1 + templateValue2;
                this.templateArray[i] = hoursValue1 + templateValue2;

            } else if (templateValue2 == -1 && templateValue1 > -1) {

                this.hoursArray[i] = templateValue1 + hoursValue2;
                this.templateArray[i] = templateValue1 + hoursValue2;

            } else {

                this.hoursArray[i] += hoursValue2;

            }
        }
        this.merged = true;
    }

    private void setStyle(Integer index, Decimal value, Decimal template) {
        if (template != -1) {
            if (template > value) {
                if (!this.cssStyle[index].contains('future')) {
                    this.cssStyle[index ] = 'fteCell future';
                }
            } else {
                if (!this.cssStyle[index].contains('future')) {
                    this.cssStyle[index] = 'fteCell blocked';
                }
            }
        }
    }
}