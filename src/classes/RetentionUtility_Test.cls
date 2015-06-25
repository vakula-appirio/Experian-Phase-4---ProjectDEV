/******************************************************************************
 * Appirio, Inc
 * Name: RetentionUtility_Test.cls
 * Description: T-335663: Test class for RetentionUtility.cls
 * Created Date: Nov 24th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Jan 15th, 2015     Nathalie Le Guay             Updated basicNewOppRetentionTest() for better assertion (unordered query causing issues)
 * Jan 29th, 2015     Noopur                       Updated to improve the coverage of some methods
 * Mar 28th, 2015     Gaurav Kumar Chadha          Updated Method updateOppOwnerIdTest and basicCloseNewOppRetentionTest (changed Account__c to Opportunity__c )
 *                                                   in query filter)          
 * May 1st, 2015      Noopur                       Modified the class for test failures.
 ******************************************************************************/
@isTest(seeAllData = false)
private class RetentionUtility_Test {

  public static Opportunity testOpp;
  public static OpportunityLineItem opportunityLineItem1;
  public static OpportunityLineItem opportunityLineItem2;
  public static OpportunityLineItem opportunityLineItem3;
  public static Contact newcontact;
  public static Partner opr;
  public static Account testAcc;
  public static List<OpportunityLineItem> oliList;
    
  public static Date testDate = Date.newInstance(2050, 02, 01);
  
