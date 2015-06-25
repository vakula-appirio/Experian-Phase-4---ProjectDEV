/**=====================================================================
 * Appirio, Inc
 * Name: ContactTrigger
 * Description: Add Owner to Contact Team.
 * Created Date: Dec 12th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified        Modified By                Description of the update
 * Jan 30th, 2014       Naresh Kr Ojha(Appirio)    T-232755: Homogenize triggers
 * Jan 30th, 2014       Jinesh Goyal(Appirio)      T-232760: Homogenize the comments
 * Mar 04th, 2014       Arpita Bose(Appirio)       T-243282: Added Constants in place of String
 * Aug 26th, 2014       Noopur (Appirio)           T-313856: added logic for before update and before insert
 * Feb 6th, 2015	      Paul Kissick               Adding logic for after delete (CASE #50069)
 * Mar 9th, 2015        Paul Kissick               Case #583339: Moved the isAfter AND isDelete to outside of the 'IsDataAdmin' check
 =====================================================================*/

trigger ContactTrigger on Contact (after insert,after update,before insert,before update, after delete) {

  //Skip if Trigger is disabled.
  if (TriggerState.isActive(Constants.CONTACT_TRIGGER)) {
  	
  	// Skip if IsDataAdmin
  	if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
  		if (Trigger.isAfter && Trigger.isInsert) {
        ContactTriggerHandler.afterInsert(Trigger.new); 
      }
      if (Trigger.isAfter && Trigger.isUpdate) {
	      ContactTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap); 
	    }
	    if(Trigger.isBefore && Trigger.isUpdate){
	      ContactTriggerHandler.beforeUpdate(Trigger.new,Trigger.oldMap);
	    }
  	}
  	
  	if (Trigger.isAfter && Trigger.isDelete) {
      ContactTriggerHandler.afterDelete(Trigger.oldMap);
    }
  	
  }
}//END: trigger.