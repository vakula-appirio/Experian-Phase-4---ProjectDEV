/**=====================================================================
 * Appirio, Inc
 * Name: OrderTriggerHandler_Test
 * Description: Test Class for OrderTrigger
 * Created Date: March 19th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified          Modified By             Description of the update
 * Mar 19th, 2014         Megha Agarwal           test methods for validate Service Dates and populate Service Dates on OLI
 *                                                testValidateServiceDates() ,testUpdateServiceDatesOnOLI()
 * Mar 21st, 2014         Megha Agarwal           test methods for Cancel Order  testCancelledOrder()
 *                                                test methods to Read Only Order testReadOnlyOrder()
 * Apr 02nd, 2014         Arpita Bose             T-268663: Renamed OrderLineItem's Service Start/End dates to Start/End dates
 * Apr 2nd, 2014          Nathalie Le Guay        Replaced order.Service_Start/End_Date__c with order.Contract_Start/End_Date__c
 * Apr 03rd, 2014         Arpita Bose             T-268982: Updated a Test_Utils method from insertOrder() to insertOrderLineItems()
 * Apr 04th, 2014         Mohit Parnami (Appirio) T-267423
 * Apr 07th, 2014         Nathalie Le Guay        Update to Order LI.Renewable__c as it becomes a picklist
 * Apr 08th, 2014         Nathalie Le Guay        Order LI.Renewable__c renamed to Type__c
 * Apr 14th, 2014         Arpita Bose             T-271244: Added method testMultiCurrencyFieldUpdate() to test multi-currency config
 * Apr 15th, 2014         Arpita Bose             Updated method testMultiCurrencyFieldUpdate()
 * Apr 15th, 2014         Arpita Bose             T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014         Arpita Bose             T-271695: Renamed field Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 30th, 2014         Arpita Bose             Updated testCancelledOrder() method to fix the failure
 * Apr 30th, 2014         Arpita Bose             I-113908: Added test method testCurrencyIsoOnChildOfOrder()
 * Jul 31st, 2014         Arpita Bose             T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Oct 20th, 2014         Naresh Kr Ojha          T-326947: added test_updateOpportunityContactAddresses() Test method to cechk Oppty Cont Address order populated.
 * Oct 20th, 2014         Arpita Bose             Updated method createTestData() to remove IsDataAdmin__c
 * Nov 12th, 2014         Noopur                  Modified to add Type to Opportunity and corresponding Order type to its OLIs
 * Dec 8th, 2014          Nathalie Le Guay        Fixed test method testReadOnlyOrder(): adding StartTest() and StopTest()
 * Mar 16th, 2015         Paul Kissick            Case #530104 - Adding tests for EDQ users and Orders (testReadOnlyEDQOrder())
 * Apr 20th, 2015         Paul Kissick            Case #593979 - Adding renewal owner to team for EDQ test
 * Apr 30th, 2015         Suminder Singh          Fixed Test class for assert failure
 =====================================================================*/
@isTest
private class OrderTriggerHandler_Test {

    static User testUser1, testUser2;
    static Opportunity opp;
    public static Account account;
    static Order__c orderWithNoOpp, orderWithOpp;
    static OpportunitySplit oppSplit1, oppSplit2;
    static List<OpportunitySplit> listOppSplit = new List<OpportunitySplit>();
    private static List<Order__c> orders;
    private static List<Order_Line_Item__c> olis;
    private static Opportunity testOpp;
    static List<Account_Segment__c> listAccSegments = new List<Account_Segment__c>();
    static Order__c testOrdr;
    static Account acc;
    /* Description :
    Case 1 :        Create a User with all the fields populated: BU, BL, GBL, Sales Team, Sales Sub-Team, Region, country.
                    => Create an Order with Opportunity__c = null AND ownerId = user above
                    => Verify that an Order_Split__c record is created */

