/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_SWOTTrigger
 * Description: Account_Plan_SWOTTrigger on Account_Plan_SWOT__c (for T-276704)
 * Created Date: May 6th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update
 * Jul 14th, 2014     Arpita Bose(Appirio)       I-120524: Added beforeInsert and beforeUpdate 
 =====================================================================*/
trigger Account_Plan_SWOTTrigger on Account_Plan_SWOT__c (after insert, before insert, before update) {	
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
                              TriggerState.isActive(Constants.ACCOUNT_PLAN_SWOT_TRIGGER)) {   
    if(Trigger.isAfter){
    	if(Trigger.isInsert){
    		Account_Plan_SWOTTriggerHandler.afterInsert(Trigger.new);
    	}
    }
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Account_Plan_SWOTTriggerHandler.beforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            Account_Plan_SWOTTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } 
  }
}