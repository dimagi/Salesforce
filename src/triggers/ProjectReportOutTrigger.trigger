trigger ProjectReportOutTrigger on Project_Report_Out__c (before insert, after insert, after update) {
    if (Trigger.isbefore && Trigger.isInsert) {
      ProjectReportOutTriggerHandler.beforeInsert(Trigger.new);
  } else if (Trigger.isAfter && Trigger.isInsert) {
      ProjectReportOutTriggerHandler.afterInsert(Trigger.new);
  }
  else if (Trigger.isAfter && Trigger.isUpdate) {
      ProjectReportOutTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
  }
}