    //@isTest
    public static void testCreateOrderSplitRecordCase1() {
        createUserAndOppSplitTestData();
        acc = Test_Utils.insertAccount();
        Test.startTest();
            orderWithNoOpp = Test_Utils.CreateOrder();
            orderWithNoOpp.Transactional_Sale__c = true;
            orderWithNoOpp.Account__c = acc.Id ;
            orderWithNoOpp.OwnerId = testUser1.Id;
            insert orderWithNoOpp;

            //orderWithNoOpp.OwnerId = testUser1.Id;
            orderWithNoOpp.Opportunity__c = null;
            update orderWithNoOpp;

            Order_Split__c orderSplit = [Select Order__c, Split_Percentage__c, OwnerId, Split_Note__c, Credited_To__c, Credited_To_GBL__c,
                                        Credited_To_BU__c, Credited_To_BL__c, Credited_To_Sales_Team__c, Credited_To_Sales_Sub_Team__c,
                                        Credited_To_Country__c, Credited_To_Region__c
                                        From Order_Split__c
                                        Where Order__c =: orderWithNoOpp.Id];

                system.assertEquals(orderSplit.Order__c, orderWithNoOpp.Id);
                system.assertEquals(orderSplit.Split_Percentage__c, 100);
                system.assertEquals(orderSplit.OwnerId, orderWithNoOpp.OwnerId);
                system.assertEquals(orderSplit.Split_Note__c, null);
                system.assertEquals(orderSplit.Credited_To__c, orderWithNoOpp.OwnerId);
                system.assertEquals(orderSplit.Credited_To_GBL__c, testUser1.Global_Business_Line__c);
                system.assertEquals(orderSplit.Credited_To_BU__c, testUser1.Business_Unit__c);
                system.assertEquals(orderSplit.Credited_To_BL__c, testUser1.Business_Line__c);
                system.assertEquals(orderSplit.Credited_To_Sales_Team__c, testUser1.Sales_Team__c);
                system.assertEquals(orderSplit.Credited_To_Sales_Sub_Team__c, testUser1.Sales_Sub_Team__c);
                system.assertEquals(orderSplit.Credited_To_Country__c, testUser1.Country__c);
                system.assertEquals(orderSplit.Credited_To_Region__c, testUser1.Region__c);
        Test.stopTest();
    }

    /* Description :
        Case 2)
        - Create User 1 with all the fields populated: BU, BL, GBL, Sales Team, Sales Sub-Team, Region, country.
        - Create User 2 with all the fields populated: BU, BL, GBL, Sales Team, Sales Sub-Team, Region, country, with different values

        - Create an Opp with 2 OpportunitySplit records created related to it (percentages 40%-60%).
        - OppSplit1.OwnerId = user1 and OppSplit2.OwnerId = user2

        - Create an Order with Opportunity__c = testOpp
        => Verify that
        1) Order has 2 Split Orders related to it
        2) that the values of the order split with Split_Percentages__c = 40% matches the user1's data
        3) that the values of the order split with Split_Percentages__c = 60% matches the user2's data */

    //@isTest
    public static void testCreateOrderSplitRecordCase2() {
        createUserAndOppSplitTestData();
        Test.startTest();
            orderWithOpp = Test_Utils.CreateOrder();
            orderWithOpp.Opportunity__c = opp.Id;
            orderWithOpp.Account__c = account.ID;
            insert orderWithOpp;

            System.debug('**classcalling**opptyID:'+opp.Id);

            orderWithOpp.OwnerId = testUser1.Id;
            update orderWithOpp;
            Test.stopTest();
            List<Order_Split__c> lstOrderSplit = [Select Order__c, Split_Percentage__c, OwnerId, Split_Note__c, Credited_To__c, Credited_To_GBL__c,
                                        Credited_To_BU__c, Credited_To_BL__c, Credited_To_Sales_Team__c, Credited_To_Sales_Sub_Team__c,
                                        Credited_To_Country__c, Credited_To_Region__c
                                        From Order_Split__c
                                        Where Order__c =: orderWithOpp.Id];
            system.debug('$$$no.of OrderSplit'+ lstOrderSplit.size());
            System.debug('*****lstOrderSplit******:'+lstOrderSplit);

            for(OpportunitySplit oppSplit : listOppSplit){
                for(Order_Split__c orderSplit : lstOrderSplit){
                    if(oppSplit.SplitOwnerId == testUser1.Id){
                        if(orderSplit.OwnerId == oppSplit.SplitOwnerId){
                            system.assertEquals(orderSplit.Credited_To_GBL__c, testUser1.Global_Business_Line__c);
                            system.assertEquals(orderSplit.Credited_To_BU__c, testUser1.Business_Unit__c);
                            system.assertEquals(orderSplit.Credited_To_BL__c, testUser1.Business_Line__c);
                            system.assertEquals(orderSplit.Credited_To_Sales_Team__c, testUser1.Sales_Team__c);
                            system.assertEquals(orderSplit.Credited_To_Sales_Sub_Team__c, testUser1.Sales_Sub_Team__c);
                            system.assertEquals(orderSplit.Credited_To_Country__c, testUser1.Country__c);
                            system.assertEquals(orderSplit.Credited_To_Region__c, testUser1.Region__c);
                            system.assertEquals(orderSplit.Split_Percentage__c, oppSplit.SplitPercentage);
                            system.assertEquals(orderSplit.OwnerId, oppSplit.SplitOwnerId);
                            system.assertEquals(orderSplit.Split_Note__c, OppSplit.SplitNote);
                            system.assertEquals(orderSplit.Credited_To__c, oppSplit.SplitOwnerId);
                        }
                    }

                    if(oppSplit.SplitOwnerId == testUser2.Id){
                        if(orderSplit.OwnerId == oppSplit.SplitOwnerId){
                            system.assertEquals(orderSplit.Credited_To_GBL__c, testUser2.Global_Business_Line__c);
                            system.assertEquals(orderSplit.Credited_To_BU__c, testUser2.Business_Unit__c);
                            system.assertEquals(orderSplit.Credited_To_BL__c, testUser2.Business_Line__c);
                            system.assertEquals(orderSplit.Credited_To_Sales_Team__c, testUser2.Sales_Team__c);
                            system.assertEquals(orderSplit.Credited_To_Sales_Sub_Team__c, testUser2.Sales_Sub_Team__c);
                            system.assertEquals(orderSplit.Credited_To_Country__c, testUser2.Country__c);
                            system.assertEquals(orderSplit.Credited_To_Region__c, testUser2.Region__c);
                            system.assertEquals(orderSplit.Split_Percentage__c, oppSplit.SplitPercentage);
                            system.assertEquals(orderSplit.OwnerId, oppSplit.SplitOwnerId);
                            system.assertEquals(orderSplit.Split_Note__c, OppSplit.SplitNote);
                            system.assertEquals(orderSplit.Credited_To__c, oppSplit.SplitOwnerId);
                        }
                    }
                    system.assertEquals(orderSplit.Order__c, orderWithOpp.Id);
                }
            }

    }

