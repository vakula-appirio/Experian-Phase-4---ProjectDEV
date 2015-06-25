/**=====================================================================
 * Appirio, Inc
 * Name: RecalculateBURelationshipForAccount
 * Description: T-206013
 				1. Create button on Account called "Recalculate BU Relationships"
                2. Write a VF page that is invoked from the button above, details of which are:
                    2.1 Retrieves all BU Relationship records associated to the Account
                    2.2 Passes it into the calculation method in BURelationshipCalculator
                    2.3 Updates the BU Relationships that are passed back
                    2.4 Redirects back to the Account
                    2.5 The VF page should display the Account header it was invoked from
                            Underneath the header should be the standard spinning waiting circle with a message 
                            (set via a custom label) which says, "Calculation in progress, please wait....."
 * Created Date: Nov 07th, 2013
 * Created By: Manish Soni (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 * Apr 08th, 2014               Arpita Bose(Appirio)             T-269372: Added addError()in try-catch block
 * Apr 23rd, 2014               Nathalie Le Guay             Commenting class
 =====================================================================*/

public without sharing class RecalculateBURelationshipForAccount {
    
    /*public Boolean hasError {get;set;}
    // Will hold Account id
    private String accountId {get;set;}
    // Will hold set of BURelationship record id
    private Set<Id> setBURelationship;
    
    // Construnctor 
    public RecalculateBURelationshipForAccount( ApexPages.StandardController stdController ){
        hasError = false;
        setBURelationship = new Set<Id>();
        if(stdController != null){
            // Getting current account id
            accountId = stdController.getId();
            for(BU_Relationship__c buRelationship : [ SELECT Id FROM BU_Relationship__c WHERE Account__c =:accountId ]){
                setBURelationship.add(buRelationship.id);
            }
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
                hasError = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getmessage()));
        apexLogHandler.createLogAndSave('RecalculateBURelationshipForAccount','recalculateBURelationship', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          lstBURelationship.get(0).addError(ex.getDmlMessage(i));
        }
        return null;
            }
        }
        return new pagereference('/' + accountId); 
    }*/
}