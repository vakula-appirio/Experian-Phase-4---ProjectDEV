/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentationHelper_Test
 * Description: T-372668: Account Segmentation: @Future utility method
 *
 * Created Date: March 24th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By           Description of the update
 * 3rd, Apr 2015            Noopur                Added the method testForOppUpdate() to verify the
 *                                                Account Segment record update on update of Opportunity.
 * 10th, Apr 2015      Suminder Singh      Fixed test class failures and improved test coverage
 * 13th, Apr 2015      Suminder Singh      T-377400: Added unit test method testForOppDelete() for Opp Delete
 ======================================================================*/
@isTest (seeAllData = false)
private class AccountSegmentationHelper_Test {

  static Account_Segment__c accSeg1,accSeg2,accSeg3,accSeg4,accSeg5;
  static Contact newcontact;

  //===========================================================================
  // This will test the @future method
  // In this test scenario, the test data was created with triggers turned off.
  // As a result, the automation to populate the Opportunity's Segment* fields
  // based on the owner's values did not kick in. In this test we don't have
  // all the opp's Segment* fields populated
  // Amounts are calculated based on which opportunity the Account Segment
  // belongs to
  //===========================================================================
  private static Set<String> segments = new Set<String>{'test-BU','test-BL','test-GBL','test-Country','test-Region'};
  static testMethod void basicTest() {


    Test.startTest();
    AccountSegmentationUtility.segmentationMaintenance(segments, null);
    Test.stopTest();

    for ( Account_Segment__c accSeg : [SELECT Id, Total_Open_Pipeline__c, Total_Won__c, Value__c, Type__c
                                      FROM Account_Segment__c
                                      WHERE Value__c IN :segments] ) {
      if (accSeg.Value__c == 'test-BU') {
        system.assertEquals(850, accSeg.Total_Open_Pipeline__c);
        system.assertEquals(100, accSeg.Total_Won__c);
      }
      if (accSeg.Value__c == 'test-GBL') {
        system.assertEquals(50, accSeg.Total_Open_Pipeline__c);
        system.assertEquals(100, accSeg.Total_Won__c);
      }
      if (accSeg.Value__c == 'test-BL') {
        system.assertEquals(1850, accSeg.Total_Open_Pipeline__c);
        system.assertEquals(100, accSeg.Total_Won__c);
      }
      if (accSeg.Value__c == 'test-Region') {
        system.assertEquals(110, accSeg.Total_Open_Pipeline__c);
        system.assertEquals(100, accSeg.Total_Won__c);
      }
      if (accSeg.Value__c == 'test-Country') {
        system.assertEquals(260, accSeg.Total_Open_Pipeline__c);
        // Our order2 does not have the Segment_Country__c populated
        system.assertEquals(0, accSeg.Total_Won__c);
      }
    }
  }

    //===========================================================================
    // Method to check if the opp is deleted then the related
    // segment is also updated
    //===========================================================================
    static testMethod void testForOppDelete() {

      // This will populate the rollups
      AccountSegmentationUtility.segmentationMaintenance(segments, null);

      Test.StartTest();

      Opportunity oppTest = [SELECT Id, StageName, Channel_Type__c, Amount, Has_Senior_Approval__c, Type,
                                    Starting_Stage__c, CloseDate, Contract_Start_Date__c, Contract_End_Date__c,
                                    Amount_Corp__c,Segment_Business_Line__c,Segment_Business_Unit__c,
                                    Segment_Global_Business_Line__c,Segment_Region__c,Segment_Country__c
                             FROM Opportunity
                             WHERE Name = 'this opp to test delete as well'];


      /*Double oppAmountCorpTotal = 0.0;
      for (Opportunity opp: accSegment.Opportunities_Business_Lines__r) {
        oppAmountCorpTotal += opp.Amount_Corp__c;
      }

      System.assertEquals(oppAmountCorpTotal, accSegment.Total_Open_Pipeline__c);*/

      //Test.startTest();
      delete oppTest;
      // Need to stop test here as segmentationMaintenance is an @future method
      Test.StopTest();


      Decimal amountDeducted = oppTest.Amount_Corp__c;
      System.assertEquals(1000, amountDeducted);
      Decimal originalAccountSegmentAmount = 1850; // Is verified in basicTest()

      Account_Segment__c accSegment = [SELECT Id, Total_Open_Pipeline__c, Total_Won__c, Value__c,
                                              (SELECT Id, Amount_Corp__c FROM Opportunities_Business_Lines__r WHERE IsClosed = false)
                                      FROM Account_Segment__c
                                      WHERE Value__c = 'test-BL'];

      Double expectedNewAmount = originalAccountSegmentAmount - amountDeducted;

      for( Account_Segment__c accSeg : [SELECT Id, Total_Open_Pipeline__c, Total_Won__c, Segment__r.Value__c
                                        FROM Account_Segment__c
                                        WHERE Segment__r.Value__c = 'test-BL'] ) {
        system.assertEquals(expectedNewAmount,  accSeg.Total_Open_Pipeline__c);
      }
    }

