/**=====================================================================
 *  * Name: ProductRegionTrigger 
 * Description: Trigger on Product_Region__c
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
trigger ProductRegionTrigger on  Product_Region__c (after insert, after update) {
  //Commented out after inital Data Load. 
  //if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&   !ProductMasterUpdateHelper.isRecursive)
  if (!ProductMasterUpdateHelper.isRecursive && TriggerState.isActive('ProductRegionTrigger'))
  {
    if (Trigger.isInsert && Trigger.isAfter) {   
      ProductRegionTriggerHandler.afterInsert(Trigger.newMap);
    }
    else if (Trigger.isupdate && Trigger.isafter) { 
      ProductRegionTriggerHandler.afterupdate(Trigger.newMap , Trigger.oldMap);
    }       
  }
}