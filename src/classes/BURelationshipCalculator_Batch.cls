/**=====================================================================
 * Appirio, Inc
 * Name: BURelationshipCalculator_Batch
 * Description: Batch Class to populate Total/Type field on BU Relationship 
              objects
 * Created Date: Nov 07th, 2013
 * Created By: Pankaj Mehra (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * March 11th, 2014							Naresh Kr Ojha (Appirio)		 Updated for debugging purpose for T-257854
 * Apr 23, 2014                 Nathalie Le Guay             Commenting class
 =====================================================================*/

global class BURelationshipCalculator_Batch /*implements Database.Batchable<sObject>*/{
	
  /*global Database.QueryLocator start(Database.BatchableContext BC){
    String query = 'Select Id From BU_Relationship__c';
		return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope){
  	
  	List<BU_Relationship__c> lstBURelationship = (List<BU_Relationship__c>) scope;
    Set<Id> setBURelationship = new Set<Id>();
    for(BU_Relationship__c bu : lstBURelationship){
    	setBURelationship.add(bu.Id);
    }
    System.debug('[BURelationshipCalculator_Batch:execute][setBURelationship:'+setBURelationship+']');
    BURelationshipCalculator buCalculator =  new BURelationshipCalculator();
    List<BU_Relationship__c> lstBURelationshipUpdated = buCalculator.updateTypeAndAmountFieldOnBU(setBURelationship);
    update lstBURelationshipUpdated;
    System.debug('[BURelationshipCalculator_Batch:execute][lstBURelationshipUpdated:'+lstBURelationshipUpdated+']');
  }

	global void finish(Database.BatchableContext BC){
		
	}*/
}