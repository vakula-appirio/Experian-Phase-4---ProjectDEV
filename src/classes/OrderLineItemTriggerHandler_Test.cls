/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineItemTriggerHandler_Test
 * Description: To Test funcitonality of Trigger on Order Line Item
 * Created Date: 02/13/2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 26th, 2014       Nathalie Le Guay (Appirio)   Removed references to Selection_confirmed__c and Signed_Contract__c
 *                                                   and Task_Quote_Delivered__c
 * Feb 27th, 2014       Naresh Kr Ojha(Appirio)      Commented code which checks Orders when oppty goes won.
 * Feb 27th, 2014       Nathalie Le Guay (Appirio)   Added opp.Starting_Stage__c values
 * Mar 04th, 2014       Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 20th ,2014       Megha Agarwal(Appirio JDC)   T-260650 : Service Dates testServiceDates()
 * Mar 28th, 2014       Arpita Bose(Appirio)         T-266095: Retest_LinkRoyaltyRecordsWithOrderLineItemmoving reference to the field 
 *                                                   Opportunity.Status__c which is removed
 * Apr 02nd, 2014       Arpita Bose(Appirio)         T-268651: Removed method testServiceDates() as the functionality is changed
 * Apr 02nd, 2014      Nathalie Le Guay              Replaced order.Service_Start/End_Date__c with order.Contract_Start/End_Date__c
 * Apr 03rd, 2014      Arpita Bose                   T-268982: Updated Test_Utils method name to insertOrderLineItems()
 * Apr 15th, 2014      Arpita Bose                   T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014      Arpita Bose                   T-271695: Renamed field Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 30th, 2014      Arpita Bose                   I-113908: Added test method testCurrencyIsoOnOrderLine()
 * Jul 31st, 2014      Arpita Bose                   T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Sept 04st, 2014     Naresh Kr Ojha                T-313547: Linking royalty records with order lines. added testLinkRoyaltyRecordsWithOrderLineItem()
 * Oct 07, 2014        Naresh Kr Ojha                T-323664: test_createAssetsForReadOnlyOrderLines_InsertCase() and test_createAssetsForReadOnlyOrderLines_UpdateCase()
 * Oct 16th, 2014      Arpita Bose                   Commented method test_createAssetsForReadOnlyOrderLines_InsertCase() and test_createAssetsForReadOnlyOrderLines_UpdateCase() 
                                                     T-326258:
 * Oct 21st, 2014      Arpita Bose                   Updated to remove IsData_Admin__c     
 * Oct 27th, 2014      Pallavi Sharma                Fix failures 
 * Nov 03rd, 2014      Arpita Bose                   Updated test_createAssetForRenwal_ExistingAsset_Insert() to fix failure on P2QA
 * Feb 02th, 2014      Noopur                        Added methods - test_createAssetForRenwal_NOExistingAsset_Insert(),test_createAssetForRenwal_ExistingAsset_SignificantChange_Insert(),
 *                                                   test_createAssetForRenwal_ExistingAsset_NoSignificantChange_Insert()
 * Feb 02th, 2014      Noopur                        Added methods - test_createAssetForRenwal_ExistingOriginalAsset_SignificantChange_Insert(), test_createAssetForRenwal_ExistingOriginalAsset_NoSignificantChange_Insert() 
 * Mar 5th, 2015       Paul Kissick                  Case #583351 - Added line to reset isExecuted variable on OpportunityTrigger_OrderHelper class and removed seealldata
 * Mar 10th, 2015      Sadar Yacob                   Added code to increase Code coverage
 * Mar 26th, 2015      Gaurav Kumar Chadha           Inserted Address__c , Account_Address__c , Contact_Address__c in methods test_createAssetForRenwal_ExistingOriginalAsset_SignificantChange_Insert() , test_createAssetForRenwal_ExistingOriginalAsset_NoSignificantChange_Insert()
                                                     test_createAssetForRenwal_ExistingAsset_SignificantChange_Insert() , test_createAssetForRenwal_ExistingAsset_NoSignificantChange_Insert()
                                                     test_createAssetForNonRenwal_Insert()     
 * May 2nd, 2015       Noopur                        Reset the static variables used in related triggerHandlers and Helper classes to resolve the test failures 
 =====================================================================*/
