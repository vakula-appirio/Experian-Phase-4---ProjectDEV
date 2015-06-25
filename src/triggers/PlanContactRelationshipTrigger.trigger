trigger PlanContactRelationshipTrigger on Plan_Contact_Relationship__c (before insert) {
    if(Trigger.isInsert && Trigger.isBefore){
        PlanContactRelationshipHandler.validatePlanContactRelationship(Trigger.new);
    }

}