  //================================================================//
  // Scenario 1 : Creation of a  Opportunity
  //================================================================//
  @isTest(seeAllData = false)
  public static void basicNewOppRetentionTest(){
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
 
    System.runAs(testUser1) { 
    // create test data
    createTestData(true);
        
    // start test
    Test.startTest();
    
    
    // create Opportunity Partner record
    Account accPartner = Test_Utils.insertAccount(); 
    opr = new Partner();
    opr.OpportunityId = testOpp.Id;
    opr.IsPrimary = true;
    opr.AccountToId = accPartner.Id;
    insert opr;
    
    testOpp.StageName = Constants.OPPTY_STAGE_4 ;
    update testOpp;
    // stop test
    Test.stopTest();
    
    List<Retention__c> retRecord = [SELECT Id, Year__c, Month__c FROM Retention__c 
                                    WHERE Account__c = :testAcc.Id];
    System.debug('retRecord>>>' +retRecord);
    //Assert to Verify that there is a Retention__c record for year = 2222 and month = 02
    System.assertEquals(retRecord.size(), 1); 
       
    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Partner_Account__c,
                                        Account__c, Opportunity_Owner__c, Month__c, Status__c, Callidus_Reference__c 
                                        FROM Retention_Line_Item__c WHERE Retention__c IN :retRecord];
    System.debug('rliRecord>>>' +rli);   
    //Asserts to Verify that there should be Retention_Line_Item__c records for the above Retention__c record
    system.assert(rli.size() > 0);
   
    //Asserts to Verify RLI.Actual_Margin__c == blank for each RLI
    system.assertEquals(rli.get(0).Actual_Margin__c, null);

    //Asserts to Verify the RLI.Available_Margin__c should have value.
    system.assert(rli.get(0).Available_Margin__c > 0);
    
    //Match the RLI with OLI by comparing RLI.Callidus_Reference__c == oli.Item_Number__c
    //system.assertEquals(rli.get(0).Callidus_Reference__c, oliList.get(1).OpportunityId + '~' + oliList.get(0).Part_Number__c); 
    
    //Asserts to Verify the RLI.Partner_Account__c == opp's Primary Partner Account
    //system.assertEquals(rli.get(0).Partner_Account__c, opr.AccountToId);
    
    //Asserts to Verify RLI.Account__c == opp.AccountId
    system.assertEquals(rli.get(0).Account__c, testOpp.AccountId);
    
    //Assert to Verify RLI.Opportunity_Owner__c == opp.OwnerId
    system.assertEquals(rli.get(0).Opportunity_Owner__c, testOpp.OwnerId);
    
    //Assert to Verify RLI.Month__c == retention.Month__c
    system.assertEquals(rli.get(0).Month__c, retRecord.get(0).Month__c);
    
    //Assert to Verify RLI.Status__c == 'Unpaid'                      
    system.assertEquals(rli.get(0).Status__c, 'Unpaid');
    }
  } 
  

  //================================================================//
  // Scenario 2) Closing of a  Opportunity
  //================================================================//
  public static testmethod void basicCloseNewOppRetentionTest(){
    //create test data
    createTestData(true);
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
    Test_Utils.createOpptyTasks(testOpp.Id, true);
    // start test
    Test.startTest();
    
     // create Opportunity Partner record
    Account accPartner = Test_Utils.insertAccount();
    opr = new Partner();
    opr.OpportunityId = testOpp.Id;
    opr.IsPrimary = true;
    opr.AccountToId = accPartner.Id;
    insert opr;

    //close/won the Opportunity
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.CloseDate = date.today();
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    update testOpp;
     
    // stop test
    Test.stopTest();
     
    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c, Callidus_Reference__c
                                        FROM Retention_Line_Item__c WHERE Opportunity__c = :testOpp.Id];
    System.debug('rliRecord1>>>' +rli);                                    
    //Asserts
    system.assert(rli.size() > 0);
    oliList = [SELECT Id,EDQ_Margin__c,Part_Number__c
               FROM OpportunityLineItem
               WHERE OpportunityId = :testOpp.Id];
    for (Retention_Line_Item__c li: rli) {
      for (OpportunityLineItem oli: oliList ) {
        if (li.Callidus_Reference__c.contains(oli.Part_Number__c)) {
          //Asserts to Verify that the RLI.Actual_Margin__c == oli.EDQ_Margin__c
          system.assertEquals(li.Actual_Margin__c, oli.EDQ_Margin__c); 
          //Asserts to that RLI.Available_Margin__c == oli.EDQ_Margin__c 
          system.assertEquals(li.Available_Margin__c, oli.EDQ_Margin__c);
        }
      }
    }
    //Assert to Verify RLI.Status__c == 'Paid'                      
    system.assertEquals(rli.get(0).Status__c, 'Paid');
    system.assertEquals(rli.get(1).Status__c, 'Paid');
    
  }

  //================================================================//
  // Scenario 3) Closing of a Opportunity
  //================================================================//
  public static testmethod void complexCloseNewOppRetentionTest() { 
    // create test data
    createTestData(true);
    // create Opportunity Partner record
    Account accPartner = Test_Utils.insertAccount();
    opr = new Partner();
    opr.OpportunityId = testOpp.Id;
    opr.IsPrimary = true;
    opr.AccountToId = accPartner.Id;
    insert opr;
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
    Test_Utils.createOpptyTasks(testOpp.Id, true);
    
    Decimal oldEDQMargin = opportunityLineItem1.EDQ_Margin__c; 
    // start test
    Test.startTest();
    // update OLI's EDQ Margin
    //oliList.get(1).EDQ_Margin__c = 400;
    //update oliList; 
    // create new Opportunity Partner record
    Account accPartner1 = Test_Utils.insertAccount();
    Partner opr1 = new Partner();
    opr1.OpportunityId = testOpp.Id;
    opr1.IsPrimary = true;
    opr1.AccountToId = accPartner1.Id;
    insert opr1;

    //close/won the Opportunity
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.CloseDate = date.today();
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    update testOpp;
    // stop test
    Test.stopTest();
    List<Retention__c> retRecord = [SELECT Id, Year__c, Month__c FROM Retention__c 
                                    WHERE Account__c = :testAcc.Id];
    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c
                                        FROM Retention_Line_Item__c WHERE Account__c = :testOpp.AccountId];
    System.debug('rliRecord1>>>' +rli);
    //Asserts
    system.assert(rli.size() > 0); 
    //Asserts to 
    //system.assertEquals(rli.get(0).Actual_Margin__c, opportunityLineItem2.EDQ_Margin__c);
    system.assertEquals(rli.get(0).Status__c, 'Paid');
  }


  //================================================================//
  // Scenario 4) Deleting Opp Line Items (as a result of the Opp Stage not being one to track for)
  //================================================================//
  public static testmethod void deleteRetentionLineItemTest1() {
    
    // create test data
    createTestData(true);
    
    // start test
    Test.startTest();

    
     // create Opportunity Partner record
    Account accPartner = Test_Utils.insertAccount();
    opr = new Partner();
    opr.OpportunityId = testOpp.Id;
    opr.IsPrimary = true;
    opr.AccountToId = accPartner.Id;
    insert opr;
    
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.Type = Constants.ORDER_TYPE_CREDITED ;
    update testOpp;

    // stop test
    Test.stopTest();

    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c
                                        FROM Retention_Line_Item__c 
                                        WHERE Account__c = :testOpp.AccountId];
    //Assert to verify that Retention Line Items are deleted
    system.assertEquals(rli.size(), 0);
  }

  //================================================================//
  // Scenario 5) Opp Line Item being deleted (as part of Renewal Opp being deleted on parent Opp being reopened)
  //================================================================//
  public static testmethod void deleteOrReopenOppTest() {
    // create test data
    User testUser1 = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    
    Account testAcc1 = Test_Utils.insertAccount();
    
    Contact newcontact1  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                               AccountId = testAcc1.Id, Email = 'larrye@email.com');
    insert newcontact1;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc1.ID);
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact1.Id);
    
    Opportunity testOpp1 = Test_Utils.createOpportunity(testAcc1.Id);
    testOpp1.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp1.Type = Constants.OPPTY_NEW_FROM_NEW;
    testOpp1.Contract_Start_Date__c = testDate.addDays(1);
    testOpp1.Contract_End_Date__c = testDate.addYears(1);
    testOpp1.OwnerId = testUser1.Id;
    insert testOpp1;
    System.debug('testOpp>>>' +testOpp);
  
    // Create Opportunity Line Item
    Product2 product = Test_Utils.insertProduct();
    
    Pricebook2 pricebook = Test_Utils.getPriceBook2();
    Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
    
    OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testOpp1.Id, stdPricebookEntry.Id, testOpp1.Type);
    opportunityLineItem.Start_Date__c = testDate.addDays(1);
    opportunityLineItem.End_Date__c = testDate.addYears(1);
    opportunityLineItem.EDQ_Margin__c = 100;
    opportunityLineItem.Item_Number__c = 'Item-1';
    opportunityLineItem.Quote_Number__c = 'Q-100';
    opportunityLineItem.Part_Number__c = 'PN-100';
    insert opportunityLineItem;
    
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp1.Id, newcontact1.Id, Constants.DECIDER, true);
    Test_Utils.createOpptyTasks(testOpp1.Id, true);
    // Start test
    Test.startTest();

    // Update oppty
    testOpp1.StageName = Constants.OPPTY_STAGE_7 ;
    testOpp1.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    testOpp1.Amount = 100;
    testOpp1.Has_Senior_Approval__c = true;
    testOpp1.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp1.CloseDate = date.today();
    update testOpp1;


    // Reopen oppty
    testOpp1.StageName = Constants.OPPTY_STAGE_6;
    testOpp1.Forecast_Category__c = Constants.OPPTY_FORECAST_CATEGORY_FORECAST; 
    update testOpp1;

    // Stop test
    Test.stopTest();

    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c
                                        FROM Retention_Line_Item__c 
                                        WHERE Account__c = :testOpp1.AccountId];
    //Assert to verify that Retention Line Items are deleted
    system.assertEquals(rli.size(), 0);
  } 

  //================================================================//
  // Scenario 6) Scenario when opp is changed to Renewal Opp
  //================================================================//
  public static testmethod void testOppTypeChangedTest() {

    // create test data
    User testUser1 = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    Account testAcc1 = Test_Utils.insertAccount();
    Contact newcontact1  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                               AccountId = testAcc1.Id, Email = 'larrye@email.com');
    insert newcontact1;

    Opportunity testLocalOpp = Test_Utils.createOpportunity(testAcc1.Id);
    testLocalOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testLocalOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
    testLocalOpp.Contract_Start_Date__c = testDate.addDays(1);
    testLocalOpp.Contract_End_Date__c = testDate.addYears(1);
    testLocalOpp.OwnerId = testUser1.Id;
    insert testLocalOpp;
  
    // Create Opportunity Line Item
    Product2 product = Test_Utils.insertProduct();
    Pricebook2 pricebook = Test_Utils.getPriceBook2();
    Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
    
    OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testLocalOpp.Id, stdPricebookEntry.Id, testLocalOpp.Type);
    opportunityLineItem.Start_Date__c = testDate.addDays(1);
    opportunityLineItem.End_Date__c = testDate.addYears(1);
    opportunityLineItem.Quantity = 1;
    opportunityLineItem.EDQ_Margin__c = 100;
    opportunityLineItem.Item_Number__c = 'Item-1';
    opportunityLineItem.Quote_Number__c = 'Q-100';
    opportunityLineItem.Part_Number__c = 'PN-100';
    
    insert opportunityLineItem;

    Test.StartTest();
    System.assertEquals(0, [SELECT count() FROM Retention_Line_Item__c WHERE Account__c =: testAcc1.Id]);

    delete opportunityLineItem;
    
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    OpportunityLineItemTriggerHandler.hasRunRetentionUpdates = false;
    OpportunityTriggerHandler.isRunningOpportunityTrigger = true;
    testLocalOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    update testLocalOpp;
    
    
    opportunityLineItem = Test_Utils.createOpportunityLineItem(testLocalOpp.Id, stdPricebookEntry.Id, testLocalOpp.Type);
    opportunityLineItem.Start_Date__c = testDate.addDays(1);
    opportunityLineItem.End_Date__c = testDate.addYears(1);
    opportunityLineItem.Quantity = 1;
    opportunityLineItem.EDQ_Margin__c = 100;
    opportunityLineItem.Item_Number__c = 'Item-1';
    opportunityLineItem.Quote_Number__c = 'Q-100';
    opportunityLineItem.Part_Number__c = 'PN-100';
    insert opportunityLineItem;

    test.stopTest();
    System.assertEquals(1, [SELECT count() FROM Retention_Line_Item__c WHERE Account__c =: testAcc1.Id]);
  }

  //================================================================//
  // Scenario 7) Scenario when opp is deleted
  //================================================================//
  public static testmethod void deleteOpportunityTest() {
    createTestData(true);
    User testUser2 = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    test.startTest();
    testOpp.stageName = Constants.OPPTY_STAGE_7;
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.CloseDate = date.today();
    update testOpp;

    List<Order_Line_Item__c> orderLine = [SELECT Id, Order__r.Opportunity__c, Order__c, Order_Type__c , Part_Number__c 
                                          FROM Order_Line_Item__c
                                          WHERE Order__r.Opportunity__c = :testOpp.Id];

    delete [SELECT Id FROM Order__c WHERE Opportunity__c = :testOpp.Id];
    delete testOpp;
    System.assertEquals(0, [SELECT count() FROM Retention_Line_Item__c WHERE Account__c =: testAcc.Id]);
    
    test.stopTest();
    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c,Lost_Margin__c
                                        FROM Retention_Line_Item__c WHERE Account__c = :testOpp.AccountId];
    system.assert(rli.size() == 0);

  }

  //================================================================//
  // Scenario 8) Scenario when opp has its owner  updated
  //================================================================//
  public static testmethod void updateOppOwnerIdTest() {
    createTestData(true);
    User testUser2 = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    test.startTest();
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.stageName = Constants.OPPTY_STAGE_7;
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.CloseDate = date.today();
    update testOpp;
    
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.OwnerId = testUser2.Id;
    update testOpp;

    test.stopTest();
    System.assertEquals(testUser2.Id, [SELECT Id, Opportunity_Owner__c FROM Retention_Line_Item__c WHERE Opportunity__c =: testOpp.Id LIMIT 1].Opportunity_Owner__c);

  }
  
  //================================================================//
  // Scenario 9) Scenario when the Opp is closed lost
  //================================================================//
  public static testmethod void oppClosedLostTest() {    
    createTestData(true);
    test.startTest();
    OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
    OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
    testOpp.stageName = Constants.OPPTY_CLOSED_LOST;
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.CloseDate = date.today();
    update testOpp;
    test.stopTest();
    List<Retention_Line_Item__c> rli = [SELECT Id, Actual_Margin__c, Available_Margin__c, Status__c,Lost_Margin__c
                                        FROM Retention_Line_Item__c WHERE Opportunity__c = :testOpp.Id];
    System.assert(rli.size() > 0);
    system.assert(rli[0].Status__c  == Constants.RLI_STATUS_LOST);
    System.assert(rli[0].Lost_Margin__c == rli[0].Available_Margin__c);
  }


  //================================================================//
  // Method for test data
  //================================================================//
  public static void createTestData(Boolean isRenewalOpp){
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    
    testAcc = Test_Utils.insertAccount();
    
    newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                               AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert newcontact;
    Address__c address = Test_Utils.insertAddress(true);
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAcc.ID);

    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    
    testOpp = Test_Utils.createOpportunity(testAcc.Id);
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    if (isRenewalOpp) {
      testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
    } else {
      testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
    }
    testOpp.Contract_Start_Date__c = testDate.addDays(1);
    testOpp.Contract_End_Date__c = testDate.addYears(1);
    testOpp.OwnerId = testUser.Id;
    insert testOpp;
    System.debug('testOpp>>>' +testOpp);
  
    // Create Opportunity Line Item
    Product2 product = Test_Utils.insertProduct();
    
    Pricebook2 pricebook = Test_Utils.getPriceBook2();
    Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
    oliList = new List<OpportunityLineItem>();
    
    //Create 2 product lines with 2 EDQ_Margin__c values, 2 Item_Number__c values, Start_Date__c, 
    //End_Date__c populated and Order_Type__c = "Renewal" Start_Date__c = 2222/02/02 and End_Date__c = 2223/02/01
    opportunityLineItem1 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
    opportunityLineItem1.Start_Date__c = testDate.addDays(1);
    opportunityLineItem1.End_Date__c = testDate.addYears(1);
    opportunityLineItem1.EDQ_Margin__c = 100;
    opportunityLineItem1.Item_Number__c = 'Item-1';
    opportunityLineItem1.Quote_Number__c = 'Q-100';
    opportunityLineItem1.Part_Number__c = 'PN-1';
    oliList.add(opportunityLineItem1);
    System.debug('opportunityLineItem1>>>' +opportunityLineItem1);
    
    opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
    opportunityLineItem2.Start_Date__c = testDate.addDays(1);
    opportunityLineItem2.End_Date__c = testDate.addYears(1);
    opportunityLineItem2.EDQ_Margin__c = 200;
    opportunityLineItem2.Item_Number__c = 'Item-2';
    opportunityLineItem2.Quote_Number__c = 'Q-101';
    opportunityLineItem2.Part_Number__c = 'PN-2';
    oliList.add(opportunityLineItem2);
    System.debug('opportunityLineItem2>>>' +opportunityLineItem2);
    
    //Create 1 product line with EDQ_Margin__c, Item_Number__c, Start_Date__c, End_Date__c populated and Order_Type__c = "Paid Dev Tools"
    opportunityLineItem3 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
    opportunityLineItem3.Start_Date__c = testDate.addDays(1);
    opportunityLineItem3.End_Date__c = testDate.addYears(1);
    opportunityLineItem3.Order_Type__c = Constants.OLI_ORDER_TYPE_PDT;
    opportunityLineItem3.EDQ_Margin__c = 300;
    opportunityLineItem3.Item_Number__c = 'Item-3';
    opportunityLineItem3.Quote_Number__c = 'Q-102';
    opportunityLineItem3.Part_Number__c = 'PN-3';
    //oliList.add(opportunityLineItem3);
    System.debug('opportunityLineItem3>>>' +opportunityLineItem3);
    
    insert oliList;   
    
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true); 
  }
  
  
}