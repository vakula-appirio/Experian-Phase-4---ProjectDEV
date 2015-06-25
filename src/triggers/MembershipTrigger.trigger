/**============================================================================
 * Appirio, Inc
 * Name             : MembershipTrigger
 * Description      : T-362372: Trigger on the Membership object
 * Created Date     : Feb 16th, 2015
 * Created By       : Noopur 
 * 
 * Date Modified          Modified By          Description of the update
 * Feb 26th, 2015      Gaurav Kumar Chadha     T-365462 - added after Update
 =============================================================================*/
trigger MembershipTrigger on Membership__c (after insert , after update) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                        TriggerState.isActive(Constants.MEMBERSHIP_TRIGGER)) {
    if (Trigger.isAfter && Trigger.isInsert ) {
      MembershipTriggerHandler.OnAfterInsert( trigger.new );
    }
    if (Trigger.isAfter && Trigger.isUpdate ) {
      MembershipTriggerHandler.OnAfterUpdate( trigger.new , trigger.oldmap);
    }
  }
}