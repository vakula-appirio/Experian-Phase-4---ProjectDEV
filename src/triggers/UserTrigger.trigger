/**=====================================================================
 * Appirio, Inc
 * Trigger Name: UserTrigger
 * Handler Class: UserTriggerHandler  
 * Description: T-264687
 * Created Date: Apr 2nd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 9th, 2014                Arpita Bose(Appirio)         T-269989: Added beforeInsert and beforeUpdate
 *                                                           for Multi-currency validation
 * Sept 02, 2014                Richard Joseph               To add CPQ user creation   from salesforce 
                                                                 after a new user is created.
 =====================================================================*/
trigger UserTrigger on User (after update, before insert, before update, after Insert) {
  
    //Ensure a data admin is not loading the data, so the triggers will not fire
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                                                            TriggerState.isActive(Constants.USER_TRIGGER)) {
      //After update call
      if(Trigger.isAfter && Trigger.isUpdate) {
        UserTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
      }
      //Before insert call
      if (Trigger.isBefore && Trigger.isInsert) {
      UserTriggerHandler.beforeInsert(trigger.New); 
    }
    //After insert call
    if (Trigger.isAfter && Trigger.isInsert) {
      UserTriggerHandler.afterInsert(trigger.New); 
    }
    //Before Update call
      if (Trigger.isBefore && Trigger.isUpdate) {
      UserTriggerHandler.beforeUpdate(trigger.NewMap, trigger.OldMap);
    } 
    }     
}