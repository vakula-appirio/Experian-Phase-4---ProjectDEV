/**=====================================================================
 * Appirio, Inc
 * Name: BatchBURelationshipStatusUpdate
 * Description: 
 * Created Date:
 * Created By:
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 =====================================================================*/
global class BatchBURelationshipStatusUpdate implements Database.Batchable<sObject>{
	 
	final String query = 'SELECT Id, CloseDate FROM Opportunity';// WHERE CloseDate < ' + DateTime.now().addYears;
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
     
	}

	global void finish(Database.BatchableContext BC){
		
	}
	
	@isTest
	static void testMe () {
    Account acc = Test_Utils.createAccount();
    Opportunity oppty = Test_Utils.insertOpportunity(acc.ID);
		BatchBURelationshipStatusUpdate b = new BatchBURelationshipStatusUpdate();
		Database.executebatch(b, 10);
	}
}