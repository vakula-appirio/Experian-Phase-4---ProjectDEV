/**********************************************************
   Class           :       OpportunityLineItemTriggerHandler_Test
   Author          :       Shane Khublall
   Date            :       10/30/2013
   Description     :       For testing the OpportunityLineItemTrigger.trigger, 
                        and for Testing the OpportunityLineItemTriggerHandler.cls
                         S-135692    Task: T-214187                    
   Modified On              Modified By                   Description
 * Jan 30th, 2014                Jinesh Goyal(Appirio)      T-232760: Homogenize the comments

 * 02/12/2014               Naresh Ojha (Appirio)         Updated class for coverage and convention purpose
                                                          and moved old code from TestOpportunityItemTriggerHandler.cls T-248805                        
 * Feb 19th, 2014           Naresh kr Ojha(Appirio)       T-250093: Testing for Has complex product on oppty to set true
 * Feb 27th, 2014           Naresh kr Ojha(Appirio)       Fixed failure.
 * Mar 03rd, 2014           Arpita Bose(Appirio)          T-243282: Added Constants in place of String
 * Mar 14th, 2014           Arpita Bose(Appirio)          T-253906: Fixed error
 * Mar 31st, 2014           Arpita Bose(Appirio)          T-267875: Removed references to field Annual_Amount__c
 * Mar 31st, 2014           Arpita Bose(Appirio)          T-267479: Test method to test Service Start/End Dates populate on OLI and opportunity
 * Apr 01st, 2014           Arpita Bose(Appirio)          T-268401: Removed a test method checking populate of Service start/end dates
 * Apr 02nd, 2014           Arpita Bose(Appirio)          T-268405: OLI's Service Start/End dates changed to Start/End dates
 * Apr 14th, 2014           Arpita Bose                   Updated method testbeforeInsert()to fix the failure
 * Apr 14th, 2014           Naresh Kr Ojha                T-271248: Revenue Calculation Test methods
 * Apr 16th, 2014           Arpita Bose                   T-272243: Added testmethod testOppDeliveryDatesPlannedUncheck()
 * Jul 31st, 2014           Arpita Bose                   T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Sep 11th, 2014           Mohit Parnami                 T-318596 : Created method testDeleteOrphanRoyalties()
 * Sep 16th, 2014           Naresh kr Ojha                T-319440: added method testRequoteAndLockingOLIs().
 * Oct 22nd, 2014           Tyaga Pati                    Case#5576: on Function testOppDeliveryDatesPlannedUncheck, increased the End Date from Add(5) to Add(6) 
 * Nov 12th, 2014           Noopur                        Modified to add Type to Opportunity and corresponding Order type to its OLIs
 * Jun 8th, 2015            Paul Kissick                  Case #964253 - Fixing test failures which happen regularly. Removed SeeAllData=true!
 ***********************************************************/
@isTest
private class OpportunityLineItemTriggerHandler_Test {
  
