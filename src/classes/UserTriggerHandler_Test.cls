/**=====================================================================
 * Appirio, Inc
 * Name: UserTriggerHandler_Test
 * Description: T-271249: To test Currency Sync on User
 * Created Date: Apr 15th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 23rd, 2014               Arpita Bose                  Added method testUpdateARIABillingAccounts()
 * May 26th, 2014               Naresh Kr Ojha (Appirio)     T-280244: Testing functionality to mark true AriaBillingAccnt.SendBillingAccToAria
 *                                                           updated method testUpdateARIABillingAccounts()
 * Sep 18th 2014                Richard Joseph               Added testCPQUserInsertUpdate Test Method.
 * Oct 09th, 2014               Arpita Bose                  Added method testValidateEDQUserFields1() and testValidateEDQUserFields2()
 * Oct 10th, 2014               Arpita Bose                  Updated method testCPQUserInsertUpdate() to fix failure
 * Oct 31st, 2014               Arpita Bose                  Updated method testCPQUserInsertUpdate() to fix failure
 * Apr 29th, 2015				James Weatherall			 Created method testUpdateExperianContactManager
 =====================================================================*/
@isTest
private class UserTriggerHandler_Test {
    
    static testmethod void testCurrencyFieldsOnUser(){
        //create user 
        User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert  testUser1;
    //start test
    Test.startTest();
    testUser1.DefaultCurrencyIsoCode = 'GBP';
    testUser1.Currency__c ='AUD';
    try {
      update testUser1;
    }catch(Exception ex){
      System.assert(ex.getMessage().contains(System.Label.USER_CURRENCY_FIELDS_MUST_MATCH));
    }
    testUser1.DefaultCurrencyIsoCode = 'AUD';
    testUser1.Currency__c ='AUD';
    update testUser1;
    //stop test 
    Test.stopTest();                            
    }
  //Test trigger to update AriaBillingAccount.sendBillingAccntToAria = true
    static testmethod void testUpdateARIABillingAccounts(){
        Account testAcc = Test_Utils.insertAccount();
    //create user 
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    testUser1.Business_Unit__c = 'EMEA MS';
    insert  testUser1;
    
    ARIA_Billing_Account__c aria = new ARIA_Billing_Account__c();
    aria.Account__c = testAcc.Id;
    aria.Push_To_Aria__c = Constants.PICKLISTVAL_YES;
    aria.SendBillingAccntToAria__c = false;
    aria.Owner__c = testUser1.Id;
    aria.Billing_Account_Country__c  = 'USA';
    aria.Business_ID_Number__c = '1232313213';    
    aria.Business_ID_Type__c = 'ABN';
    insert aria;
    
    //start test
    Test.startTest();
    testUser1.Business_Unit__c = 'India CS';
    update testUser1;
    
    List<ARIA_Billing_Account__c> lstAria = [SELECT ID, Push_To_Aria__c, SendBillingAccntToAria__c 
                                                     FROM ARIA_Billing_Account__c 
                                             WHERE Owner__c =:testUser1.Id
                                                              AND ID =:aria.Id];
    //stop test 
    Test.stopTest(); 
    //Assert
    system.assert(lstAria.get(0).SendBillingAccntToAria__c, true);
  }
                             
  static testmethod void testCPQUserInsertUpdate(){
      
    //create user 
    User testUserCPQ = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    testUserCPQ .CPQ_User__c = True;
    testUserCPQ.CPQ_User_Type__c = 'EDQ Sales';
    testUserCPQ.Country__c = 'USA';
    
     CPQ_Settings__c testCPQSetting = CPQ_Settings__c.getInstance('CPQ');
     if(testCPQSetting == null){
     testCPQSetting= new CPQ_Settings__c ();
         testCPQSetting.Name = 'CPQ';
         testCPQSetting.Company_Code__c= 'Experian';
         testCPQSetting.CPQ_API_Access_Word__c = 'Accessword';
         testCPQSetting.CPQ_API_Endpoint__c= 'https://test.webcomcpq.com/';
         testCPQSetting.CPQ_API_UserName__c= 'TestUser#Experian';
         Insert testCPQSetting; 
     }
     
    
    HttpResponse resTest = new HttpResponse();
    resTest .setStatus('OK');
    resTest .setStatusCode(200);
    resTest .setBody('<Result>OK</Result>');
    
    
    //start test
    Test.startTest();
    
    SFDCToCPQUserServiceClass.responseCPQ= resTest ;
    
    testUserCPQ.CPQ_User_Type__c = 'CFO';
    testUserCPQ.Region__c ='Global';
    testUserCPQ.Country__c = 'Australia';
    insert  testUserCPQ ;
    
    testUserCPQ .CPQ_User__c = False;
    update testUserCPQ;
    Test.stoptest();
  }

