/**=====================================================================
 * Appirio, Inc
 * Name: OrderTrigger
 * Description: 
 * Created Date: Feb 5th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 19, 2014                 Nathalie Le Guay             multiCurrencyFieldUpdate() is now called from the trigger as it needs
 *                                                           to run during the data loads
 * Apr 14, 2015                 Naresh kr                    T-377401: Delete and undelete call
 =====================================================================*/
trigger OrderTrigger on Order__c (after insert, after update, before insert, before update, after undelete, after delete) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive(Constants.ORDER_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isInsert) {
      OrderTriggerHandler.beforeInsert(trigger.New);
    }
    else if (Trigger.isAfter && Trigger.isInsert) {
      OrderTriggerHandler.afterInsert(trigger.NewMap);
    }
    else if (Trigger.isBefore && Trigger.isUpdate) {
      OrderTriggerHandler.beforeUpdate(trigger.NewMap, trigger.OldMap);
    }
    else if (Trigger.isAfter && Trigger.isUpdate) {
      OrderTriggerHandler.afterUpdate(trigger.NewMap, trigger.OldMap);
    }
    else if (Trigger.isAfter && Trigger.isDelete) {
    	OrderTriggerHandler.afterDelete(Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUnDelete) {
    	OrderTriggerHandler.afterUnDelete(Trigger.newMap);
    }
  }
}