    private static void createUserAndOppSplitTestData(){
        testUser1 = Test_Utils.createUser('System Administrator');
        testUser1.Business_Unit__c = 'APAC Marketing Services India';
        testUser1.Business_Line__c = 'India Credit Services';
        testUser1.Global_Business_Line__c = 'Credit Services';
        testUser1.Sales_Team__c = 'APAC Marketing Services India';
        testUser1.Sales_Sub_Team__c = 'EMEA CS SA Financial Services';
        testUser1.Region__c = 'India';
        testUser1.Country__c = 'India';
        insert testUser1;

        System.debug('---testuser1---'+testUser1.ID);

        testUser2 = Test_Utils.createUser('System Administrator');
        testUser2.Business_Unit__c = 'India DA';
        testUser2.Business_Line__c = 'APAC Decision Analytics';
        testUser2.Global_Business_Line__c = 'Decision Analytics';
        testUser2.Sales_Team__c = 'India CS North & East';
        testUser2.Sales_Sub_Team__c = 'EMEA CS SA Mid Tier';
        testUser2.Region__c = 'India';
        testUser2.Country__c = 'India';
        insert testUser2;

        System.debug('---testuser2---'+testUser2.ID);
        System.debug('--------userInfo---'+UserInfo.getUserId());
        System.runAs(testUser1) {
          account = Test_Utils.insertAccount();
        }
        opp = Test_Utils.createOpportunity(account.Id);
        opp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert opp;

        OpportunityTeamMember member1 = new OpportunityTeamMember ();
        member1.OpportunityId = opp.Id;
        member1.UserId = testUser1.Id;
        member1.TeamMemberRole ='Account Manager';
        insert member1;

        OpportunityTeamMember member2 = new OpportunityTeamMember ();
        member2.OpportunityId = opp.Id;
        member2.UserId = testUser2.Id;
        member2.TeamMemberRole ='Sales Rep';
        insert member2;

        System.debug('**testdata**opptyID:'+opp.Id);
        oppSplit1 = Test_Utils.createOppSplit(opp);
        oppSplit1.SplitPercentage = 40;
        oppSplit1.SplitOwnerId = testUser1.Id;
        oppSplit1.SplitNote = 'testNote1';
        listOppSplit.add(oppSplit1);

        oppSplit2 = Test_Utils.createOppSplit(opp);
        oppSplit2.SplitPercentage = 60;
        oppSplit2.SplitOwnerId = testUser2.Id;
        oppSplit2.SplitNote = 'testNote2';
        listOppSplit.add(oppSplit2);
        insert listOppSplit;
        System.debug('*****listOppSplit****'+listOppSplit);
    }

    //@isTest
    static void testValidateServiceDates() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser;

