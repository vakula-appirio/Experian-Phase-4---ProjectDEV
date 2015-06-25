/**=====================================================================
 * Appirio, Inc
 * Name: CaseCommentTrigger 
 * Description: T-376602: Trigger to update case comments on child records
 *
 * Created Date: April 24th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By              Description of the update
 ======================================================================*/
trigger CaseCommentTrigger on CaseComment (after insert) {
  if (TriggerState.isActive(Constants.CASE_COMMENT_TRIGGER)) {
      if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {  
          if (Trigger.isAfter){
             if (Trigger.isInsert) {
               CaseCommentTriggerHandler.afterInsert(Trigger.new);    
             } 
          }
      }
  }    
}