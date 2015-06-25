/**=====================================================================
 * Appirio, Inc
 * Name: DeliveryLineTrigger
 * Description: Trigger on Delivery_Line__c
 * Created Date: Jul 31st, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified         Modified By                  Description of the update
 * Jul 31, 2014          Nathalie Le Guay             After insert/update events
 * May 29th, 2015        Paul Kissick                 Case #593374: After delete event added
  =====================================================================*/
trigger DeliveryLineTrigger on Delivery_Line__c (after insert, after update, after delete) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('DeliveryLineTrigger')) {
    // After insert call with new values as list
    // =========================================================================
    if (trigger.isAfter && trigger.isInsert) {
      DeliveryLineTriggerHandler.afterInsert(trigger.new);
    }

    // =========================================================================
    // After update call with new values as list and prior values as map.
    // =========================================================================
    if (trigger.isAfter && trigger.isUpdate) {
      DeliveryLineTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    }
    
    // =========================================================================
    // After delete call with old records as map.
    // =========================================================================
    if (trigger.isAfter && trigger.isDelete) {
      DeliveryLineTriggerHandler.afterDelete(trigger.oldMap);
    }
  }
}