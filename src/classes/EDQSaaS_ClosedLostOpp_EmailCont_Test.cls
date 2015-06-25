/**=====================================================================
 * Appirio, Inc
 * Name: EDQSaaS_ClosedLostOpp_EmailCont_Test
 * Description: Test class for EDQSaaS_ClosedLostOpp_EmailController.cls
 * Created Date: March 3rd, 2015
 * Created By: Naresh Kumar Ojha
 *
 * Date Modified      Modified By                Description of the update
 * Apr 4th, 2015      Terri Kellough             added test for asset
 * Apr 15th, 2015     Terri Kellough             added test for opp line items
 =====================================================================*/
@isTest
private class EDQSaaS_ClosedLostOpp_EmailCont_Test {

  
   static testMethod void testControllerFindsData() {
     EDQSaaS_ClosedLostOpp_EmailController controller = new EDQSaaS_ClosedLostOpp_EmailController();
     controller.opportunityId = [SELECT ID FROM Opportunity LIMIT 1].ID;
     System.assert(controller.getSaaSOpportunity() != null);
     System.assert(controller.getSaaSOpportunity().opptyAccountSaaSContacts != null);
     System.assert(controller.getSaaSOpportunity().opptyAccSaaSAssets  != null);
     System.assert(controller.getSaaSOpportunity().oppSaaSLines != null);
   }
   
  //============================================================================
  //  Method for creating test data to be used in various test methods
  //============================================================================
  @testSetup
  static void createTestdata() {
    Account testAcc = Test_Utils.insertAccount();
    
    Opportunity testOppty = Test_Utils.createOpportunity(testAcc.ID);
    insert testOppty;

    Product2 product = Test_Utils.insertProduct();
    PricebookEntry pricebookEntry1 = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);
    OpportunityLineItem oppLineItem = Test_Utils.createOpportunityLineItem(testOppty.Id, pricebookEntry1.Id, 'New from New');
    oppLineItem.SaaS__c = true;
    oppLineItem.SaaS_Product_Code__c = 'abc';
    insert oppLineItem;

    
    Contact testContact = Test_Utils.createContact(testAcc.ID);
    testContact.SaaS__c = true;
    insert testContact;
    
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.AccountID = testAcc.ID;
    asst.SaaS__c = true;
    asst.SaaS_Product_Code__c = 'abc';
    insert asst;    
  }
}