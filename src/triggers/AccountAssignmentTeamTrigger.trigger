/**=====================================================================
 * Appirio, Inc
 * Name: AccountAssignmentTeamTrigger
 * Description: T-354803
 * Created Date: Jan 21st, 2015
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * 21-Jan-2015                  Noopur                       Added logic for After Delete
  =====================================================================*/
trigger AccountAssignmentTeamTrigger on Account_Assignment_Team__c (after insert,after delete) {
	
	if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false 
                                  && TriggerState.isActive(Constants.ACCOUNT_ASSIGNMENT_TEAM_TRIGGER)) {
      //After insert
      if (Trigger.isAfter && Trigger.isInsert) {
        AccountAssignmentTeamTriggerHandler.afterInsert(Trigger.new);
      }
      
      //After delete
      if (trigger.isAfter && trigger.isDelete) {
      	AccountAssignmentTeamTriggerHandler.afterDelete(Trigger.oldMap);
      }
  }
  
  
}