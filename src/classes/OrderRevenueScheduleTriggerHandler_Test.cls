/**=====================================================================
 * Appirio, Inc
 * Name: OrderRevenueScheduleTriggerHandler_Test
 * Description: T-249804: To Test funcitonality of OrderRevenueScheduleTriggerHandler
 * Created Date: Feb 14th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified        Modified By                  Description of the update
 * Feb 26th, 2014       Nathalie Le Guay (Appirio)   Removed references to Selection_confirmed__c and Signed_Contract__c
 *                                                   and Task_Quote_Delivered__c
 * Feb 27th, 2014     Nathalie Le Guay               Added opp.Starting_Stage__c values
 * Mar 04th, 2014     Arpita Bose (Appirio)          T-243282: Added Constants in place of String
 * Mar 14th, 2014     Arpita Bose (Appirio)          T-253906: Fixed error
 * Mar 28th, 2014     Arpita Bose(Appirio)           T-266095: Removing reference to the field
 *                                                   Opportunity.Status__c which is removed
 * Apr 12th, 2014     Arpita Bose                    Updated the method testRecalculateSalesPrice()to fix the failure
 * Apr 15th, 2014     Arpita Bose                    T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014     Arpita Bose                    T-271695: Renamed field Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 30th, 2014     Arpita Bose                    I-113908: Added test method testCurrencyIsoOnOrderRevenue
 * May 21st, 2014     Nathalie Le Guay               Fix test class due to validation rule: Opportunity.Must_be_Stage_3_if_not_a_renewal
 * Jul 31st, 2014     Arpita Bose                    T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Oct 20th, 2014     Arpita Bose                    Updated method testRecalculateSalesPrice() to remove IsDataAdmin__c
 * Nov 12th, 2014     Noopur                         Modified the code to add Type to Opportunity and corresponding Order Type to the OLI
 * Mar 3rd, 2015      Paul Kissick                   Removed SeeAllData, added fix for updating opp
 * Mar 5th, 2015      Paul Kissick                   Case #583351 - Added line to reset isExecuted variable on OpportunityTrigger_OrderHelper class.
 * Mar 17th, 2015     Gaurav Kumar Chadha            Added Account and Contact Address Test Data
 =====================================================================*/
@isTest
private class OrderRevenueScheduleTriggerHandler_Test {
    
    @isTest
  static void testRecalculateSalesPrice () {
    
    // create User
    
    TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings;
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings;
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_ADDRESS_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings; 
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_ADDRESS_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings; 
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.TASK_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings; 
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPORTUNITY_CONTACT_ADDRESS_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings; 
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.USER_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings; 
    IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true); 
    insert ida;
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
    
    Order_Line_Item__c orderLineItem ;
    System.runAs(testUser1) {
    // Create an account
    Account testAccount = Test_Utils.insertAccount();


    // Create an opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Has_Senior_Approval__c = true;
    testOpp.StageName = Constants.OPPTY_STAGE_3;
    //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695
    testOpp.Amount = 100;
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
    testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
    insert testOpp;

    Test_Utils.createOpptyTasks(testOpp.Id, true);

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                        AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;
    // insert Address
    Address__c address = Test_Utils.insertAddress(true);
    // insert Contact Address as it mandatory
    Contact_Address__c contactAddress = Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    // insert Account Registered Address as it mandatory
    Account_Address__c accountAddress =  Test_Utils.insertAccountAddress(true, address.ID, testAccount.ID);
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
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);
    //insert OLI
    //OpportunityLineItem opportunityLineItem2 = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
    OpportunityLineItem opportunityLineItem2 =  new OpportunityLineItem (TotalPrice = 200, UnitPrice = null, Quantity = 1,
                                                   OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(5), Order_Type__c = Constants.STATUS_NEW,
                                                   End_Date__c = Date.today().addDays(10));
    insert opportunityLineItem2;

    //insert OLIS
    OpportunityLineItemSchedule olsi1 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
    olsi1.ScheduleDate = System.today().addDays(5);
    OpportunityLineItemSchedule olsi2 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
    olsi2.ScheduleDate = System.today().addDays(5);
    OpportunityLineItemSchedule olsi3 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
    olsi3.ScheduleDate = System.today().addDays(5);

    List<OpportunityLineItemSchedule> opptySchedules = new List<OpportunityLineItemSchedule>();
    opptySchedules.add(olsi1);
    opptySchedules.add(olsi2);
    opptySchedules.add(olsi3);
    insert opptySchedules;

    Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
    insert comp;
    
    delete ida;
    
    // PK: Case #583351 - Adding this to properly test creating orders.
    OpportunityTrigger_OrderHelper.isExecuted = false;

    Test.startTest();

    testOpp.StageName = Constants.OPPTY_STAGE_7;
    testOpp.Channel_Type__c = 'Direct';
    //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
    testOpp.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_DATA_QUALITY;
    update testOpp;
    Test.stopTest();
      Order__c ordr =  Test_Utils.createOrder();
      ordr.CurrencyIsoCode = Constants.CURRENCY_GBP;
      ordr.Opportunity__c = testOpp.Id;
      ordr.Account__c = testAccount.ID;
      ordr.Transactional_Sale__c = false;
      insert ordr;