      System.runAs(testUser) {

       createTestData();

       // We are populating the Order's Service Start/End Date, which will
       // populate the OLI's Service Start/End Date
       orders.get(0).Contract_Start_Date__c = Date.today();
       orders.get(1).Contract_End_Date__c = Date.today();
       update orders;

       List<Order_Line_Item__c> resultOLIs = [SELECT Id, Start_Date__c
                                              FROM Order_Line_Item__c
                                              WHERE Order__c = : orders.get(0).Id AND Start_Date__c != null];
       System.assert(resultOLIs.size() > 0);
       // Here we try to update the Order's Service Start Date
       // At this point the OLI's Service Start/End dates are already populated, so
       // we will prevent from updating the Order's Service Dates
       orders.get(0).Contract_Start_Date__c = Date.today().addDays(1);

       try {
         update orders.get(0);
       } catch(Exception ex) {
          // Expecting an error preventing the user from updating the Order's date if any of
          // the OLI have their dates populated
          System.assert(ex.getMessage().contains(System.Label.Service_Start_Date_Error_Msg));
       }

       // Testing the same on the Service End Date
       orders.get(1).Contract_End_Date__c = Date.today().addDays(1);
       try {
         update orders.get(1);
       } catch(Exception ex) {
          System.assert(ex.getMessage().contains(System.Label.Service_End_Date_Error_Msg));
       }
      }
    }

    //@isTest
    static void testUpdateServiceDatesOnOLI() {
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser;

      System.runAs(testUser) {

       createTestData();
       // Updating the Order's Service Start/End Dates - OLI should be updated accordingly
       // because the OLI's Service Start/End Date are blank
       orders.get(0).Contract_Start_Date__c = Date.today().adddays(-30);
       orders.get(1).Contract_End_Date__c = Date.today().addDays(10);
       update orders;
       List<Order_Line_Item__c> resultOLIs = [SELECT Id, Start_Date__c, End_Date__c
                                              FROM Order_Line_Item__c
                                              WHERE order__c in : orders];
       System.assert(resultOLIs.size() > 0);
       // Expecting the OLI's date to match the Order's date
       System.assertEquals(resultOLIs.get(0).Start_Date__c , orders.get(0).Contract_Start_Date__c);
      }
    }

    private static void createTestData(){
        // Create an account
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Has_Senior_Approval__c = true;
        testOpp.StageName = Constants.OPPTY_STAGE_3;
        //testOpp.Below_Review_Thresholds__c = 'Yes';
        //testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Amount = 100;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

        Test_Utils.createOpptyTasks(testOpp.Id, true);

        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;


        orders = new List<Order__c>();
        orders.add(Test_Utils.createOrder());
        orders.get(0).Name ='Test Order 0';
        orders.get(0).Account__c = testAccount.id;
        orders.get(0).Contact__c = newcontact.id;
        orders.get(0).Opportunity__c = testOpp.id;
        orders.add(Test_Utils.createOrder());
        orders.get(1).Name ='Test Order 1';
        orders.get(1).Account__c = testAccount.id;
        orders.get(1).Contact__c = newcontact.id;
        orders.get(1).Opportunity__c = testOpp.id;
        orders.add(Test_Utils.createOrder());
        orders.get(2).Name ='Test Order 2';
        orders.get(2).Account__c = testAccount.id;
        orders.get(2).Contact__c = newcontact.id;
        orders.get(2).Opportunity__c = testOpp.id;
        insert orders;

        List<Order__c> ordrs = [SELECT Name, Opportunity__c FROM Order__c where ID IN: orders];
        system.debug('@@@Orders@@@' +ordrs);

        olis = new List<Order_Line_Item__c>();
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(0).id , null));
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(0).id , null));
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(1).id , null));
        for(Order_Line_Item__c oli : olis ){
            //oli.Start_Date__c = Date.today().addDays(-10);//null;
            oli.Start_Date__c = Date.Today();
            oli.End_Date__c = Date.today().addDays(10);//null;
            oli.Quantity__c = 1;
        }
        insert olis;
    }


    //@isTest
    static void testCancelledOrder(){
        Account testAccount = Test_Utils.insertAccount();
        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;
        Opportunity testOpp1 = Test_Utils.createOpportunity(testAccount.Id);
        insert testOpp1;

        Order__c order1 = Test_Utils.insertOrder (true, testAccount.Id, newcontact.Id, testOpp1.Id );
        Order__c order2 = Test_Utils.insertOrder (true, testAccount.Id, newcontact.Id, testOpp1.Id );
        Order__c order3 = Test_Utils.insertOrder (true, testAccount.Id, newcontact.Id, testOpp1.Id );

        List<Order__c>  ordrLst = new List<Order__c>();
        ordrLst.add(order1);
        ordrLst.add(order2);
        ordrLst.add(order3);
        //insert ordrLst;

        Test.StartTest();
        ordrLst.get(0).Cancellation_Date__c = Date.today();
        ordrLst.get(0).Transactional_Sale__c = true;
        ordrLst.get(1).Cancellation_Date__c = Date.today();
        ordrLst.get(1).Transactional_Sale__c = true;
        ordrLst.get(2).Cancellation_Date__c = Date.today();
        ordrLst.get(2).Transactional_Sale__c = true;
        update ordrLst;
        System.debug('****orders****'+orders);

        Test.StopTest();

        List<Opportunity> deletedOpps = [select id from Opportunity where id = :testOpp1.id ];
        System.assertEquals(true, deletedOpps.size() == 0);

    }

    //@isTest //(seeAllData=true)
    static void testReadOnlyOrder(){
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser;

      System.runAs(testUser) {
        createTestData();

        Test.StartTest();
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
        PricebookEntry stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPriceBookId(), Constants.CURRENCY_USD);
        //insert OLI
        List<OpportunityLineItem> opptyLIs = new List<OpportunityLineItem>();
        opptyLIs.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        opptyLIs.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        insert opptyLIs;

        String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
        olis.get(0).Type__c = Constants.ORDER_RENEWAL;
        olis.get(0).End_Date__c = Date.today().addDays(10);
        update olis.get(0);
        orders.get(0).RecordTypeId = orderReadOnlyRT_ID;
        update orders.get(0);
        Test.StopTest();

        System.assert(([select id from Opportunity where previous_Order__c = : orders.get(0).id]).size() > 0);
      }
    }

    //@isTest
    static void testReadOnlyEDQOrder(){
      // create User
      IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true); 
      insert ida;
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
      insert testUser;

      User testUserB = Test_Utils.createUser(p, 'test9876@gmail.com', 'test2');
      insert testUserB;

      System.runAs(testUser) {
        Account testAccount = Test_Utils.insertAccount();
        Account testCompetitor = Test_Utils.insertAccount();
        testCompetitor.Is_Competitor__c = true;
        update testCompetitor;
        // Create an opportunity
        testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Has_Senior_Approval__c = true;
        testOpp.StageName = Constants.OPPTY_STAGE_3;
        //testOpp.Below_Review_Thresholds__c = 'Yes';
        //testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Amount = 100;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;

        OpportunityTeamMember renewalOwner = Test_Utils.insertOpportunityTeamMember(true, testOpp.Id, testUserB.Id, Constants.TEAM_ROLE_RENEWAL_OWNER);

        Test_Utils.createOpptyTasks(testOpp.Id, true);

        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAccount.Id, Email = 'larrye@email.com');
        insert newcontact;

        Test_Utils.insertEDQOpportunityContactRoles(testOpp.Id, newContact.Id);

        Competitor__c oppComp = new Competitor__c(Opportunity__c = testOpp.Id, Account__c = testCompetitor.Id);
        insert oppComp;

        orders = new List<Order__c>();
        orders.add(Test_Utils.createOrder());
        orders.get(0).Name ='Test Order 0';
        orders.get(0).Account__c = testAccount.id;
        orders.get(0).Contact__c = newcontact.id;
        orders.get(0).Opportunity__c = testOpp.id;
        orders.add(Test_Utils.createOrder());
        orders.get(1).Name ='Test Order 1';
        orders.get(1).Account__c = testAccount.id;
        orders.get(1).Contact__c = newcontact.id;
        orders.get(1).Opportunity__c = testOpp.id;
        orders.add(Test_Utils.createOrder());
        orders.get(2).Name ='Test Order 2';
        orders.get(2).Account__c = testAccount.id;
        orders.get(2).Contact__c = newcontact.id;
        orders.get(2).Opportunity__c = testOpp.id;
        insert orders;

        List<Order__c> ordrs = [SELECT Name, Opportunity__c FROM Order__c where ID IN: orders];
        system.debug('@@@Orders@@@' +ordrs);

        Billing_Product__c billProd = Test_Utils.insertBillingProduct();

        olis = new List<Order_Line_Item__c>();
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(0).id , billProd.Id));
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(0).id , billProd.Id));
        olis.add(Test_Utils.insertOrderLineItems(false, orders.get(1).id , billProd.Id));
        for(Order_Line_Item__c oli : olis ){
            //oli.Start_Date__c = Date.today().addDays(-10);//null;
            oli.Start_Date__c = Date.Today();
            oli.End_Date__c = Date.today().addDays(10);//null;
            oli.Quantity__c = 1;
        }
        insert olis;

        Test.StartTest();
        // Create Opportunity Line Item
        Product2 product = Test_Utils.insertProduct();
        product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;
        product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;
        product.NumberOfRevenueInstallments = 2;
        //product.CanUseQuantitySchedule = false;
        product.CanUseRevenueSchedule = true;

        update product;

        for(Order_Line_Item__c oli : olis ) {
            oli.Product__c = product.Id;
        }


        //Pricebook2 pricebook = Test_Utils.getPriceBook2();
        //Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
        //insert OLI
        List<OpportunityLineItem> opptyLIs = new List<OpportunityLineItem>();
        opptyLIs.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        opptyLIs.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        insert opptyLIs;

        Royalty__c r1 = Test_Utils.insertRoyalty(true,opptyLIs.get(0).Id);
        r1.Opportunity__c = testOpp.Id;
        update r1;
        for(Order_Line_Item__c oli : olis ){
            oli.Opportunity_Line_Item_Id__c = opptyLIs.get(0).Id;
        }
      }
      delete ida;
      System.runAs(testUser) {
        Test.StartTest();

        String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
        olis.get(0).Type__c = Constants.ORDER_RENEWAL;
        olis.get(0).End_Date__c = Date.today().addDays(10);
        update olis.get(0);
        orders.get(0).RecordTypeId = orderReadOnlyRT_ID;
        update orders.get(0);

        Test.StopTest();

        system.assertEquals(1,[SELECT COUNT() FROM Opportunity WHERE Previous_Opportunity__c = :testOpp.Id]);
        // get the id of the renewal opp...
        Opportunity renOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Previous_Opportunity__c = :testOpp.Id];

        system.assertEquals(1,[SELECT COUNT() FROM Competitor__c WHERE Opportunity__c = :renOpp.Id]);
        system.assertEquals(1,[SELECT COUNT() FROM Royalty__c WHERE Opportunity__c = :renOpp.Id]);

        System.assert(([SELECT Id FROM Opportunity WHERE previous_Order__c = : orders.get(0).id]).size() > 0);

        system.debug([SELECT Id, Name, Order_Line_Item__c FROM Royalty__c]);

        /* PK Commenting out 28/04/15 
        // system.assertEquals(renOpp.OwnerId, testUserB.Id,'Renewal Opp has an incorrect owner :'+renOpp.OwnerId);
        */
      }
    }

    // T-271244: Test method for multi-currency dashboard

    //@isTest(seeAllData = false)
    static void testMultiCurrencyFieldUpdate(){
      //create Account
      Account testAcc = Test_Utils.insertAccount();
      //create Opportunity
      Opportunity testOppty = Test_Utils.createOpportunity(testAcc.Id);
      insert testOppty;
      //create Order
      Order__c testOrder = Test_Utils.createOrder();
      testOrder.CurrencyIsoCode = Constants.CURRENCY_USD;
      testOrder.Opportunity__c = testOppty.Id;
      testOrder.Close_Date__c = Date.today().addDays(7);
      testOrder.Amount_Corp__c = null;
      testOrder.Account__c = testAcc.ID;
      insert testOrder;

      Billing_Product__c billProd = Test_Utils.insertBillingProduct();
      //create Order Line Item
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(true, testOrder.Id, billProd.Id);
      ordrli.CurrencyIsoCode = Constants.CURRENCY_USD;
      update ordrli;

      Test.startTest();
      //update the currency on Order to 'GBP'
      testOrder.CurrencyIsoCode = Constants.CURRENCY_GBP;
      update testOrder;
      //update the currency on Order Line Item to 'GBP'
      ordrli.CurrencyIsoCode = Constants.CURRENCY_GBP;
      update ordrli;
      List<Order__c> resultOrder = [SELECT ID, Close_Date__c, Total__c, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c,CurrencyIsoCode
                               FROM Order__c WHERE Id =:testOrder.Id];

      List<Order_Line_Item__c> rsltOli = [SELECT ID, Start_Date__c, End_Date__c, Total__c, CurrencyIsoCode, Order__c
                                           FROM Order_Line_Item__c WHERE Id =:ordrli.Id AND Order__c =:resultOrder.get(0).Id
                                           LIMIT 1];

      Map<String, DatedConversionRate> dtConvRateMap = new Map<String, DatedConversionRate>();

      for (DatedConversionRate dcr : [SELECT ISOCode, ID, ConversionRate
                                      FROM DatedConversionRate
                                      WHERE StartDate <= NEXT_N_DAYS:7 AND NextStartDate > NEXT_N_DAYS:7]) {
        dtConvRateMap.put(dcr.ISOCode, dcr);
      }
      Decimal D1 = resultOrder.get(0).Total__c;
      Long ordTot = D1.round();

      system.assertEquals(rsltOli.get(0).Total__c, ordTot);
      system.assertEquals(dtConvRateMap.get(Constants.CURRENCY_GBP).ConversionRate, resultOrder.get(0).GBP_Conversion_Rate__c);
      system.assertEquals(dtConvRateMap.get(Constants.CURRENCY_AUD).ConversionRate, resultOrder.get(0).AUD_Conversion_Rate__c);
      system.assertEquals(resultOrder.get(0).Amount_Corp__c, resultOrder.get(0).Total__c / dtConvRateMap.get(Constants.CURRENCY_GBP).ConversionRate);

      //update the currency on Order to 'AUD'
      testOrder.CurrencyIsoCode = Constants.CURRENCY_AUD;
      testOrder.Close_Date__c = Date.today().addDays(8);
      update testOrder;
      //update the currency on Order Line Item to 'AUD'
      ordrli.CurrencyIsoCode = Constants.CURRENCY_AUD;
      update ordrli;

      resultOrder = [SELECT ID, Close_Date__c, GBP_Conversion_Rate__c, AUD_Conversion_Rate__c, Amount_Corp__c, Total__c FROM Order__c WHERE Id =:testOrder.Id];

      Test.stopTest();
      system.assertEquals(resultOrder.get(0).Amount_Corp__c, resultOrder.get(0).Total__c / dtConvRateMap.get('AUD').ConversionRate);

    }

    public static testmethod void testCurrencyIsoOnChildOfOrder(){
      //create Account
      acc = Test_Utils.insertAccount();
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
      //create Order Line Item
      Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(true, ordr.Id, billProd.Id);
      ordrli.CurrencyIsoCode = 'GBP';
      update ordrli;
      //Create users
      User user = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      //Creating Order split
      Order_Split__c orderSplit = new Order_Split__c();
      orderSplit.Credited_To__c = user.ID;
      orderSplit.Order__c = ordr.Id;
      orderSplit.Split_Percentage__c = 40;
      orderSplit.CurrencyIsoCode = Constants.CURRENCY_GBP;
      insert orderSplit;
      //create Order Revenue Schedule
      Order_Revenue_Schedule__c revenue = new Order_Revenue_Schedule__c();
      revenue.CurrencyIsoCode = Constants.CURRENCY_GBP;
      revenue.Order_Line_Item__c = ordrli.Id;
      revenue.Revenue__c = 200;
      insert revenue;

      Test.startTest();
      system.assertEquals(ordrli.CurrencyIsoCode, Constants.CURRENCY_GBP);
      system.assertEquals(orderSplit.CurrencyIsoCode, Constants.CURRENCY_GBP);
      system.assertEquals(revenue.CurrencyIsoCode, Constants.CURRENCY_GBP);

      ordr.CurrencyIsoCode = Constants.CURRENCY_USD;
      update ordr;

      Order_Line_Item__c ordrli1 = [SELECT Id, CurrencyIsoCode From Order_Line_Item__c WHERE ID =:ordrli.Id];
      Order_Split__c ordrsplit = [SELECT Id, CurrencyIsoCode From Order_Split__c WHERE ID =:orderSplit.Id];
      Order_Revenue_Schedule__c ordrRevenue = [SELECT Id, CurrencyIsoCode From Order_Revenue_Schedule__c WHERE Order_Line_Item__c =: ordrli1.ID];

      Test.stopTest();
      system.assertEquals(ordrli1.CurrencyIsoCode, Constants.CURRENCY_USD);
      system.assertEquals(ordrsplit.CurrencyIsoCode, Constants.CURRENCY_USD);
      system.assertEquals(ordrRevenue.CurrencyIsoCode, Constants.CURRENCY_USD);

    }

    public static testmethod void testOwnerFieldUpdates() {

    Test.StartTest();
    //create Account
    acc = Test_Utils.insertAccount();
    //create Contact
    Contact con = new Contact(FirstName = 'Jim', LastName = 'Bond');
    insert con;
    //create User
    Profile prof = [select Id from Profile where Name = 'System Administrator'];
    User user = new User(UserName = 'james@experiantest.com', Email = 'james@test.com', Alias = 'jtest', CommunityNickname = 'jtest1', ProfileId = prof.Id, FirstName = 'James', LastName = 'Test', Region__c = 'EMEA', CurrencyIsoCode = 'USD', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', UserPermissionsMobileUser = false);
    insert user;
    //create Order
    Order__c ordr =  Test_Utils.createOrder();
    ordr.OwnerId = user.Id;
    ordr.CurrencyIsoCode = Constants.CURRENCY_GBP;
    ordr.Account__c = acc.Id;
    ordr.Contact__c = con.Id;
    ordr.Transactional_Sale__c = true;
    ordr.Type__c = 'Renewal';
    insert ordr;

        // Lock Order in order for the Owner fields to be updated
        Order_Lock_WS.lockOrder(ordr.Id);

    Order__c ord = [select Id, Owner_Region_on_Order_Create_Date__c from Order__c where Id =: ordr.Id];
    system.assertEquals(ord.Owner_Region_on_Order_Create_Date__c, 'EMEA');
    Test.StopTest();
    }

    //T-326947: Test method to cechk Oppty Cont Address order populated.
    static testmethod void test_updateOpportunityContactAddresses() {
      // create User
      Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
      User systemUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert systemUser;

      System.runAs(systemUser){
        // insert account
         acc = Test_Utils.insertAccount();
        Contact testContact = Test_Utils.createContact(acc.ID);
        insert testContact;

        // insert opportunity
        Opportunity newOppty = Test_Utils.createOpportunity(acc.Id);
        newOppty.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
        newOppty.Starting_Stage__c = Constants.OPPTY_STAGE_7;
        insert newOppty;

        // start test
        Test.startTest();

          List<Address__c> addressList = new List<Address__c>();
          for (Integer i = 0; i < 10; i++) {
            Address__c addrs = Test_Utils.insertAddress(false);
            addressList.add(addrs);
          }

          insert addressList;
          List<Opportunity_Contact_Address__c> opptyContAddList = new List<Opportunity_Contact_Address__c>();
          for (Integer i = 0; i < 10; i++) {
            Opportunity_Contact_Address__c opConAdrs = new Opportunity_Contact_Address__c();
            opConAdrs.Contact__c = testContact.Id;
            opConAdrs.Opportunity__c = newOppty.Id;
            opConAdrs.Address__c = addressList.get(i).Id;
            opptyContAddList.add(opConAdrs);
          }

          insert opptyContAddList;

          //Create Order (Locked = true, Type=Renewal, Opportunity = aboveOppty)
          Order__c ordr = Test_Utils.createOrder();
          ordr.Opportunity__c = newOppty.Id;
          insert ordr;

         //stop test
         Test.stopTest();

         for (Opportunity_Contact_Address__c oppContAdd : [SELECT ID, Order__c FROM Opportunity_Contact_Address__c
                                                           WHERE Opportunity__c =: newOppty.ID]) {
            System.assertEquals(oppContAdd.Order__c, ordr.ID);
         }
      }
    }


    // Test Data for testrecalculateSegmentOnOrder method  T-376294
    private static void createTestDatatoRecalculateSegment() {
      // create test data
        User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        testUser.Global_Business_Line__c = 'Credit Services';
        testUser.Business_Line__c = 'APAC Credit Services';
        testUser.Region__c = 'APAC';
        testUser.Country__c = 'United States of America';
        insert testUser;

        acc = Test_Utils.insertAccount();

        Contact con = Test_Utils.insertContact(acc.Id);

        Opportunity testOpp1 =  Test_Utils.createOpportunity(acc.Id);
        testOpp1.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp1.Type = Constants.OPPTY_NEW_FROM_NEW;
        testOpp1.OwnerId = testUser.Id;
        testOpp1.Amount = 50;
        insert testOpp1;

        //create some Hierarchy records (one for each: BU, BL, GBL)
        Hierarchy__c gbl = Test_Utils.insertHierarchy(true, null, 'Credit Services', 'Test Global Business Line');
        Hierarchy__c bl = Test_Utils.insertHierarchy(true, gbl.Id, 'APAC Credit Services', 'Test Business Line');
        Hierarchy__c bu = Test_Utils.insertHierarchy(true, bl.Id, 'APAC CS Japan', 'Test Business Unit');
        Hierarchy__c region = Test_Utils.insertHierarchy(true, null, 'APAC', 'Test Region');
        Hierarchy__c country = Test_Utils.insertHierarchy(true, null, 'United States of America', 'Test Country');

     //   Hierarchy__c country1 = Test_Utils.insertHierarchy(true, null, 'Algeria', 'Test Country');

        Account_Segment__c gblAccSeg = Test_Utils.insertAccountSegment(false, acc.Id, gbl.Id, null);
        listAccSegments.add(gblAccSeg);
        Account_Segment__c blAccSeg = Test_Utils.insertAccountSegment(false, acc.Id, bl.Id, null);
        listAccSegments.add(blAccSeg);
        Account_Segment__c buAccSeg = Test_Utils.insertAccountSegment(false, acc.Id, bu.Id, null);
        listAccSegments.add(buAccSeg);
        Account_Segment__c regionAccSeg = Test_Utils.insertAccountSegment(false, acc.Id, region.Id, null);
        listAccSegments.add(regionAccSeg);
        Account_Segment__c countryAccSeg = Test_Utils.insertAccountSegment(false, acc.Id, country.Id, null);
        listAccSegments.add(countryAccSeg);

        insert listAccSegments;
        
        System.debug('listAccSegments::::::: ' + listAccSegments);

        // THIS IS OK only because it is called by a method trying to test the future (recalculation of AS)
        testOrdr = Test_Utils.insertOrder (false, acc.Id , con.Id,testOpp1.Id);
        testOrdr.Segment_Business_Line__c = blAccSeg.Id;
        testOrdr.Segment_Business_Unit__c = buAccSeg.Id;
        testOrdr.Segment_Country__c = countryAccSeg.Id;
        testOrdr.Segment_Global_Business_Line__c = gblAccSeg.Id;
        testOrdr.Segment_Region__c = regionAccSeg.ID;
        testOrdr.Amount_Corp__c = 10;
        testOrdr.RecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
        insert testOrdr;
    }


  //============================================================================
  // T-376294 : Method to test recalculate Segment fields on order
  //============================================================================
    
    @isTest
    public static void testRecalculateAccountSegmentsOnOrderInsert() {

      Test.startTest();
      createTestDatatoRecalculateSegment();
      Test.stopTest();
      for (Account_Segment__c accSeg: [SELECT Id, Total_Won__c
                                       FROM Account_Segment__c
                                       WHERE ID IN :listAccSegments]) {
        System.debug('[\nOrderTriggerHandler_Test: testRecalculateAccountSegmentsOnOrderInsert]' + accSeg);
        System.assertEquals(10, accSeg.Total_Won__c);
      }
    }

  //============================================================================
  // T-376294 : Method to test recalculate Segment fields on order
  //============================================================================
    @isTest
    public static void testRecalculateAccountSegmentsOnOrderUpdate() {
    	Double insertOrdAmount, updateOrdAmount;
    	createTestDatatoRecalculateSegment();
    	List<Account_Segment__c> accSeg = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                              FROM Account_Segment__c 
                                              WHERE Account__c =: acc.ID];
      insertOrdAmount = accSeg[0].Total_Won__c;
      Test.startTest();
      testOrdr.Amount_Corp__c = 100;
      update testOrdr;
      Test.stopTest();
      
      List<Account_Segment__c> accSeg1 = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                        FROM Account_Segment__c 
                                        WHERE Account__c =: acc.ID];
      updateOrdAmount = accSeg1[0].Total_Won__c;
      system.assert(updateOrdAmount > insertOrdAmount);
    }
}