  // method to test users to have Office location if user is updated to EDQ user
  public static testmethod void testValidateEDQUserFields1(){
    // create test data       
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User currentUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    currentUser.Global_Business_Line__c = 'Corporate';
    currentUser.Business_Line__c = 'Corporate';
    currentUser.Business_Unit__c = 'APAC:SE';
    insert currentUser;

    Test.startTest();
    // update user to EDQ user
    currentUser.Global_Business_Line__c = 'Credit Services';
    currentUser.Business_Line__c = 'APAC Credit Services';
    currentUser.Business_Unit__c = Test_Utils.edqSetting.User_Business_Unit__c;
    
    try {
      update currentUser;
    } catch(Exception ex){
        // Assert for error message
        System.assert(ex.getMessage().contains(Label.EDQ_USER_REQD_FIELDS));
    }

    Test.stopTest();
  }

  // method to test users to have Office location if user is EDQ user
  public static testmethod void testValidateEDQUserFields2(){
    Test.startTest();
    // create user

    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User currentUser = Test_Utils.createEDQuser(p, 'test1234@gmail.com', 'test1');
    /*currentUser.Global_Business_Line__c = 'Credit Services';
    currentUser.Business_Line__c = 'APAC Credit Services';
    currentUser.Business_Unit__c = Test_Utils.edqSetting.User_Business_Unit__c;*/
    
    try {
      insert currentUser;
    } catch(Exception ex){
        // Assert for error message
        System.assert(ex.getMessage().contains(Label.EDQ_USER_REQD_FIELDS));
    }

    Test.stopTest();
  }
    
  // James Weatherall : 29th April, 2015
  // method to test Experian Employee Manager update
  // TODO: Modify the code to test the method UserTriggerHandler.createExperianContact when that is live
  public static testmethod void testUpdateExperianContactManager()
  {
    Test.startTest();
      
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    
    // Create 2 user records. One will be set as the Manager of the other.
    User managerUser = Test_Utils.createUser(p, 'test1234@experian.com', 'Contact');
    insert managerUser;
      
    User anotherUser = Test_Utils.createUser(p, 'test1234@experian.com', 'Contact');
    insert anotherUser;
    
    // Create an Account and then attach a Contact based on the User record created above.
    Account experianBUAcc = Test_Utils.insertAccount();  
    Contact insertExpEmployee = new Contact(AccountId = experianBUAcc.Id, FirstName = anotherUser.FirstName, LastName = anotherUser.LastName, Email = anotherUser.Email, SFDC_User__c = anotherUser.Id);
    insert insertExpEmployee;
    
    // Check the Current Manager is null
    Contact expEmployee = [SELECT Id, Current_Manager__c FROM Contact WHERE Id =: insertExpEmployee.Id];
    System.assertEquals(null, expEmployee.Current_Manager__c);
    
    // Update the User's Manager to the Manager User.
    User updateUser = [SELECT Id, ManagerId FROM User WHERE Id =: anotherUser.Id];
    updateUser.ManagerId = managerUser.Id;
    update updateUser;
    
    // Check that the Current Manager is updated on the Contact.
    Contact updateExpEmployee = [SELECT Id, Current_Manager__c FROM Contact WHERE SFDC_User__c =: anotherUser.Id];
    System.assertEquals(managerUser.Id, updateExpEmployee.Current_Manager__c); 
    
    Test.stopTest();
  }



