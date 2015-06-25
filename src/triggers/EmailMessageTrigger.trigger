/**=====================================================================
 * Appirio, Inc
 * Name: EmailMessageTrigger
 * Description: T-311459: Trigger to update Case Sub Origin with email address                 
 * Created Date: Aug 11th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 
  =====================================================================*/
trigger EmailMessageTrigger on EmailMessage (after insert) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('EmailMessageTrigger')) {
    if(Trigger.isAfter && Trigger.isInsert){
      EmailMessageTriggerHandler.afterInsert(Trigger.new);
    }           
  }
}