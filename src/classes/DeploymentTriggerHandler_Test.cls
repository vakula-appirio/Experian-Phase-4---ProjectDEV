/**=====================================================================
 * Appirio, Inc
 * Name: AccountAssignmentTeamTriggerHandler_Test
 * Description: T-360567: Test class for DeploymentTriggerHandler.cls
 * Created Date: Feb 19th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                        Description of the update
 * March 3rd , 2015         Gaurav Kumar Chadha           T-365130: added method testErrorOnActiveDeletion() to test if error is thrown if
                                                          active deployment is deleted
  =====================================================================*/
@isTest
public class DeploymentTriggerHandler_Test {
 
  static Account testAccount;
  static User testUser ;
  static User testExperianUser ;
  
  //===========================================================================
  // T-365130: to test that error is thrown when active deployment is deleted
  //===========================================================================
  static testmethod void testErrorOnActiveDeletion(){
    createTestData();
                                                     
    Deployment__c newDeployment = new Deployment__c();
    newDeployment.Name = 'Test Deployment';
    newDeployment.Account__c = testAccount.ID;
    newDeployment.OwnerID  = testUser.id;
    //newDeployment.Active__c = true;
    insert newDeployment;
     
    Asset asst = Test_Utils.insertAsset(false,testAccount.ID);
    asst.SaaS__c = true;
    asst.deployment__c = newDeployment.ID;
    insert asst;
    
    newDeployment.Active__c = true;
    update newDeployment;
    
    try{
    Test.startTest(); 
      delete newDeployment;
    Test.startTest();   
    } catch (DmlException e) {
           //Assert Error Message to check if error is thrown on delete
           System.assert( e.getMessage().contains(label.SaaS_ERR_DELETE_DEPLOYMENT) );
    }
    
        
    System.assert([SELECT ID  FROM Deployment__c WHERE ID =: newDeployment.ID] != null);
  
  }
  
  //===========================================================================
  // As per task T-360567, every new Deployment should have Owner Experian Global User
  // which is bing fetched from custom setting Experian_Global__c
  //===========================================================================
  static testMethod void testAssignEveryNewDeploymentToExperianUser(){
  User testUser1= new User();
  
    createTestData();
                                                   
    Test.startTest();
    Deployment__c newDeployment = new Deployment__c();
    newDeployment.Name = 'Test Deployment';
    newDeployment.Account__c = testAccount.ID;
    newDeployment.OwnerID  = testUser.id;
    //newDeployment.Active__c = true;
    insert newDeployment;
    
    Test.stopTest();
    
    System.assertEquals([SELECT OwnerID  FROM Deployment__c WHERE ID =: newDeployment.ID].OwnerId, testExperianUser.ID);
  }
  
  
  static void createTestData() {
    
    Profile p = [SELECT id from profile where name =: Constants.PROFILE_SYS_ADMIN ];
    
    testExperianUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    
    testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    
    testAccount = new Account();
    testAccount.Name = 'TestAccountForDeployment';
    testAccount.SaaS__c = true;
    insert testAccount;
   
    system.debug('******testExperianUser :::::::'+testExperianUser.id);
        
    Experian_Global__c expGlobal = new Experian_Global__c();
    expGlobal.OwnerId__c = testExperianUser.ID;
    insert expGlobal ;
  }
}