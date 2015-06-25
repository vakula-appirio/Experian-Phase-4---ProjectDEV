/**=====================================================================
 * Appirio, Inc
 * Trigger Name: OpportunityPlanCompetitorTrigger
 * Handler Class: OpportunityPlanCompetitorTriggerHandler
 * Description: I-120989: To synch currency with Opportunity Plan
 * Created Date: July 17th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update       
 =====================================================================*/
trigger OpportunityPlanCompetitorTrigger on Opportunity_Plan_Competitor__c (before insert, before update) {
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false 
                                                            && TriggerState.isActive('OpportunityPlanCompetitorTrigger')) {
        //Before insert
        if (Trigger.isBefore && Trigger.isInsert) {
            OpportunityPlanCompetitorTriggerHandler.beforeInsert(Trigger.New);
        }
        //Before update
        if (Trigger.isBefore && Trigger.isUpdate) {
            OpportunityPlanCompetitorTriggerHandler.beforeUpdate(Trigger.New, Trigger.oldMap);
        }
    }
}