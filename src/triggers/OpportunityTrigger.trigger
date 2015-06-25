/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger
 * Description: Trigger on Opportunity standard object
 * Created Date: Oct 18th, 2013
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified       Modified By                  Description of the update
 * Oct 21st, 2013      MIRfan(Appirio)
 * Dec 24th, 2013      MIRfan(Appirio)
 * Oct 25th, 2013      MIRfan(Appirio)
 * Dec 04th, 2013      MIRfan(Appirio)
 * Jan 30th, 2014      Jinesh Goyal(Appirio)         T-232760: Homogenize the comments
 * Feb 7th, 2014       Jinesh Goyal(Appirio)         T-232755: Homogenize Trigger
 * Feb 17th, 2014      Nathalie Le Guay (Appirio)    Replaced the "isDataAdmin" checkt to update event only (BU Relationship recalculation)
 * Mar 04th, 2014      Arpita Bose(Appirio)          T-243282: Added Constants in place of String
 * Mar 24th, 2014      Tyaga Pati                    Added Check so that the IsDataAdmin Check is ignored for Users with Experian DQ Administration profile
 * May 02nd, 2014      Nathalie Le Guay              Adding checks on oppTriggerHasAlreadyRun to prevent recursive triggers
 * Apr 14th, 2015      Nathalie Le Guay              T-377400: added after undelete
 =====================================================================*/

trigger OpportunityTrigger on Opportunity (before insert, after insert, 
                                           before update, after update,
                                           before delete, after delete,
                                           after undelete) {

  Id profileId = userinfo.getProfileId();
  Global_Settings__c globalSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING); 
  //Tyaga Pati: Added additional check to below condition to allow DQ Administration people who
  // are part of the Data Admin to be able to add Opty Owner to Account Team

  if (TriggerState.isActive(Constants.OPPORTUNITY_TRIGGER) && IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    OpportunityTriggerHandler.isRunningOpportunityTrigger = true;
    //OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    if (trigger.isBefore) {
      system.debug('\n[OpportunityTrigger] Running before trigger');
      //Before Insert call
      if (trigger.isInsert) {
        OpportunityTriggerHandler.beforeInsert (Trigger.new);
      } 
    
      //Ensure a data admin is not loading the data, so the triggers will not fire
      //MIrfan, 241013.
      if (trigger.isUpdate) {
        OpportunityTriggerHandler.beforeUpdate( Trigger.newMap, Trigger.oldMap);
      }
      
      
      if (trigger.isDelete) {
        OpportunityTriggerHandler.beforeDelete(Trigger.oldMap);
      }
    }

    if (trigger.isAfter) {
      system.debug('\n[OpportunityTrigger] Running after trigger');
      //MIrfan, 211013.
      if (trigger.isInsert) {
        OpportunityTriggerHandler.afterInsert (Trigger.newMap);
      }

      if (trigger.isUpdate) { 
        OpportunityTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
      }
    }
      if(trigger.isDelete) {
      	OpportunityTriggerHandler.afterDelete(Trigger.oldMap);
      }
      if(trigger.isUndelete) {
        OpportunityTriggerHandler.afterUndelete(Trigger.newMap);
      }
   
    //system.debug('\n[OpportunityTrigger] Setting to has already run: '+ oppTriggerHasAlreadyRun);
     //}//END: IF IsDataAdmin
  }//END: IF TriggerSetting
  
  //This section will be called only when People with  (???)
  else if (TriggerState.isActive(Constants.OPPORTUNITY_TRIGGER)
        && (profileId == globalSettings.ExpDQAdminProfileId__c || IsDataAdmin__c.getInstance().IsDataAdmin__c == false ))
  {
    if (trigger.isAfter && trigger.isUpdate) {
      OpportunityTriggerHandler.afterUpdateForDQTeam (Trigger.newMap, Trigger.oldMap);
    }

  } 
}