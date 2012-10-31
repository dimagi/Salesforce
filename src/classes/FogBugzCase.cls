public with sharing class FogBugzCase {
	public String title {get;set;}
    public String area {get;set;}
    public String assignedTo {get;set;}
    public String productType {get;set;}
    public Integer dealSize {get;set;}
    public Decimal probability {get;set;}
    public String externalBugID {get;set;}
        
    public FogBugzCase(String title, String area, String assignedTo, String productType, Integer dealSize, Decimal probability, String externalBugID)
    {
        this.title = title;
        this.area = area;
        this.assignedTo = assignedTo;
        this.productType = productType;
        this.dealSize = dealSize;
        this.probability = probability;
        this.externalBugID = externalBugID;
    }
    
    public FogBugzCase()
    {
  
    }
}