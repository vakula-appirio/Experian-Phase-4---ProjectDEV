/**=====================================================================
 * Appirio, Inc
 * Name: ContractTrigger
 * Description: 
 * Created Date: March 3rd, 2015
 * Created By: Gaurav Kumar Chadha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 13th, 2015               Naresh Kr Ojha               T-369590: before insert call added
 =====================================================================*/
trigger ContractTrigger on Contract__c (before insert, before update) {
  if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && TriggerState.isActive(Constants.CONTRACT_TRIGGER)) {
    if (Trigger.isBefore && Trigger.isUpdate) {
    	//before update call
      ContractTriggerHandler.beforeUpdate(trigger.new, trigger.OldMap);
    } else if (Trigger.isBefore && Trigger.isInsert) {
    	//before insert call
    	ContractTriggerHandler.beforeInsert(trigger.new);
    }
  }
}