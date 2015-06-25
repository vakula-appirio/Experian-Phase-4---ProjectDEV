/*******************************************************************************
 * Appirio, Inc
 * Name: AssignmentTeamMemberTrigger
 * Description: Trigger on Assignment_Team_Member__c custom object (for T-358272)
 * Created Date: Feb 03rd, 2013
 * Created By: Naresh kr Ojha (Appirio)
 *
 * Date Modified       Modified By                  Description of the update
 * May 19th, 2015      Nathalie Le Guay             Remove isDataAdmin check - this 
 *                                                  should run for the DM team as they
 *                                                  update these updates are relevant
 *******************************************************************************/
trigger AssignmentTeamMemberTrigger on Assignment_Team_Member__c (before insert) {
  
  if (TriggerState.isActive(Constants.ASSIGNMENTTEAMMEMBER_TRIGGER) /*&& 
                        IsDataAdmin__c.getInstance().IsDataAdmin__c == false*/) {
      //Before Insert call
      if (trigger.isBefore && trigger.isInsert) {
        AssignmentTeamMemberTriggerHandler.beforeInsert (Trigger.new);
      }     
  }
}