/**
 * Adds a note to the FogBugz case upon Task creation
 *
 * @todo    Handle bulk insertions
 *
 * @author  Antonio Grassi
 * @date    11/16/2012
 */
trigger TaskToCaseNote on Task (after insert) {

    Set<Id> tasksInSet = new Set<Id> {};

    for (Task t:Trigger.new) {
        tasksInSet.add(t.Id);
    }

    Task[] tasks = [select Id,
                           WhatId
                    from Task
                    where Id in :tasksInSet
                    and Subject like 'Email: %'
                    and What.Type = 'Opportunity'];

    if (!tasks.isEmpty()) {
        
        Opportunity o = [select Fogbugz_Ticket_Number__c from Opportunity where Id = :tasks[0].WhatId];
        
        if (o.Fogbugz_Ticket_Number__c != null) {
            TaskTriggers.addNoteInFogBugz(tasks[0].Id);
        }
    }
}