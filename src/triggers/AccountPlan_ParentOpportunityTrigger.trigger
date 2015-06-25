/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlan_ParentOpportunityTrigger
 * Handler Class: AccountPlan_ParentOppTriggerHandler  
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger AccountPlan_ParentOpportunityTrigger on Account_Plan_Parent_Opportunities__c (before insert, before update) {
  if(trigger.isBefore){
      if(trigger.isInsert){
        AccountPlan_ParentOppTriggerHandler.beforeInsert(Trigger.new);
      }
      if(trigger.isUpdate){
        AccountPlan_ParentOppTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
      }
  }

}