/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlanTrigger
 * Handler Class: AccountPlanTriggerHandler  
 * Description: T-282464
 * Created Date: May 29th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 14th, 2014               Arpita Bose (Appirio)        I-120524: Added afterUpdate to synch currencies
 =====================================================================*/
trigger AccountPlanTrigger on Account_Plan__c (after insert, after update) {
    public String ACCOUNTPLAN_TRIGGER = 'AccountPlanTrigger';
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false 
       														&& TriggerState.isActive(ACCOUNTPLAN_TRIGGER)) {
			//After insert
		  if (Trigger.isAfter && Trigger.isInsert) {
		  	AccountPlanTriggerHandler.afterInsert(Trigger.new);
		  }
		      //After update
          if (Trigger.isAfter && Trigger.isUpdate) {
            AccountPlanTriggerHandler.afterUpdate(trigger.NewMap, trigger.OldMap);//I-120524
          } 
		}     
}