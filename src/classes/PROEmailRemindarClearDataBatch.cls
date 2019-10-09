public class PROEmailRemindarClearDataBatch implements Database.Batchable<DContract__c>, Database.Stateful {

    @TestVisible
    private Date currentDate = Date.today();
    private Map<String, Integer> FrequencyMap = null;
    private List<DContract__c> failedReocrds = new List<DContract__c>();
    private String failedDML = '';

    public PROEmailRemindarClearDataBatch(){
        FrequencyMap = new Map<String, Integer>();
        List<PRO_Frequency_Settings__C> proSettings=PRO_Frequency_Settings__C.getAll().values();
        for (PRO_Frequency_Settings__C proSet : proSettings) {
             FrequencyMap.put(proSet.Name,Integer.valueOf(proSet.Frequency_In_Week__C));
        }
    }

    public List<DContract__c> start(Database.BatchableContext context) {
       return GetContract();
    }

    public void execute(Database.BatchableContext context, List<DContract__c> contracts) {
         List<DContract__c> updateList = new List<DContract__c>();
         Integer currentYear = this.currentDate.year();
         Integer currentMonth = this.currentDate.month();
         List<Date> thursDayList = PROHelper.GetAllThursDayOfMonth(currentYear,currentMonth);

         //If Thursday then clear Data.
         if (PROHelper.IsThursDay(this.currentDate)) {
            for (DContract__c contract : contracts) {
                Integer noOfDays = FrequencyMap.get(contract.Last_Report_Out_Status__c);
                if (noOfDays == null || noOfDays == 0) {
                    noOfDays = 2;
                }

                if (noOfDays == 1 || (noOfDays == 2 && (thursDayList[1] == this.currentDate || thursDayList[3] == this.currentDate ))
                                  || (noOfDays == 3 && thursDayList[2] == this.currentDate) || (noOfDays == 4 && thursDayList[3] == this.currentDate)) {

                    contract.Is_Snooze__c = false;
                    contract.Snooze_Date__c = null;
                    contract.Snooze_Days__c = null;
                    contract.Is_First_Nag_Sent__c = false;
                    contract.First_Nag_Sent_Date__c = null;
                    contract.Second_Nag_Sent_Date__c = null;
                    contract.Third_Nag_Sent_Date__c = null;
                    contract.Fourth_Nag_Sent_Date__c = null;
                    updateList.add(contract);
                }
            }

            //update updateList;
            List<Database.SaveResult> updateResults = Database.update(updateList, false);

            for (Integer i = 0; i < updateResults.size(); i++) {
                if (updateResults.get(i).isSuccess()) {
                    updateResults.get(i).getId();
                } else if (!updateResults.get(i).isSuccess()) {
                    // DML operation failed
                    Database.Error error = updateResults.get(i).getErrors().get(0);
                    failedDML = error.getMessage();
                    System.debug('Failed ID' + updateList.get(i).Id);
                    failedReocrds.add(updateList.get(i));
                }
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        List<String> toAddresses = new List<String>();
        List<PRO_Email_Remindar_Settings__c> settingList = PRO_Email_Remindar_Settings__c.getALL().values();
        PRO_Email_Remindar_Settings__c settings = settingList[0];
        if (settings.Error_Email__c != null && settings.Error_Email__c.contains(',')) {
            for (String email : settings.Error_Email__c.split(',')) {
                toAddresses.add(email);
            }
        } else if(settings.Error_Email__c != null) {
            toAddresses.add(settings.Error_Email__c);
        }

        if (failedReocrds.size() > 0 && toAddresses.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('');
            mail.setSubject('');
            String htmlBody = 'Second reminder was failed to sent on the following records.<br/>';
            htmlBody += '<b>Error:</b> '+failedDML+'<br/><br/>';
            htmlBody += '<b>Records:</b> <br/>';
            for(DContract__c contract : failedReocrds) {
                htmlBody +=  '<b>Name:</b> ' + contract.Name + ' - <b>Id:</b> ' + contract.Id + '<br/>';
            }

            mail.setUseSignature(false);
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    private List<DContract__c> GetContract() {
       List<DContract__c> contractList = [SELECT Id, Name, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Is_Snooze__c, Is_First_Nag_Sent__c, Snooze_Days__c, Snooze_Date__c, First_Nag_Sent_Date__c,
                                          OwnerId, Owner.Name,Owner.Email ,Backstop__c, Backstop__r.FirstName, Backstop__r.LastName,Backstop__r.Email, Project_Manager__c, Project_Manager__r.FirstName,
                                          Project_Manager__r.LastName, Project_Manager__r.Email, Prime_Contracting_Business_Unit__c, Last_Report_Out_Created_Date__c FROM DContract__c
                                          WHERE Last_Report_Out_Date__c != null AND Requires_Report_Out__c = 'Yes' AND Workflow_Escalation_Enabled__c = true];
       return contractList;
    }
}