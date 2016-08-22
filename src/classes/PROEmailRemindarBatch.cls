global class PROEmailRemindarBatch implements Database.Batchable<DContract__c>, Database.Stateful {

    PROEmailContractFilterHelper contractFilterHelper = null;
    PROEmailProcessHelper processHelper=null;
    Id orgWideId;
    String ManagmentTeamEmail;
    Map<Id,SFDC_Employee__c> BusinessUnitEmpMap=new Map<Id,SFDC_Employee__c>();

    public PROEmailRemindarBatch() {
        List<PRO_Email_Remindar_Settings__c> settingList=PRO_Email_Remindar_Settings__c.getALL().values();
        contractFilterHelper=new PROEmailContractFilterHelper();

        if (settingList != null && settingList.size() > 0) {
            PRO_Email_Remindar_Settings__c settings = settingList[0];
            contractFilterHelper.FirstNagDays = Integer.ValueOf(settings.First_Nag_Days__c);
            contractFilterHelper.SecondNagDays = Integer.ValueOf(settings.Second_Nag_Days__c);
            contractFilterHelper.ThirdNagDays = Integer.ValueOf(settings.Third_Nag_Days__c);
            contractFilterHelper.FourthNagDays = Integer.ValueOf(settings.Fourth_Nag_Days__c);
            ManagmentTeamEmail = settings.Management_Team_Email__c;
        }

        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                                              Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        orgWideId = orgWideAddress.Id;
        processHelper = new PROEmailProcessHelper(orgWideId,ManagmentTeamEmail,BusinessUnitEmpMap);

        List<SFDC_Employee__c> empList = [SELECT Id, Email_Address__c, Business_Unit__c FROM SFDC_Employee__c
                                          WHERE Business_Unit__c != null AND Title__c = 'company director'];

        for (SFDC_Employee__c emp:empList) {
            if (!BusinessUnitEmpMap.containsKey(emp.Business_Unit__c)) {
                BusinessUnitEmpMap.put(emp.Business_Unit__c, emp);
            }
        }
    }

    global List<DContract__c> start(Database.BatchableContext context) {
        return GetContract();
    }

    global void execute(Database.BatchableContext context, List<DContract__c> contracts) {

        List<DContract__c> firstNagContract=new List<DContract__c>();
        List<DContract__c> secondNagContract=new List<DContract__c>();
        List<DContract__c> thirdNagContract=new List<DContract__c>();
        List<DContract__c> fourthNagContract=new List<DContract__c>();

        firstNagContract.addAll(contractFilterHelper.filter(contracts,PROEmailContractFilterType.FirstNag));
        secondNagContract.addAll(contractFilterHelper.filter(contracts,PROEmailContractFilterType.SecondNag));
        thirdNagContract.addAll(contractFilterHelper.filter(contracts,PROEmailContractFilterType.ThirdNag));
        fourthNagContract.addAll(contractFilterHelper.filter(contracts,PROEmailContractFilterType.FourthNag));

        System.debug('First Nag Count:'+firstNagContract.size());
        System.debug('Second Nag Count:'+secondNagContract.size());
        System.debug('Third Nag Count:'+thirdNagContract.size());
        System.debug('Fourth Nag Count:'+fourthNagContract.size());
 
        processHelper.ProcessFirstNag(firstNagContract);
        processHelper.ProcessSecondNag(secondNagContract);
        processHelper.ProcessThirdNag(thirdNagContract);
        processHelper.ProcessFourthNag(fourthNagContract);
    }

    global void finish(Database.BatchableContext context) {
        //TODO Send error info
    }

    /*
        Get All contract where at least one PRO is created and 
        require report out.
    */
    private List<DContract__c> GetContract() {
        List<DContract__c> contractList;
        if (Test.isRunningTest()) {
            contractList = [SELECT Id, Name, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Is_Snooze__c, Is_First_Nag_Sent__c,
                                    Snooze_Days__c, Snooze_Date__c, First_Nag_Sent_Date__c , OwnerId, Owner.Name,Owner.Email,
                                    Backstop__c, Backstop__r.FirstName, Backstop__r.LastName, Backstop__r.Email,
                                    Project_Manager__c, Project_Manager__r.FirstName, Project_Manager__r.LastName, Project_Manager__r.Email,
                                    Prime_Contracting_Business_Unit__c, Last_Report_Out_Created_Date__c,
                                    In_Charge_Of_Report_Out__c, Field_Manager__c, Field_Manager__r.FirstName, Field_Manager__r.LastName, CreatedDate
                                    FROM DContract__c
                                    WHERE Requires_Report_Out__c = 'Yes' AND Workflow_Escalation_Enabled__C = true LIMIT 30];
        } else {
            contractList = [SELECT Id, Name, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Is_Snooze__c, Is_First_Nag_Sent__c,
                                    Snooze_Days__c, Snooze_Date__c, First_Nag_Sent_Date__c , OwnerId, Owner.Name,Owner.Email,
                                    Backstop__c, Backstop__r.FirstName, Backstop__r.LastName, Backstop__r.Email,
                                    Project_Manager__c, Project_Manager__r.FirstName, Project_Manager__r.LastName, Project_Manager__r.Email,
                                    Prime_Contracting_Business_Unit__c, Last_Report_Out_Created_Date__c,
                                    In_Charge_Of_Report_Out__c, Field_Manager__c, Field_Manager__r.FirstName, Field_Manager__r.LastName, CreatedDate
                                    FROM DContract__c
                                    WHERE Requires_Report_Out__c = 'Yes' AND Workflow_Escalation_Enabled__C = true];
        }

       return contractList;
    }
}