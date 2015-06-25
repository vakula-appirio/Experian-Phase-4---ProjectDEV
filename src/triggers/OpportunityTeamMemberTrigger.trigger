/**=====================================================================
 * Appirio, Inc
 * Trigger Name: OpportunityTeamMemberTrigger
 * Handler Class: OpportunityTeamMemberTriggerHandler  
 * Description: T-266946: Synching OpportunityTeamMembers & Confidential Information Share
 * Created Date: Mar 28th, 2014	
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
trigger OpportunityTeamMemberTrigger on OpportunityTeamMember (after delete, after insert, after update) {
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (TriggerState.isActive(Constants.OPPTYTEAMMEMBER_TRIGGER) && 
  										IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
		//After Insert Call
    if (trigger.isAfter && trigger.isInsert) {
      OpportunityTeamMemberTriggerHandler.afterInsert (Trigger.new);
    }
    //After Update Call
    if (trigger.isAfter && trigger.isUpdate) {
      OpportunityTeamMemberTriggerHandler.afterUpdate (Trigger.newMap, Trigger.oldMap);
    }
    //After Delete Call
    if (trigger.isAfter && trigger.isDelete) {
      OpportunityTeamMemberTriggerHandler.afterDelete (Trigger.oldMap);
    }
  }
}