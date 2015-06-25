/******************************************************************************
 * Appirio, Inc
 * Name: OpportunityReopenHelper
 * Description: T-324835: Change Opportunity Process: Custom Opp Button.
 * Created Date: Oct 15th, 2014
 * Created By:  Noopur (Appirio)
 * Date Modified        Modified By                  Description of the update
 * Oct 19, 2014         Nathalie Le Guay (Appirio)   Made running Users EDQ users as this functionality is EDQ-specific
 * Feb 05, 2015         Gaurav Kumar Chadha          T-356440 - Created createTestData to reduce line of code and remove repetitive test data
 * Apr 20, 2015         Arpita Bose                  Updated method test_reopenPostInvoiceOpp() to fix failure
 * Apr 29, 2015         Suminder Singh               Fixed Test class for failures
 * Apr 13th, 2015       Paul Kissick                 Case #607717 Removed seealldata=true
 ******************************************************************************/
@isTest
private class OpportunityReopenHelper_Test {

   static Map<String, TriggerSettings__c> triggerSettingMap ;
   static Opportunity testOpp ;
   static Opportunity testOpp1 ;
   static OpportunityLineItem opportunityLineItem2;
   static Product2 product;

  //==========================================================================
  // Method to set the TriggerSetting custom setting to bypass triggers
  //==========================================================================
   /*static void createTriggerSetting() {
     triggerSettingMap = TriggerSettings__c.getAll();
     List<TriggerSettings__c> tSettingsList = new List<TriggerSettings__c>();
     tSettingsList.add ( fetchTriggerSetting('AccountTrigger') );
     tSettingsList.add ( fetchTriggerSetting('AssetTrigger') );
     tSettingsList.add ( fetchTriggerSetting('OpportunityLineItemTrigger') );
     tSettingsList.add ( fetchTriggerSetting('OrderSplitTrigger') );
     tSettingsList.add ( fetchTriggerSetting('UserTrigger') );
     tSettingsList.add ( fetchTriggerSetting('OrderTrigger') );
     tSettingsList.add ( fetchTriggerSetting('OrderLineItemTrigger') );
     upsert tSettingsList;
   }

  //==========================================================================
  // Set the isActive to false for the TriggerSetting for particular trigger
  //==========================================================================
   static TriggerSettings__c fetchTriggerSetting (String triggerName) {
     TriggerSettings__c tSetting;
      if (triggerSettingMap.containsKey(triggerName)) {
        tSetting = triggerSettingMap.get(triggerName);
      }
      else {
        tsetting = new TriggerSettings__c();
        tsetting.Name = triggerName;
      }
      tsetting.IsActive__c = false;
      return tSetting;
   }*/

