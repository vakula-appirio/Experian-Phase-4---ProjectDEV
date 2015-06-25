/**=====================================================================
 *  * Name: ProductCountryTrigger 
 * Description: Trigger on Product_Country__c
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
trigger ProductCountryTrigger on  Product_Country__c (after insert, after update) {
  //Commented out after inital Data Load. 
  //if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&  !ProductMasterUpdateHelper.isRecursive)
  if (!ProductMasterUpdateHelper.isRecursive && TriggerState.isActive('ProductCountryTrigger'))
  {
    if (Trigger.isInsert && Trigger.isAfter) {
      ProductCountryTriggerHandler.afterInsert(Trigger.newMap);
    }
    else if (Trigger.isUpdate && Trigger.isAfter) {
      ProductCountryTriggerHandler.afterupdate(Trigger.newMap , Trigger.oldMap);  
    }
  }
}