public class PROEmailProcessHelper{
    PROEmailTemplateHelper emailTemplateObj=null;
    PROEmailContractSnoozeHelper snoozeHelperObj=null;
    ID orgwideId;
    string ManagmentTeamEmail;
    Map<Id,SFDC_Employee__c> BusinessUnitEmpMap=new Map<Id,SFDC_Employee__c>();
    
    public PROEmailProcessHelper(ID orgwideId,string ManagmentTeamEmail,Map<Id,SFDC_Employee__c> BusinessUnitEmpMap){
        this.orgwideId=orgwideId;
        this.ManagmentTeamEmail=ManagmentTeamEmail;
        emailTemplateObj=new PROEmailTemplateHelper();
        snoozeHelperObj=new PROEmailContractSnoozeHelper();
        this.BusinessUnitEmpMap=BusinessUnitEmpMap;
    }
    
    /*
        Process First Nag.
        Send email to Project Incharge.
    */
    public void ProcessFirstNag(List<DContract__c> contracts){
        
        if(contracts.size()>0){
            
            Map<id,List<DContract__c>> projectInchargeFirstNagMap=GetProjectInCharge(contracts);
            List<Messaging.SingleEmailMessage> emailMessageList=new List<Messaging.SingleEmailMessage>();
            
            List<DContract__c> updateList=new List<DContract__c>();
            //Send First Nag Email
            for(Id projectInchargeId : projectInchargeFirstNagMap.keySet()){
                List<DContract__c> contractList=projectInchargeFirstNagMap.get(projectInchargeId);
                string name=GetName(contractList[0]);
               
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetProjectInchargeEmailTemplate(name,projectInChargeId,contractList,PROEmailContractFilterType.FirstNag));
                emailMsg.setTargetObjectId(projectInchargeId);
                emailMsg.subject='PRO Reminder';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
                emailMessageList.add(emailMsg);
                
                updateList.addAll(contractList);
            }
            
            if(updateList.size()>0){
                //Set field for First Nag Sent;
                snoozeHelperObj.SetFirstNegSent(updateList);
            }
            if(emailMessageList.size()>0){
                //Send Email.
                Messaging.sendEmail(emailMessageList);
            }    
        }
    }
    /*
        This method is userd to process Second Nag.
        1. Send Email to Project In charge.
        2. Send Email to Backstop.
    */
    public void ProcessSecondNag(List<DContract__c> contracts){
        if(contracts.size()>0){
            //Sent Email to Owner
            Map<id,List<DContract__c>> projectInchargeMap=GetProjectInCharge(contracts);
            
            List<Messaging.SingleEmailMessage> ownerEmailMessageList=new List<Messaging.SingleEmailMessage>();
            //Send First Nag Email;
            for(Id projectInChargeId : projectInchargeMap.keySet()){
                List<DContract__c> contractList=projectInChargeMap.get(projectInchargeId);
                
                string name=GetName(contractList[0]);
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetProjectInchargeEmailTemplate(name,projectInChargeId,contractList,PROEmailContractFilterType.SecondNag));
                emailMsg.setTargetObjectId(projectInchargeId);
                emailMsg.subject='PRO Second Reminder';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
                ownerEmailMessageList.add(emailMsg);
                
                //Set field for Second Nag Sent;
                snoozeHelperObj.SetSecondNegSent(contractList);
            }
            if(ownerEmailMessageList.size()>0){
                Messaging.sendEmail(ownerEmailMessageList);
            }
           
            //Send Email to Backstop
            List<Messaging.SingleEmailMessage> backtopEmailMessageList=new List<Messaging.SingleEmailMessage>();
            Map<id,List<DContract__c>> backstopMap=GetBacktstopMap(contracts);
            
            for(Id backstopId : backstopMap.keySet()){
                List<DContract__c> contractList=backstopMap.get(backstopId);
                
                string name='';
                if(contractList[0].backstop__r.FirstName!=null){
                    name=contractList[0].backstop__r.FirstName;
                }
                else{
                    name=contractList[0].backstop__r.LastName;
                }
                
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetBackstopEmailTemplate(name,contractList));
                emailMsg.setTargetObjectId(backstopId);
                emailMsg.subject='PRO Second Reminder';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
                backtopEmailMessageList.add(emailMsg);
            }
            if(backtopEmailMessageList.size()>0){
                Messaging.sendEmail(backtopEmailMessageList);
            }
        }
    }
    /*
          This email is used to Process Third Nag Contact.
          1. Send Email to Project In charge.
          2. Send Email to Project Manager.
          3. Send Email to Country Director.
    */
    public void ProcessThirdNag(List<DContract__c> contracts){
        
        if(contracts.size()>0){
            //send email to owner
            Map<id,List<DContract__c>> projectInChargeMap=GetProjectInCharge(contracts);
            List<Messaging.SingleEmailMessage> ownerEmailMessageList=new List<Messaging.SingleEmailMessage>();
            for(Id projectInChargeId : projectInChargeMap.keySet()){
                
                List<DContract__c> contractList=projectInChargeMap.get(projectInChargeId);
                
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetThirdNagEmailTemplate(contractList));
                emailMsg.setTargetObjectId(projectInChargeId);
                emailMsg.subject='PRO Third Reminder(Project Incharge)';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
                ownerEmailMessageList.add(emailMsg);
                
                //Set field for Second Nag Sent;
                snoozeHelperObj.SetThirdNegSent(contractList);
            }
            if(ownerEmailMessageList.size()>0){
                Messaging.sendEmail(ownerEmailMessageList);
            }
            
            //Send Email To PM.
            Map<id,List<DContract__c>> PMMap=GetPMMap(contracts);
            List<Messaging.SingleEmailMessage> PMEmailMessageList=new List<Messaging.SingleEmailMessage>();
            for(Id pmId: PMMap.keySet()){
                List<DContract__c> contractList=PMMap.get(pmId);
                
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetThirdNagEmailTemplate(contractList));
                emailMsg.setTargetObjectId(pmId);
                emailMsg.subject='PRO Third Reminder(PM)';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                //emailMsg.setToAddresses(new string[]{'niketsoral@gmail.com'});
                emailMsg.setSaveAsActivity(false);
                PMEmailMessageList.add(emailMsg);
            }
            if(PMEmailMessageList.size()>0){
                Messaging.sendEmail(PMEmailMessageList);
            }
            
            //Send Email to County Director.
            Map<id,List<DContract__c>> CDMap=GetCountryDirectorMap(contracts);
            List<Messaging.SingleEmailMessage> CDEmailMessageList=new List<Messaging.SingleEmailMessage>();
            for(Id pmId: CDMap.keySet()){
                List<DContract__c> contractList=CDMap.get(pmId);
                
                SFDC_Employee__c emp=BusinessUnitEmpMap.get(pmId);
                if(emp!=null){
                    Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                    emailMsg.setHtmlBody(emailTemplateObj.GetThirdNagEmailTemplate(contractList));
                    emailMsg.subject='PRO Third Reminder(CD)';
                    emailMsg.setOrgWideEmailAddressId(orgwideId);
                    emailMsg.setToAddresses(new string[]{emp.Email_Address__c});
                    emailMsg.setSaveAsActivity(false);
                    CDEmailMessageList.add(emailMsg);
                }
            }
            if(CDEmailMessageList.size()>0){
                Messaging.sendEmail(CDEmailMessageList);
            }
            
        }
    }
    /*
          This email is used to Process Third Nag Contact.
          1. Send Email to Project Incharge.
          2. Send Email to Project Manager.
          3. Send Email to Country Director.
          4. Send Email to Management Team.
    */
    public void ProcessFourthNag(List<DContract__c> contracts){
        if(contracts.size()>0){
            
            //send email to owner
            Map<id,List<DContract__c>> projectInchargeMap=GetProjectInCharge(contracts);
            List<Messaging.SingleEmailMessage> ownerEmailMessageList=new List<Messaging.SingleEmailMessage>();
            
            for(Id projectInchargeId : projectInchargeMap.keySet()){
                List<DContract__c> contractList=projectInchargeMap.get(projectInchargeId);
                
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetFourthNagEmailTemplate(contractList));
                emailMsg.setTargetObjectId(projectInchargeId);
                emailMsg.subject='PRO Fourth Reminder(Project Incharge)';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
                ownerEmailMessageList.add(emailMsg);
                
                //Set field for Second Nag Sent;
                snoozeHelperObj.SetFourthNegSent(contractList);
            }
            
            if(ownerEmailMessageList.size()>0){
                Messaging.sendEmail(ownerEmailMessageList);
            }
            
            //Send Email To PM.
            Map<id,List<DContract__c>> PMMap=GetPMMap(contracts);
            List<Messaging.SingleEmailMessage> PMEmailMessageList=new List<Messaging.SingleEmailMessage>();
            for(Id pmId: PMMap.keySet()){
                List<DContract__c> contractList=PMMap.get(pmId);
                
                Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                emailMsg.setHtmlBody(emailTemplateObj.GetFourthNagEmailTemplate(contractList));
                emailMsg.setTargetObjectId(pmId);
                emailMsg.subject='PRO Fourth Reminder(PM)';
                emailMsg.setOrgWideEmailAddressId(orgwideId);
                emailMsg.setSaveAsActivity(false);
               
                PMEmailMessageList.add(emailMsg);
            }
            if(PMEmailMessageList.size()>0){
                Messaging.sendEmail(PMEmailMessageList);
            }
            
            //Send Email to County Director.
            Map<id,List<DContract__c>> CDMap=GetCountryDirectorMap(contracts);
            List<Messaging.SingleEmailMessage> CDEmailMessageList=new List<Messaging.SingleEmailMessage>();
            for(Id pmId: CDMap.keySet()){
                List<DContract__c> contractList=CDMap.get(pmId);
                
                SFDC_Employee__c emp=BusinessUnitEmpMap.get(pmId);
                if(emp!=null){
                    Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
                    emailMsg.setHtmlBody(emailTemplateObj.GetThirdNagEmailTemplate(contractList));
                    emailMsg.subject='PRO Fourth Reminder(CD)';
                    emailMsg.setOrgWideEmailAddressId(orgwideId);
                    emailMsg.setToAddresses(new string[]{emp.Email_Address__c});
                    emailMsg.setSaveAsActivity(false);
                    CDEmailMessageList.add(emailMsg);
                }
            }
            if(CDEmailMessageList.size()>0){
                Messaging.sendEmail(CDEmailMessageList);
            }
            
            //Send Email to Managment Team.
            Messaging.SingleEmailMessage emailMsg=new Messaging.SingleEmailMessage();
            emailMsg.setHtmlBody(emailTemplateObj.GetThirdNagEmailTemplate(contracts));
            emailMsg.subject='PRO Fourth Reminder(MT)';
            emailMsg.setOrgWideEmailAddressId(orgwideId);
            emailMsg.setToAddresses(new string[]{ManagmentTeamEmail});
            emailMsg.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailMsg});
            
        }
    }
    
    private Map<id,List<DContract__c>> GetCountryDirectorMap(List<DContract__c> contracts){
         Map<id,List<DContract__c>> ownerMap=new Map<id,List<DContract__c>>();
         for(DContract__c contract: contracts){
             if(contract.Prime_Contracting_Business_Unit__c!=null){
                 List<DContract__c> contractList=ownerMap.get(contract.Prime_Contracting_Business_Unit__c);
                 if(contractList==null){
                    contractList=new List<DContract__c>();
                 }
                 contractList.add(contract);
                 ownerMap.put(contract.Prime_Contracting_Business_Unit__c,contractList);
             }
         }
         return ownerMap;
    }
    
    private Map<id,List<DContract__c>> GetOwnerMap(List<DContract__c> contracts){
        Map<id,List<DContract__c>> ownerMap=new Map<id,List<DContract__c>>();
        
        for(DContract__c contract: contracts){
            List<DContract__c> contractList=ownerMap.get(contract.OwnerId);
            if(contractList==null){
                contractList=new List<DContract__c>();
            }
            contractList.add(contract);
            ownerMap.put(contract.OwnerId,contractList);
        }
        return ownerMap;
    }
    
    private Map<id,List<DContract__c>> GetProjectInCharge(List<DContract__c> contracts){
        Map<id,List<DContract__c>> ownerMap=new Map<id,List<DContract__c>>();
        
        for(DContract__c contract: contracts){
            string ownerId='';
            if(contract.In_Charge_Of_Report_Out__c=='Project Manager'){
                ownerId=contract.Project_Manager__c;
            }
            else if(contract.In_Charge_Of_Report_Out__c=='Field Manager'){
                ownerId=contract.Field_Manager__c;
            }
            else if(contract.In_Charge_Of_Report_Out__c=='Backstop'){
                ownerId=contract.Backstop__c;
            }
            if(ownerId!=null && ownerId!=''){
                List<DContract__c> contractList=ownerMap.get(ownerId);
                if(contractList==null){
                    contractList=new List<DContract__c>();
                }
                contractList.add(contract);
                ownerMap.put(ownerId,contractList);
            }
        }
        return ownerMap;
    }
    private Map<id,List<DContract__c>> GetBacktstopMap(List<DContract__c> contracts){
        Map<id,List<DContract__c>> backtstopMap=new Map<id,List<DContract__c>>();
        
        for(DContract__c contract: contracts){
            if(contract.Backstop__c!=null){
            
                List<DContract__c> contractList=backtstopMap.get(contract.Backstop__c);
                if(contractList==null){
                    contractList=new List<DContract__c>();
                }
                contractList.add(contract);
                backtstopMap.put(contract.Backstop__c,contractList);
            }
        }
        return backtstopMap;
    }
    private Map<id,List<DContract__c>> GetPMMap(List<DContract__c> contracts){
        Map<id,List<DContract__c>> PMMap=new Map<id,List<DContract__c>>();
        
        for(DContract__c contract: contracts){
            if(contract.Project_Manager__c!=null){
            
                List<DContract__c> contractList=PMMap.get(contract.Project_Manager__c);
                if(contractList==null){
                    contractList=new List<DContract__c>();
                }
                contractList.add(contract);
                PMMap.put(contract.Project_Manager__c,contractList);
            }
        }
        return PMMap;
    }
    private string GetName(DContract__c contract){
        string name='';
        if(contract.In_Charge_Of_Report_Out__c=='Project Manager'){
            if(contract.Project_Manager__r.FirstName!=null){
                name=contract.Project_Manager__r.FirstName;
            }
            else{
                name=contract.Project_Manager__r.LastName;
            }
        }
        else if(contract.In_Charge_Of_Report_Out__c=='Field Manager'){
            if(contract.Field_Manager__r.FirstName!=null){
                name=contract.Field_Manager__r.FirstName;
            }
            else{
                 name=contract.Field_Manager__r.LastName;
            }
        }
        else if(contract.In_Charge_Of_Report_Out__c=='Backstop'){
            if(contract.Backstop__r.FirstName != null){
                name=contract.Backstop__r.FirstName;
            }
            else{
                name=contract.Backstop__r.LastName;
            }
        }
        return name;
    }

}