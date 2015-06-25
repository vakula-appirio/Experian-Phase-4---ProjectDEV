/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlan_CSF_Trigger
 * Handler Class: AccountPlan_CSF_TriggerHandler  
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 28th, 2015               Naresh Kr Ojha               T-356475: Refactoring trigger
 =====================================================================*/
trigger AccountPlan_CSF_Trigger on Account_Plan_Critical_Success_Factor__c (before insert, before update) {
  
  if (TriggerState.isActive(Constants.ACCOUNTPLAN_CSF_TRIGGER) && 
                         IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    // Before insert call
    if (trigger.isBefore && trigger.isInsert) {
      AccountPlan_CSF_TriggerHandler.beforeInsert(Trigger.new);
    }
    // Before Update call
    if (trigger.isBefore && trigger.isUpdate) {
      AccountPlan_CSF_TriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}