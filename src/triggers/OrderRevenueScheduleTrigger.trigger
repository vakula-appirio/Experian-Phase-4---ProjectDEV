/**=====================================================================
 * Appirio, Inc
 * Name: OrderRevenueScheduleTrigger
 * Description: Trigger on Order Revenue Schedule
 * Created Date: Feb 10th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified    Modified By        Description of the update
 * Apr 30th, 2013		Naresh Kr Ojha		 I-113908: Update Currency when inserting added onBeforeInsert() call
 =====================================================================*/
trigger OrderRevenueScheduleTrigger on Order_Revenue_Schedule__c (after insert, after update, before insert, 
before update, before delete, after delete) {

  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('OrderRevenueScheduleTrigger')) {
    // =========================================================================
    // After insert call with new values as list
    // =========================================================================
    if (Trigger.isBefore && trigger.isInsert) {
      OrderRevenueScheduleTriggerHandler.onBeforeInsert(Trigger.new);
    }

    // =========================================================================
    // After insert call with new values as list
    // =========================================================================
    else if (Trigger.isAfter && Trigger.isInsert) {
      OrderRevenueScheduleTriggerHandler.onAfterInsert(Trigger.new);
    }

    //==========================================================================
    //On after update trigger method
    //==========================================================================
    else if (Trigger.isAfter && Trigger.isUpdate) {
      OrderRevenueScheduleTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    //==========================================================================
    //On before delete trigger method
    //==========================================================================
    else if (Trigger.isAfter && Trigger.isDelete) {
      OrderRevenueScheduleTriggerHandler.onAfterDelete(Trigger.oldMap);
    }
    
    
  }
}