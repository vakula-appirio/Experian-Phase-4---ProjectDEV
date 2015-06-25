/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_TeamTrigger
 * Description: Trigger on Account_Plan_Team__c (for T-275542)
 * Created Date: May 1st, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 =====================================================================*/
trigger Account_Plan_TeamTrigger on Account_Plan_Team__c (before insert, before update, before delete, after undelete) {
	//Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
                              TriggerState.isActive(Constants.ACCOUNT_PLAN_TEAM_TRIGGER)) {
    if(Trigger.isBefore){    
    	if(Trigger.isInsert){  
        Account_Plan_TeamTriggerHandler.beforeInsert(Trigger.new);
    	}
    	if(Trigger.isUpdate){
    		Account_Plan_TeamTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    	}
    	if(Trigger.isDelete){
    		Account_Plan_TeamTriggerHandler.beforeDelete(Trigger.old);
    	}
    }
    
    if(Trigger.isAfter){
    	if(Trigger.isUnDelete){
    		Account_Plan_TeamTriggerHandler.afterUnDelete(Trigger.new);
    	}
    }
  }
}