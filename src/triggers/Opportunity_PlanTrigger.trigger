/**=====================================================================
 * Appirio, Inc
 * Name: Opportunity_PlanTrigger
 * Description: Trigger on Opportunity_Plan__c (for T-273695)
 * Created Date: April 25th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified        Modified By             Description of the update 
 * April 30th, 2014     Sonal Shrivastava       T-273788: Added after update functionality
 * July  17th, 2014     Arpita Bose(Appirio)    I-120989: To synch currencies in related object of Opportunity
 =====================================================================*/
trigger Opportunity_PlanTrigger on Opportunity_Plan__c (after insert, after update, before insert, before update) { 
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
              TriggerState.isActive(Constants.OPPORTUNITY_PLAN_TRIGGER)) {
    if(Trigger.isInsert && Trigger.isAfter){
      Opportunity_PlanTriggerHandler.afterInsert(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isAfter){
      Opportunity_PlanTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap); 
    }
    if(Trigger.isInsert && Trigger.isBefore){
      Opportunity_PlanTriggerHandler.beforeInsert(Trigger.new); 
    }
    if(Trigger.isUpdate && Trigger.isBefore){
      Opportunity_PlanTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap); 
    }
  }
}