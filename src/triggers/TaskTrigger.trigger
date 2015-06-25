/**=====================================================================
 * Appirio, Inc
 * Name: TaskTrigger
 * Description: Trigger on Task
 * Created Date: Nov 12th, 2013
 * Created By: Isaac Lehr (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Nov 22nd, 2013               MIrfan(Appirio)              Pass List of Task to update corresponding Opps.
 * Jan 30th, 2014               Naresh Kr Ojha(Appirio)      T-232755: Homogenize triggers
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Jan 31th, 2014               Naresh Kr Ojha (Appirio)     T-235305: Updated as per description on task for Feedback on EA code.
 * Mar 04th, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String   
 * Jul 31st, 2014               Nathalie Le Guay             T-309151: Uncomment (or 'reactivate') trigger
 * Aug 01st, 2014               Bharti Mehta (Appirio)       S-209627: Account Planning
 =====================================================================*/ 
 trigger TaskTrigger on Task (before insert, before update, after insert, after update, after delete) {
 	
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                       TriggerState.isActive(Constants.TASK_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isInsert) {
      TaskTriggerHandler.beforeInsert(Trigger.new);                                           
    } else if (Trigger.isAfter && Trigger.isInsert) {
      TaskTriggerHandler.afterInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
      TaskTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isDelete) {
      TaskTriggerHandler.afterDelete();
    }
  }
}