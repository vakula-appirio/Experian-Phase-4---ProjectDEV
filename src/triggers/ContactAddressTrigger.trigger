/**=====================================================================
 * Appirio, Inc
 * Name: ContactAddressTrigger
 * Description: Trigger on Contact_Address__c
 * Created Date: Nov 11th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Naresh Kr Ojha(Appirio)      T-232755: Homogenize triggers
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 =====================================================================*/

trigger ContactAddressTrigger on Contact_Address__c (before insert, after insert) {

  //Ensure a data admin is not loading the data, so the triggers will not fire
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
                              TriggerState.isActive(Constants.CONTACT_ADDRESS_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isInsert) {
      ContactAddressTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
      ContactAddressTriggerHandler.afterInsert(Trigger.new);
    }
  }
}