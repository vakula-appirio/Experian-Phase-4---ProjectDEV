/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlanContactTrigger
 * Handler Class: AccountPlanContactTriggerHandler  
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger AccountPlanContactTrigger on Account_Plan_Contact__c (before insert, before update) {
  if(trigger.isBefore){
      if(trigger.isInsert){
        AccountPlanContactTriggerHandler.beforeInsert(Trigger.new);
      }
      if(trigger.isUpdate){
        AccountPlanContactTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
      }
  }

}