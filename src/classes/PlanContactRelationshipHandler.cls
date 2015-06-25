/**
 * @ApexClass : PlanContactRelationshipHandler
 * Handler class for the PlanContactRelationshipTrigger
 */
public class PlanContactRelationshipHandler {
    /**
     * @description: A contact can be related to another contact only once. (either positive or negative)
     * Following method makes sure that a contact is not having any relationship with other contact
     */
    public static void validatePlanContactRelationship(List<Plan_Contact_Relationship__c> planContactRelationshipList){
        Map<Id, Set<Id>> mapContact1VsContact2Ids = new Map<Id, Set<Id>>();
        Set<Id> contactSet = new Set<Id>();
        
        //create the set of contacts for the inserted records
        for(Plan_Contact_Relationship__c pcr : planContactRelationshipList){
            //consider contact1
           if(pcr.Contact_1__c != null && pcr.Contact_2__c != null){
                contactSet.add(pcr.Contact_1__c);
            }
        }
        System.debug('contactSet --->>> ' + contactSet);
        
        //create a map of such contacts 
        for(Plan_Contact_Relationship__c pcr : [SELECT Contact_1__c, Contact_2__c 
                                                FROM Plan_Contact_Relationship__c 
                                                WHERE Contact_1__c in :contactSet and Contact_2__c <> null]){
            if(pcr.Contact_1__c != null && pcr.Contact_2__c != null){
               if(!mapContact1VsContact2Ids.containsKey(pcr.Contact_1__c)){
                	mapContact1VsContact2Ids.put(pcr.Contact_1__c, new Set<Id>());
               }
               mapContact1VsContact2Ids.get(pcr.Contact_1__c).add(pcr.Contact_2__c);
            }                                             
        }
        
        System.debug('mapContact1VsContact2Ids --->>> ' + mapContact1VsContact2Ids);
        
        //Check if there is any relation between contact1 and contact1 if so then add the error to the record stopping it from inserting
        for(Plan_Contact_Relationship__c pcr : planContactRelationshipList){
            if(pcr.Contact_1__c!=null){
                if((mapContact1VsContact2Ids.containsKey(pcr.Contact_1__c) && mapContact1VsContact2Ids.get(pcr.Contact_1__c).contains(pcr.Contact_2__c))){                	
                	 pcr.addError(System.Label.A_contact_can_be_related_to_another_contact_only_once);
                }
            }        
        }           
    }
}