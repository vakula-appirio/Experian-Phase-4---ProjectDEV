/**=====================================================================
 *  * Name: BillingProductTrigger 
 * Description: Trigger on Billing_Product__c
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
trigger BillingProductTrigger on  Billing_Product__c (after insert, after update) {
  //Commented out after inital Data Load. 
  //if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&  !ProductMasterUpdateHelper.isRecursive)
  if (!ProductMasterUpdateHelper.isRecursive && TriggerState.isActive('BillingProductTrigger'))
  {
    if (Trigger.isInsert && Trigger.isAfter) {
      BillingProductTriggerHandler.afterInsert(Trigger.newMap);
    }
    else if (Trigger.isUpdate && Trigger.isAfter) {
      BillingProductTriggerHandler.afterupdate(Trigger.newMap , Trigger.oldMap);
    }
  }
}