    //===========================================================================
    // Method to check if the order is deleted then the related
    // segment is also updated
    //===========================================================================
   static testMethod void testForOrderDelete() {

      Test.startTest();

      Double expectedNewAmount;
      Order__c ordr = [SELECT Id, Total__c, Segment_Global_Business_Line__c,
                              Segment_Business_Line__c, Segment_Business_Unit__c,
                              Segment_Region__c, Segment_Country__c FROM Order__c 
                       WHERE RecordType.Name = :Constants.READ_ONLY];

      Set<Id> accSegmentIds = new Set<Id>();
      accSegmentIds.add(ordr.Segment_Global_Business_Line__c);
      accSegmentIds.add(ordr.Segment_Business_Line__c);
      accSegmentIds.add(ordr.Segment_Business_Unit__c);
      accSegmentIds.add(ordr.Segment_Region__c);
      accSegmentIds.add(ordr.Segment_Country__c);
      AccountSegmentationUtility.segmentationMaintenance(segments, null);


      // When an order is deleted, the Amount_Corp__c should be deducted from the Account
      // Segment Total_Won__c. We cannot verify the original Total_Won__c amount, because it
      // also calls a @future method; however, it is verified in basicTest()
      delete ordr;

      Test.stopTest();

      List<Account_Segment__c> accountSegments = [SELECT Id, Total_Open_Pipeline__c, Total_Won__c
                                       FROM Account_Segment__c
                                       WHERE Id IN :accSegmentIds];
      // The order has been tied to 4 account segments in the createData() method.
      // Country was omitted. This is verified in basicTest()
      system.assertEquals(4, accountSegments.size());

      for (Account_Segment__c accSegment: accountSegments) {
        // This is == 0 because there was only 1 order created
        // Any Account Segment that was tied to the Order should have its Total_Won__c decreased
        system.assertEquals(0, accSegment.Total_Won__c);
      }

    }

