/**========================================================================================
 * Appirio, Inc
 * Name: BatchReCreateBURelationship_Test
 * Description: This class contains test method to test BatchReCreateBURelationship
 * Created Date: March 20th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 15th, 2014               Arpita Bose(Appirio)         T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014               Arpita Bose                  T-271695: Renamed Has_Stage_5_Approval to Has_Senior_Approval__c
 * Apr 23rd, 2014               Nathalie Le Guay             Comment code
 ========================================================================================*/
@isTest
private class BatchReCreateBURelationship_Test {
  
  /*static Opportunity testOpp;
  static void testBatchReCreate(){
  	//Test.startTest();   
  	createTestData();
  	Test.StartTest(); 
  		BatchReCreateBURelationship testBatch = new BatchReCreateBURelationship();
  		Database.executeBatch(testBatch);
  	Test.stopTest();
  }	
  @isTest	
  static void testFailureOppty(){
  	//Test.startTest();  
  	createTestData();  
  	User oldUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    oldUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    oldUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    insert oldUser;
    System.runAs(new User (id = userInfo.getUserId())){
	  	BatchReCreateBURelationship testBatch = new BatchReCreateBURelationship();
	  	Database.QueryLocator QL;
	    Database.BatchableContext BC;
	    List<Opportunity> lstOpp = new List<Opportunity>();
	    lstOpp.add(testOpp);
	    lstOpp.get(0).stageName = null;
	    lstOpp.get(0).ownerID = oldUser.id;
	    testBatch.EmailToOnFinish ='test@testmail.com';
	    QL = testBatch.start(bc);
	    testBatch.execute(BC, lstOpp);
	    testBatch.finish(BC); 
	    testBatch.createMailMessage(testBatch.EmailToOnFinish, 'Failure');
    }
   //Test.StopTest();
  }
  
   private static void createTestData(){
        // Create an account    
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Has_Senior_Approval__c = true;
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        //testOpp.Below_Review_Thresholds__c = 'Yes';   T-271695: Removed reference to Below_Review_Thresholds__c field
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    	testOpp.Amount = 100;
        
        insert testOpp;
        Test_Utils.createOpptyTasks(testOpp.Id, true);
    
        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;
     }*/

}