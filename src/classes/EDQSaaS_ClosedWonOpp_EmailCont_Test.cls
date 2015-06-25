/**=====================================================================
 * Appirio, Inc
 * Name: EDQSaaS_ClosedWonOpp_EmailCont_Test
 * Description: Test class for EDQSaaS_ClosedWonOpp_EmailController.cls
 * Created Date: March 2nd, 2015
 * Created By: Naresh Kumar Ojha
 *
 * Date Modified      Modified By                Description of the update
 =====================================================================*/
@isTest
private class EDQSaaS_ClosedWonOpp_EmailCont_Test {

  
   static testMethod void forFetchAccountTeamMember() {
     EDQSaaS_ClosedWonOpp_EmailController controller = new EDQSaaS_ClosedWonOpp_EmailController();
     controller.opportunityId = [SELECT ID FROM Opportunity LIMIT 1].ID;
     System.assert(controller.getSaaSOpportunity() != null);
     System.assert(controller.getSaaSOpportunity().opptyAccountSaaSContacts != null);
   }
   
  //============================================================================
  //  Method for creating test data to be used in various test methods
  //============================================================================
  @testSetup
  static void createTestdata() {
    Account testAcc = Test_Utils.insertAccount();
    
    Opportunity testOppty = Test_Utils.createOpportunity(testAcc.ID);
    insert testOppty;
    
    Contact testContact = Test_Utils.createContact(testAcc.ID);
    testContact.SaaS__c = true;
    insert testContact;
    
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Opportunity__c = testOppty.ID;
    asst.AccountID = testAcc.ID;
    asst.SaaS__c = true;
    insert asst;    
  }
}