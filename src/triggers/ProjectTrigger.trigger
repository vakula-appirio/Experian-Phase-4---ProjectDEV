/**=====================================================================
 * Appirio, Inc
 * Name: ProjectTrigger
 * Description: Trigger on Project
 * Created Date: Jul 31st, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified         Modified By                  Description of the update
 * Jul 31, 2014          Nathalie Le Guay             After insert/update events
 * Aug 01, 2014          Naresh Kr Ojha         Before delete event
 * May 29th, 2015        Paul Kissick                 Added before insert/update
  =====================================================================*/
trigger ProjectTrigger on Project__c (before insert, before update, after insert, after update, before delete) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('ProjectTrigger')) {
    // Before insert call with new values as list
    // =========================================================================
    if (trigger.isBefore && trigger.isInsert) {
      ProjectTriggerHandler.beforeInsert(trigger.new);
    }
  
  
    // =========================================================================
    // before update call with new values as list and prior values as map.
    // =========================================================================
    if (trigger.isBefore && trigger.isUpdate) {
      ProjectTriggerHandler.beforeUpdate(trigger.newMap, trigger.oldMap);
    } 
  
  
    // After insert call with new values as list
    // =========================================================================
    if (trigger.isAfter && trigger.isInsert) {
      ProjectTriggerHandler.afterInsert(trigger.new);
    }
    

    // =========================================================================
    // After update call with new values as list and prior values as map.
    // =========================================================================
    if (trigger.isAfter && trigger.isUpdate) {
      ProjectTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
    } 
    //==========================================================================
    // Before delete call with old values as list.
    //==========================================================================
    if (trigger.isBefore && trigger.isDelete) {
       ProjectTriggerHandler.beforeDelete(trigger.old); 
    }
  }
}