  //===========================================================================
  // T-373930: Test the functionality of recalculation segment fields when User
  // has its GBL/BL/BU/Region/Country fields updated
  //===========================================================================
  static testmethod void testRecalculateSegmentFieldValues(){
    // create test data
    String name_GBL = 'Credit Services Test';
    String name_BL = 'APAC Credit Services Test';
    String name_BU = 'APAC CS Japan Test';
    String name_region = 'APAC Test';
    String name_country = 'United States of America Test';

    User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    testUser.Region__c = null;
    insert testUser;

    system.runAs(testUser) {
        system.debug('==user>>'+testUser);
      Account acc = Test_Utils.insertAccount();

      Contact con = Test_Utils.insertContact(acc.Id);

      Opportunity testOpp =  Test_Utils.createOpportunity(acc.Id);
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        testOpp.OwnerId = testUser.Id;
        testOpp.Amount = 100;
        insert testOpp;

        //create some Hierarchy records (one for each: BU, BL, GBL)
        Hierarchy__c gbl = Test_Utils.insertHierarchy(true, null, name_GBL, 'Global Business Line');
        Hierarchy__c bl = Test_Utils.insertHierarchy(true, gbl.Id, name_BL, 'Business Line');
        Hierarchy__c bu = Test_Utils.insertHierarchy(true, bl.Id, name_BU, 'Business Unit');
        Hierarchy__c region = Test_Utils.insertHierarchy(true, null, name_region, 'Region');
        Hierarchy__c country = Test_Utils.insertHierarchy(true, null, name_country, 'Country');

        Opportunity opp = [SELECT Id, Segment_Business_Line__c, Segment_Business_Unit__c,
                                  Segment_Global_Business_Line__c, Segment_Region__c, Segment_Country__c
                           FROM Opportunity
                           WHERE Id = :testOpp.Id ];

        system.debug('Oppty>>'+opp);
        //Asserts to check that there is no segment field populated.
        System.assert(opp.Segment_Global_Business_Line__c == null);
      System.assert(opp.Segment_Business_Line__c == null);
      System.assert(opp.Segment_Business_Unit__c == null);
      System.assert(opp.Segment_Region__c == null);
      System.assert(opp.Segment_Country__c == null);


        // start test
        Test.startTest();
            //change the user's BU to populate it
            testUser.Global_Business_Line__c = name_GBL;
          testUser.Business_Line__c = name_BL;
          testUser.Region__c = name_region;
          testUser.Country__c = name_country;
            testUser.Business_Unit__c = name_BU;
            update testUser;

           system.debug('==user>>'+testUser);
           // stop test
        Test.stopTest();
        Map<String, Account_Segment__c> accountSegmentMap = new Map<String, Account_Segment__c>();

        //Asserts that the BU Account_Segment__c now has Pipeline Amount populated with the opp's value
        for (Account_Segment__c accSeg : [SELECT Name, Id, Total_Open_Pipeline__c, Account__c, Total_Won__c,
                                                 Value__c, Parent_Account_Segment__c, Relationship_Type__c
                                         FROM Account_Segment__c
                                         WHERE Account__c = : acc.Id]) {
            accountSegmentMap.put(accSeg.Value__c, accSeg);
            //Account segment has populated open pipleline amount
          System.assertEquals(100.00, accSeg.Total_Open_Pipeline__c);
          System.assertEquals('Prospect', accSeg.Relationship_Type__c);
        }


        Opportunity updatedOpp = [SELECT Id, Segment_Business_Line__c, Segment_Business_Unit__c,
                               Segment_Global_Business_Line__c, Segment_Region__c, Segment_Country__c
                        FROM Opportunity
                        WHERE Id =: testOpp.Id];

      //Asserts: Account segment populated on segment fields for opportunity.
      System.assertEquals(accountSegmentMap.get(name_GBL).Id, updatedOpp.Segment_Global_Business_Line__c);
      System.assertEquals(accountSegmentMap.get(name_BL).Id, updatedOpp.Segment_Business_Line__c);
      System.assertEquals(accountSegmentMap.get(name_BU).Id, updatedOpp.Segment_Business_Unit__c);
      System.assertEquals(accountSegmentMap.get(name_Region).Id, updatedOpp.Segment_Region__c);
      System.assertEquals(accountSegmentMap.get(name_Country).Id, updatedOpp.Segment_Country__c);
      System.assertNotEquals(null, accountSegmentMap.get(name_BU).Parent_Account_Segment__c);
      System.assertNotEquals(null, accountSegmentMap.get(name_BL).Parent_Account_Segment__c);
    }
  }
}