/**************************************************
Class Name: OpenOpportunityMailer
Class Description: Class in charge of encapsulating the filtering logic from the batches and send the notification emails  
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando
Update Date: 2013-03-04
Additional Comments:    
**************************************************/
public class OpenOpportunityMailer {
    
    private static final String EMAIL_SUBJECT = '<Name of User> | <Date> | Biz Dev Report Out';
    private static final String RED_EMAIL_SUBJECT = 'Your Overdue Opportunities';
    private static final String[] earlyStages = new String[] {'Stage 1 - Connect','Stage 2 - Talking', 'Stage 5 - Submitted'};

    public static void sendOpenOpportunitiesBatchReport(User user, String[] recipients, Map<String, Opportunity[]> stagedOpportunities) {
        
        Map<String, String> stageComments = new Map<String, String>();
        for (String stageComment :stagedOpportunities.keySet()) {           
            stageComments.put(stageComment, '');
        }
        
        String content = OpenOpportunityEmailUtils.buildEmailContent(stagedOpportunities, false, stageComments);
        
        sendEmail(content, recipients, EMAIL_SUBJECT, user.Name);        
    }

    public static void sendOpenOpportunitiesSingleReport(User[] users, String[] recipients, Map<String, String> stageComments) {        
        
        Id[] usersId = new Id[] {};
        String usersNameSubject = ' - ';
        for (User user :users) {
            usersId.add(user.Id);
            usersNameSubject += user.Name + ' - ';
        }
        
        Map<String, Opportunity[]> stagedOpportunities = OpenOpportunityReportController.getInstance().getOpenOpportunitiesOrderByStage(usersId);
        
        String content = OpenOpportunityEmailUtils.buildEmailContent(stagedOpportunities, true, stageComments);
        
        sendEmail(content, recipients, EMAIL_SUBJECT, usersNameSubject);
    }
    
    public static void sendRedOpenOpportunitiesBatchReport(User user, String[] recipients, Map<String, Opportunity[]> stagedOpportunities) {
        
        Map<String, Opportunity[]> redStagedOpportunities = new Map<String, Opportunity[]>();
        
        Integer daysNotUpdatedLimit = Open_Opportunity_Settings__c.getOrgDefaults().Days_Not_Updated_Limit__c != null 
                                       ? Open_Opportunity_Settings__c.getOrgDefaults().Days_Not_Updated_Limit__c.intValue()
                                       : 30;
                                       
        Integer daysNotUpdatedLimitEarlyStages = Open_Opportunity_Settings__c.getOrgDefaults().Days_Not_Updated_Limit_Early_Stages__c != null 
                                       ? Open_Opportunity_Settings__c.getOrgDefaults().Days_Not_Updated_Limit_Early_Stages__c.intValue()
                                       : 10;    
        
        Set<String> earlyStagesSet = new Set<String>(earlyStages);
        
        // Remove fresh opportunities
        for (String stageName :stagedOpportunities.keySet()) {          
            
            Opportunity[] opportunities = new Opportunity[] {};
            
            for(Opportunity opportunity :stagedOpportunities.get(stageName)) {
                
                if (earlyStagesSet.contains(opportunity.StageName)) {
                    
                    if (opportunity.Total_Days_Not_Updated__c > daysNotUpdatedLimitEarlyStages) {                   
                        opportunities.add(opportunity);
                    }                   
                }
                else {
                    
                    if (opportunity.Total_Days_Not_Updated__c > daysNotUpdatedLimit) {                  
                        opportunities.add(opportunity);
                    }
                }
            }

            if (!opportunities.isEmpty()) {
              redStagedOpportunities.put(stageName, opportunities);
            }
        } 
    
        // Only send Mail if there are opportunities    
        if (!redStagedOpportunities.isEmpty()) {
            
            Map<String, String> stageComments = new Map<String, String>();
            for (String stageComment :redStagedOpportunities.keySet()) {           
                stageComments.put(stageComment, '');
            }
            
            String content = OpenOpportunityEmailUtils.buildEmailContent(redStagedOpportunities, false, stageComments);
            
            sendEmail(content, recipients, RED_EMAIL_SUBJECT, user.Name);
        }
    }
    
    private static void sendEmail(String content, String[] recipients, String subjectTemplate, String userName) {
        
        String subject = subjectTemplate.replace('<Name of User>', userName).replace('<Date>', Date.today().format());
        
        OrgWideEmailAddress wideAddress = OpenOpportunityReportController.getOrganizationWideAddressMail();
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        
        if (wideAddress != null) {
            mail.setOrgWideEmailAddressId(wideAddress.Id);
        }
        
        mail.setHtmlBody(content);
        mail.setSubject(subject);
        mail.setToAddresses(recipients);
        Messaging.sendEmail(new Messaging.Email[] {mail});
    }
    
}