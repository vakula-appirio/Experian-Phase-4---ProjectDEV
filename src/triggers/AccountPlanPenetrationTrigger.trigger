/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlanPenetrationTrigger
 * Handler Class: AccountPlanPenetrationTriggerHandler  
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger AccountPlanPenetrationTrigger on Account_Plan_Penetration__c (before insert, before update) {
  if(trigger.isBefore){
      if(trigger.isInsert){
        AccountPlanPenetrationTriggerHandler.beforeInsert(Trigger.new);
      }
      if(trigger.isUpdate){
        AccountPlanPenetrationTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
      }
  }

}