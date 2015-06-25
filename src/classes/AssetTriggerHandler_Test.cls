/**********************************************************************************
 * Appirio, Inc
 * Name: AssetTriggerHandler_Test
 * Main Class: AssetTriggerHandler.cls
 * Description: T-320731: To verify functional testing of Main class
 * Created Date: Sep 19th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified        Modified By                  Description of the update
 * Sep 24th, 2014       Arpita Bose(Appirio)         Added methods test_createUpdateRecords_onInsert() and test_createUpdateRecords_onUpdate()
 * Oct 6th, 2014        Naresh Kr Ojha               T-324044: test_trackAssetFieldHistory()
 * Oct 9th, 2014        Arpita Bose                  T-324663: added method testCreateRegistrationRecords()
 * Oct 15th, 2014       Arpita Bose                  T-325309: Updated methods test_createUpdateRecords_onInsert() and test_createUpdateRecords_onUpdate
 * Oct 16th, 2014       Arpita Bose                  Updated testCreateRegistrationRecords() for I-134978
 * Nov 12th, 2014       Arpita Bose                  Updated methods test_createUpdateRecords_onInsert() and test_createUpdateRecords_onUpdate() to fix the failure
 * Feb 13th, 2015       Naresh kr Ojha               T-360562: Updated test class to cover four scenarios mentioned in the task.
 * Feb 16th, 2015       Naresh Kr Ojha               T-362362: As per task, updated API name and label as well as all references
 *                                                   of Deployment_License__c to Deployment__c
 * Feb 17th, 2015       Noopur                       T-360546 : modified the class to add the new features related to @testSetup
 * Feb 23th, 2015       Naresh Kr Ojha               Delted Deployment__c.Type__c field as per T-364131
 * Mar 2nd, 2015        Gaurav Kumar Chadha          T-366782: created Experian global custom setting test data and verified the task use case
 * Mar 5th, 2015        Naresh Kr Ojha               T-366852: test_unsetSaaSonParentAccountForAssetDeleted()
 * Mar 7th, 2015        Naresh kr Ojha               T-364293: Added method test_assetDeleteValidationForActiveDeployment()
 * Mar 7th, 2015        Terri Kellough               T-364293: added additional check per D-16 SaaS Use Case, that active deployment has 1 or less assets
 *                                                   associated to ittest_assetDeleteValidationForActiveDeployment
 * Mar 7th, 2015        Terri Kellough               Change made above undone
 * Mar 11th, 2015       Terri Kellough               added test_assetCountOnDeploymentLicenseOnRemoveAllFromActiveDeployment ()
 * Apr 23th, 2014       Richard Joseph               Case # 00607940- To remove RPI whenever an Asset is retaged.  
 **********************************************************************************/
@isTest
private class AssetTriggerHandler_Test {
  public static Account testAcc;
  public static Account testAccSaasCheck;
  public static Order_Line_Item__c ordrli;
  public static Product2 product;
  public static Opportunity testOpp;

  //==========================================================================
  // Insert case
  //==========================================================================
  @isTest
  static void test_createUpdateRecords_onInsert() {

     // Create User
     Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
     User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
     insert edqUser;


     testAcc = [select Id , Saas__c from Account ];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];
     System.runAs(edqUser) {

      System.debug('=========EDQUSER===='+BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId()));
      // Create test records
     // createTestData();

      // Start test
      Test.startTest();

      product = Test_Utils.insertProduct();
      product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
      upsert product;

      // Insert new Asset record with No_Update__c = false
      Asset newAsset = Test_Utils.insertAsset(false, testAcc.Id);
      newAsset.Order_Line__c = ordrli.Id;
      newAsset.Product2Id = product.Id;
      newAsset.No_Update__c = false;
      newAsset.Part_Number__c = 'PN-123';
      newAsset.Media_Type__c='Electronic Only';
      newAsset.Media_Quantity__c= 1;
      newAsset.UsageEndDate = system.today().addDays(2);
      newAsset.saas__c = true;
      insert newAsset;
      system.debug('newAsset>>>' +newAsset);


      // stop test
      Test.stopTest();

      //Assert to verify that Account.Saas__c is true
      Asset testAsset = [SELECT Account.Saas__c
                         From Asset
                         Where ID = :newAsset.ID];

      system.assert(testAsset.Account.Saas__c == true);

