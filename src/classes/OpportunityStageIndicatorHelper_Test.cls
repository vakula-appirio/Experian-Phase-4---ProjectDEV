/**=====================================================================
 * Appirio, Inc
 * Test Class Name: OpportunityStageIndicatorHelper_Test
 * Class Name: OpportunityStageIndicatorHelper.cls
 * Description: To test functionality of OpportunityStageIndicatorHelper
 * Created Date: Apr 22nd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 29th, 2015               Noopur                       T-356448: Added code to cover the wrapper class and edqUKIUser
 * 18th Mar, 2015               Paul Kissick                 Added more tests for other circumstances.
 =====================================================================*/
@isTest
private class OpportunityStageIndicatorHelper_Test {

  //=========================================================================
  // Test funcitonality of helper class - basic constructor test
  //=========================================================================
  static testMethod void testOpportunityStageIndicatorHelper() {
    insert new Opportunity_Sales_Process__c( Name = Constants.OPPTY_STAGE_7, Sales_Process_Name__c = Constants.OPPTY_SALES_PROCESS_STANDARD);
    // Create Account
    Account accnt = Test_Utils.insertAccount();
    // Create Opportunity
    Opportunity opp = Test_Utils.insertOpportunity(accnt.ID);
    opp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    update opp;

    PageReference pageRef = Page.OpportunityStageIndicatorPage;
    Test.setCurrentPage(pageRef);

    Test.startTest();

    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
    OpportunityStageIndicatorHelper controller = new OpportunityStageIndicatorHelper(sc);

    // Check that constructor executed and populated opportunity
    System.assertEquals(controller.opp.ID, opp.ID);
    User currentUser = [SELECT Id,Region__c
                        FROM User
                        WHERE Id = : userinfo.getUserId()];
    String groupName = BusinessUnitUtility.getBusinessUnit(userinfo.getUserId()) ;
    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ) &&
      currentUser.Region__c == Constants.REGION_UKI) {
        System.assertEquals(controller.edqUKIUser,true);
      }
      else {
        System.assertEquals(controller.edqUKIUser,false);
      }

    Test.stopTest();
  }

  //=========================================================================
  // Test functionality of helper class for Opp closed/lost
  //=========================================================================
  static testMethod void testOpportunityClosedLost() {
    // Creating admin user
    User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser;
    insert new Opportunity_Sales_Process__c( Name = Constants.OPPTY_STAGE_7, Sales_Process_Name__c = Constants.OPPTY_SALES_PROCESS_STANDARD);

    System.runAs(testUser) {

      // Create Account
      Account accnt = Test_Utils.insertAccount();
      // Create Opportunity
      Opportunity opp = Test_Utils.insertOpportunity(accnt.ID);
      opp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      update opp;
      opp.StageName = Constants.OPPTY_CLOSED_LOST;
      update opp;
      Test_Utils.createOpptyTasks(opp.Id, true);
      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                    AccountId = accnt.Id, Email = 'larrye@email.com');
      insert newcontact;

      OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id,
                                               OpportunityId = opp.Id, IsPrimary = true, Role = 'Decider');
      insert oppContactRole ;

      PageReference pageRef = Page.OpportunityStageIndicatorPage;
      Test.setCurrentPage(pageRef);

      Test.startTest();

      ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
      OpportunityStageIndicatorHelper controller = new OpportunityStageIndicatorHelper(sc);

      // Check that constructor executed and populated opportunity
      System.assertEquals(controller.opp.ID, opp.ID);

      System.assert(controller.hasSelectionConfirmed);
      System.assert(controller.hasSignedContract);
      System.assert(controller.hasQuoteDelivered);
      System.assert(controller.hasContactRole);
      System.assert(controller.hasCompletedTask);

      Test.stopTest();
    }
  }

  static testMethod void testEDQUser() {
    CPQ_Settings__c cpqSettings1 = new CPQ_Settings__c(
      Name = 'CPQ',
      Company_Code__c = 'Experian',
      CPQ_API_Access_Word__c = 'password',
      CPQ_API_Endpoint__c = 'https://doesntmatter/endpoint.asmx',
      CPQ_API_UserName__c = 'username'
    );
    insert cpqSettings1;
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    User edqUser = Test_Utils.createEDQUser(p, 'test1234@gmail.com', 'test1');
    insert edqUser;
    insert new Opportunity_Sales_Process__c( Name = Constants.OPPTY_STAGE_7, Sales_Process_Name__c = Constants.OPPTY_SALES_PROCESS_STANDARD);
    edqUser.Region__c = Constants.REGION_UKI;
    edqUser.CPQ_User_Type__c = 'EDQ Sales';
    edqUser.CPQ_User__c = false;
    update edqUser;

    System.runAs(edqUser) {

      // Create Account
      Account testAccount = Test_Utils.insertEDQAccount(true);

      // Create an Contact
      Contact con1  = new Contact (FirstName = 'Test 1', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
      con1.EDQ_On_Demand__c = true;
      con1.Title = 'NewTitle';
      con1.EDQ_Integration_Id__c = 'TESTID0011001002';
      con1.Phone = '9799559433';
      insert con1;

      // Create an opportunity
      Opportunity opp = Test_Utils.insertOpportunity(testAccount.ID);
      opp.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      update opp;

      OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = con1.Id,
                                               OpportunityId = opp.Id, IsPrimary = true, Role = 'Decider');
      insert oppContactRole ;

      PageReference pageRef = Page.OpportunityStageIndicatorPage;
      Test.setCurrentPage(pageRef);

      Test.startTest();

      ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
      OpportunityStageIndicatorHelper controller = new OpportunityStageIndicatorHelper(sc);

      //Check that constructor executed and populated opportunity
      System.assertEquals(controller.opp.ID, opp.ID);
      system.assertEquals(true,controller.edqUKIUser,'Not EDQ User');

      Test.stopTest();
    }
  }
}