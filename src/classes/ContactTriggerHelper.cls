public class ContactTriggerHelper{

    public static void UpdateEmployee(Map<Id,Contact> oldContactMap,List<Contact> contactList) {
        if (CheckRecursive.firstRun) {
            CheckRecursive.firstrun = false;
            List<SFDC_Employee__c> empList = [SELECT Id, Contact__c, Email_Address__c, Entity__c FROM SFDC_Employee__c WHERE Contact__c =: contactList];
            Map<Id, SFDC_Employee__c> contactEmployeeMap = new Map<Id, SFDC_Employee__c>();

            for (SFDC_Employee__c emp : empList) {
               if (!contactEmployeeMap.containsKey(emp.Contact__c)) {
                   contactEmployeeMap.put(emp.Contact__c,emp);
               }
            }

            Set<Id> accountIds = new Set<Id>();
            Set<Id> reportToIds = new Set<Id>();

            for(Contact con:contactList){
                accountIds.add(con.accountid);
                reportToIds.add(con.ReportsToId);
            }

            Map<Id ,Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE id=: accountIds]);
            List<SFDC_Employee__c> reportTOEmpList = [SELECT Id, Contact__c FROM SFDC_Employee__c WHERE Contact__c =: reportToIds];
            Map<Id, Id> reportTOEmpMap = new Map<Id, Id>();

            for (SFDC_Employee__c emp : reportTOEmpList) {
                if (!reportTOEmpMap.containsKey(emp.Contact__c)) {
                    reportTOEmpMap.put(emp.Contact__c, emp.Id);
                }
            }

            List<SFDC_Employee__c> updateEmpList = new List<SFDC_Employee__c>();
            for (Contact con : contactList) {
                if (contactEmployeeMap.containsKey(con.Id)) {
                     Boolean shouldUpdateEmployee = false;
                     SFDC_Employee__c updateEmp = contactEmployeeMap.get(con.Id);

                      System.debug('Update EMP Fire: ' + updateEmp.id);
                      Account acc = accountMap.get(con.AccountId);
                      Contact oldContact = oldContactMap.get( con.Id );

                      if (con.FirstName == null && oldContact.LastName != con.LastName) {
                          updateEmp.Name = con.LastName;
                          shouldUpdateEmployee = true;
                      } else if (oldContact.FirstName != con.FirstName || oldContact.LastName != con.LastName) {
                          updateEmp.Name = con.FirstName + ' ' + con.LastName;
                          shouldUpdateEmployee = true;
                      }

                      if (con.Country__c != null && oldContact.Country__c != con.Country__c) {
                          updateEmp.Country__c = con.Country__c;
                          shouldUpdateEmployee = true;
                      }

                      if (con.Department != null && oldContact.Department != con.Department) {
                          updateEmp.Sub_Unit__c = con.Department;
                          shouldUpdateEmployee = true;
                      }

                      if (con.Skype__c != null && oldContact.Skype__c != con.Skype__c) {
                          updateEmp.Skype_ID__c = con.Skype__c;
                          shouldUpdateEmployee = true;
                      }

                      if(con.Email != null && oldContact.Email != con.Email){
                          updateEmp.Email_Address__c = con.Email;
                          shouldUpdateEmployee = true;
                      }

                      if (con.Title != null && oldContact.Title != con.Title) {
                          updateEmp.Title__c = con.Title; 
                          shouldUpdateEmployee = true;
                      }

                      if (con.ReportsToId != oldContact.ReportsToId) {
                          shouldUpdateEmployee = true;
                          if (con.ReportsToId != null) {
                              updateEmp.Direct_Manager_Lookup__c = reportTOEmpMap.get(con.ReportsToId);  
                          } else {
                              updateEmp.Direct_Manager_Lookup__c = null;
                          }
                      }

                      if(shouldUpdateEmployee) {
                          updateEmpList.add(updateEmp);
                      }
                }
            }

            if(updateEmpList.size()>0){
                update updateEmpList;
            }
        }
    }
}