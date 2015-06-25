/*******************************************************************************
 * Appirio, Inc
 * Name         : OpportunityTrigger_AccountSegment_Test
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Test class of class "OpportunityTrigger_AccountSegmentation"
 * Created Date : April 07th, 2015
 *
 * Date Modified                Modified By         Description of the update
 * Apr 14th, 2015               Naresh Kr           updated as per coding standards
 * Apr 16th, 2015               Suminder Singh      T-378087 : Added test method segmentFieldPopulateOnOpptyDelete_Test()
                                                               for Oppty delete and undelete
 *******************************************************************************/

@isTest
private class OpportunityTrigger_AccountSegment_Test {
  
  //==========================================================================
  // Test method to test the functionality of Opportunity creation should 
  // populate segment fields on newly created opportunity.
  //==========================================================================
  static testMethod void segmentFieldPopulateOnOpptyInsert_Test() {
    //createHierarchies();

    //fetching profile Id of system admin
    Profile p = [SELECT id from profile where name =: 'System Administrator' ];
    //creating user with all necessary values for our use case like Bussiness Unit, Business Line, + 3
    User usr = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                  emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                  localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', 
                  username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true, 
                  CompanyName = 'test Company', Business_Line__c = 'APAC Corporate', 
                  Business_Unit__c = 'APAC Corporate Finance', Global_Business_Line__c = 'Corporate', 
                  Country__c = 'India', Region__c = 'Global');
    
    Opportunity testOpp;
    Date tempDate = date.today();
    system.runAs(usr) {
      //Create Account
      Account testAcc = Test_Utils.insertAccount();
        
      //Create a Contact
      Contact testCon = Test_Utils.insertContact(testAcc.ID);

      //Create a Address
      Address__c testAddress = Test_Utils.insertAddress(true);
          
      //Create a Contact Address record
      Contact_Address__c testCA = Test_Utils.insertContactAddress(true, testAddress.Id, testCon.Id);
        
      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, testAddress.Id, testAcc.Id);

      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                              AccountId = testAcc.Id, Email = 'larrye@email.com');
      insert newcontact;

      //Create an opportunity
      testOpp = Test_Utils.createOpportunity(testAcc.Id);
      //testOpp.Type = Constants.OPPTY_TYPE_CREDITED;
      testOpp.Type = 'New From New';
      testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      testOpp.Amount = 1000;
      testOpp.CloseDate = tempDate;
      insert testOpp;
    }  

    Opportunity oppty = [SELECT Id, CloseDate, Type, Segment_Business_Line__r.Name, 
                                Segment_Business_Unit__r.Name, Segment_Global_Business_Line__r.Name, 
                                Segment_Country__r.Name, Segment_Region__r.Name
                         FROM Opportunity 
                         WHERE Id =: testOpp.Id];

      system.assertEquals(true, oppty.Segment_Business_Line__r.Name.containsIgnoreCase(usr.Business_Line__c));
      system.assertEquals(true, oppty.Segment_Business_Unit__r.Name.containsIgnoreCase(usr.Business_Unit__c));
      system.assertEquals(true, oppty.Segment_Global_Business_Line__r.Name.containsIgnoreCase(usr.Global_Business_Line__c));
      system.assertEquals(true, oppty.Segment_Country__r.Name.containsIgnoreCase(usr.Country__c));
      system.assertEquals(true, oppty.Segment_Region__r.Name.containsIgnoreCase(usr.Region__c));
  } //End static void test_method_one() {
  
  //===========================================================================
  // T-378087: Account Segmentation: Delete and Undelete order test Unit
  //===========================================================================
  
    static testMethod void segmentFieldPopulateOnOpptyDelete_Test() {
     // createHierarchies();
  
      //fetching profile Id of system admin
      Profile p = [SELECT id from profile where name =: 'System Administrator' ];
      //creating user with all necessary values for our use case like Bussiness Unit, Business Line, + 3
      User usr = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                    emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', 
                    username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true, 
                    CompanyName = 'test Company', Business_Line__c = 'APAC Corporate', 
                    Business_Unit__c = 'APAC Corporate Finance', Global_Business_Line__c = 'Corporate', 
                    Country__c = 'India', Region__c = 'Global');
      
      Opportunity testOpp;
      Date tempDate = date.today();
      Account testAcc;
      system.runAs(usr) {
        //Create Account
        testAcc = Test_Utils.insertAccount();
          
        //Create a Contact
        Contact testCon = Test_Utils.insertContact(testAcc.ID);
  
        //Create a Address
        Address__c testAddress = Test_Utils.insertAddress(true);
            
        //Create a Contact Address record
        Contact_Address__c testCA = Test_Utils.insertContactAddress(true, testAddress.Id, testCon.Id);
          
        //insert account address
        Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, testAddress.Id, testAcc.Id);
  
        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                                AccountId = testAcc.Id, Email = 'larrye@email.com');
        insert newcontact;
  
        //Create an opportunity
        testOpp = Test_Utils.createOpportunity(testAcc.Id);
        //testOpp.Type = Constants.OPPTY_TYPE_CREDITED;
        testOpp.Type = 'New From New';
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
        testOpp.Amount = 1000;
        testOpp.CloseDate = tempDate;
        testOpp.All_dates_based_on_Closed_Date__c = true;
        insert testOpp;
        Test.startTest();
        delete testOpp;
        
      }  
      //List to check total won and total pipeline segment amount
      List<Account_Segment__c> accSeg = [SELECT Total_Open_Pipeline__c, Total_Won__c
                                          FROM Account_Segment__c 
                                          WHERE Account__c =: testAcc.ID];
       system.assertEquals(0, accSeg[0].Total_Open_Pipeline__c);
       
       //Undelete Oppty to check account segment functionality
       undelete testOpp;
       Test.stopTest();
       for (Account_Segment__c accSegment : [SELECT Total_Open_Pipeline__c, Total_Won__c
                                          FROM Account_Segment__c 
                                          WHERE Account__c =: testAcc.ID]) {
        system.assertEquals(1000, accSegment.Total_Open_Pipeline__c);
      }
    }
    
  @testSetup
  private static void createHierarchies() {
    List<Hierarchy__c> lstHierarchy = new List<Hierarchy__c>();
    Hierarchy__c hierarchy_BusinessUnit = Test_Utils.insertHierarchy(false, null, 'APAC Corporate Finance', 'Business Unit');
    lstHierarchy.add(hierarchy_BusinessUnit);
     
     Hierarchy__c hierarchy_BusinessLine = Test_Utils.insertHierarchy(false, null, 'APAC Corporate', 'Business Line');
     lstHierarchy.add(hierarchy_BusinessLine);
     
     Hierarchy__c hierarchy_Country = Test_Utils.insertHierarchy(false, null, 'India', 'Country');
    lstHierarchy.add(hierarchy_Country);
     
     hierarchy__c hierarchy_GlobalBusinessLine = Test_Utils.insertHierarchy(false, null, 'Corporate', 'Global Business Line');
     lstHierarchy.add(hierarchy_GlobalBusinessLine);
     
     Hierarchy__c hierarchy_Region = Test_Utils.insertHierarchy(false, null, 'Global', 'Region');
    lstHierarchy.add(hierarchy_Region);
     insert lstHierarchy;
  }
} //End private class OpportunityTrigger_AccountSegment_Test