      //Assert to verify that Update__c records has been created
      List<Update__c> updateRec = [SELECT Id, Asset__c, Update_Contact__c, Release_Version__c, Product_Name__c,
                                     Product_Family__c, Operating_System__c, Implementation__c, Data_Usage__c
                                   FROM Update__c
                                   WHERE Asset__c =: newAsset.Id ];
      system.debug('updateRec>>>' +updateRec);
      System.assert(updateRec.size() == 1);

      //T-325309: Assert to verify that Opportunity_Contact_Address__c records has been updated with Update_Record__c = Update.Id
      List<Opportunity_Contact_Address__c> opConAdrsRec = [SELECT Id, Update_Record__c, Contact__c, Opportunity__c
                                                             FROM Opportunity_Contact_Address__c
                                                             WHERE Opportunity__c = :testOpp.Id];

      System.assertEquals(opConAdrsRec.get(0).Update_Record__c, updateRec.get(0).Id);
    }
  }

  //==========================================================================
  // Update case
  //==========================================================================
  //@isTest
  static void test_createUpdateRecords_onUpdate() {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      /*// create test records
      //createTestData();

      // start test
      Test.startTest();
      //insert new Asset record with No_Update__c = true
      Asset newAsset = Test_Utils.insertAsset(false, testAcc.Id);
      newAsset.Order_Line__c = ordrli.Id;
      newAsset.Product2Id = product.Id;
      newAsset.No_Update__c = true;
      newAsset.Part_Number__c = 'PN-123';
      newAsset.UsageEndDate = system.today().addDays(1);
      insert newAsset;

      //Assert
      List<Update__c> updateRec = [SELECT Id, Asset__c, Update_Contact__c, Release_Version__c, Product_Name__c,
                                     Product_Family__c, Operating_System__c, Implementation__c, Data_Usage__c
                                   FROM Update__c
                                   WHERE Asset__c =: newAsset.Id ];
      system.debug('updateRec>>>Update' +updateRec);
      System.assert(updateRec.size() == 0);

      //Update (asset.No_Update__c = false && asset.UsageEndDate = any date)
      newAsset.No_Update__c = false;
      newAsset.UsageEndDate = system.today().addDays(2);
      update newAsset;

      // stop test
      Test.stopTest();*/
      //RJ - Commented the above code
      System.debug('=========EDQUSER===='+BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId()));

      createTestData();

      Test.startTest();

      product = Test_Utils.insertProduct();
      product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
      upsert product;

      //insert new Asset record with No_Update__c = false
      Asset newAsset = Test_Utils.insertAsset(false, testAcc.Id);
      newAsset.Order_Line__c = ordrli.Id;
      newAsset.Product2Id = product.Id;
      newAsset.No_Update__c = false;
      newAsset.Part_Number__c = 'PN-123';
      newAsset.Media_Type__c='Electronic Only';
      newAsset.Media_Quantity__c= 1;
      newAsset.UsageEndDate = system.today().addDays(1);
      insert newAsset;
      system.debug('newAsset>>>' +newAsset);
      
      newAsset.UsageEndDate = system.today().addDays(2);
        update newAsset;

      //Assert to verify that Update__c records has been created
      List<Update__c> newUpdateRec = [SELECT Id, Asset__c, Update_Contact__c, Release_Version__c, Product_Name__c,
                                       Product_Family__c, Operating_System__c, Implementation__c, Data_Usage__c
                                      FROM Update__c
                                      WHERE Asset__c =: newAsset.Id ];
      system.debug('updateRec>>>Update' +newUpdateRec);
      System.assert(newUpdateRec.size() == 1);

      //RJ - Commented it out
      //T-325309: Assert to verify that Opportunity_Contact_Address__c records has been updated with Update_Record__c = Update.Id
      /*List<Opportunity_Contact_Address__c> opConAdrsRec = [SELECT Id, Update_Record__c, Contact__c, Opportunity__c
                                                             FROM Opportunity_Contact_Address__c
                                                             WHERE Opportunity__c = :testOpp.Id];

      System.assertEquals(opConAdrsRec.get(0).Update_Record__c, newUpdateRec.get(0).Id);*/
    }
  }

  //==========================================================================
  // Update case
  //==========================================================================
  @isTest
  static void test_trackAssetFieldHistory() {
    // create test records
    Account newAccount = [select Id from Account limit 1];
    // start test
    Test.startTest();
    //insert new Asset record with No_Update__c = true
    Asset newAsset = Test_Utils.insertAsset(false, newAccount.Id);
    newAsset.No_Update__c = true;
    insert newAsset;

    //There is no audit trail record created for the record we are testing
    System.assert([SELECT ID FROM Audit_Trail__c WHERE Record_Id__c =: newAsset.ID].size() < 1);

    newAsset.Renewal_Discount__c = 10;
    newAsset.Price = 2.00;
    //RJ - Case 607940- Before Update to process or remove RPI % and RPM amount on Asset retag
    newAsset.RPI__c = 1;
    update newAsset;
    
    //RJ - Case 607940- Before Update to process or remove RPI % and RPM amount on Asset retag
    newAsset.Order_line__c = null;
    update newAsset;
    // stop test
    Test.stopTest();

    List<Audit_Trail__c> auditTrailList =  [SELECT ID, Old_Value__c, New_Value__c, Field_Name__c FROM Audit_Trail__c WHERE Asset__c =: newAsset.ID];
    System.debug('auditTrailList.size()>>>' +auditTrailList.size());
    //Assert to verify that Audit trail capturing data //RJ Changed from 2 to 3 
    System.assert(auditTrailList.size() == 3);
    for (Audit_Trail__c auditTrail: auditTrailList) {
      if (auditTrail.Field_Name__c.equalsIgnoreCase(Constants.ASSET_PRICE)) {
        System.assert(auditTrail.Old_Value__c == '1');
        System.assert(auditTrail.New_Value__c == '2');
      } else if (auditTrail.Field_Name__c.equalsIgnoreCase(Constants.ASSET_RENEWAL_DISCOUNT)) {
        System.assert(auditTrail.Old_Value__c == '5');
        System.assert(auditTrail.New_Value__c == '10');
      }
    }


  }


  //==========================================================================
  // T-324663: Method to test Registration Records are created
  //==========================================================================
  @isTest
  public static void testCreateRegistrationRecords(){
    // create Account
    Account testAcc1 = [select Id,Name from Account limit 1];

    product = Test_Utils.insertProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    upsert product;

    List<Asset> assetLst = new List<Asset>();

    // Create 20 Assets,
    // a) 10 with Data_Usage__c = null && Manual_Registration__c = false
    for (Integer i = 0; i < 10; i++) {
      Asset asset1 = new Asset(Name = 'Test Asset',
                               AccountId = testAcc1.Id,
                               Users_To__c = 2,
                               Price = 1.00,
                               Data_Usage__c = null,
                               Manual_Registration__c = false,
                               Registration_Key__c = 'Test12345',
                               Product2Id = product.Id);
      assetLst.add(asset1);
    }

    // b) 5 with Data_Usage__c = null && Manual_Registration__c = true
    for (Integer i = 0; i < 5; i++) {
      Asset asset2 = new Asset(Name = 'Test Asset',
                               AccountId = testAcc1.Id,
                               Users_To__c = 2,
                               Price = 1.00,
                               Data_Usage__c = null,
                               Manual_Registration__c = true,
                               Registration_Key__c = 'Test12345',
                               Product2Id = product.Id);
      assetLst.add(asset2);
    }
    // c) 5 with Data_Usage__c != null && Manual_Registration__c = false
    for (Integer i = 0; i < 5; i++) {
      Asset asset3 = new Asset(Name = 'Test Asset',
                               AccountId = testAcc1.Id,
                               Users_To__c = 2,
                               Price = 1.00,
                               Data_Usage__c = 'International',
                               Manual_Registration__c = false,
                               Registration_Key__c = 'Test12345',
                               Product2Id = product.Id);
      assetLst.add(asset3);
    }
    // start test
    Test.startTest();
    //insert asset records
    insert assetLst;

    //Assert to verify that 10 Registration records are created
    List<Registration__c> regLst = [SELECT Id, Asset__c, Number_of_Users__c, Manual_Registration__c
                                    FROM Registration__c
                                    WHERE Account__c = :testAcc1.Name];
    System.assertEquals(regLst.size(), 10);

    // Update 5 of the Assets created for step a), so that 3 now have Data_Usage__c != null,
    // and 2 have Manual_Registration__c = true
    List<Asset> updateAssetLst = new List<Asset>();
    integer count = 0;
    for(Asset ast: assetLst){
      if (ast.Data_Usage__c == null && ast.Manual_Registration__c == false) {
        if (count < 3) {
          ast.Data_Usage__c = 'International';
          updateAssetLst.add(ast);
        }
        if (3 < count && count < 6) {
          ast.Manual_Registration__c = true;
          updateAssetLst.add(ast);
        }

        if(count > 6) {
          break;
        }
      }
      count++;
    }

    if (updateAssetLst.size() > 0){
      update updateAssetLst;
    }
    //Assert to verify that 15 Registration records are created
    List<Registration__c> regLst15 = [SELECT Id, Asset__c, Number_of_Users__c, Manual_Registration__c, Registration_Key__c
                                      FROM Registration__c
                                      WHERE Account__c = :testAcc1.Name];
    System.assertEquals(regLst15.size(), 15);

    // Update 2 of the Assets from step b) so that Data_Usage__c != null
    for(Asset ast: assetLst){
      if (ast.Data_Usage__c == null && ast.Manual_Registration__c == true) {
        if (count < 2) {
          ast.Data_Usage__c = 'International';
          updateAssetLst.add(ast);
        }
        if(count > 2) {
          break;
        }
      }
      count++;
    }

    if (updateAssetLst.size() > 0){
      update updateAssetLst;
    }
    //Assert to verify that 15 Registration records are created
    List<Registration__c> secondRegLst15 = [SELECT Id, Asset__c, Number_of_Users__c, Manual_Registration__c, Registration_Key__c
                                            FROM Registration__c
                                            WHERE Account__c = :testAcc1.Name];
    System.assertEquals(secondRegLst15.size(), 15);

    // Update 2 of the Assets from step c) so that Manual_Registration__c = true
    for(Asset ast: assetLst){
      if (ast.Data_Usage__c != null && ast.Manual_Registration__c == false) {
        if (count < 2) {
          ast.Manual_Registration__c = true;
          updateAssetLst.add(ast);
        }
        if(count > 2) {
          break;
        }
      }
      count++;
      }

    if (updateAssetLst.size() > 0){
      update updateAssetLst;
    }
    //Assert to verify that 15 Registration records are created
    List<Registration__c> thirdRegLst15 = [SELECT Id, Asset__c, Number_of_Users__c, Manual_Registration__c, Registration_Key__c
                                            FROM Registration__c
                                            WHERE Account__c = :testAcc1.Name];
    System.assertEquals(thirdRegLst15.size(), 15);
    // stop test
    Test.stopTest();
  }

  //==========================================================================
  // Insert Assets to have a deployment and verify the count is incremented on the deployment case
  //==========================================================================
  @isTest
  static void test_assetCountOnDeploymentLicenseOnInsert () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      // create test records
      //createTestData();

      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License';
      newDepLicense.Account__c = testAcc.ID;
      //newDepLicense.Type__c = 'Eval'; //Delted this field as per T-364131
      newDepLicense.Active__c = false;
      insert newDepLicense;

      // start test
      Test.startTest();
      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Order_Line__c = ordrli.Id;
        newAsset.Product2Id = product.Id;
        newAsset.No_Update__c = true;
        newAsset.Part_Number__c = 'PN-123';
        newAsset.UsageEndDate = system.today().addDays(1);
        newAsset.Deployment__c = newDepLicense.ID;
        newAsset.SaaS__c = true;
        assetList.add(newAsset);
      }
      insert assetList;

      Test.stopTest();
      //Deployment License should have Asset Count equals to assetList.size()
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, assetList.size());
    }
  }

  //==========================================================================
  // Update the asset to have deployment and verify the deployment count is updated e
  //==========================================================================
  @isTest
  static void test_assetCountOnDeploymentLicenseOnAddToDeployment () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      // create test records
    //  createTestData();
      // start test
      Test.startTest();

      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License';
      newDepLicense.Account__c = testAcc.ID;
      //newDepLicense.Type__c = 'Eval'; //Delted this field as per T-364131
      newDepLicense.Active__c = false;
      insert newDepLicense;

      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Order_Line__c = ordrli.Id;
        newAsset.Product2Id = product.Id;
        newAsset.No_Update__c = true;
        newAsset.Part_Number__c = 'PN-123';
        newAsset.UsageEndDate = system.today().addDays(1);
        newAsset.SaaS__c = true;
        assetList.add(newAsset);
      }
      insert assetList;


      //Deployment License should not have any Asset Count
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, 0);

      for (Asset asst : assetList) {
        asst.Deployment__c = newDepLicense.ID;
      }
      update assetList;
      Test.stopTest();

      //Deployment License should have equals Asset Count with assetList.size()
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, assetList.size());
    }
  }


