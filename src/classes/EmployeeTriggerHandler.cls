/**
 * Class EmployeeTriggerHandler
 *
 * Trigger Handler for the Employee SObject. This class implements the ITrigger
 * interface to help ensure the trigger code is bulkified and all in one place.
 */
 /**
 * TODO refacor
 */
public with sharing class EmployeeTriggerHandler implements ITrigger {

    public static boolean skipExecution = false;
    private Map<Id, String> usersToUpdate;
    private Map<Id, String> businessUnitNames;
    private Map<String, SFDC_Employee__c> employeesByEmail;

    public EmployeeTriggerHandler() {
        usersToUpdate = new Map<Id, String>();
        businessUnitNames = new Map<Id, String>();
        employeesByEmail = new Map<String, SFDC_Employee__c>();
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore() {
    }

    public void bulkAfter() {
        if(Trigger.isInsert || Trigger.isUpdate) {
            businessUnitNames = EmployeeGateway.getEmployeeBusinessUnitNames(Trigger.newMap.keySet());
        }
    }

    public void beforeInsert(SObject so) {
        SFDC_Employee__c emp = (SFDC_Employee__c) so;
        if(!String.isBlank(emp.Email_Address__c)) {
            employeesByEmail.put(emp.Email_Address__c, emp);
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        SFDC_Employee__c emp = (SFDC_Employee__c) so;
        if(!String.isBlank(emp.Email_Address__c) && emp.SF_User__c == null) {
            employeesByEmail.put(emp.Email_Address__c, emp);
        }
    }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        SFDC_Employee__c emp = (SFDC_Employee__c) so;
        updateBusinessUnitNameOnUser(emp);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        SFDC_Employee__c emp = (SFDC_Employee__c) so;
        SFDC_Employee__c oldEmp = (SFDC_Employee__c) oldSo;
        if (oldEmp.Business_Unit__c != emp.Business_Unit__c) {
            updateBusinessUnitNameOnUser(emp);
        }
    }

    public void afterDelete(SObject so) {
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this 
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        if(usersToUpdate.size() > 0) {
            Database.executeBatch(new UpdateUserBusinessUnitBatch(usersToUpdate));
        }

        if(employeesByEmail.size() > 0) {
            EmployeeGateway.setUsersOnEmployees(employeesByEmail);
        }
    }

    public boolean skipExecution() {
        return skipExecution;
    }

    private void updateBusinessUnitNameOnUser(SFDC_Employee__c emp) {
        if(emp.SF_User__c != null && emp.Business_Unit__c != null) {
            usersToUpdate.put(emp.SF_User__c, businessUnitNames.get(emp.Business_Unit__c));
        }
    }
}