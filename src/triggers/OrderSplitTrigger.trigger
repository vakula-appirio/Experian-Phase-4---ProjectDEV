/**=====================================================================
 * Appirio, Inc
 * Trigger Name: OrderSplitTrigger
 * Handler Class:  
 * Description: * I-113908: Update Currency when inserting, currency should be same with parent
 * Created Date: Apr 30th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger OrderSplitTrigger on Order_Split__c (before insert) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('OrderSplitTrigger')) {
  	//On before insert call.
  	if (Trigger.isBefore && Trigger.isInsert) {
  		OrderSplitTriggerHandler.onBeforeInsert(Trigger.new);
  	}
  }
}