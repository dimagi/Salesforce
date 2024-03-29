/**
* Helper class, used to help create correct tables in FTE UI.
*/
public class FTEEmployeeTime {
    
    public String name { get; set;}
    public Id objId { get; set;}
    public DateTime hireDate {get;set;}
    public DateTime termDate {get;set;}
    public List<Decimal> hoursArray { get; set;}
    public List<Decimal> daysArray { get; set;}
    public List<String> cssStyle { get; set;}
    public String nameCss { get; set;}
    public String ContractName{get;set;}
    public list<String> Headers {get;set;}
    
    public FTEEmployeeTime (String name, Id objId,DateTime hireDate, DateTime terminationDate, Boolean isUnAssigned) {
        this.name = name;
        this.objId = objId;
      //  this.hireDate = date.newinstance(hireDate.year(), hireDate.month(), hireDate.day());
       /// this.termDate = date.newinstance(terminationDate.year(), terminationDate.month(), terminationDate.day());
        system.debug(hireDate);
        system.debug(terminationDate);
        
        this.hireDate = hireDate;
        this.termDate = terminationDate;
        this.hoursArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
                this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                    'fteCell', 'fteCell', '', ''};
                        this.nameCss = 'fteProjectCell';
        // Unassigned Days Default to 22.00
        if(isUnAssigned == true){
            this.hoursArray = new Decimal [] {176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176*12};
                }   
    }
    public FTEEmployeeTime (String name, Id objId, Boolean isUnAssigned,String ContractName) {
        this.ContractName = ContractName;
        this.name = name;
        this.objId = objId;
        this.Headers = new String[]{ 'Jan-', 'Feb-', 'Mar-', 'April-', 'May-', 'Jun-', 'Jul-', 'Aug-', 'Sep-', 'Oct-', 'Nov-', 'Dec-' };
        this.hoursArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
                this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                    'fteCell', 'fteCell', '', ''};
                        this.nameCss = 'fteProjectCell';
        // Unassigned Days Default to 22.00
        if(isUnAssigned == true){
            this.hoursArray = new Decimal [] {176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176*12};
                }   
    }
    
    
    public FTEEmployeeTime (String name, Id objId, Boolean isUnAssigned) {
        this.name = name;
        this.objId = objId;
        this.hoursArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
                this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                    'fteCell', 'fteCell', '', ''};
                        this.nameCss = 'fteProjectCell';
        // Unassigned Days Default to 22.00
        if(isUnAssigned == true){
            this.hoursArray = new Decimal [] {176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176, 176*12};
                }   
    }
    
    // New constructor for assigning working days dynamically to each month in the the Employee project view.
    public FTEEmployeeTime (String name, Id objId, Boolean isUnAssigned, Integer year) {
        this.name = name;
        this.objId = objId;
        this.hoursArray = new Decimal [13];
        Decimal total= 0;
        this.daysArray = new Decimal [] {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            this.cssStyle = new String [] {'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell', 'fteCell',
                'fteCell', 'fteCell', '', ''};
                    this.nameCss = 'fteProjectCell';
        
        if(isUnAssigned == true){
            for(Integer i=0; i<12; i++){
                Decimal workingDays = (Decimal)FTEWorkCardTriggerHandler.getMonthWorkingDays(i+1,year);
                this.hoursArray[i]=workingDays*8;
                
                total += this.hoursArray[i];
            }
            this.hoursArray[12]=total;
            
        }          
    }
    
    public void calculateDays() {
        for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
            //this.daysArray[i] = FTETrackerHelper.roundtoDays(this.hoursArray[i]);
            this.daysArray[i] = ((this.hoursArray[i])/8).setScale(4);
        }
    }
    
    public void sumHours(FTEEmployeeTime empTime) {
        for (Integer i = 0 ; i < this.hoursArray.size(); i++) {
            this.hoursArray[i] += empTime.hoursArray[i];
        }
    }
}