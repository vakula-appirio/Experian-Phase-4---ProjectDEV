/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessItemTrigger
 * Description: T-360797: Action Plans: Code
 * Created Date: Feb 10th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 26th, 2015               Nathalie Le Guay (Appirio)   T-373784: beforeUpdate()
  =====================================================================*/
 // Assumptions:
 // 1. Assume ProjectWorkItem has an attribute of Status__c 
 // 2. Assume Status__c has a value of 'Active'
trigger BusinessProcessItemTrigger on Business_Process_Item__c (before insert, before update, after update) {
  
  if (TriggerState.isActive(Constants.BUSINESSPROCESSITEM_TRIGGER) && 
                          IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    if (Trigger.isBefore && Trigger.isInsert) {
      BusinessProcessItemTriggerHandler.beforeInsert(Trigger.New);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
      BusinessProcessItemTriggerHandler.beforeUpdate(Trigger.New, Trigger.oldMap);
    }
    // After Update call
    if (Trigger.isAfter && Trigger.isUpdate) {
      BusinessProcessItemTriggerHandler.afterUpdate (Trigger.new, Trigger.old);
    }
  }
}