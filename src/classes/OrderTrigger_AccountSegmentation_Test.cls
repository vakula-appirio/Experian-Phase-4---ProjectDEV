/*******************************************************************************
 * Appirio, Inc
 * Name         : OrderTrigger_AccountSegmentation_Test
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Test class of class "OrderTrigger_AccountSegmentation"
 * Created Date : April 07th, 2015
 *
 * Date Modified                Modified By         Description of the update
 * 15th Apr, 2015               Suminder Singh      T-378086: added methnod segmentCalculationPopulateOnOrderDelete_Test()
                                                    Delete and Undelete order test Unit
*******************************************************************************/

@isTest (seeAllData = false)
private class OrderTrigger_AccountSegmentation_Test {

  private static Account testAccount;
  private static Opportunity testOpportunity;
  //===========================================================================
  // Account Segmentation: Insert order test Unit
  //===========================================================================
  @isTest 
  static void segmentFieldPopulateOnOrderInsert_Test() {
    //Creating Hierarchy records
    createHierarchies();

       //fetching profile Id of system admin
    Profile p = [SELECT id from profile where name =: 'System Administrator' ];
    //creating user with all necessary values for our use case like Bussiness Unit, Business Line, + 3
    User usr = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                  emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                  localesidkey='en_US', profileid = p.ID, timezonesidkey='America/Los_Angeles', 
                  username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true, 
                  CompanyName = 'test Company', Business_Line__c = 'APAC Corporate', 
                  Business_Unit__c = 'APAC Corporate Finance', Global_Business_Line__c = 'Corporate', 
                  Country__c = 'India', Region__c = 'Global');
    
    Order__c testOrder;
    system.runAs(usr) {
      // Create Account
        Account testAcc = Test_Utils.insertAccount();
        
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAcc.ID);
        insert testOpp;

        //Create a Contact
        Contact testCon = Test_Utils.insertContact(testAcc.ID);