    //===========================================================================
    // Method to check if the opp Segment field is updated then the related
    // segment is also updated
    //===========================================================================
    static testMethod void testForOppUpdate() {

      Opportunity opp5 = [SELECT Id, OwnerId, StageName, Channel_Type__c, Amount, Has_Senior_Approval__c, Type,
                                 Starting_Stage__c, CloseDate, Contract_Start_Date__c, Contract_End_Date__c,
                                 Segment_Global_Business_Line__c,Segment_Business_Line__c,Segment_Business_Unit__c,
                                 Segment_Region__c
                          FROM Opportunity
                          WHERE Name = 'testForOppUpdate'];

      Test.startTest();

      // Preparing the opp for a closing
      opp5.StageName = Constants.OPPTY_STAGE_7;
      opp5.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
      opp5.Amount = 100;
      opp5.Has_Senior_Approval__c = true;
      opp5.CloseDate = date.today();
      opp5.Contract_Start_Date__c = date.today().addDays(1);
      opp5.Contract_End_Date__c = date.today().addYears(1);
      update opp5;
      Test.stopTest();

      opp5 = [SELECT Id, StageName, OwnerId, Channel_Type__c, Amount, Has_Senior_Approval__c, Type,
                                 Starting_Stage__c, CloseDate, Contract_Start_Date__c, Contract_End_Date__c,
                                 Segment_Global_Business_Line__c,Segment_Business_Line__c,Segment_Business_Unit__c,
                                 Segment_Region__c, Segment_Country__c, Owner_GBL_on_Opp_Close_Date__c,
                                 Owner_BL_on_Opp_Close_Date__c, Owner_BU_on_Opp_Close_Date__c,
                                 Owner_Region_on_Opp_Close_Date__c, Owner_Country_on_Opp_Close_Date__c
                          FROM Opportunity
                          WHERE Id = : opp5.Id];
      // Since the Opp is closed/won, we will have those fields populated
      System.assertEquals(true, opp5.Owner_GBL_on_Opp_Close_Date__c != null, 'Owner_GBL_on_Opp_Close_Date__c should be populated');
      System.assertEquals(true, opp5.Owner_BL_on_Opp_Close_Date__c != null, 'Owner_BL_on_Opp_Close_Date__c should be populated');
      System.assertEquals(true, opp5.Owner_BU_on_Opp_Close_Date__c != null, 'Owner_BU_on_Opp_Close_Date__c should be populated');
      System.assertEquals(true, opp5.Owner_Region_on_Opp_Close_Date__c != null, 'Owner_Region_on_Opp_Close_Date__c should be populated');
      System.assertEquals(true, opp5.Owner_Country_on_Opp_Close_Date__c != null, 'Owner_Country_on_Opp_Close_Date__c should be populated');

      // Note: Those fields are populated from the Owner_* fields, since this opp is now closed/won
      System.assertEquals(true, opp5.Segment_Global_Business_Line__c != null, 'Segment_Global_Business_Line__c should be populated');
      System.assertEquals(true, opp5.Segment_Business_Line__c != null, 'Segment_Business_Line__c should be populated');
      System.assertEquals(true, opp5.Segment_Business_Unit__c != null, 'Segment_Business_Unit__c should be populated');
      System.assertEquals(true, opp5.Segment_Region__c != null, 'Segment_Region__c should be populated');
      System.assertEquals(true, opp5.Segment_Country__c != null, 'Segment_Country__c should be populated');

      Set<Id> accSegmentIds = new Set<Id>();
      accSegmentIds.add(opp5.Segment_Global_Business_Line__c);
      accSegmentIds.add(opp5.Segment_Global_Business_Line__c);
      accSegmentIds.add(opp5.Segment_Business_Unit__c);
      accSegmentIds.add(opp5.Segment_Business_Unit__c);
      accSegmentIds.add(opp5.Segment_Business_Unit__c);

      // When Renewal opp is close/won, a new Order is generated
      //System.assertEquals(2, [SELECT Id FROM Order__c].size(), 'There should now be 2 orders in the database, now that the opp closed.');

      for ( Account_Segment__c accSeg : [SELECT Id, Total_Open_Pipeline__c, Total_Won__c
                                        FROM Account_Segment__c
                                        WHERE Id in :accSegmentIds] ) {
        if (accSeg.Id != opp5.Segment_Country__c) {
          system.assertEquals(true, accSeg.Total_Won__c > 0);
        }
        if (accSeg.Id == opp5.Segment_Country__c) {
          system.assertEquals(100, accSeg.Total_Won__c, 'Won amount should be 100 for the Country Account Segment');
        }
      }
    }
  
  static testMethod void testForUserUpdate() {
  	User testUser = [SELECT Id,Country__c,Business_Line__c,Business_Unit__c,Region__c,Global_Business_Line__c
  	                 FROM User
  	                 Where FirstName = 'testing User For AccSegment'];
    testUser.Country__c = 'test-Country2';
	  testUser.Business_Line__c = 'test-BL2';
	  testUser.Business_Unit__c = 'test-BU2';
	  testUser.Region__c = 'test-Region2';
	  testUser.Global_Business_Line__c = 'test-GBL2';
    update testUser;
    
    List<Opportunity> oppsList = [SELECT Id,OwnerId,Segment_Country__c,
                                         Segment_Country__r.Value__c 
                                  FROM Opportunity
                                  WHERE OwnerId = :testUser.Id]; 
    system.assertEquals(oppsList[0].Segment_Country__r.Value__c , 'test-Country2');
  }

