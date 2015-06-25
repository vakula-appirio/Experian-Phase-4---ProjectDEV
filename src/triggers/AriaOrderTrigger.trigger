/**=====================================================================
 * Experian LLC 
 * Name: AriaOrderTrigger
 * Description: Trigger on ARIA_Order__c
 * Created Date: April 1st, 2014
 * Created By: Sadar Yacob (Experian)
 * 
 * Date Modified      Modified By                Description of the update
 =====================================================================*/
trigger AriaOrderTrigger on ARIA_Order__c (before delete,before insert) 
{
    
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false )
                              // && TriggerState.isActive(Constants.ARIA_ORDER_TRIGGER)) 
  {
         if (Trigger.isBefore && Trigger.isDelete) 
         {
             AriaOrderTriggerHandler.beforeDelete(Trigger.old);
         }
        
  }
}