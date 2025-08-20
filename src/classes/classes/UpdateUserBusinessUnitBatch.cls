public without sharing class UpdateUserBusinessUnitBatch implements Database.Batchable<User>, Database.Stateful {

    private Map<Id, String> userBuMap;

    public UpdateUserBusinessUnitBatch(Map<Id, String> userBuMap) {
        this.userBuMap = userBuMap;
    }

    public List<User> start(Database.BatchableContext context) {
       return [SELECT Id, Business_Unit_Name__c FROM User WHERE Id IN: userBuMap.keySet()];
    }

    public void execute(Database.BatchableContext context, List<User> scope) {
        List<User> usersToUpdate = new List<User>();
        for (User u : scope) {
            u.Business_Unit_Name__c = this.userBuMap.get(u.Id);
            usersToUpdate.add(u);
        }
        if (usersToUpdate.size() > 0) {
            update usersToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}