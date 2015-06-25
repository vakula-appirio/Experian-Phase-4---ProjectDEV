/**=====================================================================
 * Appirio, Inc
 * Name: ESDEL_TimecardTrigger
 * Description: Trigger on ESDEL_Timecard__c (for T-270393 and T-270392)
 * Created Date: April 18th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 =====================================================================*/
trigger ESDEL_TimecardTrigger on ESDEL_Timecard__c (after insert, after update, after delete) {
  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false &&
                              TriggerState.isActive(Constants.ESDEL_TIMECARD_TRIGGER)) {
    // check for after operation                          	
    if(Trigger.isAfter){
    	// check of insert operation
      if(Trigger.isInsert){
        ESDEL_TimecardTriggerHandler.afterInsert(Trigger.new);
    	}
    	// check for update operation 
    	if(Trigger.isUpdate){
        ESDEL_TimecardTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
      }
      // check for delete operation 
      if(Trigger.isDelete){
        ESDEL_TimecardTriggerHandler.afterDelete(Trigger.old);
      }       
    }
  }
}