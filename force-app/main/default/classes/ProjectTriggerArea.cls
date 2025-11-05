/* Created by Nick to try to store Area multi select in a text field */
public with sharing class ProjectTriggerArea {

    // Entry point from update event
    public static void onUpdate(Project__c[] newProjects) {
        for (Project__c p : newProjects) {
            p.Area_Text__c = p.Area__c;
            p.Sub_Area_Text__c = p.Sub_Area__c;
        }
    }
    
}