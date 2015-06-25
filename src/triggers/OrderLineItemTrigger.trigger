/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineItemTrigger
 * Description: Trigger on Order Line Item
 * Created Date: Feb 06rd, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified         Modified By                  Description of the update
 * Feb 10th, 2014        Nathalie Le Guay (Appirio)   Added settings check + onBeforeUpdate()
 * Mar 20th, 2014        Megha Aagrwal (Appirio JDC)  Added before insert 
  =====================================================================*/

trigger OrderLineItemTrigger on Order_Line_Item__c (before insert, before update, after insert, after update, before delete, after delete) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('OrderLineItemTrigger')) {
     // =========================================================================
    // before insert call with new values as list
    // =========================================================================
    if (trigger.isBefore && trigger.isInsert) {
      OrderLineItemTriggerHandler.onBeforeInsert(trigger.new);
    }
    // =========================================================================
    // After insert call with new values as list
    // =========================================================================
    if (trigger.isAfter && trigger.isInsert) {
      OrderLineItemTriggerHandler.onAfterInsert(trigger.new);
    }

    // =========================================================================
    // Before update call with new values as map and prior values as map.
    // =========================================================================
    else if (trigger.isBefore && trigger.isUpdate) {
      OrderLineItemTriggerHandler.onBeforeUpdate(trigger.newMap, trigger.oldMap);
    }

    // =========================================================================
    // After update call with new values as list and prior values as map.
    // =========================================================================
    else if (trigger.isAfter && trigger.isUpdate) {
      OrderLineItemTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
    }

    // =========================================================================
    // Before delete call with new values as list and prior values as map.
    // =========================================================================
    //else if (trigger.isBefore && trigger.isDelete) {
    //  OrderLineItemTriggerHandler.onBeforeDelete(trigger.oldMap);
    //}
    // =========================================================================
    // After delete call with new values as list and prior values as map.
    // =========================================================================
    else if (trigger.isAfter && trigger.isDelete) {
      OrderLineItemTriggerHandler.onAfterDelete(trigger.oldMap);
    }
  }
}