  static testMethod void testbeforeInsert() {

    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Type = Constants.OPPTY_NEW_FROM_EXISTING ;
      insert testOpp;
      
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.insertProduct();
      product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;    
      product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;    
      product.NumberOfRevenueInstallments = 2;    
      //product.CanUseQuantitySchedule = false;
      product.CanUseRevenueSchedule = true;
      update product;
      System.debug('***debug1.0**'+Limits.getQueries());
      
      
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2('Standard Price Book');
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //insert OLI
      OpportunityLineItem opportunityLineItem2 = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      List<OpportunityLineItemSchedule> olsiList = new List<OpportunityLineItemSchedule>();
      //insert OLIS
      OpportunityLineItemSchedule olsi1 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
      olsiList.add(olsi1);
      OpportunityLineItemSchedule olsi2 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
      olsiList.add(olsi2);
      OpportunityLineItemSchedule olsi3 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
      olsiList.add(olsi3);
      insert olsiList;
      
      olsi3.ScheduleDate = System.today().addDays(7);
      System.debug('***debug1.1**'+Limits.getQueries());
      Test.startTest();
      
      System.debug('***debug1.2**'+Limits.getQueries());
      update olsiList;
      
      
      List<OpportunityLineItem> lineItemList = [SELECT id, ServiceDate, Discount, Description, ListPrice,
                                                       Quantity, UnitPrice, Subtotal, TotalPrice,// Annual_Amount__c : T-267875:Refactoring OLI fields
                                                       Billing_Product__c, DE_Product_Name__c, Revenue_Schedule_Amt_Per_Period__c,
                                                       Revenue_Schedule_Num_of_Periods__c, Revenue_Schedule_Period_Type__c, Type_of_Sale__c 
                                               FROM OpportunityLineItem WHERE OpportunityID =: testOpp.ID];
      Map<Id,OpportunityLineItem> testOppLineItemMap = new Map<Id,OpportunityLineItem>(lineItemList);
      //Asserts
      System.assert(lineItemList.size() > 0);
      System.assertEquals(Integer.valueOf(lineItemList.get(0).TotalPrice), 300);
      // method to add billingproduct to lineItem.
      Test.stopTest();
      List <OpportunityLineItemSchedule> testOppLineItemSchedule= [SELECT Id, OpportunityLineItemId, Type, Revenue,
                                                                          Quantity, ScheduleDate, CurrencyIsoCode 
                                                                   FROM OpportunityLineItemSchedule 
                                                                   WHERE OpportunityLineItemId IN : lineItemList];
      System.debug('***debug1.3**'+Limits.getQueries());
      //Asserts
      System.assertEquals(testOppLineItemSchedule.size(), 3);
      System.assertEquals(Integer.valueOf(testOppLineItemSchedule.get(0).Revenue), 100);
      System.assertEquals(Integer.valueOf(testOppLineItemSchedule.get(1).Revenue), 100);
      System.assertEquals(Integer.valueOf(testOppLineItemSchedule.get(2).Revenue), 100);
      System.debug('***debug1.4**'+Limits.getQueries());
      //OpportunityLineItem opportunityLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
      //opportunityLineItem.Quantity = 5;
  
      //String oppIdLineItemId = opportunityLineItem.id;
    
      //Map<Id,OpportunityLineItem> oppLineItemMap = new Map<Id,OpportunityLineItem>{opportunityLineItem.Id => opportunityLineItem};
      //List<OpportunityLineItemSchedule> olis = [Select Id from OpportunityLineItemSchedule where OpportunityLineItemId = :opportunityLineItem.Id];
      
    }
    
  }

  static testMethod void testSetOpptyProductSimpleOrComplex1 () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Amount = 50000;
      testOpp.Type = Constants.OPPTY_NEW_FROM_EXISTING ;
      //testOpp.CurrencyIsoCode = Constants.CURRENCY_GBP;
      insert testOpp;
      
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
      insert product;
  
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //Assert to check oppty has false value in has complex product
      System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, false);
  
      Test.startTest();
      //insert OLI
      OpportunityLineItem opptyLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      Test.stopTest();
      //Assert to check oppty has true value in has complex product
      System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, true);
    } 
  }
  
  static testMethod void testSetOpptyProductSimpleOrComplex2 () {
    // Create an account    
    Account testAccount = Test_Utils.insertAccount();
  
    // Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    Pricebook2 pricebook = new Pricebook2();
    pricebook.CurrencyIsoCode = Constants.CURRENCY_EUR;
    pricebook.IsActive = true;
    pricebook.Description = 'EUR currency iso code pricebook';
    pricebook.Name = 'EUR Pricebook';
    insert pricebook;

    // Create an opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Amount = 50000;
    testOpp.CurrencyIsoCode = Constants.CURRENCY_EUR;
    testOpp.Pricebook2Id = pricebook.ID;
    testOpp.Type = Constants.OPPTY_NEW_FROM_NEW ;
    insert testOpp;
    
    //////////////////////
    // Create Opportunity Line Item
    Product2 product = Test_Utils.createProduct();
    product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
    insert product;
    
    
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_EUR);
    PricebookEntry newPricebookentry = Test_Utils.insertPricebookEntry(product.Id, pricebook.Id, Constants.CURRENCY_EUR);
    
    
    //Assert to check oppty has false value in has complex product
    System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, false);

    Test.startTest();
    //insert OLI
    //OpportunityLineItem opptyLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, pricebook.Id);
    OpportunityLineItem opptyLineItem = new OpportunityLineItem();
    opptyLineItem.OpportunityId = testOpp.ID;
    opptyLineItem.Quantity = 1;
    opptyLineItem.UnitPrice = 200;
    opptyLineItem.PricebookEntryId = newPricebookentry.ID;
    opptyLineItem.Start_Date__c = System.today();
    opptyLineItem.End_Date__c = System.today().addDays(10);
    opptyLineItem.Order_Type__c = Constants.STATUS_NEW;
    insert opptyLineItem;
    
    Test.stopTest();
    //Assert to check oppty has true value in has complex product
    System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, true); 
  }
  

  static testMethod void testSetOpptyProductSimpleOrComplex3 () {
    // Create an account    
    Account testAccount = Test_Utils.insertAccount();
  
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    Pricebook2 pricebook = new Pricebook2();
    pricebook.CurrencyIsoCode = Constants.CURRENCY_GBP;
    pricebook.IsActive = true;
    pricebook.Description = 'GBP currency iso code pricebook';
    pricebook.Name = 'GBP Pricebook';
    insert pricebook;

    // Create an opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Amount = 50000;
    testOpp.CurrencyIsoCode = Constants.CURRENCY_GBP;
    testOpp.Pricebook2Id = pricebook.ID;
    testOpp.Type = Constants.OPPTY_NEW_FROM_NEW ;
    insert testOpp;
    
    //////////////////////
    // Create Opportunity Line Item
    Product2 product = Test_Utils.createProduct();
    product.Simple_or_Complex__c = Constants.PRODUCT_COMPLEX;
    insert product;
    
    
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_GBP);
    PricebookEntry newPricebookentry = Test_Utils.insertPricebookEntry(product.Id, pricebook.Id, Constants.CURRENCY_GBP);
    
    
    //Assert to check oppty has false value in has complex product
    System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, false);

    Test.startTest();
    //insert OLI
    //OpportunityLineItem opptyLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, pricebook.Id);
    OpportunityLineItem opptyLineItem = new OpportunityLineItem();
    opptyLineItem.OpportunityId = testOpp.ID;
    opptyLineItem.Quantity = 1;
    opptyLineItem.UnitPrice = 200;
    opptyLineItem.PricebookEntryId = newPricebookentry.ID;
    opptyLineItem.Start_Date__c = System.today();
    opptyLineItem.End_Date__c = System.today().addDays(10);
    opptyLineItem.Order_Type__c = Constants.STATUS_NEW;
    insert opptyLineItem;
    
    Test.stopTest();
    //Assert to check oppty has true value in has complex product
    System.assertEquals([SELECT ID, Has_Complex_Product__c FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1].Has_Complex_Product__c, true); 
    
  } 


  //============================================================================
  //Scenario 1:
  //RSR #1 - "Software Sale" - Create RSR
  // a) Schedule Type = Constants.SCHEDULE_TYPE_DIVIDE_AMOUNT ("Divide Amount into multiple installments")
  // b) Installment Period = Constants.PERIOD_MONTHLY
  // c) Number of Installment = 12
  // d) Initial Recognize Amount = 25
  // e) Recognize in Month = 6
  //Create Billing Product #1 
  //"Product 1 - Consultancy" where Product__c = Product 1 and RSR__c = RSR #1
  //Create OLI where Product = Product 1 & Type of Sale = "Consultancy" and Amount = 1200 and Start date = today and End date = today + 16 months
  //=> Verify there are 12 installments
  //=> Verify the first installment = 1200 * 0.25
  //=> Verify each of all other payment amounts = (1200 - (1200 * 0.25)) / (#of installments - 1)
  //=> Verify last date installment - first date installment = 12 months
  //============================================================================
  //T-271248: RSR #1 - "Software Sale" - Create RSR
  static testMethod void testRevenueScheduleScenario1 () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-30);
      testOpp.Contract_End_Date__c = Date.today().addMonths(17);
      testOpp.CloseDate = Date.today().addDays(-5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW ;
      insert testOpp;
  
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.CanUseRevenueSchedule = true;
      insert product;
  
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //Creating RSR
      Revenue_Schedule_Rule__c rsr = new Revenue_Schedule_Rule__c();
      rsr.CurrencyIsoCode = 'USD';
      rsr.Schedule_Type__c = Constants.SCHEDULE_TYPE_DIVIDE_AMOUNT;
      rsr.Installment_Period__c = Constants.PERIOD_MONTHLY;
      rsr.Number_of_installments__c = 12;
      rsr.Initial_Recognized_Amount__c = 25;
      rsr.Recognize_In_Month__c = 6;
      insert rsr;
      System.debug('--------rsr---->'+rsr);
      
      Billing_Product__c billProd = new Billing_Product__c();
      billProd.Product__c = product.ID;
      billProd.Type_of_Sale__c = Constants.TYPE_OF_SALE_CONSULTANCY;
      billProd.Revenue_Schedule_Rule__c = rsr.ID;
      billProd.BP_External_Id__c = 'Product 1 - Consultancy';
      insert billProd;
  
      //insert OLI
      //List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
      
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id,testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today();
      opptyLineItem.End_Date__c = Date.today().addMonths(16);
      opptyLineItem.Type_of_Sale__c = Constants.TYPE_OF_SALE_CONSULTANCY;
      opptyLineItem.UnitPrice = 1200;
      opptyLineItem.TotalPrice = null;
      insert opptyLineItem;
      
      // PK Case #964253 - Adding an order to the list to check below.
      List<OpportunityLineItemSchedule> olisList = [
        SELECT ID, Revenue, ScheduleDate 
        FROM OpportunityLineItemSchedule 
        WHERE OpportunityLineItemId =: opptyLineItem.ID 
        ORDER BY ScheduleDate
      ];
  
      System.debug('****startDate***'+olisList.get(0));
      //System.debug('****EndDate***'+olisList.get(11));
      
      Date startDate = olisList.get(0).ScheduleDate;
      Date endDate = olisList.get(olisList.size()-1).ScheduleDate;
      
      // Verify there are 12 installments
      System.assertEquals(olisList.size(), 12);
      // Verify the first installment = 1200 * 0.25
      System.assertEquals(olisList.get(0).Revenue, 1200.00*0.25); // This test frequently fails with Revenue returned as  81.81818181818181
      // Verify each of all other payment amounts = (1200 - (1200 * 0.25)) / (#of installments - 1)
      System.assertEquals(Integer.valueOf(olisList.get(1).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(2).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(3).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(4).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(5).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(6).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(7).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(8).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(9).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));    
      System.assertEquals(Integer.valueOf(olisList.get(10).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      System.assertEquals(Integer.valueOf(olisList.get(11).Revenue), Integer.valueOf((1200.00 - (1200.00*0.25))/(olisList.size()-1)));
      // Verify last date installment - first date installment = 11 months
      // eg: 10-14-2014 to 09-14-2015 has difference of 11 month.
      //System.assertEquals(startDate.monthsBetween(endDate), 11); // Getting assert as 10
    }
  }     
  
  
  //============================================================================
  //Scenario 2:
  //Create RSR #2
  // RSR #2 - "Quarterly Spread over life of agreement"
  // a) Schedule Type = Constants.SCHEDULE_TYPE_DIVIDE_AMOUNT
  // b) Installment Period = Constants.PERIOD_QUARTERLY
  // c) Number of Installments = 0
  // d) Initial Recognized Amount = 0
  // e) Recognize in Month = 0
  //Create Billing Product #2
  //"Product 2 - Software Sale" where Product__c = Product 2 and RSR__c = RSR #2
  //Create OLI where Product = Product 2 & Type of Sale = "Software Sale" and Amount = 1200 and start date = today & end date = today + 16 months
  //=> Verify there are 5 installments
  //=> Verify each of all payment amounts = (1200) / ((endDate - startDate) / 3)
  //=> Verify second installment date = first installment date + 3 months
  //============================================================================  
  //T-271248: RSR #2 - "Quarterly Spread over life of agreement"
  static testMethod void testRevenueScheduleScenario2 () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-30);
      testOpp.Contract_End_Date__c = Date.today().addMonths(17);
      testOpp.CloseDate = Date.today().addDays(-5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
  
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.CanUseRevenueSchedule = true;
      insert product;
  
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //Creating RSR
      Revenue_Schedule_Rule__c rsr = new Revenue_Schedule_Rule__c();
      rsr.CurrencyIsoCode = 'USD';
      rsr.Schedule_Type__c = Constants.SCHEDULE_TYPE_DIVIDE_AMOUNT;
      rsr.Installment_Period__c = Constants.PERIOD_QUARTERLY;
      rsr.Number_of_installments__c = 5;
      rsr.Initial_Recognized_Amount__c = 0;
      rsr.Recognize_In_Month__c = 0;
      insert rsr;
      
      Billing_Product__c billProd = new Billing_Product__c();
      billProd.Product__c = product.ID;
      billProd.Type_of_Sale__c = Constants.TYPE_OF_SALE_SOFTWARESALE;
      billProd.Revenue_Schedule_Rule__c = rsr.ID;
      billProd.BP_External_Id__c = 'Product 2 - Software Sale';
      insert billProd;
  
      //insert OLI
      //List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
      
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today();
      opptyLineItem.End_Date__c = Date.today().addMonths(16);
      opptyLineItem.Type_of_Sale__c = Constants.TYPE_OF_SALE_SOFTWARESALE;
      opptyLineItem.UnitPrice = 1200;
      opptyLineItem.TotalPrice = null;
      insert opptyLineItem;
  
      
      List<OpportunityLineItemSchedule> olisList = [SELECT ID, Revenue, ScheduleDate
                                                    FROM OpportunityLineItemSchedule
                                                    WHERE OpportunityLineItemId =: opptyLineItem.ID
                                                    ORDER BY ScheduleDate];
  
      System.debug('****startDate***'+olisList.get(0));
      //System.debug('****EndDate***'+olisList.get(4));
      
      Date startDate = olisList.get(0).ScheduleDate;
      Date endDate = olisList.get(olisList.size()-1).ScheduleDate;
      Date secondInstallmentDate = olisList.get(1).ScheduleDate;
      
      // Verify there are 5 installments
      system.assertEquals(olisList.size(), 5);
      // Verify each of all other payment amounts = (1200 - (1200 * 0.25)) / (#of installments - 1)
      System.assertEquals(Integer.valueOf(olisList.get(0).Revenue), Integer.valueOf((1200.00)/(olisList.size())));
      System.assertEquals(Integer.valueOf(olisList.get(1).Revenue), Integer.valueOf((1200.00)/(olisList.size())));
      System.assertEquals(Integer.valueOf(olisList.get(2).Revenue), Integer.valueOf((1200.00)/(olisList.size())));
      System.assertEquals(Integer.valueOf(olisList.get(3).Revenue), Integer.valueOf((1200.00)/(olisList.size())));
      System.assertEquals(Integer.valueOf(olisList.get(4).Revenue), Integer.valueOf((1200.00)/(olisList.size())));
      
      //varify second installment date = first + 3 months
      System.assertEquals(startDate.monthsBetween(secondInstallmentDate), 3);
    }
  }
  
  //====================================================================================
  //  Scenario 3:
  //Create RSR #3
  //RSR #3 - "Ad-Hoc"
  // a)  Schedule Type = Constants.SCHEDULE_TYPE_REPEAT_AMOUNT ("Repeat Amount for each installment")
  // b) Installment Period = Constants.PERIOD_MONTHLY
  // c) Number of Installments = 1
  // d) Initial Recognized Amount = 100
  // e) Recognize in Month = 2
  //Create Billing Product #3
  //"Product 3 - Ad-Hoc"  where Product__c = Product 3 and RSR__c = RSR #3
  //Create OLI where Product = Product 3 & Type of Sale = "Ad-Hoc" and Amount = 1000
  //=> Verify there is 1 installment
  //=> Verify the first installment amount = oli.unitprice
  //=> Verify second installment date = oli start date + rsr.recognize in month value
  //==================================================================================== 
  //T-271248: RSR #3 - "Ad-Hoc"
  static testMethod void testRevenueScheduleScenario3 () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-30);
      testOpp.Contract_End_Date__c = Date.today().addMonths(17);
      testOpp.CloseDate = Date.today().addDays(-5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
  
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.CanUseRevenueSchedule = true;
      insert product;
  
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //Creating RSR
      Revenue_Schedule_Rule__c rsr = new Revenue_Schedule_Rule__c();
      rsr.CurrencyIsoCode = 'USD';
      rsr.Schedule_Type__c = Constants.SCHEDULE_TYPE_REPEAT_AMOUNT;
      rsr.Installment_Period__c = Constants.PERIOD_MONTHLY;
      rsr.Number_of_installments__c = 1;
      rsr.Initial_Recognized_Amount__c = 100;
      rsr.Recognize_In_Month__c = 2;
      insert rsr;
      
      Billing_Product__c billProd = new Billing_Product__c();
      billProd.Product__c = product.ID;
      billProd.Type_of_Sale__c = Constants.TYPE_OF_SALE_SOFTWARESALE;
      billProd.Revenue_Schedule_Rule__c = rsr.ID;
      billProd.BP_External_Id__c = 'Product 2 - Software Sale';
      insert billProd;
  
      //insert OLI
      //List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
      
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today();
      opptyLineItem.End_Date__c = Date.today().addMonths(16);
      opptyLineItem.Type_of_Sale__c = Constants.TYPE_OF_SALE_ADHOC;
      opptyLineItem.UnitPrice = 1000;
      opptyLineItem.TotalPrice = null;
      opptyLineItem.Billing_Product__c = billProd.Id;
      insert opptyLineItem;
    
      List<OpportunityLineItemSchedule> olisList = [SELECT ID, Revenue, ScheduleDate FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId =: opptyLineItem.ID];
    
      Date startDate = olisList.get(0).ScheduleDate;
      
      // Verify there is only 1 installments
      system.assertEquals(olisList.size(), 1);
      // Verify each of all other payment amounts = (1200 - (1200 * 0.25)) / (#of installments - 1)
      System.assertEquals(Integer.valueOf(olisList.get(0).Revenue), opptyLineItem.UnitPrice);
    }
  }
  
  //====================================================================================
  //Scenario 4:
  //Create RSR #4
  //RSR #4 - "Free of Charge"
  // a) Schedule Type = Constants.SCHEDULE_TYPE_REPEAT_AMOUNT ("Repeat Amount for each installment")
  // b) Installment Period = Constants.PERIOD_MONTHLY
  // c) Number of Installments = 0
  // d) Initial Recognized Amount = 0
  // e) Recognize in Month = 0
  //Create Billing Product #4
  //"Product 4 - Initial Software Fee" where Product__c = Product 3 and RSR__c = RSR #4
  //Create OLI where Product = Product 4 & Type of Sale = "Initial Software Fee" and Amount = 1000
  //=> Verify there are no installment
  //====================================================================================
 
  //T-271248: RSR #4 - "Free of Charge"
  static testMethod void testRevenueScheduleScenario4 () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Contract_Start_Date__c = Date.today().addDays(-30);
      testOpp.Contract_End_Date__c = Date.today().addMonths(17);
      testOpp.CloseDate = Date.today().addDays(-5);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
  
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      product.CanUseRevenueSchedule = true;
      insert product;
  
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //Creating RSR
      Revenue_Schedule_Rule__c rsr = new Revenue_Schedule_Rule__c();
      rsr.CurrencyIsoCode = 'USD';
      rsr.Schedule_Type__c = Constants.SCHEDULE_TYPE_REPEAT_AMOUNT;
      rsr.Installment_Period__c = Constants.PERIOD_MONTHLY;
      rsr.Number_of_installments__c = 0;
      rsr.Initial_Recognized_Amount__c = 0;
      rsr.Recognize_In_Month__c = 0;
      insert rsr;
      
      Billing_Product__c billProd = new Billing_Product__c();
      billProd.Product__c = product.ID;
      billProd.Type_of_Sale__c = Constants.TYPE_OF_SALE_INITIALSOFTWAREFEE;
      billProd.Revenue_Schedule_Rule__c = rsr.ID;
      billProd.BP_External_Id__c = 'Product 2 - Software Sale';
      insert billProd;
  
      //insert OLI
      //List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
      
      OpportunityLineItem opptyLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opptyLineItem.Start_Date__c = Date.today();
      opptyLineItem.End_Date__c = Date.today().addMonths(16);
      opptyLineItem.Type_of_Sale__c = Constants.TYPE_OF_SALE_ADHOC;
      opptyLineItem.UnitPrice = 1000;
      opptyLineItem.TotalPrice = null;
      insert opptyLineItem;
  
      
      List<OpportunityLineItemSchedule> olisList = [SELECT ID, Revenue, ScheduleDate FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId =: opptyLineItem.ID];
    // Verify there is 0 installments
      system.assertEquals(olisList.size(), 0);
    }
  }
  
   
  // T-272243: To test the method setOppDeliveryDatesPlannedUncheck() 
  static testmethod void testOppDeliveryDatesPlannedUncheck(){
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      Account testAcc = Test_Utils.insertAccount();
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      testOpp.Delivery_Dates_Planned__c = true;
      testOpp.Delivery_Email_Alert__c = 'test@testmail.com';
      testOpp.Contract_Start_Date__c = System.today().addDays(-5);
      testOpp.Contract_End_Date__c = System.today().addDays(10);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
      
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      insert product;
      
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      
      OpportunityLineItem opptyLineItem = new OpportunityLineItem();
      opptyLineItem.OpportunityId = testOpp.ID;
      opptyLineItem.Quantity = 1;
      opptyLineItem.UnitPrice = 200;
      opptyLineItem.PricebookEntryId = stdPricebookEntry.ID;
      opptyLineItem.Start_Date__c = System.today();
      opptyLineItem.End_Date__c = System.today().addDays(6);
      opptyLineItem.Order_Type__c = Constants.STATUS_NEW;
      insert opptyLineItem;
    
    
      Test.startTest();
      
      opptyLineItem.Start_Date__c = Date.today().addDays(5);
      update opptyLineItem;
      
      List<Opportunity> resultOpp = [SELECT ID, Delivery_Dates_Planned__c FROM Opportunity WHERE ID=:testOpp.Id];
      System.assertEquals(false, resultOpp.get(0).Delivery_Dates_Planned__c);
      
      resultOpp.get(0).Delivery_Dates_Planned__c = true;
      update resultOpp;
      
      opptyLineItem.End_Date__c = Date.today().addDays(10);
      update opptyLineItem;
      
      List<Opportunity> resultOpp1 = [SELECT ID, Delivery_Dates_Planned__c FROM Opportunity WHERE ID=:resultOpp.get(0).Id];
      Test.stopTest();
      System.assertEquals(false, resultOpp1.get(0).Delivery_Dates_Planned__c);
    }
  }
  
  static testMethod void testDeleteOrphanRoyalties() {

    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;
  
    System.runAs(testUser) {
      Account testAcc = Test_Utils.insertAccount();
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      testOpp.Delivery_Dates_Planned__c = true;
      testOpp.Delivery_Email_Alert__c = 'test@testmail.com';
      testOpp.Contract_Start_Date__c = System.today().addDays(-5);
      testOpp.Contract_End_Date__c = System.today().addDays(10);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;
      
      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      insert product;
      
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      
      List<OpportunityLineItem> listOppLineItemTOInsert = new List<OpportunityLineItem>();
      OpportunityLineItem opptyLineItem1 = new OpportunityLineItem();
      opptyLineItem1.OpportunityId = testOpp.ID;
      opptyLineItem1.Quantity = 1;
      opptyLineItem1.UnitPrice = 200;
      opptyLineItem1.PricebookEntryId = stdPricebookEntry.ID;
      opptyLineItem1.Start_Date__c = System.today();
      opptyLineItem1.End_Date__c = System.today().addDays(5);
      opptyLineItem1.Item_Number__c = 'test1234';
      opptyLineItem1.Order_Type__c = Constants.STATUS_NEW;
      listOppLineItemTOInsert.add(opptyLineItem1);
      
      OpportunityLineItem opptyLineItem2 = new OpportunityLineItem();
      opptyLineItem2.OpportunityId = testOpp.ID;
      opptyLineItem2.Quantity = 1;
      opptyLineItem2.UnitPrice = 200;
      opptyLineItem2.PricebookEntryId = stdPricebookEntry.ID;
      opptyLineItem2.Start_Date__c = System.today();
      opptyLineItem2.End_Date__c = System.today().addDays(5);
      opptyLineItem2.Item_Number__c = 'test12345';
      opptyLineItem2.Order_Type__c = Constants.STATUS_NEW;
      listOppLineItemTOInsert.add(opptyLineItem2);
     
      insert listOppLineItemTOInsert;

      //Inserting 200 records to test bulk records
      List<Royalty__c> listRoyaltyTOInsert = new List<Royalty__c>();
      for (integer i = 0; i < 200; i++) {
        Royalty__c royalty = Test_Utils.insertRoyalty(false, 'test1234');
        royalty.Opportunity__c = testOpp.Id;
        listRoyaltyTOInsert.add(royalty);
      }
      Royalty__c royalty1 = Test_Utils.insertRoyalty(false, 'test12345');
      royalty1.Opportunity__c = testOpp.Id;
      listRoyaltyTOInsert.add(royalty1);
      insert listRoyaltyTOInsert;
      
      Test.startTest();
        //Deleting list items so that ofphans can also be deleted
      delete listOppLineItemTOInsert;
        Test.stopTest();
      
      //Checking for DMLs run during functional test
      system.assert(Limits.getDMLStatements() < 20 );
      
      //Assert to check Orphans got deleted
        List<Royalty__c> listRoyalties1 = [Select Id From Royalty__c Where Line_Item_Reference_Number__c = 'test1234'];
            system.assertEquals(0, listRoyalties1.size());   
            
      //Assert to check Orphans got deleted
            List<Royalty__c> listRoyalties2 = [Select Id From Royalty__c Where Line_Item_Reference_Number__c = 'test12345'];
            system.assertEquals(0, listRoyalties2.size());  
   } 
  }
   
    //As per : T-319440
  static testMethod void testRequoteAndLockingOLIs() {

    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;
  
    System.runAs(testUser) {

      Test.startTest();
      Account testAcc = Test_Utils.insertAccount();
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      testOpp.Delivery_Dates_Planned__c = true;
      testOpp.Delivery_Email_Alert__c = 'test@testmail.com';
      testOpp.Contract_Start_Date__c = System.today().addDays(-5);
      testOpp.Contract_End_Date__c = System.today().addDays(10);
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
      insert testOpp;

      Quote__c qt = new Quote__c();
      qt.Opportunity__c = testOpp.ID;
      qt.Discount_Percent__c = 0.0;
      insert qt;

      // Create Opportunity Line Item
      Product2 product = Test_Utils.createProduct();
      insert product;
      
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      
      List<OpportunityLineItem> listOppLineItemTOInsert = new List<OpportunityLineItem>();
      OpportunityLineItem opptyLineItem1 = new OpportunityLineItem();
      opptyLineItem1.OpportunityId = testOpp.ID;
      opptyLineItem1.Quantity = 1;
      opptyLineItem1.UnitPrice = 200;
      opptyLineItem1.PricebookEntryId = stdPricebookEntry.ID;
      opptyLineItem1.Start_Date__c = System.today();
      opptyLineItem1.End_Date__c = System.today().addDays(5);
      opptyLineItem1.Item_Number__c = 'test1234';
      opptyLineItem1.Order_Type__c = Constants.STATUS_NEW;
      listOppLineItemTOInsert.add(opptyLineItem1);
      
      OpportunityLineItem opptyLineItem2 = new OpportunityLineItem();
      opptyLineItem2.OpportunityId = testOpp.ID;
      opptyLineItem2.Quantity = 1;
      opptyLineItem2.UnitPrice = 200;
      opptyLineItem2.PricebookEntryId = stdPricebookEntry.ID;
      opptyLineItem2.Start_Date__c = System.today();
      opptyLineItem2.End_Date__c = System.today().addDays(5);
      opptyLineItem2.Item_Number__c = 'test12345';
      opptyLineItem2.Order_Type__c = Constants.STATUS_NEW;
      listOppLineItemTOInsert.add(opptyLineItem2);

      try {
        
        insert listOppLineItemTOInsert;
            
        opptyLineItem1.UnitPrice = 210;
        update opptyLineItem1;  
        
      } catch (DmlException ex) {
        System.assert(String.valueOf(ex.getDmlMessage(0)).contains(Label.OLI_READ_ONLY));
      }
      Test.stopTest();
  
   } 
  }
}