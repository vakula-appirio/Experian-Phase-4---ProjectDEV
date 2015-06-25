@isTest(seeAllData = false)
public class OpportunityTriggerHandlerTest_New {
  //=======================================================================//
  // Declaring variables
  //======================================================================//
  public static final String MANAGER_USER = Constants.ROLE_GLOBAL_ADMIN;
  public static final String SALES_EXEC_USER = Constants.ROLE_SALES_EXEC_RETAIL_PROPERTY;
  
  static Set<String> userRoleNameSet = new Set<String>{SALES_EXEC_USER, MANAGER_USER};
  static Map<String, UserRole> userRoleMap;
  
  static {
    userRoleMap = new Map<String, UserRole>();
    
    for(UserRole role : [Select ID, Name FROM UserRole WHERE UserRole.Name IN: userRoleNameSet]){
      userRoleMap.put(role.Name, role);
    }
  }
  static Account testAccount;
  
  //======================================================================//
  // Test method for opportunityContactRolesAddressTestForNONFreeTrial()
  //======================================================================//    
  static testmethod void opportunityContactRolesAddressTestForNONFreeTrial(){
    Opportunity testOpp = [SELECT Id, StageName, Channel_Type__c, Amount, Has_Senior_Approval__c, 
                               Starting_Stage__c, CloseDate, Contract_Start_Date__c,
                               Contract_End_Date__c, Type
                           FROM Opportunity LIMIT 1 ];
                           
      Test.startTest();
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
      Test.stopTest();
  }
  
  //======================================================================//
  // Test method for opportunityContactRolesAddressTestForFreeTrial()
  //======================================================================//  
  static testmethod void opportunityContactRolesAddressTestForFreeTrial() {  
  	Opportunity testOpp = [SELECT Id, StageName, Channel_Type__c, Amount, Has_Senior_Approval__c, 
  	                         Starting_Stage__c, CloseDate, Contract_Start_Date__c,
  	                         Contract_End_Date__c, Type
  	                       FROM Opportunity LIMIT 1 ];    
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
  
  //======================================================================//
  // Test method for testCheckAccessOnAccountFor_ManagerOfTeam()
  //======================================================================//
  static testmethod void testCheckAccessOnAccountFor_ManagerOfTeam() {
    List<Opportunity> testOppLst = new List<Opportunity>(); 
    List<User> manager = [SELECT Id, firstName, lastname, UserRoleId 
                    FROM User
                    WHERE UserRoleId =: userRoleMap.get(MANAGER_USER).ID];
    system.debug('manager>>>' +manager);
                                                 
    //start test
   /* Test.startTest();
    System.runAs(manager) {
      testOppLst.add(Test_Utils.createOpportunity(testAccount.Id));
      testOppLst.get(0).Amount = 100;
      insert testOppLst;
    }
    //stop test
    Test.stopTest();

    //Assert to check opportunity has been created
    System.assertNotEquals([SELECT ID, AccountId FROM Opportunity WHERE AccountId =: testAccount.Id].ID, null); */
  }
  
  //======================================================================//
  // Method for test data
  //======================================================================//      
  @testSetup
  public static void createTestData() {     
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User sysAdmin = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert sysAdmin;
        
    testAccount = Test_Utils.insertAccount();

    Contact newcontact  = Test_Utils.insertContact(testAccount.id);
 
    Address__c address = Test_Utils.insertAddress(true);
        
    Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);

    Contact newcontact2  = Test_Utils.insertContact(testAccount.id);

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
    Id standardPricebookId = Test.getStandardPricebookId();
    PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebookId, Constants.CURRENCY_USD);

    //insert OLI
    OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id, testOpp.Type);
    opportunityLineItem1.Start_Date__c = Date.today().addDays(5);
    opportunityLineItem1.End_Date__c = System.today().addDays(10);
    insert opportunityLineItem1;
    
    //*********************************************
    Map<String, User> userMap = new Map<String, User>();
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
    system.debug('===userMap>>>' +userMap.values());
    Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, address.Id, testAccount.Id);
       
    AccountTeamMember atm = new AccountTeamMember();
    atm.AccountId = testAccount.Id ;
    atm.UserId = userMap.get(SALES_EXEC_USER).ID;
    atm.TeamMemberRole = Constants.TEAM_ROLE_SALES_REP;
    insert atm;

    AccountShare newAccountShare = new AccountShare();
    newAccountShare.AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT;
    newAccountShare.AccountId = testAccount.ID;
    newAccountShare.OpportunityAccessLevel = Constants.ACCESS_LEVEL_EDIT;
    newAccountShare.UserOrGroupId = userMap.get(SALES_EXEC_USER).ID;
    insert newAccountShare;    
  }

}