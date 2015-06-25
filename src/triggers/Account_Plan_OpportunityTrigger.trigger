/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_OpportunityTrigger
 * Description: Account_Plan_OpportunityTrigger on Account_Plan_Opportunity__c (for T-276706)
 * Created Date: May 6th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 * May 19th, 2014	  Naresh Kr Ojha (Appirio)	 T-278987: update Account Plan Parent Opps
 * Jul 14th, 2014     Arpita Bose (Appirio)      I-120524: Added beforeInsert
 =====================================================================*/
trigger Account_Plan_OpportunityTrigger on Account_Plan_Opportunity__c (after insert, 
                                           after update, after delete, after undelete, before update, before insert) {  
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
                              TriggerState.isActive(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER)) {    
    //After Insert call
    if(Trigger.isAfter && Trigger.isInsert){
      Account_Plan_OpportunityTriggerHandler.afterInsert(Trigger.new);
    }
    //After Update Call 
    else if (Trigger.isAfter && Trigger.isUpdate) {
    	Account_Plan_OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
    //After delete call 
    else if (Trigger.isAfter && Trigger.isDelete) {
    	Account_Plan_OpportunityTriggerHandler.afterDelete(Trigger.oldMap);
    } 
    //After undelete call
    else if (Trigger.isAfter && Trigger.isUnDelete) {
    	Account_Plan_OpportunityTriggerHandler.afterUnDelete(Trigger.new);
    }
    //Before Insert call 
    else if (Trigger.isBefore && Trigger.isInsert) {
        Account_Plan_OpportunityTriggerHandler.beforeInsert(Trigger.new);
    } 
    //Before update call
    else if (Trigger.isBefore && Trigger.isUpdate) {
    	Account_Plan_OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}