  @testSetup
  static void createData () {
  IsDataAdmin__c ida = new IsDataAdmin__c(SetupOwnerId = Userinfo.getOrganizationId(), IsDataAdmin__c = true);
  insert ida;
  User newUsr = Test_Utils.createUser('System Administrator');
  newUsr.FirstName = 'testing User For AccSegment';
  newUsr.Country__c = 'test-Country';
  newUsr.Business_Line__c = 'test-BL';
  newUsr.Business_Unit__c = 'test-BU';
  newUsr.Region__c = 'test-Region';
  newUsr.Global_Business_Line__c = 'test-GBL';
  newUsr.CPQ_User_Type__c = 'CPQ Admin';
  insert newUsr;
    List<Account> accList = new List<Account>();
    Account acc = Test_Utils.createAccount();
    accList.add(acc);
    Account acc2 = Test_Utils.createAccount();
    accList.add(acc2);
    insert accList;

     List<Hierarchy__c> listHierarchies = new List<Hierarchy__c>();
     Hierarchy__c hierarchy_BusinessUnit = Test_Utils.insertHierarchy(false, null, 'test-BU', 'Business Unit');
     hierarchy_BusinessUnit.Name = hierarchy_BusinessUnit.Type__c + '-' + hierarchy_BusinessUnit.Value__c; // WF is turned off
     hierarchy_BusinessUnit.Unique_Key__c = hierarchy_BusinessUnit.Type__c + '-' + hierarchy_BusinessUnit.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_BusinessUnit);
     Hierarchy__c hierarchy_BusinessLine = Test_Utils.insertHierarchy(false, null, 'test-BL', 'Business Line');
     hierarchy_BusinessLine.Name = hierarchy_BusinessLine.Type__c + '-' + hierarchy_BusinessLine.Value__c; // WF is turned off
     hierarchy_BusinessLine.Unique_Key__c = hierarchy_BusinessLine.Type__c + '-' + hierarchy_BusinessLine.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_BusinessLine);
     Hierarchy__c hierarchy_Country = Test_Utils.insertHierarchy(false, null, 'test-Country', 'Country');
     hierarchy_Country.Name = hierarchy_Country.Type__c + '-' + hierarchy_Country.Value__c; // WF is turned off
     hierarchy_Country.Unique_Key__c = hierarchy_Country.Type__c + '-' + hierarchy_Country.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_Country);
     Hierarchy__c hierarchy_GlobalBusinessLine = Test_Utils.insertHierarchy(false, null, 'test-GBL', 'Global Business Line');
     hierarchy_GlobalBusinessLine.Name = hierarchy_GlobalBusinessLine.Type__c + '-' + hierarchy_GlobalBusinessLine.Value__c; // WF is turned off
     hierarchy_GlobalBusinessLine.Unique_Key__c = hierarchy_GlobalBusinessLine.Type__c + '-' + hierarchy_GlobalBusinessLine.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_GlobalBusinessLine);
     Hierarchy__c hierarchy_Region = Test_Utils.insertHierarchy(false, null, 'test-Region', 'Region');
     hierarchy_Region.Name = hierarchy_Region.Type__c + '-' + hierarchy_Region.Value__c; // WF is turned off
     hierarchy_Region.Unique_Key__c = hierarchy_Region.Type__c + '-' + hierarchy_Region.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_Region);
     
     Hierarchy__c hierarchy_BusinessUnit2 = Test_Utils.insertHierarchy(false, null, 'test-BU2', 'Business Unit');
     hierarchy_BusinessUnit2.Name = hierarchy_BusinessUnit2.Type__c + '-' + hierarchy_BusinessUnit2.Value__c; // WF is turned off
     hierarchy_BusinessUnit2.Unique_Key__c = hierarchy_BusinessUnit2.Type__c + '-' + hierarchy_BusinessUnit2.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_BusinessUnit2);
     Hierarchy__c hierarchy_BusinessLine2 = Test_Utils.insertHierarchy(false, null, 'test-BL2', 'Business Line');
     hierarchy_BusinessLine2.Name = hierarchy_BusinessLine2.Type__c + '-' + hierarchy_BusinessLine2.Value__c; // WF is turned off
     hierarchy_BusinessLine2.Unique_Key__c = hierarchy_BusinessLine2.Type__c + '-' + hierarchy_BusinessLine2.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_BusinessLine2);
     Hierarchy__c hierarchy_Country2 = Test_Utils.insertHierarchy(false, null, 'test-Country2', 'Country');
     hierarchy_Country2.Name = hierarchy_Country2.Type__c + '-' + hierarchy_Country2.Value__c; // WF is turned off
     hierarchy_Country2.Unique_Key__c = hierarchy_Country2.Type__c + '-' + hierarchy_Country2.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_Country2);
     Hierarchy__c hierarchy_GlobalBusinessLine2 = Test_Utils.insertHierarchy(false, null, 'test-GBL2', 'Global Business Line');
     hierarchy_GlobalBusinessLine2.Name = hierarchy_GlobalBusinessLine2.Type__c + '-' + hierarchy_GlobalBusinessLine2.Value__c; // WF is turned off
     hierarchy_GlobalBusinessLine2.Unique_Key__c = hierarchy_GlobalBusinessLine2.Type__c + '-' + hierarchy_GlobalBusinessLine2.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_GlobalBusinessLine2);
     Hierarchy__c hierarchy_Region2 = Test_Utils.insertHierarchy(false, null, 'test-Region2', 'Region');
     hierarchy_Region2.Name = hierarchy_Region2.Type__c + '-' + hierarchy_Region2.Value__c; // WF is turned off
     hierarchy_Region2.Unique_Key__c = hierarchy_Region2.Type__c + '-' + hierarchy_Region2.Value__c; // WF is turned off
     listHierarchies.add(hierarchy_Region2);
     insert listHierarchies;

    for (Hierarchy__c hr: listHierarchies) {
      system.debug(hr);
    }

    // Insert Account Segment
    List<Account_Segment__c> listAccSegments = new List<Account_Segment__c>();
    Account_Segment__c accSegment_BusinessUnit = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_BusinessUnit.Id, null);
    accSegment_BusinessUnit.Value__c = 'test-BU';
    accSegment_BusinessUnit.Type__c = 'Business Unit';
    listAccSegments.add(accSegment_BusinessUnit);

    Account_Segment__c accSegment_BusinessLine = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_BusinessLine.Id, null);
    accSegment_BusinessLine.Value__c = 'test-BL';
    accSegment_BusinessLine.Type__c = 'Business Line';
    listAccSegments.add(accSegment_BusinessLine);

    Account_Segment__c accSegment_Country = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_Country.Id, null);
    accSegment_Country.Value__c = 'test-Country';
    accSegment_Country.Type__c = 'Country';
    listAccSegments.add(accSegment_Country);

    Account_Segment__c accSegment_GlobalBusinessLine = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_GlobalBusinessLine.Id, null);
    accSegment_GlobalBusinessLine.Value__c = 'test-GBL';
    accSegment_GlobalBusinessLine.Type__c = 'Global Business Line';
    listAccSegments.add(accSegment_GlobalBusinessLine);

    Account_Segment__c accSegment_Region = Test_Utils.insertAccountSegment(false, acc.Id, hierarchy_Region.Id, null);
    accSegment_Region.Value__c = 'test-Region';
    accSegment_Region.Type__c = 'Region';
    listAccSegments.add(accSegment_Region);

    insert listAccSegments;

    List<Opportunity> oppList = new List<Opportunity>();
    Opportunity opp1 = Test_Utils.createOpportunity(accList[0].Id);
    opp1.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    opp1.Amount = 1000;
    opp1.Amount_Corp__c = 1000;
    opp1.Name = 'this opp to test delete as well';
    opp1.OwnerId = newUsr.Id;
    oppList.add(opp1);
    Opportunity opp2 = Test_Utils.createOpportunity(accList[0].Id);
    opp2.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    opp2.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    opp2.Amount = 800;
    opp2.Amount_Corp__c = 800;
    opp2.Name = 'testWonOpp2';
    opp2.OwnerId = newUsr.Id;
    oppList.add(opp2);
    Opportunity opp3 = Test_Utils.createOpportunity(accList[0].Id);
    opp3.Segment_Global_Business_Line__c = accSegment_GlobalBusinessLine.Id;
    opp3.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    opp3.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    opp3.Segment_Region__c = accSegment_Region.Id;
    opp3.Amount = 50;
    opp3.Amount_Corp__c = 50;
    opp3.OwnerId = newUsr.Id;
    opp3.Type = Constants.OPPTY_NEW_FROM_NEW;
    opp3.Name = 'testWonOpp';
    oppList.add(opp3);
    Opportunity opp4 = Test_Utils.createOpportunity(accList[0].Id);
    opp4.Segment_Region__c = accSegment_Region.Id;
    opp4.Segment_Country__c = accSegment_Country.Id;
    opp4.Amount = 60;
    opp4.Amount_Corp__c = 60;
    opp4.OwnerId = newUsr.Id;
    oppList.add(opp4);
    Opportunity opp5 = Test_Utils.createOpportunity(accList[0].Id);
    opp5.Segment_Country__c = accSegment_Country.Id;
    opp5.Amount = 200;
    opp5.Amount_Corp__c = 200;
    opp5.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    opp5.Type = Constants.OPPTY_TYPE_RENEWAL; // We plan on closing this opp, with Renewal Order generated
    opp5.OwnerId = newUsr.Id;
    opp5.Name = 'testForOppUpdate';
    oppList.add(opp5);
    insert oppList;

    system.debug('===oppList>>'+oppList);

    newcontact  = Test_Utils.insertContact(accList[0].Id);

    CPQ_Settings__c CPQSettings = new CPQ_Settings__c();
    CPQSettings.Company_Code__c = 'Experian';
    CPQSettings.Name = 'CPQ';
    CPQSettings.CPQ_API_Endpoint__c = 'https://rssandbox.webcomcpq.com/wsapi/WsSrv.asmx';
    CPQSettings.CPQ_API_UserName__c = 'richard.joseph#ExperianGlobal';
    CPQSettings.CPQ_API_Access_Word__c = 'password';
    insert CPQSettings;

    Address__c address = Test_Utils.insertAddress(true);
    Test_Utils.insertAccountAddress(true, address.Id, accList[0].Id);
    Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, opp3.Id, newcontact.Id, Constants.DECIDER, true);
    Test_Utils.insertOpportunityContactRole(true, opp5.Id, newcontact.Id, Constants.DECIDER, true);
    Test_Utils.createOpptyTasks(opp5.Id, true);

    Product2 product = Test_Utils.insertProduct();
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);

    //insert OLI
    OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(opp3.Id, stdPricebookEntry.Id, opp3.Type);
    opportunityLineItem1.Start_Date__c = Date.today().addDays(5);
    opportunityLineItem1.End_Date__c = System.today().addDays(10);
    insert opportunityLineItem1;
    /*opp3.StageName = Constants.OPPTY_STAGE_7;
    opp3.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    opp3.Amount = 100;
    opp3.Amount_Corp__c = 100;
    opp3.Has_Senior_Approval__c = true;
    opp3.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    opp3.CloseDate = date.today();
    opp3.Contract_Start_Date__c = date.today().addDays(1);
    opp3.Contract_End_Date__c = date.today().addYears(1);*/
    //Test.startTest();
