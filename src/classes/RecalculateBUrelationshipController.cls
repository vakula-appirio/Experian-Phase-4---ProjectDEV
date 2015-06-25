/**=====================================================================
 * Appirio, Inc
 * Name: RecalculateBUrelationshipController
 * Description: T-206013
 				1. Create Button on BU Relationship called "Recalculate"
                2. Write a Visualforce page that is invoked from button above on BU Relationship, details of which are:
                     2.1 Takes the BU Relationship Id and passes it to the method in BURelationshipCalculator
                     2.2 Updates the BU Relationship that is passed back
                     2.3 Redirects back to the BU Relationship detail page
 * Created Date: Nov 07th, 2013
 * Created By: Manish Soni (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 * Apr 08th, 2014                   Arpita Bose(Appirio)         t-269372: Added addError()in try-catch block
 * Apr 23rd, 2014               Nathalie Le Guay             Commenting Class
 =====================================================================*/

public without sharing class RecalculateBUrelationshipController {
    
    /*// Will hold BURelationship record id
    private String BURelationshipId {get;set;}
    // Will hold set of BURelationship record id
    private Set<Id> setBURelationship;
    
    // Construnctor 
    public RecalculateBUrelationshipController( ApexPages.StandardController stdController ){
        
        setBURelationship = new Set<Id>();
        if(stdController != null){
            // Getting current BURelationship record id
            BURelationshipId = stdController.getId();
            setBURelationship.add(BURelationshipId);
        }
    }
    
    // Method for pass the set of BURelationship id to the calculator class 
    // and update the BURelationship record that is passed back
    public pagereference recalculateBURelationship(){
        
        // Creating instance of the BURelationshipCalculator
        BURelationshipCalculator burCalculator = new BURelationshipCalculator();
        // Getting BURelationship reocrd with the updated values
        List<BU_Relationship__c> lstBURelationship = burCalculator.updateTypeAndAmountFieldOnBU(setBURelationship);
        
        if(lstBURelationship != null && !lstBURelationship.isEmpty()){
            try{
                // Updating record
                update lstBURelationship;
            }
            catch(Exception ex){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getmessage()));
        apexLogHandler.createLogAndSave('RecalculateBUrelationshipController','recalculateBURelationship', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          lstBURelationship.get(0).addError(ex.getDmlMessage(i));
        }
        return null;
            }
        }
        return new pagereference('/' + BURelationshipId); 
    }*/
}