@isTest
public with sharing class OrderLineItemTriggerHandler_Test {
 
  private static Order__c orderObj;
  private static Billing_Product__c billingProduct;
  private static List<Order_Line_Item__c> orderLineItems;
  
  /* Commented as Order is not being created in OpportunityTriggerHandler.cls: nojha
  
  @isTest
  static void testUpdateOLITotal () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
       Test.startTest();
      
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Has_Senior_Approval__c = true;
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695: Removed reference to Below_Review_Thresholds__c field
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      testOpp.Amount = 500;
      IsDataAdmin__c dataAdmin = new IsDataAdmin__c();
      dataAdmin.SetupOwnerId = UserInfo.getUserId();
      dataAdmin.IsDataAdmin__c = true;
      insert dataAdmin;
      
      insert testOpp;
      //Test_Utils.createOpptyTasks(testOpp.Id, true);
  
      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                          AccountId = testAccount.Id, Email = 'larrye@email.com');
      insert newcontact;
  
      OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = testOpp.Id, IsPrimary = true, Role = Constants.DECIDER);
      insert oppContactRole ;
      
      //////////////////////
      // Create Opportunity Line Item
      Product2 product = Test_Utils.insertProduct();
      product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;    
      product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;    
      product.NumberOfRevenueInstallments = 2;    
      //product.CanUseQuantitySchedule = false;
      product.CanUseRevenueSchedule = true;
      
      update product;
      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //insert OLI
      OpportunityLineItem opportunityLineItem2 = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
  
      //insert OLIS
      OpportunityLineItemSchedule olsi1 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
      OpportunityLineItemSchedule olsi2 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
      OpportunityLineItemSchedule olsi3 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);    
      List<OpportunityLineItemSchedule> opptySchedules = new List<OpportunityLineItemSchedule>();
      opptySchedules.add(olsi1);
      opptySchedules.add(olsi2);
      opptySchedules.add(olsi3);
      insert opptySchedules;
      
      Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
      insert comp;
  
      dataAdmin.IsDataAdmin__c = false;
      update dataAdmin;
      
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
      testOpp.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_DATA_QUALITY;
      update testOpp; 
  
      
      
      List<Order__c> ordList = new List<Order__c>();
      List<Order_Revenue_Schedule__c> orderSchedules = new List<Order_Revenue_Schedule__c>();
      Set<String> orderLineItemIDSet = new Set<String>();
      Order_Line_Item__c orderLineItem = new Order_Line_Item__c();
      
      //Getting Order, Order lines and schedules to test.
      for (Order__c ord : [SELECT Opportunity__c, o.Id, (SELECT Id FROM Order_Line_Items__r) FROM Order__c o WHERE Opportunity__c =: testOpp.ID]) {
        ordList.add(ord);
        for (Order_Line_Item__c orderLine : ord.Order_Line_Items__r) {
          orderLineItem = orderLine;
          break;
        }
      }
      Integer totalRevenue = 0;
      
      for (Order_Revenue_Schedule__c ordRevSchedule : [SELECT ID, Revenue__c FROM Order_Revenue_Schedule__c WHERE Order_Line_Item__c =: orderLineItem.ID]) {
        orderSchedules.add(ordRevSchedule);
        
        totalRevenue += Integer.valueOf(ordRevSchedule.Revenue__c);
      }
      Test.stopTest();
      // Commented as Order is not being created in OpportunityTriggerHandler.cls: nojha
      //Asserts
      //System.assertEquals(totalRevenue, 300);
      //Updated schedule revenue by 200 (100+100) so Order Line should have 400 total
      //orderSchedules.get(0).Revenue__c = 200;
      //update orderSchedules;
      //update orderLineItem;
      //orderLineItem = [SELECT Total__c, ID FROM Order_Line_Item__c WHERE ID =: orderLineItem.ID];
      
      //100+100+200 for schedules, so total should be 400.
      //System.AssertEquals(Integer.valueOf(orderLineItem.Total__c), 400);
      
    }
  }*/

  //T-268651: Removed this method as the functionality is changed and method is commented on the class
 /* @isTest
  static void testServiceDates() {
    createTestData();
    orderLineItems = new List<Order_Line_Item__c>();
    orderLineItems.add(Test_Utils.insertOrderLineItems(false, orderObj.id, null));
    orderLineItems.add(Test_Utils.insertOrderLineItems(false, orderObj.id, null));
    orderLineItems.get(1).Service_Start_Date__c = Date.today().addDays(-10);
    orderLineItems.get(1).Service_End_Date__c = Date.today().addDays(40);
    insert orderLineItems;
    
    List<Order_Line_Item__c> resultOLIs = [select id , Service_Start_Date__c, Service_End_Date__c from Order_Line_Item__c where id in : orderLineItems];
    System.assertEquals(resultOLIs.get(0).Service_Start_Date__c , Date.today());
  }*/
  
  private static void createTestData(){ 
    // Create an account    
    Account testAccount = Test_Utils.insertAccount();
    Test.startTest();       
    
    // Create an opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Has_Senior_Approval__c = true;
    testOpp.StageName = Constants.OPPTY_STAGE_3;
    //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695: Removed reference to Below_Review_Thresholds__c field
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    testOpp.Amount = 500;
    /*IsDataAdmin__c dataAdmin = new IsDataAdmin__c();
    dataAdmin.SetupOwnerId = UserInfo.getUserId();
    dataAdmin.IsDataAdmin__c = true;
    insert dataAdmin; */
    
   insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                        AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;

    orderObj = Test_Utils.insertOrder(false, testAccount.id, newcontact.id, testOpp.id);
    orderObj.Contract_Start_Date__c = Date.today(); 
    orderObj.Contract_End_Date__c = Date.today().addDays(30);
    insert orderObj;
    
    //dataAdmin.IsDataAdmin__c = false;
    //update dataAdmin;
  }
  
  @isTest
  public static void testCurrencyIsoOnOrderLine(){
    //create Account
      Account acc = Test_Utils.insertAccount();
      //create Opportunity
      Opportunity opp1 = Test_Utils.createOpportunity(acc.Id);
      insert opp1;
      Test.startTest();
      //create Order
      Order__c ordr =  Test_Utils.createOrder();
      ordr.CurrencyIsoCode = Constants.CURRENCY_GBP;
      ordr.Opportunity__c = opp1.Id;
      ordr.Account__c = acc.ID;
      ordr.Transactional_Sale__c = false;
      insert ordr;
      
      Billing_Product__c billProd = Test_Utils.insertBillingProduct();
      
      //create Order Line Item
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, billProd.Id);
      ordrli.CurrencyIsoCode = Constants.CURRENCY_USD;
      insert ordrli;
      
      Order_Line_Item__c ordrli1 = [SELECT Id, CurrencyIsoCode From Order_Line_Item__c WHERE ID =:ordrli.Id];
      Test.stopTest();
      system.assertEquals(ordrli1.CurrencyIsoCode, Constants.CURRENCY_GBP);
     
  }
  
  @isTest
  public static void test_LinkRoyaltyRecordsWithOrderLineItem(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_NEW_FROM_NEW ;
    insert testOpp;

    // create Royalty
    Royalty__c royalty = new Royalty__c(Name = 'Test Royalty', Line_Item_Reference_Number__c = referenceNo,
                                         Opportunity__c = testOpp.Id);
    insert royalty;

    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, 
                                                   Order_Type__c = Constants.STATUS_NEW,
                                                   Item_Number__c = referenceNo);
    insert opportunityLineItem;

    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    Test.startTest();       
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    insert ordrli;
    
    
    List<Royalty__c> result = [SELECT Id, Order_Line_Item__c, Opportunity__c, Line_Item_Reference_Number__c
                               FROM Royalty__c
                               WHERE Line_Item_Reference_Number__c =: referenceNo];
                          
    system.assertEquals(result.get(0).Order_Line_Item__c, ordrli.Id);                            
    // stop test
    Test.stopTest();
  }
  
  
  @isTest
  public static void test_createAssetsForReadOnlyOrderLines_InsertCase(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    
    
    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    
    for (Integer i=0; i<10; i++) {
      OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
      olis.add(opportunityLineItem);
    }

    insert olis;
    
    Test.startTest();
    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);

    List<Order_Line_Item__c> orderLIs = new List<Order_Line_Item__c>();
    //create Order Line Item
    for (Integer i=0; i<5; i++) {
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
      ordrli.Opportunity_Line_Item_Id__c = olis.get(i).Id;
      ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
      ordrli.Product__c = product.ID;
      orderLIs.add(ordrli);
    }
    insert orderLIs;
    
    // stop test
    Test.stopTest();
    
    System.assert([SELECT ID FROM Asset WHERE Order_Line__c in : orderLIs].size() == 5);
  }  

  @isTest
  public static void test_createAssetsForReadOnlyOrderLines_UpdateCase(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
    insert opportunityLineItem;


    OpportunityLineItem opportunityLineItem2 =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
    insert opportunityLineItem2;
    
    Test.startTest();
    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineStandardRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.RECORDTYPE_STANDARDS);
           
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineStandardRT_ID;
    insert ordrli;

    System.assert([SELECT ID FROM Asset WHERE Order_Line__c =: ordrli.ID].size() == 0);
	OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);

    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Product__c = product.ID;
    update ordrli;
    
    // stop test
    Test.stopTest();
    
    System.assert([SELECT ID FROM Asset WHERE Order_Line__c =: ordrli.ID].size() == 1);
  } 
 
  @isTest
  public static void test_setOnDemandFlagOnOrderLineDeleted(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
     
    
    // create Order
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct1 = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    //Billing_Product__c oppLineItemBillingProduct2 = Test_Utils.insertBillingProduct();
    List<OpportunityLineItem> opptyLines = new List<OpportunityLineItem>();
    
    Billing_Product__c oppLineItemBillingProduct2 = Test_Utils.insertBillingProduct(); 
        
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;
    Test.startTest();
    List<Order_Line_Item__c> orderLines = new List<Order_Line_Item__c>();
    //create Order Line Item
    Order_Line_Item__c newOrderLine1 = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct1.Id);
    newOrderLine1.EDQ_On_Demand_Product__c = true;
    orderLines.add(newOrderLine1);
    
    Order_Line_Item__c newOrderLine2 = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct1.Id);
    newOrderLine2.EDQ_On_Demand_Product__c = true;
    newOrderLine2.Implementation__c = 'Salesforce.com';
    orderLines.add(newOrderLine2);
    
    Order_Line_Item__c newOrderLine3 = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct2.Id);
    newOrderLine3.EDQ_On_Demand_Product__c = false;
    newOrderLine3.Implementation__c = 'Salesforce.com';
    orderLines.add(newOrderLine3);
    
    //System.assertEquals('====>'+orderLines, '');
    insert orderLines;
    
    Order__c ord = [SELECT ID, Number_of_On_Demand_Order_Line_Items__c, EDQ_Send_to_On_Demand__c FROM Order__c WHERE ID =: ordr.ID];
    
    System.assertEquals(ord.Number_of_On_Demand_Order_Line_Items__c, 2);
    System.assertEquals(ord.EDQ_Send_to_On_Demand__c, false);
    
    //code added 03/10/15
    List<Order_Line_item__c> newOrdLnList = new list<Order_Line_Item__c> ([Select id,Order__c, Order__r.Type__c,Product__r.name,Product__c,EDQ_On_Demand_Product__c,Implementation__c,Data_Usage__c,Product__r.Family,Product_Upgrade__c ,Start_Date__c,End_Date__c from Order_Line_Item__c where Order__r.ID =:ordr.ID  ]);
    OrderLineItemTriggerHandler.populateMemoLine(newOrdLnList );
    
    
    delete newOrderLine1;

    ord = [SELECT ID, Number_of_On_Demand_Order_Line_Items__c, EDQ_Send_to_On_Demand__c FROM Order__c WHERE ID =: ordr.ID];
    
    System.assertEquals(ord.Number_of_On_Demand_Order_Line_Items__c, 1);
    System.assertEquals(ord.EDQ_Send_to_On_Demand__c, true);
    
    // stop test
    Test.stopTest();
  } 
  
  //Asset is to be created when Oppty is Renewal and OrdLine is readOnly.
  @isTest
  public static void test_createAssetForRenwal_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    
    Test_Utils.insertEDQOpportunityContactRoles(testOpp.Id, newcontact.Id);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
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
        
    Test.startTest();
    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineStandardRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.RECORDTYPE_STANDARDS);
                      
    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);                    
           
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Product__c = product.ID; 
    insert ordrli;
    
    Test.stopTest();
    
    System.assert([SELECT ID FROM Asset WHERE Order_Line__c =: ordrli.ID].size() == 1);
  }
  
  //Asset is to be created when Oppty is Non Renewal and OrdLine is readOnly.
  @isTest
  public static void test_createAssetForNonRenwal_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID); 
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id); 
                                                   //Reference_Number__c = referenceNo);
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
    
    Test_Utils.insertEDQOpportunityContactRoles(testOpp.Id, newcontact.Id);
    
    // PK: Adding this to properly test creating orders.
    OpportunityTrigger_OrderHelper.isExecuted = false;
    
    
    Test.startTest();
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;

    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
           
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Product__c = product.ID;
    insert ordrli;
    
    Order_Line_Item__c ordrli1 = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Product__c = product.ID;
    insert ordrli1;
    
    Test.stopTest();
    List<Order__c> orders = [SELECT Id FROM Order__c WHERE Opportunity__c =: testOpp.Id];
    system.assertEquals(1, orders.size());
    system.assertEquals(2, [SELECT Id FROM Order_Line_Item__c WHERE Order__c =: orders.get(0).Id].size());
    //System.assertEquals(2, [SELECT Id FROM Asset WHERE Opportunity__c =: testOpp.ID].size());
  } 
  
  //Asset is to be created when Oppty is Renewal but existing asset found and OrdLine is readOnly.
  @isTest
  public static void test_createAssetForRenwal_ExistingAsset_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111'); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);
    
    insert oliList;
    
    List<Asset> existingAssets = new List<Asset>();
    
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
    asst.Opportunity__c  = testOpp.Id;
    
    existingAssets.add(asst);
    insert existingAssets;

    System.debug('==existingAssets==>'+existingAssets);
    
    Test.startTest();
    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
           
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Item_Number__c = 'I-111';
    ordrli.Quote_Number__c = 'Q-111';
    ordrli.Product__c = product.ID;
    insert ordrli;
    
    Test.stopTest();
    List<Asset> assetLst  = [SELECT ID, Name, Product2ID, Order_Line__c FROM Asset WHERE Order_Line__c  = :ordrli.Id];
    System.debug('==assetLst==>'+assetLst);

    System.assert(assetLst.size()>= 1);
    //System.assertEquals(ordrli.RecordTypeId, orderLineReadOnlyRT_ID);
  }
 
  //Asset is to be created when Oppty is Renewal but existing asset found and OrdLine is readOnly.
  @isTest
    public static void test_createAssetForRenwal_ExistingAsset_SignifChange_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.insertProduct();
    Product2 product2 = Test_Utils.createProduct();
    insert product2;
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
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
    List<Asset> existingAssets = new List<Asset>();
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product2.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
    insert asst;
    
    Test.startTest();
    // create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Account__c = testAcc.ID;
    ordr.Transactional_Sale__c = false;
    insert ordr;

    ID orderLineReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(
                           Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
           
    //create Order Line Item
    Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, oppLineItemBillingProduct.Id);
    ordrli.Opportunity_Line_Item_Id__c = opportunityLineItem.Id;
    ordrli.RecordTypeId = orderLineReadOnlyRT_ID;
    ordrli.Item_Number__c = 'I-111';
    ordrli.Quote_Number__c = 'Q-111';
    ordrli.Product__c = product.ID;
    insert ordrli;
    
    Test.stopTest();
    
    System.assert([SELECT ID FROM Asset WHERE Order_Line__c =: ordrli.ID].size() == 1);
  }
  
  // OppLineItem's Original Asset Id not populated and NO matching asset with OppLine Item's Quote/Item number
  @isTest(seealldata = false)
  public static void test_createAssetForRenwal_NOExistingAsset_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, 'Decider', true);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.insertProduct();
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111'); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);
    
    insert oliList;
    
    
    List<Asset> assetList1 = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList1.size() , 0);
    
    Test.startTest();
    OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    OpportunityTrigger_OrderHelper.isExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;
    Test.stopTest();
    List<Asset> assetList = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList.size() , 1);
    
  }
  
  // Original Asset Id not populated and existing matching asset with Quote/Item number. Significant changes found btw Order Line Item and Asset
  @isTest(seealldata = false)
  public static void test_createAssetForRenwal_ExistingAsset_SignificantChange_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, 'Decider', true);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.createProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    insert product;
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
    
    List<Asset> existingAssets = new List<Asset>();
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
    asst.Part_Number__c = 'PN-111';
    insert asst;
    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111'); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);
    
    insert oliList;
      
    List<Asset> assetList1 = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList1.size() , 0); 
      
    oliList[0].Part_Number__c = 'PNU-111';
    update oliList;
    
    Test.startTest();
    OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    OpportunityTrigger_OrderHelper.isExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;
    Test.stopTest();
    List<Asset> assetList = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertNotEquals(assetList[0].ID , asst.Id);
    
  }
  
  
  //Original Asset Id not populated and existing matching asset with Quote/Item number. No significant changes found btw Order Line Item and Asset
  @isTest(seealldata = false)
  public static void test_createAssetForRenwal_ExistingAsset_NoSignificantChange_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, 'Decider', true);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.createProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    insert product;
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
    
    List<Asset> existingAssets = new List<Asset>();
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
    asst.Part_Number__c = 'PN-111';
    insert asst;

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111'); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    opportunityLineItem.End_Date__c = Date.today().addDays(15);
    oliList.add(opportunityLineItem);
    
    insert oliList;
      
    List<Asset> assetList1 = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList1.size() , 0); 
    OpportunityTriggerHandler.isRunningOpportunityTrigger = true;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    oliList[0].Part_Number__c = 'PN-111';
    update oliList;
    
    Test.startTest();
    OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    OpportunityTrigger_OrderHelper.isExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;
    Test.stopTest();
    List<Asset> assetList = [select Id,Opportunity__c from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList[0].ID , asst.Id);
    system.assertEquals(assetList[0].Opportunity__c , oliList[0].OpportunityId);
  }
  
  //Original Asset Id populated and there were significant changes
 @isTest(seealldata = false)
  public static void test_createAssetForRenwal_ExistingOriginalAsset_SignificantChange_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
        
    Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, 'Decider', true);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.createProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    insert product;
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
    
      List<Asset> existingAssets = new List<Asset>();
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
      asst.Part_Number__c = 'PN-111';
    insert asst;

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111',Original_Asset_ID__c = asst.Id); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);
    
    insert oliList;
    system.assertEquals(oliList[0].Original_Asset_ID__c,asst.Id);
    
    List<Asset> assetList1 = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList1.size() , 0); 
      
    oliList[0].Part_Number__c = 'PNU-111';
    update oliList;
    
    Test.startTest();
    OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    OpportunityTrigger_OrderHelper.isExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_DATA_QUALITY;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;
    Test.stopTest();
    List<Asset> assetList = [select Id,Opportunity__c from Asset Where Opportunity__c = :testOpp.Id];
    system.assertNotEquals(assetList[0].ID , asst.Id);
    
  }
  
  //Original Asset Id populated and no significant changes
  @isTest(seealldata = false)
  public static void test_createAssetForRenwal_ExistingOriginalAsset_NoSignificantChange_Insert(){
    String referenceNo = 'abc1234';
    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    insert testOpp;
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, 'Decider', true);
    
    System.debug('====>'+[SELECT Type FROM Opportunity where id =: testOpp.ID]);
    Product2 product = Test_Utils.createProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    insert product;
    //Pricebook2 pricebook = Test_Utils.getPriceBook2();
    //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
    
      List<Asset> existingAssets = new List<Asset>();
    Asset asst = new Asset(Name = 'TestAsset0001');
    asst.Product2ID = product.ID;
    asst.AccountID = testAcc.ID;
    asst.Callidus_Item_Number__c = 'I-111';
    asst.Callidus_Quote_Number__c = 'Q-111';
      asst.Part_Number__c = 'PN-111';
    insert asst;

    Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); 
    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
    OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (OpportunityId = testOpp.Id,  Quantity = 1,
                                                   PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5),TotalPrice = 200,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Item_Number__c = 'I-111', Quote_Number__c = 'Q-111',Original_Asset_ID__c = asst.Id); 
                                                   //Reference_Number__c = referenceNo);
    opportunityLineItem.Type__c = Constants.OPPTY_TYPE_RENEWAL;
    opportunityLineItem.Order_Type__c = 'Downgrade';
    oliList.add(opportunityLineItem);
    
    insert oliList;
      
    List<Asset> assetList1 = [select Id from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList1.size() , 0); 
      
    oliList[0].Part_Number__c = 'PN-111';
    update oliList;
    
    Test.startTest();
    OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OrderLineItemTriggerHandler.hasRunAssetCreation = false;
    OrderLineItemTriggerHandler.hasRunMemoline = false;  
    OpportunityTrigger_OrderHelper.isExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Channel_Type__c = 'Direct';
    update testOpp;
    Test.stopTest();
    List<Asset> assetList = [select Id,Opportunity__c from Asset Where Opportunity__c = :testOpp.Id];
    system.assertEquals(assetList[0].ID , asst.Id);
      system.assertEquals(assetList[0].Opportunity__c , oliList[0].OpportunityId);
  }
  
}