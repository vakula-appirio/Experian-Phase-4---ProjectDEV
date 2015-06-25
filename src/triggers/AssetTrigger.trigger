/**********************************************************************************
 * Appirio, Inc
 * Name: AssetTrigger
 * Description: Trigger on Asset standard object
 * Created Date: Sept 18th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified       Modified By                  Description of the update
 * Oct 13th, 2014      Arpita Bose(Appirio)         T-325339: Updated as AssetTriggerHandler.cls implements AssetInterface
 * Feb 12th, 2015      Naresh                       T-360562: Added delete and undelete call on after trigger
 * Apr 23th, 2014      Richard Joseph               Case # 00607940- To remove RPI whenever an Asset is retaged.Added before update event.
 *********************************************************************************/
trigger AssetTrigger on Asset (after insert, before update, after update, before delete, after delete, after undelete) {


   if (TriggerState.isActive(Constants.ASSET_TRIGGER) && IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        //Before Update
        System.debug('********************************* INSIDE BEFORE UPDATE ASSET TRIGGER*********************');
        AssetTriggerHandler.beforeUpdate(trigger.newMap, trigger.oldMap);
    } else if (Trigger.isBefore && Trigger.isDelete) {
        //Before Delete
        AssetTriggerHandler.beforeDelete(trigger.oldMap);
    } else if (trigger.isAfter && trigger.isInsert) {
      //After Insert call
       AssetTriggerHandler.afterInsert (trigger.new);
    } else if (trigger.isAfter && trigger.isUpdate) {
      //After Update call
       AssetTriggerHandler.afterUpdate (trigger.newMap, trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isDelete) {
      //After Delete call
      AssetTriggerHandler.afterDelete(Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUnDelete) {
      //After Undelete call
      AssetTriggerHandler.afterUndelete(Trigger.new);
    }
  }
}