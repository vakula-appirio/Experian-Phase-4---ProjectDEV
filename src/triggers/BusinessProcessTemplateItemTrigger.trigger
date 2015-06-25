/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTemplateItemTrigger
 * Description:  
 *  - T-375024: defaults the business hours on the business process template item to global crm's default business hours
 * Created Date: Apr 1st, 2015
 * Created By: Terri Kellough
 * 
 * Date Modified                Modified By                  Description of the update
  =====================================================================*/
trigger BusinessProcessTemplateItemTrigger on Business_Process_Template_Item__c (before insert, before update) {
  if (TriggerState.isActive(Constants.BUSINESSPROCESSTEMPLATEITEM_TRIGGER) && 
                          IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    //Before is before insert
    if (Trigger.isBefore && Trigger.isInsert) {
      BusinessProcessTemplateItemHandler.beforeInsert(Trigger.New);
    }
    
    //Before is before Update
    if (Trigger.isBefore && Trigger.isUpdate) {
      BusinessProcessTemplateItemHandler.beforeUpdate(Trigger.New, Trigger.oldMap);
    }
  }
}