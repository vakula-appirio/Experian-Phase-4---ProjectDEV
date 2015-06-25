/**=====================================================================
 * Appirio, Inc
 * Trigger Name: OpportunityPlanContactTrigger
 * Handler Class:  OpportunityPlanContactTriggerHandler
 * Description: [T-280558: Create trigger to delete Plan Contact Relationships]
 * Created Date: May 23th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * July 17th, 2014              Arpita Bose(Appirio)         I-120989: To synch currency with Opportunity Plan
 =====================================================================*/
trigger OpportunityPlanContactTrigger on Opportunity_Plan_Contact__c (after delete, before delete,
                                                                   after undelete, before insert, before update) {
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false 
                                                            && TriggerState.isActive('OpportunityPlanContactTrigger')) {
        //Before delete
        if (Trigger.isBefore && Trigger.isDelete) {
            OpportunityPlanContactTriggerHandler.beforeDelete(Trigger.oldMap);
        }
        //After undelete
        if (Trigger.isAfter && Trigger.isUnDelete) {
            OpportunityPlanContactTriggerHandler.afterUnDelete(Trigger.New);
        }
        //Before insert
        if (Trigger.isBefore && Trigger.isInsert) {
            OpportunityPlanContactTriggerHandler.beforeInsert(Trigger.New);
        }
        //Before update
        if (Trigger.isBefore && Trigger.isUpdate) {
            OpportunityPlanContactTriggerHandler.beforeUpdate(Trigger.New, Trigger.oldMap);
        }
    }
}