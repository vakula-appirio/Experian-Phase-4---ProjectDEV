/******************************************************************************
 * Appirio, Inc
 * Name: OpportunityFreeTrial_Helper_Test.cls
 * Description: T-323154: Test functionality of the mail class to clone oppty and its child
 * Created Date: Oct 3rd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Oct 7th, 2014      Arpita Bose(Appirio)         Updated the method test_createFreeTrialOppty
 * Oct 27th,2014      Pallavi Sharma(Appirio)      Fix Failure
 * Oct 29th, 2014     Nathalie Le Guay             Using Free_Trial_Parent_Opportunity__c instead of Previous_Opportunity__c
 * Oct 30th,2014      Pallavi Sharma(Appirio)      Fix Failure
 * Nov 12th, 2014     Arpita Bose                  Added Type in test data of Opportunity and OLI
 * Feb 23rd, 2015     Paul Kissick                 Fixed SeeAllData requirements, and also tested failure to create trial opportunity.
 ******************************************************************************/
@isTest
private class OpportunityFreeTrial_Helper_Test {

  @isTest
  private static void test_createFreeTrialOppty(){
    // create test data
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    
    CPQ_Settings__c cpqSettings1 = new CPQ_Settings__c(
      Name = 'CPQ', 
      Company_Code__c = 'Experian', 
      CPQ_API_Access_Word__c = 'password', 
      CPQ_API_Endpoint__c = 'https://doesntmatter/endpoint.asmx', 
      CPQ_API_UserName__c = 'username'
    );
    insert cpqSettings1;
    CPQ_Settings__c cpqSettings2 = new CPQ_Settings__c(
      Name = 'CPQAlt', 
      Company_Code__c = 'Experian', 
      CPQ_API_Access_Word__c = 'password', 
      CPQ_API_Endpoint__c = 'https://doesntmatter/endpoint.asmx', 
      CPQ_API_UserName__c = 'username'
    );
    insert cpqSettings2;
    
    User testUser = Test_Utils.createCPQUser(p, 'testEMAIL20134959@tst.com', 'TesT CPQ');
    System.runAs( Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN)){
      insert testUser;
    }

    System.runAs(testUser) {
    	// start test
      Test.startTest();
      String opptyName = 'NewTestOppty001OpptyNewTest';
      Account testAcc = Test_Utils.insertAccount();
      Contact testContact = Test_Utils.insertContact(testAcc.ID);
      Opportunity testOppty = Test_Utils.createOpportunity(testAcc.ID);
      testOppty.Name = opptyName;
      testOppty.Type = Constants.OLI_TYPE_FREE_TRIAL;
      //testOppty.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      insert testOppty;
      
      OpportunityContactRole testOCR = Test_Utils.insertOpportunityCR(true, testContact.ID, testOppty.ID);
      OpportunityTeamMember testOTM = Test_Utils.insertOpportunityTeamMember(true, testOppty.ID, testUser.ID, Constants.TEAM_ROLE_ACCOUNT_MANAGER);
      Product2 product = Test_Utils.insertProduct();
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      
      delete [SELECT Id FROM Quote__c  WHERE Opportunity__c = :testOppty.Id];
      //insert OLI
      OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOppty.Id, stdPricebookEntry.Id, testOppty.Type);
      insert opportunityLineItem2; 
    
      OpportunityFreeTrial_Helper.createFreeTrialOppty(testOppty.ID);
      // stop test
      Test.stopTest();
      
      
      //As new oppty has prefix 'TRIAL:'
      List<Opportunity> trialOppty = [SELECT NAME, ID, Type, StageName, 
                                          (SELECT ID FROM OpportunityContactRoles), 
                                          (SELECT ID FROM OpportunityTeamMembers), 
                                          (SELECT ID,TotalPrice, UnitPrice, ListPrice, Type__c FROM OpportunityLineItems)
                                      FROM Opportunity WHERE Name like 'FT:%'
                                      AND Free_Trial_Parent_Opportunity__c = :testOppty.ID];
      