// COMMENTED FOR NOW - NLG    update opp3;
    //Test.stopTest();
    Id readOnlyRTid = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    List<Order__c> ordersList = new List<Order__c>();
    Order__c order2 = Test_Utils.insertOrder(false, accList[0].Id, newcontact.id, null);
    order2.Contract_Start_Date__c = Date.today().addYears(-2);
    order2.Contract_End_Date__c = Date.today();
    order2.Amount_Corp__c = 100.00;
    order2.Transactional_Sale__c = true;
    order2.Segment_Global_Business_Line__c = accSegment_GlobalBusinessLine.Id;
    order2.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    order2.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    order2.Segment_Region__c = accSegment_Region.Id;
    order2.RecordTypeId = readOnlyRTid;
    order2.OwnerId = newUsr.Id;
    ordersList.add(order2);
    
    Order__c order3 = Test_Utils.insertOrder(false, accList[0].Id, newcontact.id, null);
    order3.Contract_Start_Date__c = Date.today().addYears(-2);
    order3.Contract_End_Date__c = Date.today();
    order3.Amount_Corp__c = 100.00;
    order3.Transactional_Sale__c = true;
    order3.Segment_Global_Business_Line__c = accSegment_GlobalBusinessLine.Id;
    order3.Segment_Business_Unit__c = accSegment_BusinessUnit.Id;
    order3.Segment_Business_Line__c = accSegment_BusinessLine.Id;
    order3.Segment_Region__c = accSegment_Region.Id;
    order3.OwnerId = newUsr.Id;
    ordersList.add(order3);
    
    insert ordersList;

    delete ida;
    system.debug('===opp3>>'+opp3);
  }
}