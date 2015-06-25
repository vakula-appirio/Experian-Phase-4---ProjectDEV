/**=====================================================================
 *  * Name: ProductMasterTrigger 
 * Description: Trigger on Product_Master__c
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
trigger ProductMasterTrigger on Product_Master__c (after insert, after update) {
    
    //Commented it after inital Data load
    //if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false )   
    //{
  if (TriggerState.isActive('ProductMasterTrigger')) 
  { 
  if (Trigger.isInsert && Trigger.isAfter) {
    ProductMasterTriggerHandler.afterInsert(Trigger.newMap);
  }
  else if (Trigger.isupdate && Trigger.isafter) {
    ProductMasterTriggerHandler.afterupdate(Trigger.newMap , Trigger.oldMap);
  } 
  }     
   // }
}