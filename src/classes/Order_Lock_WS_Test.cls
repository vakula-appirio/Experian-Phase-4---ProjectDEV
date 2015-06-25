/**=====================================================================
 * Appirio, Inc
 * Name: Order_Lock_WS_Test
 * Description: T-249803: To Test funcitonality of Order_Lock_WS webservice
 * Created Date: Feb 14th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 26th, 2014       Nathalie Le Guay (Appirio)   Removed references to Selection_confirmed__c and Signed_Contract__c
 *                                                   and Task_Quote_Delivered__c
 * Feb 27th, 2014     Nathalie Le Guay               Added opp.Starting_Stage__c values
 * Mar 04th, 2014     Arpita Bose (Appirio)          T-243282: Added Constants in place of String
 * Mar 14th, 2014     Arpita Bose(Appirio)           T-253906: Fixed error
 * Mar 28th, 2014     Arpita Bose(Appirio)           T-266095: Removing reference to the field 
 *                                                   Opportunity.Status__c which is removed
 * Apr 11th, 2014     Arpita Bose                    Updated method testUpdateOLITotal()to fix the failure
 * Apr 15th, 2014     Arpita Bose                    T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014     Arpita Bose                    T-271695: Renamed field Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Jul 31st, 2014     Arpita Bose                    T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Oct 21st, 2014     Arpita Bose                    Updated to remove IsDataAdmin__c
 * Nov 12th, 2014     Noopur                         Updated to add Type to Opportunity and corresponding Order Type to OLI
 * Mar 5th, 2015      Paul Kissick                   Case #583351 - Added line to reset isExecuted variable on OpportunityTrigger_OrderHelper class, and removed SeeAllData
 * Mar 17th,2015      Gaurav Kumar Chadha            Added Test Data Account and Contact Address
 * Apr 29, 2015       Suminder Singh                 Fixed test class for Failures
 =====================================================================*/
@isTest
public with sharing class Order_Lock_WS_Test {
  @isTest
  static void testUpdateOLITotal () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
  
    System.runAs(testUser1) {
      // Create an account    
      Account testAccount = Test_Utils.insertAccount();
            
      
      // Create an opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
      testOpp.Has_Senior_Approval__c = true;
      testOpp.StageName = Constants.OPPTY_STAGE_3;
      //testOpp.Below_Review_Thresholds__c = 'Yes';
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      testOpp.Amount = 100;
      testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
      testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
      insert testOpp;
      
      
      Test_Utils.createOpptyTasks(testOpp.Id, true);
  
      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                          AccountId = testAccount.Id, Email = 'larrye@email.com');
      insert newcontact;
      
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
      Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct();
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //insert OLI
      //OpportunityLineItem opportunityLineItem2 = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
      OpportunityLineItem opportunityLineItem2 =  new OpportunityLineItem (TotalPrice = 200, UnitPrice = null, Quantity = 1,
                                                     OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                     Start_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(10),
                                                     Order_Type__c = Constants.STATUS_NEW);
      insert opportunityLineItem2;
  
      Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
      insert comp;
      
      // PK: Case #583351 - Adding this to properly test creating orders.
      OpportunityTrigger_OrderHelper.isExecuted = false;
      Test.startTest(); 
      OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
      OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      testOpp.Channel_Type__c = 'Direct';
      //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
      testOpp.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_DATA_QUALITY;
      //system.assertEquals(null, testOpp);
      update testOpp;
      
      Order__c orderRecord = [SELECT ID FROM Order__c WHERE Opportunity__c =: testOpp.ID LIMIT 1];
      
      System.assertNotEquals(orderRecord.ID, null);
      
      //Calling webservice
      Order_Lock_WS.lockOrder(orderRecord.ID);
      orderRecord = [SELECT ID, RecordType.Name FROM Order__c WHERE Opportunity__c =: testOpp.ID LIMIT 1];
      Order_Line_Item__c orderLine = [SELECT ID, RecordType.Name FROM Order_Line_Item__c WHERE Order__c =: orderRecord.ID LIMIT 1];
            
      System.assertEquals(orderRecord.RecordType.Name, Constants.READ_ONLY);
      System.assertEquals(orderLine.RecordType.Name, Constants.READ_ONLY);
    }
  }
}