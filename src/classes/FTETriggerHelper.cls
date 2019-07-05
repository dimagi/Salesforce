/**
 * Helper class to cache FTE Templates and update month flags.
 */
public class FTETriggerHelper {

    public static void processTemplates(List<Time_Card__c> timeCards) {
        // we need use maps because in trigger we also calculate time card salary, we don't want exceed limits like 2000 charachters per SOQL query, 200 queries and others
        // It is complicated but we want make synchronization error prone
        Integer yearMin = Date.today().year();
        Integer yearMax = yearMin;
        Set<Id> employeeSet = new Set<Id> ();

        for (Time_Card__c tc : timeCards) {
            employeeSet.add(tc.Employee__c);
            Integer tcYear = tc.Date__c.year();
            if (tcYear > yearMax) {
                yearMax = tcYear;
            } else if (tcYear < yearMin) {
                yearMin = tcYear;
            }
        }

        Map<Id, List<FTE_Data_Record__c>> templatesMapping = new Map<Id, List<FTE_Data_Record__c>>();
        List<FTE_Data_Record__c> toUpdate = new List<FTE_Data_Record__c>();
        Set<Id> fteContracts = new Set<Id>();
        for (FTE_Data_Record__c emplTemplate : [SELECT Id, Year__c, Employee__c, Contract__c, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                                Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                                FROM FTE_Data_Record__c WHERE Contract__r.FTE_Tracker__c = 'Yes' AND Year__c >=: yearMin AND Year__c <=: yearMax ORDER BY Year__c DESC]) {
            if (templatesMapping.containsKey(emplTemplate.Employee__c)) {
                templatesMapping.get(emplTemplate.Employee__c).add(emplTemplate);
            } else {
                templatesMapping.put(emplTemplate.Employee__c, new List<FTE_Data_Record__c> { emplTemplate });
            }
            fteContracts.add(emplTemplate.Contract__c);
            toUpdate.add(emplTemplate);
        }

         for (Time_Card__c tc : timeCards) {
            if (templatesMapping.containsKey(tc.Employee__c)) { // employee has templates
                Boolean updated = false;
                FTE_Data_Record__c templateTmp = null;
                List<FTE_Data_Record__c> templates = templatesMapping.get(tc.Employee__c);
                if (fteContracts.contains(tc.Client__c)) { // contract is templated fte
                    for (FTE_Data_Record__c template : templates) {
                        if (template.Contract__c == tc.Client__c && tc.Date__c.year() == template.Year__c) {
                            markMonthToUpdate(template, tc.Date__c.month());
                            updated = true;
                        } else if (templateTmp == null && tc.Date__c.year() == template.Year__c) {
                            templateTmp = template;
                        }
                    }
                } else {
                    templateTmp = templates.get(0);
                }

                if (updated == false && templateTmp != null) { // we want mark month when unassigned time was logged, we want trigger template for allocator
                    markMonthToUpdate(templateTmp, tc.Date__c.month());
                }
            }
        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    private static void markMonthToUpdate(FTE_Data_Record__c template, Integer month) {
        Sobject sobj = (SObject) template;
        sobj.put(FTETrackerHelper.getFieldUpdatedName(month), true);
    }
}