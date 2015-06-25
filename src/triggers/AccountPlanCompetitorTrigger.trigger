/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AccountPlanCompetitorTrigger
 * Handler Class: AccountPlanCompetitorTriggerHandler  
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 28th, 2015               Naresh Kr Ojha               T-356475: Refactoring trigger
 =====================================================================*/
trigger AccountPlanCompetitorTrigger on Account_Plan_Competitor__c (before insert, before update) {

  if (TriggerState.isActive(Constants.ACCOUNTPLANCOMPETITOR_TRIGGER) && 
                         IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    //Before insert call
    if (trigger.isBefore && trigger.isInsert) {
      AccountPlanCompetitorTriggerHandler.beforeInsert(Trigger.new);
    }
    //Before Update call
    if (trigger.isBefore && trigger.isUpdate) {
      AccountPlanCompetitorTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
  }

}