      System.debug('---->'+trialOppty);
      system.assert(!trialOppty.isEmpty(),'No Trial Opportunity Found');
      if(!trialOppty.isEmpty()){
	      //Asserts to verify there is TRIAL Oppty Records with it child records are created
	      System.assert(trialOppty.size() == 1);
	      System.assert(trialOppty.get(0).OpportunityContactRoles.size() > 0);
	      System.assert(trialOppty.get(0).OpportunityTeamMembers.size() > 0);
	      System.assert(trialOppty.get(0).OpportunityLineItems.size() > 0);
	      
	      //Asserts to verify TRIAL Oppty Type = "Free Trial" and Stage Name = "Set-Up" 
	      System.assertEquals(trialOppty.get(0).Type, Constants.OPPTY_TYPE_FREE_TRIAL);
	      System.assertEquals(trialOppty.get(0).StageName, Constants.OPPTY_STAGE_SETUP);
	      
	      List<OpportunityLineItem> trialOLI = [SELECT ID, TotalPrice, UnitPrice, Type__c 
	                                            FROM OpportunityLineItem
	                                            WHERE OpportunityId IN :trialOppty];
	  
	      //Asserts to verify TRIAL OLI Type = "Free Trial" and all the Amounts are 0                                
	      System.assertEquals(trialOLI.get(0).Type__c, Constants.ORDER_LINE_ITEM_RENEWAL_ONE_OFF);
	      System.assert(trialOLI.get(0).TotalPrice == 0);
	      System.assert(trialOLI.get(0).UnitPrice == 0);
      }
    }
  }
    
  
  @isTest
  private static void test_createFreeTrialOppty2(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    Contact testContact = Test_Utils.insertContact(testAcc.ID);
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    //testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    insert testOpp;
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.insertProduct();
    // Pricebook2 pricebook = Test_Utils.getPriceBook2();
    // Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);


    OpportunityLineItem opportunityLineItem2 =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem2.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem2.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem2);
    
    insert oliList;
    
    OpportunityContactRole testOCR = Test_Utils.insertOpportunityCR(true, testContact.ID, testOpp.ID);
    OpportunityTeamMember testOTM = Test_Utils.insertOpportunityTeamMember(true, testOpp.ID, Userinfo.getUserId() , Constants.TEAM_ROLE_ACCOUNT_MANAGER);
    
    String resultString = OpportunityFreeTrial_Helper.createFreeTrialOppty(testOpp.ID);
    //System.assertEquals('=---->'+resultString, ' ');
    //As new oppty has prefix 'TRIAL:'
      List<Opportunity> trialOppty = [SELECT NAME, ID, Type, StageName, 
                                          (SELECT ID FROM OpportunityContactRoles), 
                                          (SELECT ID FROM OpportunityTeamMembers), 
                                          (SELECT ID,TotalPrice, UnitPrice, ListPrice, Type__c FROM OpportunityLineItems)
                                      FROM Opportunity WHERE Name like 'FT:%'
                                      AND Free_Trial_Parent_Opportunity__c = :testOpp.ID];
      
      System.debug('---->'+trialOppty);
      system.assert(!trialOppty.isEmpty(),'No Trial Opportunity Found');
      if(!trialOppty.isEmpty()){
	      //Asserts to verify there is TRIAL Oppty Records with it child records are created
	      System.assert(trialOppty.size() == 1);
	      System.assert(trialOppty.get(0).OpportunityContactRoles.size() > 0);
	      System.assert(trialOppty.get(0).OpportunityTeamMembers.size() > 0);
	      System.assert(trialOppty.get(0).OpportunityLineItems.size() > 0);
	      
	      //Asserts to verify TRIAL Oppty Type = "Free Trial" and Stage Name = "Set-Up" 
	      System.assertEquals(trialOppty.get(0).Type, Constants.OPPTY_TYPE_FREE_TRIAL);
	      System.assertEquals(trialOppty.get(0).StageName, Constants.OPPTY_STAGE_SETUP);
	      
	      List<OpportunityLineItem> trialOLI = [SELECT ID, TotalPrice, UnitPrice, Type__c 
	                                            FROM OpportunityLineItem
	                                            WHERE OpportunityId IN :trialOppty];
	  
	      //Asserts to verify TRIAL OLI Type = "Free Trial" and all the Amounts are 0                                
	      System.assertEquals(trialOLI.get(0).Type__c, Constants.ORDER_LINE_ITEM_RENEWAL_ONE_OFF);
	      System.assert(trialOLI.get(0).TotalPrice == 0);
	      System.assert(trialOLI.get(0).UnitPrice == 0);
      }
  }
    
  
  
}