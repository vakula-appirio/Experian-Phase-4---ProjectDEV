/**=====================================================================
 * Experian plc
 * Name: SalesSupportRequestTrigger
 * Description: Trigger on Sales_Support_Request__c
 * Created Date: Dec 5th, 2014
 * Created By: James Weatherall
 * 
 * Date Modified      Modified By                Description of the update
 * Mar 5th, 2015	  James Weatherall			 Added beforeInsert and beforeUpdate methods
 =====================================================================*/

trigger SalesSupportRequestTrigger on Sales_Support_Request__c (before insert, before update, after insert) {
    
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
                              TriggerState.isActive(Constants.SALES_SUPPORT_REQUEST_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isInsert) {
      SalesSupportRequestTriggerHandler.beforeInsert(Trigger.new);
    }
                                  
    if (Trigger.isBefore && Trigger.isUpdate) {
      SalesSupportRequestTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
    }
                                  
    if (Trigger.isAfter && Trigger.isInsert) {
      SalesSupportRequestTriggerHandler.afterInsert(Trigger.newMap);
    }
  }
}