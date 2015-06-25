/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ARIAPlanTrigger
 * Handler Class:  ARIAPlanTriggerHandler
 * Description: T-264687: Update related AriaBillingAccount to push to ARIA
 * Created Date: Apr 02nd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger ARIAPlanTrigger on ARIA_Plan__c (after update) {
	//Ensure a data admin is not loading the data, so the triggers will not fire
	if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
																			TriggerState.isActive(Constants.ARIAPLAN_TRIGGER)) {
	  //After update call
	  if(Trigger.isAfter && Trigger.isUpdate) {
	  	ARIAPlanTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
	  } 
	}	
}