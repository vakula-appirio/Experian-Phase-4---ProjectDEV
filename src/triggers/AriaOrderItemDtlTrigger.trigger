/**=====================================================================
 * Experian LLC 
 * Name: AriaOrderItemDetailTrigger
 * Description: Trigger on ARIA_Order_Items_Detail__c
 * Created Date: May 27th, 2015
 * Created By: Sadar Yacob (Experian)
 * 
 * Date Modified      Modified By                Description of the update
 =====================================================================*/
trigger AriaOrderItemDtlTrigger on ARIA_Order_Items_Detail__c(before delete,before insert) 
{
    
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false )
  {
         if (Trigger.isBefore && Trigger.isDelete) 
         {
             AriaOrderItemDtlTriggerHandler.beforeDelete(Trigger.old);
         }
        
  }
}