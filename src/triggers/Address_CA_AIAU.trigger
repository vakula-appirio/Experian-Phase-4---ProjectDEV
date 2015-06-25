/**=====================================================================
 * Appirio, Inc
 * Name: Address_CA_AIAU
 * Description: Trigger on Address__c
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                   Description of the update
 * Jan 30th, 2014               Naresh Kr Ojha(Appirio)       T-232755: Homogenize triggers
 * Jan 30th, 2014               Jinesh Goyal(Appirio)         T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose (Appirio)         T-243282: Added Constants in place of String
 * Apr 28th, 2014               Arpita Bose                   T-275717: Merged Address_CA_BIBU trigger in this trigger as there are 
 *                                                               Multiple_Trigger_On_same_sObject from Force.com Security Scanner Results
                                                                 before insert and before calls are form Address_CA_BIBU trigger
 =====================================================================*/
trigger Address_CA_AIAU on Address__c (before insert, before update, after insert, after update) {
  //Ensure a data admin is not loading the data, so the triggers will not fire
  
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                                    TriggerState.isActive(Constants.ADDRESS_CA_AIAU_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isInsert) {
      QAS_NA.RecordStatusSetter.InvokeRecordStatusSetterConstrained(trigger.new,
                                              trigger.old, trigger.IsInsert, 2);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
      QAS_NA.RecordStatusSetter.InvokeRecordStatusSetterConstrained(trigger.new,
                                              trigger.old, trigger.IsInsert, 2);
    } else if (Trigger.isAfter && Trigger.isInsert) {
      AddressTriggerHandler.afterInsert(Trigger.new);
      //QAS_NA.CAAddressCorrection.ExecuteCAAsyncForTriggerConfigurationsOnly(trigger.new);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
      AddressTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
      //QAS_NA.CAAddressCorrection.ExecuteCAAsyncForTriggerConfigurationsOnly(trigger.new);
    }
    
  }//END:IF DataAdmin bypass
}