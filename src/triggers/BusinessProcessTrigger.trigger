/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTrigger
 * Description: T-360797: Action Plans: Code, added this trigger later.
 * Created Date: Feb 18th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 7th, 2015                Terri Kelllough              T-376624 added beforeInsert
  =====================================================================*/
  trigger BusinessProcessTrigger on Business_Process__c (before insert, after insert, before update, after update) {
  if (TriggerState.isActive(Constants.BUSINESSPROCESS_TRIGGER) && 
                          IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {

    if (Trigger.isBefore && Trigger.isInsert) {
      BusinessProcessTriggerHandler.beforeInsert(Trigger.new);
    }
    //After Insert call
    else if (Trigger.isAfter && Trigger.isInsert) {
      BusinessProcessTriggerHandler.afterInsert(Trigger.new);
    }
    
    else if (Trigger.isBefore && Trigger.isUpdate) {
      BusinessProcessTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
    //After Update Call
    else if (Trigger.isAfter && Trigger.isUpdate) {
      BusinessProcesstriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}