/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTriggerHandler_Test
 * Description: Test various functionality of OpportunityTriggerHandler.cls and
 *                          OpportunityTriggerHelper.cls
 * Created Date: 10/30/2013
 * Created By    : Pankaj Mehra (Appirio)
 *
 * Date Modified      Modified By                  Description of the update
 * Feb 06th, 2014     Naresh Kr Ojha (Appirio)     Merged old class TestOpportunityTriggerHanlder.cls
 *                                                 and created test method for T-243865
 * Feb 27th, 2014     Nathalie Le Guay (Appirio)   Added opp.Starting_Stage__c values
 * Feb 28th, 2014     Naresh kr Ojha (Appirio)     T-252684: created methods to cover positive and negative senarios for
 *                                                 test access to create opportunities
 * Feb 28th, 2014     Nathalie Le Guay             Adding use of strings from Constants.cls
 * Mar 04th, 2014     Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 05th, 2014     Arpita Bose (Appirio)        Fixed error.
 * Mar 14th, 2014     Arpita Bose (Appirio)        T-253906: Fixed error
 * Mar 19th, 2014     Arpita Bose (Appirio)        T-260619: Added testmethod for testing createOrders method
 * Mar 20th, 2014     Megha Agarwal (Appirio JDC)  T-253868: Added testmethod for testing Validation on Service Dates method
 * Mar 21th, 2014     Jinesh Goyal (Appirio)       T-253906: updated method opptyReopenOrderCreationTest, testOpportunitiesExitCriteriaNotMet
 * Mar 24th, 2014     Naresh Kr Ojha(Appirio)      T-264560: Added to test oppty closing behaviour updated opptyReopenOrderCreationTest ()
 *                                                 T-264492: added method testStageDurationOnOppty()
 * Mar 28th, 2014     Arpita Bose(Appirio)         T-266095: Removing reference to the field
 *                                                 Opportunity.Status__c which is removed
 * Apr 01st, 2014     Arpita Bose(Appirio)         T-268401: Removed reference to Opp's Service Start/End dates and method testUpdateServiceDatesOnOLI
 *                                                 is commented
 * Apr 01st, 2014     Arpita Bose(Appirio)         T-265681: Added method testMultiCurrencyFieldUpdate()to test Multi-currency dashboard
 * Apr 02nd, 2014     Arpita Bose(Appirio)         T-268405: Renamed OLI's Service Start/end dates to Start/End dates
 * Apr 02nd, 2014     Arpita Bose                  T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 07th, 2014     Nathalie Le Guay             Update to Order LI.Renewable__c as it becomes a picklist
 * Apr 07th, 2014     Mohit Parnami                T-267436: Added testUpdateOppFieldsIfWonOrClosed() to test opp field stamping from Owner's fields
 * Apr 08th, 2014     Nathalie Le Guay             Order LI.Renewable__c renamed to Type__c
 * Apr 10th, 2014     Arpita Bose(Appirio)         T-270419: opportunity.Contract_Term__c is commented as the field type is changed
 * Apr 12th, 2014     Arpita Bose                  Updated methods createOrderAndOrderLineItemTest() and opptyReopenOrderCreationTest()to fix failure
 * Apr 15th, 2014     Arpita Bose                  T-271695:Removed reference to Below_Review_Thresholds__c
 * Apr 16th, 2014     Arpita Bose                  T-271695: Renamed fields Has_Stage_4_Approval__c to Has_Stage_3_Approval__c
 *                                                  and Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 21st, 2014     Arpita Bose                  Updated method testOpportunitiesExitCriteriaNotMet()to increase the code coverage
 * Apr 22nd, 2014     Aditi Bhardwaj               Added testCreateOppContactRoles method to evaluate functionality of CreateOppContactRoles method
 * Apr 24, 2014       Nathalie Le Guay             Commenting TestReAlignBUsOnOwnerChange() as it test BU Relationship
 * May 05th, 2014     Bharti Mehta(Appirio JDC)    T-273787: Experian Sales -  added method testOppToOpportunityPlansSync
 * May 07th, 2014     Rahul Jain                   T-275529 : Experian Sales - added methods testUpdateAccountPlanOpportunities, testCreateAccountPlanOpportunities
 * May 21st, 2014     Nathalie Le Guay             Fix test class due to validation rule: Opportunity.Must_be_Stage_3_if_not_a_renewal
 * Jul 31st, 2014     Arpita Bose                  T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Aug 18th, 2014     Arpita Bose                  T-313163: Updated method createOrderAndOrderLineItemTest() for CPQ_Quantity__c and updated methods
 *                                                 testUpdateOppFieldsIfWonOrClosed() and opptyReopenOrderCreationTest() to fix the failure
 * Sep 04th, 2014     Naresh Kr Ojha               T-317502: create test method to test moveTaskToOpptyWhenCreatedFromContact ()
 * Sep 08th, 2014     Naresh Kr Ojha               T-317883: Updated method createOrderAndOrderLineItemTest for the functionality implemented in task.
 * Sep 10, 2014       Nathalie Le Guay             I-130073 - Commenting testCreateOppContactRoles() as this is done by the 'conId' parameter
 * Sep 11, 2014       Nathalie Le Guay             T-317502 Cancelled - Removing testMoveTaskToOpptyWhenCreatedFromContact()
 * Sep 15th, 2014     Arpita Bose                  Added method testOnDemandOpportunityLineItem()
 * Sep 15th, 2014     Naresh Kr Ojha               Label.OPPTY_ERR_ONDEMAND_PRODUCT
 * Sep 16th, 2014     Arpita Bose                  I-130655: Reference of On_Demand_Product__c has been changed to EDQ_On_Demand_Product__c on OpportunityLineItem
 * Sep 17th, 2014     Arpita Bose                  T-319512: added method testCheckOpptyContactRoleOnClosedWon()
 * Sep 18th, 2014     Arpita Bose                  T-320132: added method test_checkOpptyChannelTypeOnClosedWon()
 * Sep 19th, 2014     Arpita Bose                  T-320157: Added method test_populateInvoiceToEndUser_EDQ1()
 * Sep 23rd, 2014     Arpita Bose                  T-321347: Added method testCreateOppContactRoles_RenewalOpps()
 * Sep 24th, 2014     Arpita Bose                  Added method test_populateInvoiceToEndUser_EDQ2() and test_populateInvoiceToEndUser_EDQ3()
 * Sep 25th, 2014     Arpita Bose                  Removed the use of IsDataAdmin__c from the class and added method test_createOppTeamMembers()
 * Sep 26th, 2014     Arpita Bose                  T-322920: Updated method testCheckOpptyContactRoleOnClosedWon() for Role='Purchase Ledger'
 * Sep 29th, 2014     Arpita Bose                  T-322814: Added method test_validateOpptyContactRoleOnClosedWon1() and test_validateOpptyContactRoleOnClosedWon2()
 * Oct 20th, 2014     Pallavi                      T-326540: Refactoring: Improve Opp Trigger ( Fix failure)
 * Oct 10, 2014       James Weatherall             Case #8991 Uncommented testMethod testOppToOpportunityPlansSync in order to test update Opp Plan method
 * Oct 27th,2014      Pallavi Sharma(Appirio)      Fix Failure
 * Nov 12th, 2014     Arpita Bose                  Added Type in test data of Opportunity and OLI
 * Feb 24th, 2015     Gaurav Kumar Chadha          T-364931 Added opportunityContactRolesAddressTest() method
 * Feb 25th, 2015     Arpita Bose                  T-364941: Added opportunityAccountAddressTest() method
 * Feb 27th, 2015     Paul Kissick                 Removed SeeAllData, replacing with Test.getStandardPriceBookId(), API to v31.0
 * Mar 03rd, 2015     Arpita Bose                  T-364941: Removed method opportunityAccountAddressTest()
 * Mar 5th, 2015      Paul Kissick                 Case #583351 - Added line to reset isExecuted variable on OpportunityTrigger_OrderHelper class.
 * Mar 20th, 2015     Noopur                       T-371756: Modified opptyReopenOrderCreationTest(), opportunityContactRolesAddressTestForNONFreeTrial() and
 *                                                 opportunityContactRolesAddressTestForFreeTrial()
 * Mar 26th, 2015     Naresh                       T-373692: added method testpopulateSalesTeamChannelAndRegion() to test functionality.
 * Mar 30th, 2015     Gaurav Kumar Chadha          Commented methods test_populateInvoiceToEndUser_EDQ2() , test_populateInvoiceToEndUser_EDQ1() and  createOrderAndOrderLineItemTest() 
 * Apr 14th, 2015     Rohit B. (Appirio)           4 Methods were failing, so fix 3 of them (opportunityContactRolesAddressTestForNONFreeTrial, testOnDemandOpportunityLineItem, testOpptyAccWithSaasContact, testSyncOppDates)
 * Apr 29th, 2015     Arpita Bose                  Commented method testUpdateAccountPlanOpportunities() and testCreateAccountPlanOpportunities() as the main method realted to this is not found and duplicate method 
 *                                                 to test this functionality exists on AccountPlanTriggerHandler_Test and Account_Plan_OpportunTriggerHandler_Test class
 =====================================================================*/