//==========================================================================
  // Remove Inactive Deployment From Asset Case
  //==========================================================================
  @isTest
  static void test_assetCountOnDeploymentLicenseOnRemoveFromDeployment () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      // create test records
      // createTestData();
      // start test
      Test.startTest();

      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License2';
      newDepLicense.Account__c = testAcc.ID;
      //newDepLicense.Type__c = 'Eval'; //Delted this field as per T-364131
      newDepLicense.Active__c = false;
      insert newDepLicense;

      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Order_Line__c = ordrli.Id;
        newAsset.Product2Id = product.Id;
        newAsset.No_Update__c = true;
        newAsset.Part_Number__c = 'PN-123';
        newAsset.UsageEndDate = system.today().addDays(1);
        newAsset.SaaS__c = true;
        assetList.add(newAsset);
      }
      insert assetList;
      for (Asset asst : assetList) {
        asst.Deployment__c = newDepLicense.ID;
      }
      update assetList;      


      //Deployment License should have equals Asset Count with assetList.size()
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, assetList.size());

      for (Asset asst : assetList) {
        asst.Deployment__c = null;
      }
      update assetList;
      Test.stopTest();

      //Deployment License should have an Asset Count of 0
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, 0);
    }
  }

//==========================================================================
  // Remove All SaaS Assets from Active Deployment Case
  //==========================================================================
  @isTest
  static void test_assetCountOnDeploymentLicenseOnRemoveAllFromActiveDeployment () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      // create test records
      // createTestData();

      // start test
      Test.startTest();
      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License2';
      newDepLicense.Account__c = testAcc.ID;
      //newDepLicense.Type__c = 'Eval'; //Delted this field as per T-364131
      newDepLicense.Active__c = false;
      insert newDepLicense;

      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Order_Line__c = ordrli.Id;
        newAsset.Product2Id = product.Id;
        newAsset.No_Update__c = true;
        newAsset.Part_Number__c = 'PN-123';
        newAsset.UsageEndDate = system.today().addDays(1);
        newAsset.SaaS__c = true;
        assetList.add(newAsset);
      }
      insert assetList;
      for (Asset asst : assetList) {
        asst.Deployment__c = newDepLicense.ID;
      }
      update assetList;   
      
      newDepLicense.Active__c = true;
      update newDepLicense;   


      //Deployment License should have equals Asset Count with assetList.size()
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, assetList.size());

      for (Integer i = 0; i < 8; i++) {
        assetList.get(i).Deployment__c = null;
      }
      
      update assetList;
      
      //Active Deployment's Asset Count = 1 = Number of Assets associated with the Active Deployment
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, [Select count() From Asset Where Deployment__c =:newDepLicense.ID]);
      
      for (Asset asst : assetList) {
        asst.Deployment__c = null;
      }

      
      
      //an error message should be thrown when all SaaS assets are removed from an active deployment
      try {
        update assetList;
      }
      catch (DMLException ex) {
        System.assert(ex.getMessage().contains(System.Label.SaaS_ERR_UPDATE_ASSET)); 
      } finally {
         //Since an updated didn't occur, Deployment License should have an Asset Count > 0 and should match number of assets associated with the deployment
        System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c,
                            [Select count() From Asset Where Deployment__c =:newDepLicense.ID]);
      }
      
      Test.stopTest();
    }
  }




  //===========================================================================
  // Clear SaaS when last SaaS asset removed from account as per T-366852
  //===========================================================================
  @isTest
  static void test_unsetSaaSonParentAccountForAssetDeleted() {
    // Create User
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;

    testAcc = [SELECT Id , Saas__c FROM Account ];
    ordrli = [SELECT Id FROM Order_Line_Item__c];
    product = [SELECT Id FROM Product2];
    testOpp = [SELECT Id FROM Opportunity];
    System.runAs(testUser) {

      // start test
      Test.startTest();

      // Insert new Asset record with No_Update__c = false
      Asset newAsset = Test_Utils.insertAsset(false, testAcc.Id);
      newAsset.Order_Line__c = ordrli.Id;
      newAsset.No_Update__c = false;
      newAsset.Part_Number__c = 'PN-123';
      newAsset.UsageEndDate = system.today().addDays(2);
      newAsset.Saas__c = true;
      insert newAsset;
      system.debug('newAsset>>>' +newAsset);

      // Insert second Asset record
      Asset newAsset2 = Test_Utils.insertAsset(false, testAcc.Id);
      newAsset2.Order_Line__c = ordrli.Id;
      newAsset2.No_Update__c = false;
      newAsset2.Part_Number__c = 'PN-123';
      newAsset2.UsageEndDate = system.today().addDays(2);
      newAsset2.Saas__c = true;
      insert newAsset2;

      // Assert to verify that Account.Saas__c is true
      Account testAccount = [SELECT Saas__c FROM Account WHERE ID =: testAcc.ID];

      // Assert to check weather saas is set true on asset.saas inserted
      system.assert(testAccount.Saas__c == true);

      delete newAsset;

      testAccount = [SELECT Saas__c From Account Where ID =: testAcc.ID];
      // Account should still have SaaS__c == true since there is another SaaS Asset
      system.assert(testAccount.Saas__c == true);

      delete newAsset2;
      Test.stopTest();

      testAccount = [SELECT Saas__c From Account Where ID =: testAcc.ID];
      // Assert to check weather account saas is set to false as it do not have any saas asset
      system.assert(testAccount.Saas__c == false);
    }

  }

  //==========================================================================
  // Delete case and Undelete case
  //==========================================================================
  @isTest
  static void test_assetCountOnDeploymentLicenseOnDeleteAndUndelete () {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;

     testAcc = [select Id from Account];
     ordrli = [select Id from Order_Line_Item__c];
     product = [select Id from Product2];
     testOpp = [select Id from Opportunity];

    System.runAs(edqUser) {
      // create test records
      // createTestData();
      // start test
      Test.startTest();

      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License';
      newDepLicense.Account__c = testAcc.ID;
      //newDepLicense.Type__c = 'Eval'; //Delted this field as per T-364131
      newDepLicense.Active__c = false;
      insert newDepLicense;

      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Deployment__c = newDepLicense.ID;
        newAsset.SaaS__c = true;
        assetList.add(newAsset);
      }
      insert assetList;


      //Deployment License should not have any Asset Count
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, assetList.size());

      delete assetList;


      //Deployment License should not have any Asset Count as all assets got deleted
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, 0);

      undelete assetList;

      //Deployment License should have 10 As Asset Count as we've undeleted assets and they should set the value on it.
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c, 10);
    }
  }
  //==========================================================================
  // Delete asset should show error when deployement is active a
  //==========================================================================
  @isTest
  static void test_assetDeleteValidationForActiveDeployment () {
    // create User
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;
    
     testAcc = [SELECT Id FROM Account];
     testAcc.SaaS__c = true;
     update testAcc;
     
     ordrli = [SELECT Id FROM Order_Line_Item__c];
     product = [SELECT Id FROM Product2];
     testOpp = [SELECT Id FROM Opportunity];
    
    System.runAs(testUser) {
      // create test records
      // createTestData();
      
      // start test
      Test.startTest();
      Deployment__c newDepLicense = new Deployment__c();
      newDepLicense.Name = 'Test Deployment License';
      newDepLicense.Account__c = testAcc.ID;
      newDepLicense.Active__c = false;
      insert newDepLicense;
      
      //insert new Asset records
      List<Asset> assetList = new List<Asset>();
      Asset newAsset;
      for (Integer i=0; i<10; i++) {
        newAsset = Test_Utils.insertAsset(false, testAcc.Id);
        newAsset.Deployment__c = newDepLicense.ID; 
        newAsset.SaaS__c = true;
        newAsset.AccountId = testAcc.ID;
        assetList.add(newAsset);
      }
      insert assetList;

      newDepLicense.Active__c = true;
      update newDepLicense;      
    
      //Deployment should have an Asset Count > 0 and  matching the number of assets created
      System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c,
                          [SELECT count() FROM Asset WHERE Deployment__c =:newDepLicense.ID]);
            
      for (Asset deleteAsset : assetList) {
        deleteAsset.Deployment__c = null;
      }
      
      try {
        //Deletion of asset should fail since asset is related to an active deploymen
        delete assetList;
      } catch (DMLException ex) {
        System.assert(ex.getMessage().contains(System.Label.SaaS_ERR_DELETE_ASSET)); 
      }
      finally {
        //Since deletion did not occur, Deployment should have an Asset Count > 0 and  matching the number of assets created
        System.assertEquals([SELECT Asset_Count__c FROM Deployment__c WHERE ID =: newDepLicense.ID].get(0).Asset_Count__c,
                            [SELECT count() FROM Asset WHERE Deployment__c =:newDepLicense.ID]);
      }
      Test.stopTest();
    }
  }
  //==========================================================================
  // Data Setup
  //==========================================================================
  @testSetup
  private static void createTestData() {
    // Business_Unit_Group_Mapping__c custSetting1 = new Business_Unit_Group_Mapping__c();
    // custSetting1.Name = 'EDQ';
    // custSetting1.User_Business_Unit__c = 'APAC:SE';
    // custSetting1.Common_Group_Name__c = 'EDQ';
    // insert custSetting1;

    User experianGlobalUser = Test_Utils.createUser('Experian Read Only Custom');
    insert experianGlobalUser;

    Experian_Global__c experianCustomSetting = new Experian_Global__c();
    experianCustomSetting.OwnerId__c = experianGlobalUser.ID;
    insert experianCustomSetting;


    User currentUser = new User();
    currentUser.Id = UserInfo.getUserId();
    currentUser.Global_Business_Line__c = 'Corporate';
    currentUser.Business_Line__c = 'Corporate';
    currentUser.Business_Unit__c = 'APAC:SE';
    update currentUser;

    //Create Account
    testAcc = Test_Utils.insertAccount();

    //Create Contact
    Contact newcontact1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAcc.Id, Email = 'test1@email.com');
    Contact newcontact2  = new Contact (FirstName = 'Test 2', LastName = 'Ellison', AccountId = testAcc.Id, Email = 'test2@email.com');

    List<Contact> conLst = new List<Contact>();
    conLst.add(newcontact1);
    conLst.add(newcontact2);
    insert conLst;

    //Create Opportunity
    testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    //Create Opportunity Contact Roles with Role = Constants.DECIDER
    OpportunityContactRole oppContactRole1 = new OpportunityContactRole(ContactId = conLst.get(0).Id,
                                                 OpportunityId = testOpp.Id, IsPrimary = true,
                                                 Role = Constants.OPPTY_CONTACT_ROLE_UPDATE);

    //Create Opportunity Contact Roles with Role = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER
    OpportunityContactRole oppContactRole2 = new OpportunityContactRole(ContactId = conLst.get(1).Id,
                                                 OpportunityId = testOpp.Id, IsPrimary = false,
                                                 Role = Constants.OPPTY_CONTACT_ROLE_UPDATE);

    List<OpportunityContactRole> oppConRoleLst = new List<OpportunityContactRole>();
     oppConRoleLst.add(oppContactRole1);
     oppConRoleLst.add(oppContactRole2);
     insert oppConRoleLst;

    //Create Product2 records (Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY)
    product = Test_Utils.insertProduct();
    product.Business_Line__c = Constants.BUSINESSLINE_DATA_QUALITY;
    upsert product;

    //Create Order (Locked = true, Type=Renewal, Opportunity = aboveOppty)
    Order__c ordr = Test_Utils.createOrder();
    ordr.Opportunity__c = testOpp.Id;
    ordr.Locked__c = true;
    ordr.Type__c = Constants.ORDER_RENEWAL;
    insert ordr;

    //Create Order Line Item
    Billing_Product__c billProd = Test_Utils.insertBillingProduct();

    ordrli = Test_Utils.insertOrderLineItems(false, ordr.Id, billProd.Id);
    ordrli.Part_Number__c = 'PN-123';
    insert ordrli;

    //T-325309
    Address__c addrs = Test_Utils.insertAddress(true);

    Opportunity_Contact_Address__c opConAdrs = new Opportunity_Contact_Address__c();
    opConAdrs.Contact__c = conLst.get(0).Id;
    opConAdrs.Opportunity__c = testOpp.Id;
    opConAdrs.Address__c = addrs.Id;
    opConAdrs.Role__c = Constants.OPPTY_CONTACT_ROLE_UPDATE;
    insert opConAdrs;

  }
}