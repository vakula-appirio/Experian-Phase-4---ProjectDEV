/**************************************************************************************
 This trigger is used to update the Used_on_Aria_Billing_Account__c  on the Address object
 when an Address is used on a Aria Billing Account.
* Created Date: March 3th, 2013
* Created By: Sadar Yacob( Experian)
 * 
 * Date Modified                Modified By                  Description of the update
  Mar 31st, 2014                              Naresh kr Ojha (Appirio)     Coding convention to use Handler properly.
                                                                                                                     (Created before and after methods in handler and put call for them in trigger)
 
 **************************************************************************************/

trigger AriaBillingAccntTrigger on ARIA_Billing_Account__c (after insert, after update, 
                                                                                                                    before insert, before update) {

    //Ensure a data admin is not loading the data, so the triggers will not fire
  if(IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive('AriaBillingAccntTrigger')) {
    //Before insert
    if(Trigger.isBefore && Trigger.isInsert)  {
        BillingAccntTriggerHandler.beforeInsert(Trigger.newMap);
    }
    //Before Update
    if(Trigger.isBefore && Trigger.isUpdate)  {
        System.debug('[AriaBillingAccntTrigger:beforeUpdate][In trigger call]');
      BillingAccntTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
    //After Insert
    if(Trigger.isAfter && Trigger.isInsert )  {
        BillingAccntTriggerHandler.afterInsert(Trigger.newMap);
        }
    //After Update
    if(Trigger.isAfter && Trigger.isUpdate)  {
        BillingAccntTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
        }
  }//END:IF DataAdmin bypass
 }