      Billing_Product__c billProd = Test_Utils.insertBillingProduct();
      //create Order Line Item
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(true, ordr.Id, billProd.Id);
      //create Order Revenue Schedule
      Order_Revenue_Schedule__c revenue = new Order_Revenue_Schedule__c();
      revenue.CurrencyIsoCode = Constants.CURRENCY_USD;
      revenue.Order_Line_Item__c = ordrli.Id;
      revenue.Revenue__c = 200;
      insert revenue;
    
    List<Order__c> ordList = new List<Order__c>();
    List<Order_Revenue_Schedule__c> orderSchedules = new List<Order_Revenue_Schedule__c>();
    Set<String> orderLineItemIDSet = new Set<String>();
    orderLineItem = new Order_Line_Item__c();
    //Getting Order, Order lines and schedules to test.
    //system.assertEquals('~~~~~~' + [SELECT Opportunity__c, o.Id, (SELECT Id FROM Order_Line_Items__r) FROM Order__c o WHERE Opportunity__c =: testOpp.ID], '~~~~~');
    for (Order__c ord : [SELECT Opportunity__c, o.Id, (SELECT Id FROM Order_Line_Items__r) FROM Order__c o WHERE Opportunity__c =: testOpp.ID]) {
      ordList.add(ord);
      for (Order_Line_Item__c orderLine : ord.Order_Line_Items__r) {
        orderLineItem = orderLine;
        break;
      }
    }
    
    //system.assertEquals('~~~~~~' + [SELECT ID, Revenue__c FROM Order_Revenue_Schedule__c WHERE Order_Line_Item__c =: orderLineItem.ID], '~~~~~');
    Integer totalRevenue = 0;
    for (Order_Revenue_Schedule__c ordRevSchedule : [SELECT ID, Revenue__c FROM Order_Revenue_Schedule__c WHERE Order_Line_Item__c =: orderLineItem.ID]) {
      orderSchedules.add(ordRevSchedule);
    }
    
   
    //Updated schedule revenue by 200 (100+100) so Order Line should have 400 total
    orderSchedules.get(0).Revenue__c += 200;
    update orderSchedules;
    
    
    //System.assertEquals('===>'+[SELECT Total__c, ID, Recalculate_Sales_Price__c FROM Order_Line_Item__c WHERE ID =: orderLineItem.ID].Total__c, '200');
    orderLineItem = [SELECT Total__c, ID, Recalculate_Sales_Price__c FROM Order_Line_Item__c WHERE ID =: orderLineItem.ID];
    //Assert to check Recalculate_Sales_Price__c updated and Total__c.
    //OrderRevenueScheduleTriggerHandler marks Recalculate_Sales_Price field to true,
    //but in OrderLineItemTriggerHandler.updateOLITotal sets it false back, so we are
    //putting assert for false. nojha appirio (feb 14th, 2014)
    System.AssertEquals(orderLineItem.Recalculate_Sales_Price__c, false);
    System.AssertEquals(Integer.valueOf(orderLineItem.Total__c), 400);
    // Test.startTest();
    delete orderSchedules.get(0);
   // Test.stopTest();
    }
    orderLineItem = [SELECT Total__c, ID, Recalculate_Sales_Price__c FROM Order_Line_Item__c WHERE ID =: orderLineItem.ID];
    System.AssertEquals(Integer.valueOf(orderLineItem.Total__c), 0.0);
  }

  public static testmethod void  testCurrencyIsoOnOrderRevenue(){
  	  TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings;
     
     insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings;
      //create Account
      Account acc = Test_Utils.insertAccount();
      //create Opportunity
      Opportunity opp1 = Test_Utils.createOpportunity(acc.Id);
      insert opp1;
      //create Order
      Order__c ordr =  Test_Utils.createOrder();
      ordr.CurrencyIsoCode = Constants.CURRENCY_GBP;
      ordr.Opportunity__c = opp1.Id;
      ordr.Account__c = acc.ID;
      ordr.Transactional_Sale__c = false;
      insert ordr;

      Billing_Product__c billProd = Test_Utils.insertBillingProduct();
      Test.startTest();
      //create Order Line Item
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(true, ordr.Id, billProd.Id);
      //create Order Revenue Schedule
      Order_Revenue_Schedule__c revenue = new Order_Revenue_Schedule__c();
      revenue.CurrencyIsoCode = Constants.CURRENCY_USD;
      revenue.Order_Line_Item__c = ordrli.Id;
      revenue.Revenue__c = 200;
      insert revenue;

      Order_Revenue_Schedule__c ordrRevenue = [SELECT Id, CurrencyIsoCode From Order_Revenue_Schedule__c WHERE Order_Line_Item__c =: ordrli.ID];

      Test.stopTest();
      system.assertEquals(ordrRevenue.CurrencyIsoCode, Constants.CURRENCY_GBP);

    }

}