@isTest
public with sharing class OpportunityTriggerHandler_Test {

  public static final String MANAGER_USER = Constants.ROLE_GLOBAL_ADMIN;
  public static final String SALES_EXEC_USER = Constants.ROLE_SALES_EXEC_RETAIL_PROPERTY;
  private static Opportunity opp;
  private static List<OpportunityLineItem> olis;
  private static PricebookEntry stdPricebookEntryObj;
 /*   @isTest
    static void testPopulateStartingStage(){
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        List<Opportunity> listOpp = new List<Opportunity>();
        listOpp.add(Test_utils.createOpportunity(testAccount.Id));
        listOpp[0].Starting_Stage__c ='';
        listOpp[0].Amount = 100;
        insert listOpp;
        //start test
        Test.startTest();
        Map<Id,Opportunity> mapOpp=new Map<Id,Opportunity>();
        for (Opportunity oppty : listOpp) {
          mapOpp.put (oppty.Id, oppty);
        }
        OpportunityTrigger_DatesUtility.populateStartingStage(listOpp, mapOpp);
        //stop test
        Test.stopTest();
        String StartingStage = listOpp[0].Starting_Stage__c;
        system.assert(StartingStage !=null);
    } */



    @isTest
    static void opportunityContactRolesAddressTestForNONFreeTrial(){
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      Account testAccount = Test_Utils.insertAccount();

        Contact newcontact  = Test_Utils.insertContact(testAccount.id);

        Address__c address = Test_Utils.insertAddress(true);
        
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, address.Id, testAccount.Id);

        Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);

        Contact newcontact2  = Test_Utils.insertContact(testAccount.id);

        Test_Utils.insertContactAddress(true, address.Id, newcontact2.Id);

        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

        OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
        OpportunityContactRole oppContactRole2 = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact2.Id, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);

        Product2 product = Test_Utils.insertProduct();
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);

        //insert OLI
        OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem1.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem1.End_Date__c = System.today().addDays(10);
        insert opportunityLineItem1;
        
        Test.startTest();

      System.runAs(testUser1) {

        
        //update the Standard Opp
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        testOpp.Amount = 100;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);

        try {
          update testOpp;
        } catch (DmlException e) {
            //Assert Error Message
            System.assert(e.getMessage().contains(label.OPPTY_ERR_MISSING_CONTACT_ADDRESS));
        }

        
      }
      Test.stopTest();
    }
    
    
    @isTest
    static void opportunityContactRolesAddressTestForFreeTrial() {
      
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_TRIGGER);
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPTY_LINE_ITEM_TRIGGER);
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      insertTriggerSettings = Test_Utils.insertTriggerSettings('OrderTrigger');
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      
      
        
        Account testAccount = Test_Utils.insertAccount();

        Contact newcontact  = Test_Utils.insertContact(testAccount.id);
 
        Address__c address = Test_Utils.insertAddress(true);
        
        Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);

        Contact newcontact2  = Test_Utils.insertContact(testAccount.id);
        System.runAs(testUser1) {
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

        List<OpportunityContactRole> OCR = new List<OpportunityContactRole>();
        OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
        OpportunityContactRole oppContactRole2 = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, newcontact2.Id, Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, false);
        
        OCR.add(oppContactRole);
        OCR.add(oppContactRole2);
        insert OCR;
        
        Product2 product = Test_Utils.insertProduct();
        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);

        //insert OLI
        OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem1.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem1.End_Date__c = System.today().addDays(10);
        insert opportunityLineItem1;
      
      Test.startTest();
      
        
       
        
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        testOpp.Amount = 100;
        testOpp.Has_Senior_Approval__c = true; 
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Type = Constants.OPPTY_TYPE_FREE_TRIAL ; 
        
        update testOpp;
  
          system.assert(Constants.OPPTY_STAGE_7 == testOpp.StageName);
      
      Test.stopTest();
     }
    }
    /* commenting as orders are not being created in OpportunityTriggerHandler : GChadha 30/3/2015

    @isTest
    static void createOrderAndOrderLineItemTest() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {
        // Create an account
        Account testAccount = Test_Utils.insertAccount();
        
        Address__c addrs1 = Test_Utils.insertAddress(true);
      
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);

        //Test.startTest();

        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Type = 'New From New';
        //testOpp.RecordTypeId = oppRecordTypeId;
        insert testOpp;
        Test_Utils.createOpptyTasks(testOpp.Id, true);

        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;
        
        Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).id,newcontact.Id);
        
        OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(false, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
        oppContactRole.IsPrimary = true;
        insert oppContactRole;
        
        system.debug('oppContactRole>>>' +oppContactRole);                

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
        OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem2.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem2.End_Date__c = System.today().addDays(10);
        opportunityLineItem2.CPQ_Quantity__c = 1000;
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
         insert opptySchedules; // commenting to remove 101 soql error

        Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
        insert comp;

        // PK: Case #583351 - Adding this to properly test creating orders.
        OpportunityTrigger_OrderHelper.isExecuted = false;

        Test.startTest();
        
        Test_Utils.createOpptyTasks(testOpp.Id, true);
        List<OpportunityContactRole> oppconrole = [SELECT Id, Role, ContactId, Contact.Name, OpportunityId, IsPrimary
                                                   FROM OpportunityContactRole
                                                   WHERE OpportunityId =:testOpp.Id
                                                   AND ContactId != null ];
                                                   
        System.debug('===oppconrole=>'+oppconrole);
        
        
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
        testOpp.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
        testOpp.Amount = 100;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        update testOpp;

        Test.stopTest();
        
        List<Order__c> ordList = new List<Order__c>();
        List<Order_Revenue_Schedule__c> orderSchedules = new List<Order_Revenue_Schedule__c>();
        Set<String> orderLineItemIDSet = new Set<String>();

        //Getting Order, Order lines and schedules to test.
        for (Order__c ord : [SELECT Opportunity__c, o.Id, (SELECT Id, CPQ_Quantity__c FROM Order_Line_Items__r) FROM Order__c o WHERE Opportunity__c =: testOpp.ID]) {
            ordList.add(ord);
            for (Order_Line_Item__c orderLine : ord.Order_Line_Items__r) {
                orderLineItemIDSet.add(orderLine.ID);
            }
        }

        for (Order_Revenue_Schedule__c ordRevSchedule : [SELECT ID, Revenue__c FROM Order_Revenue_Schedule__c WHERE Order_Line_Item__c IN: orderLineItemIDSet]) {
            orderSchedules.add(ordRevSchedule);
        }
        List<Order_Line_Item__c> ordli = [SELECT Id, CPQ_Quantity__c, EDQ_Margin__c, Renewal_EDQ_Margin__c FROM Order_Line_Item__c WHERE Order__c IN :ordList];

        //Asserts
        System.assertEquals(1, ordList.size());
        System.assertEquals(1, ordList.get(0).Order_Line_Items__r.size());
        System.assert(orderSchedules.size() > 0);
        // T-313163: Asserts to verify CPQ_Quantity__c
        System.assertEquals(ordli.get(0).CPQ_Quantity__c, opportunityLineItem2.CPQ_Quantity__c);
        // T-317883: Assert to verify EDQ_Margin__c and Renewql_EDQ_Margin__c
        System.assertEquals(ordli.get(0).EDQ_Margin__c, opportunityLineItem2.EDQ_Margin__c);
        System.assertEquals(ordli.get(0).Renewal_EDQ_Margin__c, opportunityLineItem2.Renewal_EDQ_Margin__c);
      }
    }
   */
   
   @isTest
    static void testCreateOrders(){
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        //create account
        Account testAccount = Test_Utils.insertAccount();
        Test.startTest();
        // Create opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        //testOpp.Start_Date__c = date.today().addDays(2); //T-268400: Removed reference to Opp's Service Start/End Dates
        //testOpp.End_Date__c = date.today().addDays(10);
        testOpp.Amount = 100;
        insert testOpp;
        //create Contact
        Contact testcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert testcontact;

        //Order__c testOrder = OpportunityTrigger_OrderHelper.createOrder(testOpp, testcontact.Id);

        Test.stopTest();
        //system.debug('@@@@@@@Service start date'+testOrder.Service_Start_Date__c);
        //system.debug('#######Service end date'+ testOrder.Service_End_Date__c);
        // T-268400: Removed reference to Opp's service Start/End dates
        //system.assert(testOrder.Service_Start_Date__c <> null);
        //system.assert(testOrder.Service_End_Date__c <> null);
        //system.assertEquals(testOpp.Service_Start_Date__c, testOrder.Service_Start_Date__c);
        //system.assertEquals(testOpp.Service_End_Date__c, testOrder.Service_End_Date__c);
      }

    }
   
    @isTest
    static void testCheckAccessOnAccountFor_TeamMember(){
      //Creating admin user
      User sysAdmin = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert sysAdmin;
      User salesExecUser;
      System.runAs(sysAdmin) {
        //create user
        salesExecUser = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
        insert salesExecUser;
      }

      //create account
      Account testAcc = Test_Utils.insertAccount();
      
      Address__c addrs1 = Test_Utils.insertAddress(true);
        //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAcc.Id);
        

      AccountTeamMember atm = new AccountTeamMember();
      atm.AccountId = testAcc.Id ;
      atm.UserId = salesExecUser.ID;
      //atm.AccountAccessLevel = 'Edit';
      atm.TeamMemberRole = Constants.TEAM_ROLE_SALES_REP;
      insert atm;

      AccountShare newAccountShare = new AccountShare();
      newAccountShare.AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT;
      newAccountShare.AccountId = testAcc.ID;
      newAccountShare.OpportunityAccessLevel = Constants.ACCESS_LEVEL_EDIT;
      newAccountShare.UserOrGroupId = salesExecUser.ID;
      insert newAccountShare;

      //start test
      Test.startTest();

      System.runAs(salesExecUser) {
        List<Opportunity> testOpp = new List<Opportunity>();
        testOpp.add(Test_Utils.createOpportunity(testAcc.Id));
        testOpp.get(0).Amount = 100;
        insert testOpp;
      }

      Test.stopTest();

      //Assert to check opportunity has been created
      System.assertNotEquals([SELECT ID, AccountId FROM Opportunity WHERE AccountId =: testAcc.Id].ID, null);

    }


    @isTest
    static void testCheckAccessOnAccountFor_ManagerOfTeam() {

      //create set userRoleNameSet
      Set<String> userRoleNameSet = new Set<String>{SALES_EXEC_USER, MANAGER_USER};
      Map<String, UserRole> userRoleMap = new Map<String, UserRole>();

      for(UserRole role : [Select ID, Name from UserRole where UserRole.Name IN: userRoleNameSet]){
        userRoleMap.put(role.Name, role);
      }

      Map<String, User> userMap = new Map<String, User>();
      User sysAdmin = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert sysAdmin;

      System.runAs(sysAdmin) {
        //create user

        User salesExecUser = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
        salesExecUser.UserRoleId = userRoleMap.get(SALES_EXEC_USER).ID;
        userMap.put(SALES_EXEC_USER, salesExecUser);

        User managerUser = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
        managerUser.UserRoleId = userRoleMap.get(MANAGER_USER).ID;
        userMap.put(MANAGER_USER, managerUser);
        insert userMap.values();
      }

      //create account
      Account testAcc = Test_Utils.insertAccount();
        
      Address__c addrs1 = Test_Utils.insertAddress(true);
        //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAcc.Id);
       
      AccountTeamMember atm = new AccountTeamMember();
      atm.AccountId = testAcc.Id ;
      atm.UserId = userMap.get(SALES_EXEC_USER).ID;
      //atm.AccountAccessLevel = 'Edit';
      atm.TeamMemberRole = Constants.TEAM_ROLE_SALES_REP;
      insert atm;

      AccountShare newAccountShare = new AccountShare();
      newAccountShare.AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT;
      newAccountShare.AccountId = testAcc.ID;
      newAccountShare.OpportunityAccessLevel = Constants.ACCESS_LEVEL_EDIT;
      newAccountShare.UserOrGroupId = userMap.get(SALES_EXEC_USER).ID;
      insert newAccountShare;

      //start test
      Test.startTest();

      System.runAs(userMap.get(MANAGER_USER)) {
        List<Opportunity> testOpp = new List<Opportunity>();
        testOpp.add(Test_Utils.createOpportunity(testAcc.Id));
        testOpp.get(0).Amount = 100;
        insert testOpp;
      }

      Test.stopTest();

      //Assert to check opportunity has been created
      System.assertNotEquals([SELECT ID, AccountId FROM Opportunity WHERE AccountId =: testAcc.Id].ID, null);
    }

    @isTest
    static void testCheckAccessOnAccountFor_UserOnContact(){
      //Creating admin user
      User sysAdmin = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert sysAdmin;
      User userOnContact;
      System.runAs(sysAdmin) {
        //create user
        userOnContact = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
        insert userOnContact;
      }

      //create account
      Account testAcc = Test_Utils.insertAccount();
      Contact testContact = Test_Utils.insertContact(testAcc.ID);
      Contact_Team__c contTeam = new Contact_Team__c();
      contTeam.Contact__c = testContact.ID;
      contTeam.Primary_User__c = true;
      contTeam.Relationship_Owner__c = userOnContact.ID;
      insert contTeam;

      //start test
      Test.startTest();

      System.runAs(userOnContact) {
        try {
          List<Opportunity> testOpp = new List<Opportunity>();
          testOpp.add(Test_Utils.createOpportunity(testAcc.Id));
          testOpp.get(0).Amount = 100;
          insert testOpp;
        } catch (Dmlexception ex) {
          System.assertNotEquals (String.valueOf(ex.getMessage()).contains('You do not have the necessary access'), true);
        }
      }

      Test.stopTest();

      List<Opportunity> opptyList = [SELECT ID, AccountId FROM Opportunity WHERE AccountId =: testAcc.Id];
      //Assert to check opportunity has been created
      System.assertEquals(opptyList.size() > 0, false);

    }


    @isTest
    static void testValidateServiceDates() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

       createTestData();

       List<OpportunityLineItem> resultOLIs = [select id , Start_Date__c from OpportunityLineItem where opportunityId = : opp.id and Start_Date__c != null];

       //System.assert(resultOLIs.size() > 0);

       //validate for Service Start Date
       opp.Contract_Start_Date__c = Date.today().addDays(1);
       try{
         update opp;
       }catch(Exception ex){
          System.assert(ex.getMessage().contains(System.Label.Service_Start_Date_Error_Msg));
       }

       opp.Contract_Start_Date__c = null;
       opp.Contract_End_Date__c = Date.today().addDays(10);
       try{
         update opp;
       }catch(Exception ex){
          System.assert(ex.getMessage().contains(System.Label.Service_End_Date_Error_Msg));
       }
      }
    }
  //T-268401: Removed reference to Opp's Service start/end dates, this method is commented on class
  /*  @isTest(seealldata=true)
    static void testUpdateServiceDatesOnOLI() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        // Create an account
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        opp = Test_Utils.createOpportunity(testAccount.Id);
        opp.Has_Senior_Approval__c = true;
        opp.StageName = Constants.OPPTY_STAGE_6; // Changed to Stage 6 as Validation prevents OLI's being created on Closed Opps
        //opp.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c
        opp.Amount = 500;
        opp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        insert opp;

        IsDataAdmin__c dataAdmin = new IsDataAdmin__c();
        dataAdmin.SetupOwnerId = UserInfo.getUserId();
        dataAdmin.IsDataAdmin__c = true;
        insert dataAdmin;
        system.debug('++++++++++before '+opp);

        system.debug('++++++++++after '+opp.Id);
        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;

          //////////////////////
        // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
        product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;
        product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;
        product.NumberOfRevenueInstallments = 2;
        //product.CanUseQuantitySchedule = false;
        product.CanUseRevenueSchedule = true;

        update product;
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);

        //dataAdmin.IsDataAdmin__c = false;
        //update dataAdmin;

        //insert OLI
        olis = new List<OpportunityLineItem>();
        olis.add(Test_Utils.createOpportunityLineItem(opp.Id, stdPricebookEntryObj.Id));
        olis.add(Test_Utils.createOpportunityLineItem(opp.Id, stdPricebookEntryObj.Id));
        for(OpportunityLineItem oli : olis){
          oli.Start_Date__c = System.today();
          oli.End_Date__c = System.today().addDays(10);
        }
        insert olis;

        opp.StageName = Constants.OPPTY_STAGE_6;
        update opp;

         //List<Opportunity> resultOLIs = [select id , Service_Start_Date__c, Service_End_Date__c from Opportunity where ID = : opp.id];

         //System.assertEquals(resultOLIs.get(0).Service_Start_Date__c , resultOLIs.get(0).Service_Start_Date__c);
         //System.assertEquals(resultOLIs.get(0).Service_End_Date__c , resultOLIs.get(0).Service_End_Date__c);
      }
    } */

    private static void createTestData(){
      // Create an account
      Account testAccount = Test_Utils.insertAccount();
        
      Address__c addrs1 = Test_Utils.insertAddress(true);
      
        //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);
        
      // Create an opportunity
      opp = Test_Utils.createOpportunity(testAccount.Id);
      opp.Has_Senior_Approval__c = true;
      //opp.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c
      opp.Amount = 500;
      opp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
      opp.Type = 'New From New';
      insert opp;

      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                          AccountId = testAccount.Id, Email = 'larrye@email.com');
      insert newcontact;

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
      stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //insert OLI
      olis = new List<OpportunityLineItem>();
      olis.add(Test_Utils.createOpportunityLineItem(opp.Id, stdPricebookEntryObj.Id, opp.Type));
      olis.add(Test_Utils.createOpportunityLineItem(opp.Id, stdPricebookEntryObj.Id, opp.Type));
      olis.get(0).Start_Date__c = Date.today().addDays(-10);
      olis.get(0).End_Date__c = Date.today().addDays(10);
      olis.get(1).Start_Date__c = Date.today().addDays(-10);
      olis.get(1).End_Date__c = Date.today().addDays(10);
      insert olis;

    }
    
    // commenting as orders are not being created in OpportunityTriggerhandler : GChadha 30/3/2015 
    /*
    //T-264560: Added to test oppty closing behaviour
    static testMethod void opptyReopenOrderCreationTest () {
      
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.CONTACT_TRIGGER);
      insertTriggerSettings.IsActive__c = false;
      update insertTriggerSettings;
      
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      
      System.runAs(testUser1) {
        // Create an account
        Account testAccount = Test_Utils.insertAccount();
        
        Address__c addrs1 = Test_Utils.insertAddress(true);
      
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);
        

        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.StageName = Constants.OPPTY_STAGE_3;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
        //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Amount = 100;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        testOpp.Type = 'New From New';
        insert testOpp;

        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;

        Task t = Test_Utils.createTask(newContact.Id, testOpp.Id);
        t.Type = Constants.ACTIVITY_TYPE_SIGNED_CONTRACT;
        t.Status = Constants.STATUS_COMPLETED;
        t.Outcomes__c = 'Received signed contract';
        insert t;

        OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);

        Test_Utils.insertContactAddress(true,Test_Utils.insertAddress(true).id,newcontact.Id);

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
        OpportunityLineItem opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
        opportunityLineItem2.Start_Date__c = Date.today().addDays(5);
        opportunityLineItem2.End_Date__c = System.today().addDays(10);
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
        // insert opptySchedules;

        Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
        insert comp;



        List<Order__c> ordList = new List<Order__c>();
        Set<String> orderLineItemIDSet = new Set<String>();
        List<Order_Line_Item__c> orderLineItem = new List<Order_Line_Item__c>();

        // PK: Adding this to properly test creating orders.
        OpportunityTrigger_OrderHelper.isExecuted = false;
        Test.startTest();

        testOpp.StageName = Constants.OPPTY_STAGE_7;
        //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
        testOpp.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
        update testOpp;

        //Getting Order, Order lines and schedules to test.
        for (Order__c ord : [SELECT Opportunity__c, o.Id, (SELECT Id FROM Order_Line_Items__r)
                             FROM Order__c o WHERE Opportunity__c =: testOpp.ID]) {
          ordList.add(ord);
          for (Order_Line_Item__c orderLine : ord.Order_Line_Items__r) {
              orderLineItemIDSet.add(orderLine.ID);
          }
        }
 
        if (ordList.size() > 0 && ordList.get(0).Order_Line_Items__r.size() > 0) {
          for(Order_Line_Item__c ordLine : ordList.get(0).Order_Line_Items__r) {
            ordLine.Type__c = Constants.ORDER_LINE_ITEM_RENEWAL_ONE_OFF;
            ordLine.Start_Date__c = Date.today().addDays(-20);
            ordLine.End_Date__c = Date.today().addDays(10);
            orderLineItem.add(ordLine);
          }
          if (!orderLineItem.isEmpty())
            update orderLineItem;
        }

        if (ordList.size()> 0) {
          String orderStandardRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.RECORDTYPE_STANDARDS);

          for (Order__c ord : ordList) {
            ord.RecordTypeId = orderStandardRT_ID;
          }
          update ordList;

          String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
          for (Order__c ord : ordList) {
            ord.RecordTypeId = orderReadOnlyRT_ID;
          }
          update ordList;
        }

        Test.stopTest();
        //Asserts
        System.assertEquals(1, ordList.size());
        System.assertEquals(1, ordList.get(0).Order_Line_Items__r.size());
        //System.assertEquals(1, [SELECT ID FROM Opportunity WHERE Previous_Opportunity__c =: testOpp.ID].size());

        testOpp.StageName = Constants.STAGE_6_DURATION;
        //testOpp.Status__c = 'Pipeline';
        testOpp.Forecast_Category__c = 'Pipeline';
        update testOpp;


        System.assertEquals(0, [SELECT ID FROM Opportunity WHERE Previous_Opportunity__c =: testOpp.ID].size());
       // System.assertEquals(0, [SELECT Id FROM Order__c o WHERE Opportunity__c =: testOpp.ID].size());
      }
    }
    */
    
    //T-264492: to test durations of stages.
    /* NLG Commenting this method on 2014-09-25 because this is tricky to test (can't have the trigger 'wait' for a few millisecond)
    @isTest
    static void testStageDurationOnOppty(){
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.StageName = Constants.OPPTY_STAGE_3;
        //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        testOpp.Is_There_Commercial_Risk__c = 'Yes';
        testOpp.Is_There_Delivery_Risk__c = 'Yes';
        testOpp.Is_There_Financial_Risk__c = 'No';
        testOpp.Is_There_Legal_Risk__c = 'No';
        insert testOpp;

        Test_Utils.insertCompetitor(testOpp.Id);

        Contact contact = new Contact(FirstName = 'Test-Contact', LastName = 'J');
        insert contact;

        Test_Utils.createOpptyTasks(testOpp.Id, true);

        OpportunityContactRole OppRole = new OpportunityContactRole(OpportunityId = testOpp.Id, ContactId = contact.Id,
                                                                    Role = Constants.DECIDER, IsPrimary = true );
        insert OppRole;

        Test.startTest();

        Integer startTime = System.now().addMinutes(-5).millisecond();
        while(System.Now().millisecond()< startTime+10){
        }
        testOpp.StageName = Constants.OPPTY_STAGE_4;
        testOpp.Has_Senior_Approval__c = true;
        update testOpp;


        Opportunity assertChkOppty = [SELECT ID, Stage_3_Duration__c FROM Opportunity WHERE ID =: testOpp.ID];
        System.debug('***assertChkOppty1***'+assertChkOppty);
        //System.assert(assertChkOppty.Stage_3_Duration__c > 0); NLG commenting May 11th 2014- failing in Prod, no wait() method exist to test this

        startTime = System.now().addMinutes(-5).millisecond();
        while(System.Now().millisecond()< startTime+1){
        }
        // Create Opportunity Line itemn
        Product2 product = Test_Utils.insertProduct();
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
        //PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, priceBook.Id, 'USD');
        OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
        opportunityLineItem.Start_Date__c = System.today();
        opportunityLineItem.End_Date__c = System.today().addDays(10);
        insert opportunityLineItem;

        //testOpp.Below_Review_Thresholds__c = 'Yes'; T-271695:Removed reference to Below_Review_Thresholds__c
        testOpp.StageName = Constants.OPPTY_STAGE_5;
        update testOpp;

        Test.stopTest();
      }
    } */


    //T-265681: Test method for multi-currency dashboard
    @isTest
    static void testMultiCurrencyFieldUpdate(){

      //create Account
      Account testAcc = Test_Utils.insertAccount();
      //create Opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      testOpp.Amount = 1000;
      testOpp.CurrencyIsoCode ='GBP';
      testOpp.CloseDate = Date.today().addDays(7);
      insert testOpp;

      Test.startTest();
      Opportunity resultOpp = [SELECT ID, CloseDate, Amount, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c
                               FROM Opportunity WHERE Id =:testOpp.Id];
      Map<String, DatedConversionRate> dtConvRateMap = new Map<String, DatedConversionRate>();

      for (DatedConversionRate dcr : [SELECT ISOCode, ID, ConversionRate
                                      FROM DatedConversionRate
                                      WHERE StartDate < NEXT_N_DAYS:7 AND NextStartDate > NEXT_N_DAYS:7]) {
        dtConvRateMap.put(dcr.ISOCode, dcr);
      }

      system.debug('*****dtConvRateMap------------'+dtConvRateMap);
      system.assertEquals(dtConvRateMap.get('GBP').ConversionRate, resultOpp.GBP_Conversion_Rate__c);
      //system.assertEquals([], resultOpp.GBP_Conversion_Rate__c);
      system.assertEquals(dtConvRateMap.get('AUD').ConversionRate, resultOpp.AUD_Conversion_Rate__c);
      system.assertEquals(resultOpp.Amount_Corp__c, resultOpp.Amount / dtConvRateMap.get('GBP').ConversionRate);
      //update the currency on Opp
      testOpp.CurrencyIsoCode ='AUD';
      testOpp.CloseDate = Date.today().addDays(8);
      update testOpp;

      resultOpp = [SELECT ID, CloseDate, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c, Amount FROM Opportunity WHERE Id =:testOpp.Id];

     // system.assertEquals(resultOpp.Amount_Corp__c, resultOpp.Amount / dtConvRateMap.get('AUD').ConversionRate);
      Test.stopTest();
    }




  //Test method to evaluate functionality of CreateOppContactRoles method
  // NLG - Sep 10, 2014 - Commenting as this is done by the 'conId' parameter
  /*static testmethod void testCreateOppContactRoles(){
       // Create test data
       Test.startTest();
       // Create Account
       Account testAccount = Test_Utils.insertAccount();

       // Create an Contact
       Contact con  = new Contact (FirstName = 'Larry', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
       insert con;

       // Create an opportunity
       Opportunity sObjOpp = Test_utils.createOpportunity(testAccount.Id);
       sObjOpp.Originating_Contact_Id__c = con.Id;

       insert sObjOpp;

       List<OpportunityContactRole> oppContactRoleList = [SELECT Id FROM OpportunityContactRole WHERE ContactId = :con.id and OpportunityId = :sObjOpp.Id];

       System.assert(oppContactRoleList.size() > 0);
       Test.stopTest();
  } */


  //=========================================================================
  // Testing functionality of moveOriginatingTaskToNewOppty ()
  //=========================================================================
  @isTest
  static void test_moveOriginatingTaskToNewOppty () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;

    System.runAs(testUser){
      // insert account
      Account account = Test_Utils.insertAccount();
      //Insert Contact
      Contact testContact = Test_Utils.insertContact(account.ID);

      Id standardTaskRecId = [SELECT Id FROM RecordType WHERE SobjectType ='Task' and Name = 'Standard Task'].Id;

      List<Task> taskList = new List<Task>();
      Task newTask = new Task(ActivityDate = Date.today(), WhoId = testContact.ID);
      //newTask.RecordTypeId = standardTaskRecId;
      newTask.Status = 'Not Started';
      insert newTask;

      newTask = [SELECT ID, WhatID, WhoId, AccountId FROM Task WHERE ID =:newTask.Id];

      Test.startTest();
      Opportunity  testOppty = new Opportunity();
      testOppty.AccountId = account.Id;
      testOppty.Name = 'Test Opportunity';
      testOppty.CloseDate = date.today().addDays(2);
      testOppty.StageName = Constants.OPPTY_STAGE_3;
      testOppty.CurrencyIsoCode = 'USD';
      testOppty.Originating_Task_Id__c = newTask.ID;
      testOppty.Budget__c = 'Less than 1,000';
      testOppty.Type = 'New From New';
      testOppty.Capability__c = 'Application Processing';
      testOppty.Proposal_Type__c = 'Standard quote';
      testOppty.PO_Required__c = 'No';
      insert testOppty;

      Test.stopTest();

      Task resultTask = [SELECT ID, WhatID, WhoId, AccountId FROM Task WHERE Id =:newTask.Id];

      //Tasks should have Opportunity ID newly created from task
      System.assertEquals(resultTask.WhatID, testOppty.ID);
   }
  }

  @isTest
  static void testOnDemandOpportunityLineItem(){
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;

    System.runAs(testUser1){
      // insert account without 'On Demand' contact
      Account acc = Test_Utils.insertAccount();
        
      Address__c addrs1 = Test_Utils.insertAddress(true);
      
      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, acc.Id);
        
      //Insert Contact
      Contact testContact = Test_Utils.createContact(acc.ID);
      testContact.Email = 'test1@gmail.com';
      testContact.EDQ_On_Demand__c = false;
      testContact.Inactive__c = false;
      testContact.Title = 'Test';
      insert testContact;

      Test_Utils.insertContactAddress(true, addrs1.Id, testContact.Id);

      // insert opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
      testOpp.Type = 'New From New';
      insert testOpp;

      OpportunityContactRole oppContactRole =  Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.DECIDER, true);

      // insert OpportunityLineItem with 'On Demand'
      Product2 product = Test_Utils.insertProduct();
      Product2 product1 = Test_Utils.insertProduct();

      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);
      PricebookEntry stdPricebookEntry1 = Test_Utils.insertPricebookEntry(product1.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);

      OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry1.Id, testOpp.Type);
      opportunityLineItem.EDQ_On_Demand_Product__c = true;
      opportunityLineItem.Part_Number__c = '113232';
      opportunityLineItem.CPQ_Quantity__c = 10;
      insert opportunityLineItem;

      // start test
      Test.startTest();
      //update opp
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      testOpp.Has_Senior_Approval__c = true;
      testOpp.Amount = 100;

      try{
        update testOpp;
      }catch(Exception ex){
        System.assert(ex.getMessage().contains(Label.OPPTY_ERR_ONDEMAND_PRODUCT));
      }

      finally {

        List<Opportunity> oppty = [SELECT ID, StageName, AccountID,
                                   (SELECT Id, OpportunityId, EDQ_On_Demand_Product__c
                                    FROM OpportunityLineItems
                                    WHERE EDQ_On_Demand_Product__c = true)
                                 FROM Opportunity
                                 WHERE ID =: testOpp.Id ];
        System.assert(oppty.size() > 0);
        System.assertEquals(true, oppty.get(0).OpportunityLineItems.size() > 0);
      }
    }

      // stop test
      Test.stopTest();

  }  
      

   // test method to check createOppTeamMembers()
     @isTest
     static void test_createOppTeamMembers(){
         // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {
        // create user
        Profile pro = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
        User testUser = Test_Utils.createUser(pro, 'test1234@gmail.com', 'test1');
        insert testUser;
        // create Account
        Account testAccount = Test_Utils.insertAccount();
        // create Account Team Member
        AccountTeamMember atm = Test_Utils.createAccountTeamMembers(testAccount.Id, testUser.Id, false);
        atm.TeamMemberRole = Constants.TEAM_ROLE_STRAT_ACCOUNT_MANAGER;
        insert atm;

         // start test
        Test.startTest();
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        insert testOpp;

        // stop test
        Test.stopTest();
        List<OpportunityTeamMember> otmLst = [SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember
                                              WHERE OpportunityId =: testOpp.Id];
        System.assert(otmLst.size() > 0);


      }
   }

  //==========================================================================================
  // T-366560: prevent close/winning SaaS opp if Account doesn't have any SaaS Contact
  //==========================================================================================
  @isTest
  static void testOpptyAccWithSaasContact() {
      // create User
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;

    System.runAs(testUser1) {
      // insert account without 'On Demand' contact
      Account acc = Test_Utils.insertAccount();
      //Insert Contact
      Contact testContact = Test_Utils.createContact(acc.ID);
      testContact.SaaS__c = false;
      insert testContact;

      Address__c address = Test_Utils.insertAddress(true);

      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, address.Id, acc.Id);

      Test_Utils.insertContactAddress(true, address.Id, testContact.Id);

      // insert opportunity
      Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
      testOpp.Type = 'New From New';
      insert testOpp;

      OpportunityContactRole oppContactRole =  Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.DECIDER, true);

      // insert OpportunityLineItem with 'Saas'
      Product2 product = Test_Utils.insertProduct();

      //Pricebook2 pricebook = Test_Utils.getPriceBook2();
      //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);

      OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
      opportunityLineItem.SaaS__c = true;
      opportunityLineItem.SaaS_Product_Code__c = 'Test Saas Prod-1';
      opportunityLineItem.Start_Date__c = date.today().addDays(7);
      opportunityLineItem.End_Date__c = date.today().addDays(20);
      insert opportunityLineItem;

      // start test
      Test.startTest();
      //update opp
      testOpp.StageName = Constants.OPPTY_STAGE_7;
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      testOpp.Has_Senior_Approval__c = true;
      testOpp.Amount = 100;
      testOpp.CloseDate = date.today();
      testOpp.Contract_Start_Date__c = date.today().addDays(1);
      testOpp.Contract_End_Date__c = date.today().addYears(1);
      testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;

      try {
        update testOpp;
      } catch(Exception ex) {
         System.assert(ex.getMessage().contains(Label.SaaS_OPP_NEEDS_SAAS_CONTACTS));
      }

      // stop test
      Test.stopTest();
    }
   }

   //=========================================================================
  // Experian Sales Academy Test Cases BELOW
  //=========================================================================

  // T-273787 : test Update related Opp plans records on opportunity update
  @isTest
  static void testOppToOpportunityPlansSync(){
       // Create test data
       Test.startTest();
       // insert account
        Account account = Test_Utils.insertAccount();
        // insert opportunity

       // Create an opportunity
       Opportunity opportunity = Test_utils.createOpportunity(account.Id);
       opportunity.Budget__c = '1,000 - 10,000';
       insert opportunity;

       List<Opportunity_Plan__c> opporuntiyPlans = new List<Opportunity_Plan__c>();
       Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
       oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
       insert oPlan;

       Test.stopTest();
  }

  //******************************************************************************************************************//
  // Commented by: abose, 29th April, 2015- Main methods related to these are not found and a duplicate method exist
  // on class AccountPlanTriggerHandler_Test.createAccountPlanOppsTest() 
  
  /*  static testMethod void testCreateAccountPlanOpportunities() {
        Test.startTest();
        // create User
        Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
        User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
        insert testUser1;

        System.runAs(testUser1){
          TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER);
          insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_SWOT_TRIGGER);
          //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
          IsDataAdmin__c dataAdmin = new IsDataAdmin__c();
          dataAdmin.SetupOwnerId = testUser1.id;
          dataAdmin.IsDataAdmin__c = false;
          insert dataAdmin;

          Account_Plan_Opportunity__c accountPlanOpp;
          // insert account
          Account account = Test_Utils.insertAccount();
          List<Account_Plan__c> accountPlanList = new List<Account_Plan__c>();
          // create account plan
          Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
          insert accountPlan;
          accountPlanList.add(accountPlan);
          // create account plan
          Account_Plan__c accountPlan1 = Test_Utils.insertAccountPlan(false, account.id);
          insert accountPlan1;
          accountPlanList.add(accountPlan1);

          List<Account_Plan_Opportunity__c> accountPlanOppList = [select id
                                                                  from Account_Plan_Opportunity__c
                                                                  where Account_Plan__c IN : accountPlanList];

          System.assertEquals(accountPlanOppList.size(), 0, 'No Account plan opps should be created as no opp association to account');

           // Create an opportunity
          Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
          opp1.Has_Senior_Approval__c = true;
          opp1.StageName = Constants.OPPTY_STAGE_3;
          opp1.Amount = 500;
          opp1.Starting_Stage__c = Constants.OPPTY_STAGE_7;
          insert opp1;

          accountPlanOppList = [select id, Opportunity_Name__c, Current_Year_Revenue__c
                                 from Account_Plan_Opportunity__c
                                 where Account_Plan__c IN : accountPlanList];

          system.assertEquals(accountPlanOppList.size(), accountPlanList.size(), 'creation of opp should have created 2 acc plan opp records');

          for(Account_Plan_Opportunity__c accPlanOpportunity : accountPlanOppList){
            System.assertEquals(accPlanOpportunity.Opportunity_Name__c, opp1.Name, 'should match with opp1 name');
            System.assertEquals(accPlanOpportunity.Current_Year_Revenue__c, opp1.Amount, 'should match with opp1 amount');
          }


        }
        Test.stopTest();
    }


    static testMethod void testUpdateAccountPlanOpportunities() {
        Test.startTest();
        // create User
        Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
        User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
        insert testUser1;

        System.runAs(testUser1){
          TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER);
          insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_SWOT_TRIGGER);
          //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
          IsDataAdmin__c dataAdmin = new IsDataAdmin__c();
          dataAdmin.SetupOwnerId = testUser1.id;
          dataAdmin.IsDataAdmin__c = false;
          insert dataAdmin;

          Account_Plan_Opportunity__c accountPlanOpp;
          // insert account
          Account account = Test_Utils.insertAccount();
          List<Account_Plan__c> accountPlanList = new List<Account_Plan__c>();
          // create account plan
          Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
          //insert accountPlan;
          accountPlanList.add(accountPlan);
          // create account plan
          Account_Plan__c accountPlan1 = Test_Utils.insertAccountPlan(false, account.id);
          //insert accountPlan1;
          accountPlanList.add(accountPlan1);
          insert accountPlanList;
          
          List<Account_Plan_Opportunity__c> accountPlanOppList = [select id
                                                                  from Account_Plan_Opportunity__c
                                                                  where Account_Plan__c IN : accountPlanList];

          System.assertEquals(accountPlanOppList.size(), 0, 'No Account plan opps should be created as no opp association to account');

           // Create an opportunity
          Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
          opp1.Has_Senior_Approval__c = true;
          opp1.StageName = Constants.OPPTY_STAGE_3;
          opp1.Amount = 500;
          opp1.Starting_Stage__c = Constants.OPPTY_STAGE_7;
          opp1.CurrencyIsoCode = Constants.CURRENCY_GBP;
          insert opp1;

          accountPlanOppList = [select id, Opportunity_Name__c, Current_Year_Revenue__c
                                 from Account_Plan_Opportunity__c
                                 where Account_Plan__c IN : accountPlanList];

          system.assertEquals(accountPlanOppList.size(), accountPlanList.size(), 'creation of opp should have created 2 acc plan opp records');

          for(Account_Plan_Opportunity__c accPlanOpportunity : accountPlanOppList){
            System.assertEquals(accPlanOpportunity.Opportunity_Name__c, opp1.Name, 'should match with opp1 name');
            System.assertEquals(accPlanOpportunity.Current_Year_Revenue__c, opp1.Amount, 'should match with opp1 amount');
          }

          // Create Opportunity Line itemn
            Product2 product = Test_Utils.insertProduct();
            product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;
              product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_WEEKLY;
              product.NumberOfRevenueInstallments = 2;
              product.CanUseRevenueSchedule = true;
              update product;

              // Create Opportunity Line itemn
          Product2 product1 = Test_Utils.insertProduct();

            //Pricebook2 pricebook = Test_Utils.getPriceBook2();
            //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
            PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_GBP);
            PricebookEntry stdPricebookEntry1 = Test_Utils.insertPricebookEntry(product1.Id, Test.getStandardPricebookId(), Constants.CURRENCY_GBP);




            List<OpportunityLineItem> oppLineItemsToInsert = new List<OpportunityLineItem>();

            OpportunityLineItem opportunityLineItem = Test_Utils.createOpportunityLineItem(opp1.Id, stdPricebookEntry.Id, opp1.Type);
            opportunityLineItem.Start_Date__c = System.today();
            opportunityLineItem.End_Date__c = System.today().addDays(20);
            oppLineItemsToInsert.add(opportunityLineItem);

            OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(opp1.Id, stdPricebookEntry1.Id, opp1.Type);
          opportunityLineItem1.Start_Date__c = System.today();
          opportunityLineItem1.End_Date__c = System.today().addDays(20);
          oppLineItemsToInsert.add(opportunityLineItem1);
          insert oppLineItemsToInsert;

          List<OpportunityLineItemSchedule> olsList = new List<OpportunityLineItemSchedule>();

          OpportunityLineItemSchedule ols = new OpportunityLineItemSchedule();
                    ols.ScheduleDate = date.today();
                    ols.opportunityLineItemID = opportunityLineItem.id;
                    ols.type = Constants.REVENUE_SCHEDULED_TYPE_REVENUE;
                    ols.Revenue = 50;
          olsList.add(ols);

          OpportunityLineItemSchedule ols0 = new OpportunityLineItemSchedule();
          ols0.ScheduleDate = date.today().addDays(10);
          ols0.opportunityLineItemID = opportunityLineItem.id;
          ols0.type = Constants.REVENUE_SCHEDULED_TYPE_REVENUE;
          ols0.Revenue = 50;
          olsList.add(ols0);

          OpportunityLineItemSchedule ols1 = new OpportunityLineItemSchedule();
          ols1.ScheduleDate = date.today().addYears(1);
          ols1.opportunityLineItemID = opportunityLineItem.id;
          ols1.type = Constants.REVENUE_SCHEDULED_TYPE_REVENUE;
          ols1.Revenue = 50;
           olsList.add(ols1);

          OpportunityLineItemSchedule ols2 = new OpportunityLineItemSchedule();
          ols2.ScheduleDate = date.today().addYears(2);
          ols2.opportunityLineItemID = opportunityLineItem.id;
          ols2.type = Constants.REVENUE_SCHEDULED_TYPE_REVENUE;
          ols2.Revenue = 50;
          olsList.add(ols2);

          insert  olsList;


          opp1 = [Select id, Amount, Name from Opportunity where id=: opp1.id];
          System.assertEquals(opportunityLineItem.TotalPrice.intValue() + opportunityLineItem1.TotalPrice.intValue(), opp1.Amount.intValue(), 'match');

          accountPlanOppList = [select id, Opportunity_Name__c, Current_Year_Revenue__c, Year_1_Revenue__c, Year_2_Revenue__c
                                 from Account_Plan_Opportunity__c
                                 where Account_Plan__c IN : accountPlanList];

          system.assertEquals(accountPlanOppList.size(), accountPlanList.size(), 'creation of opp should have updated 2 acc plan opp records');

          for(Account_Plan_Opportunity__c accPlanOpportunity : accountPlanOppList){
            System.assertEquals(accPlanOpportunity.Opportunity_Name__c, opp1.Name, 'should match with opp1 name');
            decimal currentYearRevenue = ols.Revenue + ols0.Revenue + opportunityLineItem1.TotalPrice;
            System.assertEquals(accPlanOpportunity.Current_Year_Revenue__c.intValue(), currentYearRevenue.intValue(), 'should match with current year revenue scheduled');
            System.assertEquals(accPlanOpportunity.Year_1_Revenue__c, ols1.Revenue, 'should match with year1 revenue scheduled');
            System.assertEquals(accPlanOpportunity.Year_2_Revenue__c, ols2.Revenue, 'should match with year2 revenue scheduled');
          }


        }
        Test.stopTest();
    } */
    //***********************************************************************************************************************//
    
    
    //========================================================================
    // As per T-373692
    //========================================================================
    @isTest
    static void testpopulateSalesTeamChannelAndRegion() {
      // create User
      Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      testUser1.Sales_Team__c = 'Test Value for Sales Team';
      testUser1.Sales_Sub_Team__c = 'Test Value For SubTeam';
      insert testUser1;
  
      System.runAs(testUser1) {
        // insert account without 'On Demand' contact
        Account acc = Test_Utils.insertAccount();
        //Insert Contact
        Contact testContact = Test_Utils.createContact(acc.ID);
        testContact.SaaS__c = false;
        insert testContact;
  
        //Address__c address = Test_Utils.insertAddress(true);
        //Test_Utils.insertContactAddress(true, address.Id, testContact.Id);

        // insert opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
        testOpp.Type = 'New From New';
        insert testOpp;
        testOpp = [SELECT Sales_Team_Channel__c, Sales_Sub_Team_Region__c FROM Opportunity WHERE ID =: testOpp.ID];
        
        System.assertEquals(testOpp.Sales_Team_Channel__c, testUser1.Sales_Team__c);
        System.assertEquals(testOpp.Sales_Sub_Team_Region__c, testUser1.Sales_Sub_Team__c);
      }
    }
    
    //=======================================================================
    // T-372609 
    //=======================================================================
    /* NLG Apr 21, 2015: ON HOLD
    @isTest
    static void testSyncOppDates() {
      // create User
      Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      
      System.runAs(testUser1) {
        Date tempDate = date.today();
        
        Account acc = Test_Utils.insertAccount();
        //Insert Contact
        Contact testContact = Test_Utils.createContact(acc.ID);
        insert testContact;
  
        Address__c address = Test_Utils.insertAddress(true);
        
        Test_Utils.insertContactAddress(true, address.Id, testContact.Id);
  
        // insert opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(acc.Id);
        testOpp.Type = 'New From New';
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Amount = 1000;
        testOpp.CloseDate = tempDate;
        testOpp.All_dates_based_on_Closed_Date__c = true;
        testOpp.Contract_Start_Date__c = testOpp.CloseDate.addDays(1);
        testOpp.Contract_End_Date__c = testOpp.CloseDate.addYears(1);
        //testOpp.Contract_Start_Date__c = tempDate.addDays(3);
        //testOpp.Contract_End_Date__c = tempDate.addMonths(6);
        insert testOpp;
        system.debug('testOpp>>>' +testOpp); 
        
        OpportunityContactRole oppContactRole =  Test_Utils.insertOpportunityContactRole(true, testOpp.Id, testContact.Id, Constants.DECIDER, true);
  
        // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
        product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;
        product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;
        product.NumberOfRevenueInstallments = 2;
        //product.CanUseQuantitySchedule = false;
        product.CanUseRevenueSchedule = true;
        update product;
        
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2('Standard Price Book');
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
  
        //insert OLI
        OpportunityLineItem opportunityLineItem2 =  new OpportunityLineItem (TotalPrice = 200, UnitPrice = null, Quantity = 1,
                                                        OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                        Start_Date__c = tempDate.addDays(5), End_Date__c = tempDate.addDays(10));
        insert opportunityLineItem2;
    
        //insert OLIS
        OpportunityLineItemSchedule olsi1 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
        olsi1.ScheduleDate = tempDate.addDays(2);
        OpportunityLineItemSchedule olsi2 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
        olsi2.ScheduleDate = tempDate.addDays(2);
        OpportunityLineItemSchedule olsi3 =  Test_Utils.createOpportunityLineItemSchedule(opportunityLineItem2.id);
        olsi3.ScheduleDate = tempDate.addDays(2);
    
        List<OpportunityLineItemSchedule> opptySchedules = new List<OpportunityLineItemSchedule>();
        opptySchedules.add(olsi1); 
        opptySchedules.add(olsi2);
        opptySchedules.add(olsi3);
        insert opptySchedules;
      
        // start test
        Test.startTest();
        //update opp
        Integer shiftByDays = 5;
        testOpp.CloseDate = tempDate.addDays(shiftByDays);
        update testOpp;
        
        // stop test
        Test.stopTest();
        
        Opportunity oppty = [SELECT Id, CloseDate, Contract_Start_Date__c, Contract_End_Date__c,
                                    (SELECT Id, Start_Date__c, End_Date__c
                                     FROM OpportunityLineItems)
                             FROM Opportunity
                             WHERE Id =: testOpp.Id];
                             
        system.debug('testOpp>>>' +oppty);           
        system.assertEquals(testOpp.Contract_Start_Date__c.addDays(shiftByDays), oppty.Contract_Start_Date__c);
        system.assertEquals(testOpp.Contract_End_Date__c.addDays(shiftByDays), oppty.Contract_End_Date__c);

        for (OpportunityLineItem item: oppty.OpportunityLineItems) {
          system.assertEquals(opportunityLineItem2.Start_Date__c.addDays(shiftByDays), item.Start_Date__c);
          system.assertEquals(opportunityLineItem2.End_Date__c.addDays(shiftByDays), item.End_Date__c);
        }
      }
    }*/
}