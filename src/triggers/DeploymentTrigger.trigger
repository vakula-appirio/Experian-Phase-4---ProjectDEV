/**********************************************************************************
 * Appirio, Inc
 * Name: DeploymentTrigger
 * Description: Trigger on Deployment__c custom object
 *              T-360562: Added beforeInsert
 * Created Date: Feb 12th, 2015
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified       Modified By                  Description of the update
 * Feb 16th, 2015      Naresh Kr Ojha               T-362362: As per task, updated API name and label as well as all references
 *                                                  of Deployment_Lincense__c to Deployment__c
 * March 2th,2015      Gaurav Kumar Chadha          T-365130: Added before delete 
 
 *********************************************************************************/
trigger DeploymentTrigger on Deployment__c(before insert , before delete) {
   
   if (TriggerState.isActive(Constants.DEPLOYMENT_TRIGGER) && IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    if (Trigger.isBefore && trigger.isInsert) {
      //Before Insert call
       DeploymentTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && trigger.isDelete) {
       DeploymentTriggerHandler.beforeDelete(Trigger.old);   
    } 
  }
}