trigger ContractTrigger on DContract__c (after insert,after update,before insert,before update) {
    
    //Set Workflow Escalation Enabled
    if(Trigger.IsBefore){
        for(DContract__c cont : Trigger.New){
            DContract__c oldCont=null;
            
            if(Trigger.IsUpdate){
                oldCont=Trigger.OldMap.get(cont.id);
            }
            
            if(oldCont==null || cont.Requires_Report_Out__c!=oldCont.Requires_Report_Out__c){
                
                if(cont.Requires_Report_Out__c=='Yes'){
                  cont.Workflow_Escalation_Enabled__c=true;
                }
                else{
                  cont.Workflow_Escalation_Enabled__c=false;
                }
            
            }
        }
    
    }
    
    if(Trigger.IsAfter){
        List<Contract_Contact__c> upsertList=new List<Contract_Contact__c>();
        List<Contract_Contact__c> deleteList=new List<Contract_Contact__c>();
        
        List<Contact> contactList=[select id from contact where email in('ltse@dimagi.com','czue@dimagi.com')];
        List<Contact> VPOfGlobalServices=[select id from contact where Title='VP of Global services'];
        
        List<SFDC_Employee__c> chkEmpList=[select id,Contact__C,Employee_Status__c from 
                                          SFDC_Employee__c where Employee_Status__c='Terminated' and Contact__C!=null ]; 
                                          
        set<id> inactiveContactList=new set<id>();
        
        for(SFDC_Employee__c emp: chkEmpList){
            inactiveContactList.add(emp.Contact__c);
        }
        
        
        if(Trigger.IsInsert){
            for(DContract__c cont : Trigger.New){
                
                if(cont.Project_Manager__c!=null && !inactiveContactList.contains(cont.Project_Manager__c)){
                
                    upsertList.add(new Contract_Contact__c(Type__c='Project Manager',Contract__c=cont.id,Contact__c=cont.Project_Manager__c));
                }
                if(cont.Backstop__c!=null && !inactiveContactList.contains(cont.Backstop__c)){
                    upsertList.add(new Contract_Contact__c(Type__c='Backstop',Contract__c=cont.id,Contact__c=cont.Backstop__c));
                }
                if(cont.Field_Manager__c!=null && !inactiveContactList.contains(cont.Field_Manager__c)){
                    upsertList.add(new Contract_Contact__c(Type__c='Field Manager',Contract__c=cont.id,Contact__c=cont.Field_Manager__c));
                }
                
                if(cont.Requires_Developer_Work__c){
                    for(Contact c1 : contactList){
                        upsertList.add(new Contract_Contact__c(Type__c='Person',Contract__c=cont.id,Contact__c=c1.id));
                    }
                }
            }
        }
        if(Trigger.IsUpdate){
            
            Map<Id,SFDC_Employee__c> BusinessUnitEmpMap=new Map<Id,SFDC_Employee__c>();

            List<SFDC_Employee__c> empList=[select id,Email_Address__c,Business_Unit__c,Contact__c from SFDC_Employee__c
            where Business_Unit__c!=null and Title__c='Country Director' and Employee_Status__c!='Terminated'];
            
            for(SFDC_Employee__c emp:empList){
                if(!BusinessUnitEmpMap.containsKey(emp.Business_Unit__c)){
                    BusinessUnitEmpMap.put(emp.Business_Unit__c,emp);
                }
            }
            
            
            
            //get PM,Backstop and FM.
            List<Contract_Contact__c> contContrList=[select id,Contact__c,Contract__c,Type__c 
                                  from Contract_Contact__c where Contract__c=:Trigger.New and Type__c not 
                                  in('Person','Email')];
        
            Map<id,List<Contract_Contact__c>> contContrMap=new Map<id,List<Contract_Contact__c>>();
            Map<id,List<Contract_Contact__c>> contContrMapYellow=new Map<id,List<Contract_Contact__c>>();
            Map<id,List<Contract_Contact__c>> contContrMapRed=new Map<id,List<Contract_Contact__c>>();
            
            for(Contract_Contact__c contr:contContrList){
                if(contr.Type__c=='Management' ){
                    FillMap(contr,contContrMapRed);
                }
                else if(contr.Type__c=='VP' || contr.Type__c=='Country Director'){
                    FillMap(contr,contContrMapYellow);
                }
                else{
                    FillMap(contr,contContrMap);
                }
            }
            
            List<Contract_Contact__c> contContactListNew=[select id,Contact__c,Contract__c,Type__c from Contract_Contact__c 
                                                       where Contract__c=:Trigger.New and Contact__c=:contactList];
            
            Map<id,Set<Id>> contContrNewMap=new Map<id,Set<Id>>();
            
            for(Contract_Contact__c contr : contContactListNew){
                Set<id> tempList=contContrNewMap.get(contr.Contract__c);
                if(tempList==null){
                    tempList=new Set<id>();
                }
                tempList.add(contr.Contact__c);
                contContrNewMap.put(contr.Contract__c,tempList);
            }
            
           
            
            for(DContract__c cont:Trigger.New){
                DContract__c oldContact=Trigger.OldMap.get(cont.id);
                
                if(cont.Project_Manager__c!=oldContact.Project_Manager__c || cont.Backstop__c!=oldContact.Backstop__c ||
                   cont.Field_Manager__c!=oldContact.Field_Manager__c
                ){
                        List<Contract_Contact__c> tempList=contContrMap.get(cont.id);
                        if(tempList!=null){  
                            deleteList.addAll(tempList);
                        } 
                        
                        if(cont.Project_Manager__c!=null && !inactiveContactList.contains(cont.Project_Manager__c)){
                            upsertList.add(new Contract_Contact__c(Type__c='Project Manager',Contract__c=cont.id,Contact__c=cont.Project_Manager__c));
                        }
                        if(cont.Backstop__c!=null && !inactiveContactList.contains(cont.Backstop__c)){
                            upsertList.add(new Contract_Contact__c(Type__c='Backstop',Contract__c=cont.id,Contact__c=cont.Backstop__c));
                        }
                        if(cont.Field_Manager__c!=null && !inactiveContactList.contains(cont.Field_Manager__c)){
                            upsertList.add(new Contract_Contact__c(Type__c='Field Manager',Contract__c=cont.id,Contact__c=cont.Field_Manager__c));
                        }     
                
                }
                
                //If Developer work is required then add ltse and czue to email list.
                if(cont.Requires_Developer_Work__c){
                    Set<Id> tempList=contContrNewMap.get(cont.id);
                    for(Contact c : contactList){
                        if(tempList==null || !tempList.Contains(c.id)){
                            upsertList.add(new Contract_Contact__c(Type__c='Person',Contract__c=cont.id,Contact__c=c.id));
                        }
                    }
                }    
                //If Last_Report_Out_Status__c is changed
                if(cont.Last_Report_Out_Status__c!=oldContact.Last_Report_Out_Status__c){
                    
                    //Remove entry if last status is red.
                    if(oldContact.Last_Report_Out_Status__c=='Red'){
                        List<Contract_Contact__c> tempList=contContrMapRed.get(cont.id);
                        if(tempList!=null){  
                            deleteList.addAll(tempList);
                        } 
                    }
                    //Remove entry if last status is Yellow.
                    if(oldContact.Last_Report_Out_Status__c=='Yellow'){
                        List<Contract_Contact__c> tempList=contContrMapYellow.get(cont.id);
                        if(tempList!=null){  
                            deleteList.addAll(tempList);
                        } 
                    }
                    //Add Management Email if status is red.
                    if(cont.Last_Report_Out_Status__c=='Red'){
                        upsertList.add(new Contract_Contact__c(Type__c='Management',Contract__c=cont.id,Email__C='mgmt@dimagi.com'));
                    }
                    //Add VP and Country Director if status is Yellow.
                    if(cont.Last_Report_Out_Status__c=='Yellow'){
                        //add VP
                        if(VPOfGlobalServices!=null && VPOfGlobalServices.size()>0){
                            upsertList.add(new Contract_Contact__c(Type__c='VP',Contract__c=cont.id,Contact__c=VPOfGlobalServices[0].id));
                        }
                        //Add Country director.
                        if(cont.Prime_Contracting_Business_Unit__c!=null){
                           SFDC_Employee__c emp=BusinessUnitEmpMap.get(cont.Prime_Contracting_Business_Unit__c);
                           if(emp!=null && emp.Contact__c!=null){
                               upsertList.add(new Contract_Contact__c(Type__c='Country Director',Contract__c=cont.id,Contact__c=emp.Contact__c));
                           }
                        }
                        
                    }
                    
                }
            }
            
        }
         
        if(upsertList.size()>0){
            upsert upsertList;
        }
        if(deleteList.size()>0){
            delete deleteList;
        }
    
    }
    public void FillMap(Contract_Contact__c contr,Map<id,List<Contract_Contact__c>> contContrMap){
        List<Contract_Contact__c> tempList=contContrMap.get(contr.Contract__c);
        if(tempList==null){
            tempList=new List<Contract_Contact__c>();
        }
        tempList.add(contr);
        contContrMap.put(contr.Contract__c,tempList);
    }
}