  //==========================================================================
  // Method to test and verify the reopenPostInvoiceOpp()
  //==========================================================================
  static testmethod void test_reopenPostInvoiceOpp(){
    IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true); 
    insert ida;
    //createTriggerSetting();
    TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.USER_TRIGGER);
     insertTriggerSettings.IsActive__c = false;
     update insertTriggerSettings;
    Profile p;
    UserRole copsRole;
    User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    List<User> usrList = new List<User>();
    User testUser1;
    User testUser2;
    Record_Type_Ids__c recIds = new Record_Type_Ids__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Opportunity_Standard__c = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get('Standard').getRecordTypeId()
    );
    insert recIds;
    
    Global_Settings__c gs = new Global_Settings__c(Name = Constants.GLOBAL_SETTING,
      Opp_Closed_Lost_Stagename__c = Constants.OPPTY_CLOSED_LOST,
      Opp_Renewal_Probability__c = 30,
      Opp_Renewal_Name_Format__c = 'Renewal - ####',
      Opp_Renewal_StageName__c = Constants.OPPTY_STAGE_3,
      Opp_Renewal_Type__c = Constants.OPPTY_TYPE_RENEWAL,
      Opp_Stage_3_Name__c = Constants.OPPTY_STAGE_3,
      Opp_Stage_4_Name__c = Constants.OPPTY_STAGE_4
    );
    insert gs;

    System.runAs ( thisUser ) {
      p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      copsRole = [SELECT Id FROM UserRole WHERE Name =: Constants.ROLE_NA_COPS];
      testUser1 = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
      testUser2 = Test_Utils.createEDQUser(p, 'test1234@gmail2.com', 'test2');
      testUser1.UserRoleId = copsRole.Id;
      testUser2.UserRoleId = copsRole.Id;
      usrList.add(testUser1);
      usrList.add(testUser2);
      insert usrList;
    }
      System.runAs(testUser1) {
        createTestData();
        
      }
      delete ida;
      OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
      OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
      OpportunityTrigger_OrderHelper.isExecuted = false;
      system.runAs(testUser2) {
      	
      	
      	
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
        testOpp.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        testOpp.Amount = 100;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        //testOpp.Type = Constants.OPPTY_TYPE_CREDITED; ttk
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW; //ttk
        update testOpp;
        
      }
        
      // DELETE ISDATAADMIN
      //delete ida;

      Test.startTest();
      Export_Batch__c testBatch = new Export_Batch__c();
        testBatch.Name = 'testBatch';
        testBatch.CurrencyIsoCode = testOpp.CurrencyIsoCode;
        insert testBatch;
      List<Order__c> ordList = new List<Order__c>();
        /*Order__c ord = new Order__c();
        ord.Opportunity__c = testOpp.Id;
        ord.Credited_Date__c = Date.today(); 
        ord.Type__c = Constants.ORDER_TYPE_CREDITED;
        ord.Finance_Invoice_Export_Batch__c = testBatch.Id;
        ordList.add(ord);*/
        for (Order__c ord2: [select Id,Finance_Invoice_Export_Batch__c from Order__c where Opportunity__c = :testOpp.Id]) {
          ord2.Finance_Invoice_Export_Batch__c = testBatch.Id;
          ord2.Credited_Date__c = null; //TTK
          ord2.Type__c = Constants.ORDER_TYPE_NEW_FROM_NEW; //TTK
          ordList.add(ord2); 
        }
       // system.assertEquals(ordList.size(), 2);
        upsert ordList;
        
        
        System.runAs(testUser1) {
        User currentUser = [select Id,Business_Unit__c from User where Id = :userinfo.getUserId()];
        List<Business_Unit_Group_Mapping__c> buMapping = [select User_Business_Unit__c,Common_Group_Name__c
                                                          from Business_Unit_Group_Mapping__c
                                                          where Common_Group_Name__c = :Constants.EDQ ];
        if ( buMapping.size() > 0 && !String.isBlank(buMapping[0].User_Business_Unit__c)) {
          currentUser.Business_Unit__c = buMapping[0].User_Business_Unit__c;
        }
        else {
          currentUser.Business_Unit__c = 'APAC CS ANZ';
        }
        update currentUser;

        //verify test opportunity stage is stage 7
        system.assert(testOpp.StageName == Constants.OPPTY_STAGE_7); //TTK

        OpportunityTrigger_OrderHelper.isExecuted = false;
        OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
        OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
        OpportunityTriggerHandler.hasRunReopenPostInvoice = false; //TTK
        
        OpportunityReopenHelper.reopenCurrentOpportunity(testOpp.Id);

        Test.stopTest();
        Opportunity testOpp3;
        List<Opportunity> opp = new List<Opportunity>();
        for ( Opportunity oppObj : [SELECT Id, StageName, Type ,Previous_Opportunity__c
                                    FROM Opportunity 
                                    WHERE Id=:testOpp.Id
                                    OR Previous_Opportunity__c = :testOpp.Id]) {
        	if ( oppObj.Id == testOpp.Id) {
        		testOpp3 = oppObj;
        	}
        	else if ( oppObj.Previous_Opportunity__c == testOpp.Id) {
        		opp.add(oppObj);
        	}
        }

        system.assert(testOpp3.StageName == Constants.OPPTY_CLOSED_LOST); //TTK
        system.assert(testOpp3.Type == Constants.OPPTY_TYPE_CREDITED); //TTK

        List<Order__c> orders = new List<Order__c>();
        List<Order__c> credNoteOrders = new List<Order__c>();
        
        for ( Order__c ordObj : [SELECT Id,Credited_Date__c,Opportunity__c,Type__c,Order_to_Credit__c
                              FROM Order__c
                              WHERE Opportunity__c = :testOpp.Id ]) {
        	if( ordObj.Opportunity__c == testOpp.Id  && ordObj.Type__c == Constants.ORDER_TYPE_CREDITED && ordObj.Order_to_Credit__c == null) {
        		orders.add(ordObj);
        	}
        	else if ( ordObj.Opportunity__c == testOpp.Id && ordObj.Order_to_Credit__c != null) {
        		credNoteOrders.add(ordObj);
        	}
        }
        
        system.assert(orders.size() == 1, 'Only 1 order should exist');

        system.assert(orders[0].Type__c == Constants.ORDER_TYPE_CREDITED);
        system.assert(orders[0].Credited_Date__c != null); //ttk
        system.assert(orders[0].Credited_Date__c == Date.today()); //ttk
        system.assertEquals(1, credNoteOrders.size(), 'Only 1 Credit Note order should exist');

        system.assert(opp.size() > 0);
        system.assertEquals(opp[0].StageName ,Constants.OPPTY_STAGE_4);
      }
  }

  //==========================================================================
  // Method to test and verify the reopenPreInvoiceOpp()
  //==========================================================================
  static testmethod void test_reopenPreInvoiceOpp() {
    IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true); 
    insert ida;
    //createTriggerSetting();
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    //UserRole copsRole = [SELECT Id FROM UserRole WHERE Name =: Constants.ROLE_NA_COPS];
    User testUser1 = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    //testUser1.UserRoleId = copsRole.Id;
    insert testUser1;
    Record_Type_Ids__c recIds = new Record_Type_Ids__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Opportunity_Standard__c = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get('Standard').getRecordTypeId()
    );
    insert recIds;
    
    Global_Settings__c gs = new Global_Settings__c(Name = 'Global',
      Opp_Closed_Lost_Stagename__c = Constants.OPPTY_CLOSED_LOST,
      Opp_Renewal_Probability__c = 30,
      Opp_Renewal_Name_Format__c = 'Renewal - ####',
      Opp_Renewal_StageName__c = Constants.OPPTY_STAGE_3,
      Opp_Renewal_Type__c = Constants.OPPTY_TYPE_RENEWAL,
      Opp_Stage_3_Name__c = Constants.OPPTY_STAGE_3,
      Opp_Stage_4_Name__c = Constants.OPPTY_STAGE_4
    );
    insert gs;

    System.runAs(testUser1) {

    createTestData();
        testOpp.StageName = Constants.OPPTY_STAGE_7;
        //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
        testOpp.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
        testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        testOpp.Amount = 100;
        testOpp.Has_Senior_Approval__c = true;
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.CloseDate = date.today();
        testOpp.Contract_Start_Date__c = date.today().addDays(1);
        testOpp.Contract_End_Date__c = date.today().addYears(1);
        update testOpp;
        
        // DELETE ISDATAADMIN
        delete ida;

        Test.startTest();

        OpportunityReopenHelper.reopenCurrentOpportunity(testOpp.Id);

        Test.stopTest();

        List<Opportunity> opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
        List<Asset> assetObj = [SELECT Id, Order_Line__r.Opportunity_Line_Item_Id__c,
                                     Order_Line__r.Order__c, Order_Line__c, Cancellation_Date__c ,
                                     Order_Line__r.Order__r.Opportunity__r.Id
                              FROM Asset
                              WHERE Opportunity__c = :testOpp.Id];
        if ( assetObj.size() > 0 ) {
          system.assert(assetObj[0].Cancellation_Date__c == Date.today());
          system.assertEquals(opp[0].StageName, Constants.OPPTY_STAGE_4);
        }

      }
  }

  //==========================================================================
  // Method to test and verify the reopenPostInvoiceOpp()
  //==========================================================================
  static testmethod void test_ForExceptionCoverage() {
    IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true);
    insert ida;
    //createTriggerSetting();
    // Create an account
    Account testAccount = Test_Utils.insertAccount();
    Address__c addrs1 = Test_Utils.insertAddress(true);
    //insert account address
    Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);
    // Create an opportunity
    testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    insert testOpp;
    testOpp1 = Test_Utils.createOpportunity(testAccount.Id);
    testOpp1.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    insert testOpp1;
    OpportunityReopenHelper.reopenCurrentOpportunity(testOpp.Id);

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                           AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;
    Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, newcontact.Id);
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);
    Test_Utils.insertEDQOpportunityContactRoles(testOpp.Id, newContact.Id);
    testOpp.StageName = Constants.OPPTY_STAGE_7;
    //testOpp.Status__c = Constants.OPPTY_CLOSED_WON;
    testOpp.Primary_Reason_W_L__c = constants.PRIMARY_REASON_WLC_DATA_QUALITY;
    testOpp.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    testOpp.Amount = 100;
    testOpp.Has_Senior_Approval__c = true;
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.CloseDate = date.today();
    testOpp.Contract_Start_Date__c = date.today().addDays(1);
    testOpp.Contract_End_Date__c = date.today().addYears(1);
    testOpp.Previous_Opportunity__c = testOpp1.Id;
    update testOpp;

    // DELETE ISDATAADMIN
    delete ida;
    
    Test.startTest();
    try {

      OpportunityReopenHelper.reopenCurrentOpportunity(testOpp.Id);
    }
    catch (Exception ex) {
      System.assert(!String.isBlank(ex.getMessage()));
    }
    Test.stopTest();
  }

   //============================================================================
   // test method for creating test data to be used in various test methods
   //============================================================================
   static void createTestData() {
   	
   	
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
     
     
     // Create an account
    Account testAccount = Test_Utils.insertAccount();
    //Test.startTest();
    Address__c addrs1 = Test_Utils.insertAddress(true);
    //insert account address
    Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, testAccount.Id);    
    // Create an opportunity
    testOpp = Test_Utils.createOpportunity(testAccount.Id);
    testOpp1 = Test_Utils.createOpportunity(testAccount.Id);
    testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    testOpp.Type = 'New From New';
    
    insert testOpp;

    Test_Utils.createOpptyTasks(testOpp.Id, true);

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                       AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;
    Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, Test_Utils.insertAddress(true).Id, newcontact.Id);

    List<Opportunity_Contact_Address__c> oppConAdds = new List<Opportunity_Contact_Address__c>();
    Opportunity_Contact_Address__c oppConAdd = new Opportunity_Contact_Address__c();
    oppConAdd.Opportunity__c= testOpp.Id ;
    oppConAdd.Address__c = conAdd.Address__c;
    oppConAdd.Contact__c = newcontact.Id;
    oppConAdd.Role__c = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER;
    oppConAdds.add( oppConAdd);

    Opportunity_Contact_Address__c oppConAdd1 = new Opportunity_Contact_Address__c();
    oppConAdd1.Opportunity__c= testOpp.Id ;
    oppConAdd1.Address__c = conAdd.Address__c;
    oppConAdd1.Contact__c = newcontact.Id;
    oppConAdd1.Role__c = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL;
    oppConAdds.add( oppConAdd1);

    Opportunity_Contact_Address__c oppConAdd2 = new Opportunity_Contact_Address__c();
    oppConAdd2.Opportunity__c= testOpp.Id ;
    oppConAdd2.Address__c = conAdd.Address__c;
    oppConAdd2.Contact__c = newcontact.Id;
    oppConAdd2.Role__c = Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL;
    oppConAdds.add( oppConAdd2);

    Opportunity_Contact_Address__c oppConAdd3 = new Opportunity_Contact_Address__c();
    oppConAdd3.Opportunity__c= testOpp.Id ;
    oppConAdd3.Address__c = conAdd.Address__c;
    oppConAdd3.Contact__c = newcontact.Id;
    oppConAdd3.Role__c = Constants.OPPTY_CONTACT_ROLE_RENEWAL;
    oppConAdds.add( oppConAdd3);

    Opportunity_Contact_Address__c oppConAdd4 = new Opportunity_Contact_Address__c();
    oppConAdd4.Opportunity__c= testOpp.Id ;
    oppConAdd4.Address__c = conAdd.Address__c;
    oppConAdd4.Contact__c = newcontact.Id;
    oppConAdd4.Role__c = Constants.OPPTY_CONTACT_ROLE_SHIPTO;
    oppConAdds.add( oppConAdd4);

    Opportunity_Contact_Address__c oppConAdd5 = new Opportunity_Contact_Address__c();
    oppConAdd5.Opportunity__c= testOpp.Id ;
    oppConAdd5.Address__c = conAdd.Address__c;
    oppConAdd5.Contact__c = newcontact.Id;
    oppConAdd5.Role__c = Constants.OPPTY_CONTACT_ROLE_UPDATE;
    oppConAdds.add( oppConAdd5);

    insert oppConAdds;

    Test_Utils.insertEDQOpportunityContactRoles(testOpp.Id, newContact.Id);
    //OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, testOpp.Id, newcontact.Id, Constants.DECIDER, true);

    // Create Opportunity Line Item
    product = Test_Utils.insertProduct();
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
    opportunityLineItem2 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
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
    insert opptySchedules;

    Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
    insert comp;
  }

}