        //Create an Order
        testOrder = Test_Utils.insertOrder(true, testAcc.ID, testCon.ID, testOpp.ID);
      } //End system.runAs(usr) {

      //Quering inserted Order for assert check 
      Order__c odr = [SELECT Id, Owner_Business_Line__c, Owner_Business_Unit__c,
                Owner_Global_Business_Line__c, Owner_Country__c, Owner_Region__c
                             FROM Order__c WHERE Id =: testOrder.Id];

      system.assertEquals(usr.Business_Line__c, odr.Owner_Business_Line__c);
      system.assertEquals(usr.Business_Unit__c, odr.Owner_Business_Unit__c);
      system.assertEquals(usr.Global_Business_Line__c, odr.Owner_Global_Business_Line__c);
      system.assertEquals(usr.Country__c, odr.Owner_Country__c);
      system.assertEquals(usr.Region__c, odr.Owner_Region__c);
  } //End static void test_method_one() {
  
  //===========================================================================
  // Account Segmentation: Update order test Unit
  //===========================================================================
  @isTest 
  static void segmentFieldPopulateOnOrderUpdate_Test() {
    //fetching profile Id of system admin
    Id readOnlyRTid = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    createHierarchies();
    
    Profile p = [SELECT id from profile where name =: 'System Administrator' ];
    //creating user with all necessary values for our use case like Bussiness Unit, Business Line, + 3
    User usr = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                  emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                  localesidkey='en_GB', profileid = p.ID, timezonesidkey='Europe/London', 
                  username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true, 
                  CompanyName = 'test Company', Business_Line__c = 'APAC Corporate', 
                  Business_Unit__c = 'APAC Corporate Finance', Global_Business_Line__c = 'Corporate', 
                  Country__c = 'India', Region__c = 'Global', CurrencyIsoCode='USD');

    Order__c testOrder;
    Order__c odrToUpdate;
    Account testAcc;
    Double insertOrdAmount, updateOrdAmount;
    system.runAs(usr) {
      // Create Account
        testAcc = Test_Utils.insertAccount();
        
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAcc.ID);
        testOpp.Amount_Corp__c = 1000;
        insert testOpp;

        //Create a Contact
        Contact testCon = Test_Utils.insertContact(testAcc.ID);

        //Create an Order
        testOrder = Test_Utils.insertOrder(false, testAcc.ID, testCon.ID, testOpp.ID);
        testOrder.Amount_Corp__c = 1050;
        testOrder.CurrencyIsoCode = 'USD';
        testOrder.RecordTypeId = readOnlyRTid;
        testOrder.Owner_GBL_on_Order_Create_Date__c = 'Corporate';
        testOrder.Owner_BL_on_Order_Create_Date__c = 'APAC Corporate';
        testOrder.Owner_BU_on_Order_Create_Date__c = 'APAC Corporate Finance';
        testOrder.Owner_Region_on_Order_Create_Date__c = 'Global';
        testOrder.Owner_Country_on_Order_Create_Date__c = 'India';
        
        OrderTriggerHandler.hasRunAccountSegmentation = false;
        OrderTrigger_AccountSegmentation.hasRunBatch = false;
        
        insert testOrder;

        //Updating Order
        odrToUpdate = [SELECT Id, Contract_Start_Date__c, Contract_End_Date__c, Amount_Corp__c
                       FROM Order__c 
                       WHERE Id =: testOrder.Id];
          odrToUpdate.Contract_Start_Date__c = Date.Today()+5;
          odrToUpdate.Contract_End_Date__c = Date.Today()+5;
          List<Account_Segment__c> accSeg = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                              FROM Account_Segment__c 
                                              WHERE Account__c =: testAcc.ID];
          insertOrdAmount = accSeg[0].Total_Won__c;
          odrToUpdate.Amount_Corp__c = 2050;
          Test.startTest();
          OrderTrigger_AccountSegmentation.hasRunBatch = false;
          OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
          OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
          OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
          OrderLineItemTriggerHandler.hasRunAssetCreation = false;
          OrderLineItemTriggerHandler.hasRunMemoline = false;  
          OpportunityTrigger_OrderHelper.isExecuted = false;
          OrderTriggerHandler.hasRunAccountSegmentation = false;
          update odrToUpdate;
          Test.stopTest();
      } //End system.runAs(usr) {

      //Quering inserted Order for assert check 
      Order__c odr = [SELECT Id, Owner_Business_Line__c, Owner_Business_Unit__c,
                              Owner_Global_Business_Line__c, Owner_Country__c, Owner_Region__c,
                              Segment_Business_Unit__r.Name, Segment_Global_Business_Line__r.Name, 
                              Segment_Country__r.Name, Segment_Region__r.Name, Segment_Business_Line__r.Name
                      FROM Order__c WHERE Id =: odrToUpdate.Id];
      system.assertEquals(true, odr.Segment_Business_Line__r.Name.containsIgnoreCase(usr.Business_Line__c));
      system.assertEquals(true, odr.Segment_Business_Unit__r.Name.containsIgnoreCase(usr.Business_Unit__c));
      system.assertEquals(true, odr.Segment_Global_Business_Line__r.Name.containsIgnoreCase(usr.Global_Business_Line__c));
      system.assertEquals(true, odr.Segment_Country__r.Name.containsIgnoreCase(usr.Country__c));
      system.assertEquals(true, odr.Segment_Region__r.Name.containsIgnoreCase(usr.Region__c));

      system.assertEquals(true, odr.Segment_Business_Line__r.Name.contains(odr.Owner_Business_Line__c));
      system.assertEquals(true, odr.Segment_Business_Unit__r.Name.contains(odr.Owner_Business_Unit__c));
      system.assertEquals(true, odr.Segment_Global_Business_Line__r.Name.contains(odr.Owner_Global_Business_Line__c));
      system.assertEquals(true, odr.Segment_Country__r.Name.contains(odr.Owner_Country__c));
      system.assertEquals(true, odr.Segment_Region__r.Name.contains(odr.Owner_Region__c));

      List<Account_Segment__c> accSeg1 = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                        FROM Account_Segment__c 
                                        WHERE Account__c =: testAcc.ID];
      updateOrdAmount = accSeg1[0].Total_Won__c;
     system.assert(updateOrdAmount > insertOrdAmount);
  } //End static void test_method_two() {

  //===========================================================================
  // T-378086: Account Segmentation: Delete and Undelete order test Unit
  //===========================================================================
  static testMethod void segmentCalculationPopulateOnOrderDelete_Test() {
    //Creating Hierarchy records
    createHierarchies();

       //fetching profile Id of system admin
    Profile p = [SELECT id from profile where name =: 'System Administrator' ];
    //creating user with all necessary values for our use case like Bussiness Unit, Business Line, + 3
    User usr = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                  emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                  localesidkey='en_US', profileid = p.ID, timezonesidkey='America/Los_Angeles', 
                  username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true, 
                  CompanyName = 'test Company', Business_Line__c = 'APAC Corporate', 
                  Business_Unit__c = 'APAC Corporate Finance', Global_Business_Line__c = 'Corporate', 
                  Country__c = 'India', Region__c = 'Global');
    Account testAcc;
    Order__c testOrder;
    system.runAs(usr) {
      // Create Account
        testAcc = Test_Utils.insertAccount();
        Id readOnlyRTid = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAcc.ID);
        testOpp.Amount_Corp__c = 2000;
        insert testOpp;
        //Create a Contact
        Contact testCon = Test_Utils.insertContact(testAcc.ID);
        
        //Create an Order
        testOrder = Test_Utils.insertOrder(false, testAcc.ID, testCon.ID, testOpp.ID);
        testOrder.Amount_Corp__c = 1050;
        testOrder.RecordTypeId = readOnlyRTid;
        testOrder.Owner_GBL_on_Order_Create_Date__c = 'Corporate';
        testOrder.Owner_BL_on_Order_Create_Date__c = 'APAC Corporate';
        testOrder.Owner_BU_on_Order_Create_Date__c = 'APAC Corporate Finance';
        testOrder.Owner_Region_on_Order_Create_Date__c = 'Global';
        testOrder.Owner_Country_on_Order_Create_Date__c = 'India'; 
        insert testOrder;
        
        Test.startTest();
        OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
        OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
        OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
        OrderLineItemTriggerHandler.hasRunAssetCreation = false;
        OrderLineItemTriggerHandler.hasRunMemoline = false;
        OpportunityTrigger_OrderHelper.isExecuted = false;
        OrderTriggerHandler.hasRunAccountSegmentation = false;
        //update testOpp;
        delete testOrder;
      
         //List to check total won and total pipeline segment amount
         List<Account_Segment__c> accSeg = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                            FROM Account_Segment__c 
                                            WHERE Account__c =: testAcc.ID];
         System.assertEquals(0, accSeg[0].Total_Won__c) ;
         
         OpportunityTriggerHandler.isRunningOpportunityTrigger =  true;
         OpportunityTriggerHandler.isAfterUpdateTriggerExecuted = false;
         OpportunityTriggerHandler.isBeforeUpdateTriggerExecuted = false;
         OrderLineItemTriggerHandler.hasRunAssetCreation = false;
         OrderLineItemTriggerHandler.hasRunMemoline = false; 
         OpportunityTrigger_OrderHelper.isExecuted = false;
         OrderTriggerHandler.hasRunAccountSegmentation = false;
         //Insert order to check undelete functionality on order undelete
          undelete testOrder;
         Test.stopTest();
         
     } //End system.runAs(usr) {
     List<Account_Segment__c> accSeg1 = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                        FROM Account_Segment__c 
                                        WHERE Account__c =: testAcc.ID];
     System.assertEquals(1050, accSeg1[0].Total_Won__c);
  } //End static void test_method_one() {

  private static void createHierarchies() {
        List<Hierarchy__c> lstHierarchy = new List<Hierarchy__c>();
     Hierarchy__c hierarchy_BusinessUnit = 
     Test_Utils.insertHierarchy(false, null, 'APAC Corporate Finance', 'Business Unit');
     lstHierarchy.add(hierarchy_BusinessUnit);
     Hierarchy__c hierarchy_BusinessLine = 
     Test_Utils.insertHierarchy(false, null, 'APAC Corporate', 'Business Line');
     lstHierarchy.add(hierarchy_BusinessLine);
     Hierarchy__c hierarchy_Country = 
     Test_Utils.insertHierarchy(false, null, 'India', 'Country');
     lstHierarchy.add(hierarchy_Country);
     Hierarchy__c hierarchy_GlobalBusinessLine = 
     Test_Utils.insertHierarchy(false, null, 'Corporate', 'Global Business Line');
     lstHierarchy.add(hierarchy_GlobalBusinessLine);
     Hierarchy__c hierarchy_Region = 
     Test_Utils.insertHierarchy(false, null, 'Global', 'Region');
     lstHierarchy.add(hierarchy_Region);
     insert lstHierarchy;    //insertion of hierarchy records
  }

} //End private class OrderTrigger_AccountSegmentation_Test