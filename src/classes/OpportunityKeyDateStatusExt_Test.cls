/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityKeyDateStatusExt_Test
 * Description: T-271251: Test Class for Key dates functionality.
 * Created Date: Apr 14th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * May 07, 2014                 Nathalie Le Guay             Removing test scenario 1 as it was testing a validation rule
 * Jul 31st, 2014               Arpita Bose(Appirio)         T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 =====================================================================*/
@isTest(seeAllData=true)
private class OpportunityKeyDateStatusExt_Test {


  //Scenario 2 as required by the task.
  static testMethod void testOLIsScheduleOutsideOfOpptyClosedDate () {
    // create User
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-20);
      testOpp.Contract_End_Date__c = Date.today().addDays(10);
      testOpp.CloseDate = Date.today().addDays(5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
        
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
      product.CanUseRevenueSchedule = true;
      insert product;
  
      Pricebook2 pricebook = Test_Utils.getPriceBook2();
      Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
      
      //insert OLI
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today().addDays(-20);
      opptyLineItem.End_Date__c = Date.today().addDays(2);
      insert opptyLineItem;
  
      OpportunityLineItemSchedule olis = Test_Utils.createOpportunityLineItemSchedule(opptyLineItem.ID);
      olis.ScheduleDate = Date.today().addDays(-40);
      insert olis;    

      Test.startTest();
  
      //Page reference
      PageReference pageRef = Page.OpportunityKeyDateStatus;
      Test.setCurrentPage(pageRef);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(testOpp);
  
      OpportunityKeyDateStatusExt scExt = new OpportunityKeyDateStatusExt(controller);
      
      Test.stopTest();
  
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      boolean b = false;
  
      for(Apexpages.Message msg:msgs){
        if (msg.getDetail().contains(Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CLOSE_DATE)) {
          b = true;
        }
      }
      
      system.assert(b);
    }
  }
  
  //Scenario 3 as required by the task.
  static testMethod void testOLIsScheduleOutsideOfOpptyContractDate () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {    
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-20);
      testOpp.Contract_End_Date__c = Date.today().addDays(10);
      testOpp.CloseDate = Date.today().addDays(5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
        
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
      product.CanUseRevenueSchedule = true;
      insert product;
  
      Pricebook2 pricebook = Test_Utils.getPriceBook2();
      Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
      
      //insert OLI
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today().addDays(-20);
      opptyLineItem.End_Date__c = Date.today().addDays(2);
      insert opptyLineItem;
  
      OpportunityLineItemSchedule olis = Test_Utils.createOpportunityLineItemSchedule(opptyLineItem.ID);
      olis.ScheduleDate = Date.today().addDays(-30);
      insert olis;    
  
      Test.startTest();
  
      //Page reference
      PageReference pageRef = Page.OpportunityKeyDateStatus;
      Test.setCurrentPage(pageRef);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(testOpp);
  
      OpportunityKeyDateStatusExt scExt = new OpportunityKeyDateStatusExt(controller);
      
      Test.stopTest();
  
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      boolean b = false;
  
      for(Apexpages.Message msg:msgs){
        if (msg.getDetail().contains(Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CONTRACT_STRT_DATE)) {
          b = true;
        }
      }
      
      system.assert(b);
    }
  }
  
  //Scenario 4 as required by the task.
  static testMethod void testOLISchedulePositiveTest () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(30);
      testOpp.Contract_End_Date__c = Date.today().addDays(60);
      testOpp.CloseDate = Date.today();
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
        
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
      product.CanUseRevenueSchedule = true;
      insert product;
  
      Pricebook2 pricebook = Test_Utils.getPriceBook2();
      Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
      
      //insert OLI
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today().addDays(32);
      opptyLineItem.End_Date__c = Date.today().addDays(58);
      insert opptyLineItem;
  
      OpportunityLineItemSchedule olis = Test_Utils.createOpportunityLineItemSchedule(opptyLineItem.ID);
      olis.ScheduleDate = Date.today().addDays(35);
      insert olis;    
  
      Test.startTest();
  
      //Page reference
      PageReference pageRef = Page.OpportunityKeyDateStatus;
      Test.setCurrentPage(pageRef);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(testOpp);
  
      OpportunityKeyDateStatusExt scExt = new OpportunityKeyDateStatusExt(controller);
      
      Test.stopTest();
  
      List<Apexpages.Message> msgs = ApexPages.getMessages();
      //No page messages
      System.assertEquals(msgs.size(), 0);
    }
  }
}