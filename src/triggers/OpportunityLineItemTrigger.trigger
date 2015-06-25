/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityLineItemTrigger
 * Description: T-211312
 * Created Date: Nov 13th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Naresh Kr Ojha(Appirio)      T-232755: Homogenize triggers
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 19th, 2014               Naresh kr Ojha (Appirio)     T-T-250093: Exchange Rate: Change workflow to OLI trigger.
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 20th, 2014               Naresh Kr Ojha               T-260617: Populating service start/end date on OLIs and Oppties.
 * Sep 11, 2014                 Mohit Parnama                T-318596: added after delete
 * Sep 16, 2014                 Naresh Kr Ojha               Updated calling for before updated, passed oldMap too, Also did not find
 *                                                           after delete method in trigger handler, and its giving compile error so 
                                                             commented the call for now - NLG readded call to delete 2014-09-17
 =====================================================================*/

trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, before insert, before update, after delete) {
   
    //Ensure a data admin is not loading the data, so the triggers will not fire
    //if ((Trigger.isbefore || trigger.isUpdate) && IsDataAdmin__c.getInstance().IsDataAdmin__c ==false && TriggerState.isActive('OpportunityLineItemTrigger')){
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                                TriggerState.isActive(Constants.OPPTY_LINE_ITEM_TRIGGER)) {
        
    //Before insert call
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityLineItemTriggerHandler.beforeInsert(Trigger.new);
    }
    //After insert call
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityLineItemTriggerHandler.afterInsert(Trigger.newMap);
    }
    if (Trigger.isbefore && Trigger.isUpdate) {     
        OpportunityLineItemTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
    }
    //After update call
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityLineItemTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
      OpportunityLineItemTriggerHandler.afterDelete(Trigger.oldMap);
    }
  }//END:IF DataAdmin bypass          
}