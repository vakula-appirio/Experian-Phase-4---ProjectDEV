/**=====================================================================
 * Appirio, Inc
 * Name: CaseTrigger
 * Description: T-208210                 
 * Created Date: Nov 08th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Dec 16th, 2013               Sadar Yacob                  provide support for After Insert to the trigger
                                                             to add the Case Requestor to the case Team Member 
 * Dec 19th, 2013               MIrfan                       afterInsert handler
 * Jan 30th, 2014               Naresh Kr Ojha(Appirio)      Code alignment and conventions.
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose(Appiiro)         T-243282: Added Constants in place of String
 * Apr 22nd, 2014               Rahul Jain                   Added beforeUpdate and beforeInsert operation for T-270394
 * Jun 20th, 2014               Richard Joseph               Made is before Insert and Update . 
                                                             To populate the Requestor__c field from Requestor email.Case#1939
 * Aug 28th, 2014               Arpita Bose                  T-309768: Added code from CaseTrigger of the installed package 
 * Sep 04th, 2014               Arpita Bose                  T-310733: Added afterInsert and updated afterUpdate for adding
 *                                                           caseResolutionTimeTrackingProcess()
 * Nov 6th, 2014                Nathalie Le Guay             Fix to call to the future method: onAfterUpdateAsync not to be called during tests
  =====================================================================*/

trigger CaseTrigger on Case (before insert, before update, after insert, after update,
                               after undelete ) {
    
    // added for Task T-309768
    CaseTriggerHandler handler = new CaseTriggerHandler(Trigger.isExecuting, Trigger.size);
        
    //Ensure a data admin is not loading the data, so the triggers will not fire
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                     TriggerState.isActive(Constants.CASE_TRIGGER)) {
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                CaseTriggerHandler.beforeInsert(Trigger.new);
            }           
            if(Trigger.isUpdate){
                CaseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
                // added for Task T-309768
                handler.onBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap);
            }   
        }

        //MIrfan. 19Dec13. afterInsert handler.
        if (Trigger.isAfter){
             // added for T-310733
            if(Trigger.isInsert) {
                CaseTriggerHandler.afterInsert(Trigger.new);    
            } 
            if(Trigger.isUpdate) {
                CaseTriggerHandler.afterUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap);
                // added for Task T-309768
                handler.onAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap);
                if (!System.isBatch()) {
                  CaseTriggerHandler.onAfterUpdateAsync(Trigger.newMap.keySet());
                }
            }
            // added for Task T-309768
            if(Trigger.isUndelete){
                // Enable if needed
                //CaseTriggerHandler.OnUndelete(Trigger.new);    
            }
               
        }
    } //END:IF DataAdmin bypass        
}