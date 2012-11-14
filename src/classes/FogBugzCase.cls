public with sharing class FogBugzCase {
	
	public String title {get;set;}
	public String project {get; set;}
    public String area {get;set;}
    public String assignedTo {get;set;}
    public String client {get; set;}
    public String status {get; set;}
    public Integer priority {get; set;}
    public String productType {get;set;}
    public Integer dealSize {get;set;}
    public Decimal probability {get;set;}
    public String externalBugID {get;set;}
        
    public FogBugzCase(String title,
                       String project,
                       String area,
                       String assignedTo,
                       String client,
                       String status,
                       Integer priority,
                       String productType,
                       Integer dealSize,
                       Decimal probability,
                       String externalBugID) {
                       	
        this.title = title;
        this.project = project;
        this.area = area;
        this.assignedTo = assignedTo;
        this.client = client;
        this.status = status;
        this.priority = priority;
        this.productType = productType;
        this.dealSize = dealSize;
        this.probability = probability;
        this.externalBugID = externalBugID;
    }
    
    public FogBugzCase()
    {
  
    }
}