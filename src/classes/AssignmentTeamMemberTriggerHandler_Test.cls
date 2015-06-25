/******************************************************************************
 * Appirio, Inc
 * Name: AssignmentTeamMemberTriggerHandler_Test
 * Description: Test class for AssignmentTeamMemberTriggerHandler (for T-358272)
 * Created Date: Feb 03rd, 2015
 * Created By: Naresh kr Ojha (Appirio)
 *
 * Date Modified            Modified By                  Description of the update
 * Feb 18th , 2015          Gaurav Kumar Chadha           T-361103 - test Assignment_Team_Role__c
 ******************************************************************************/
@isTest
public with sharing class AssignmentTeamMemberTriggerHandler_Test {
  private static Assignment_Team_Member__c assgnTeamMem;
  private static Assignment_Team_Member__c assignTeamMemWithoutRole;
  private static User testUser;

  //================================================================================
  // Test method to verify the Assignment_Team_Member__c..._Starting_Value__c fields
  // are populated on insert
  //================================================================================
  public static testmethod void test_setStartingValues() {
    // Create users
    Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_SYS_ADMIN];
    testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'T-AE');
    insert testUser;

    System.runAs(testUser) {
      createTestData();

      Test.StartTest();
      insert assgnTeamMem;
      Test.StopTest();

      assgnTeamMem = [SELECT User__c, User_Starting_Value__c, IsActive__c, IsActive_Starting_Value__c ,
                      Id, Assignment_Team_Role__c, Assignment_Team_Role_Starting_Value__c
                      FROM Assignment_Team_Member__c
                      WHERE ID =: assgnTeamMem.ID];


      System.assertEquals(assgnTeamMem.User__c, assgnTeamMem.User_Starting_Value__c);
      System.assertEquals(assgnTeamMem.IsActive__c, assgnTeamMem.IsActive_Starting_Value__c);
      System.assertEquals(assgnTeamMem.Assignment_Team_Role__c, assgnTeamMem.Assignment_Team_Role_Starting_Value__c);

    }
  }

  //================================================================================
  // Test Assignment_Team_Role__c value is populated with User CSDA_Team_Role__c
  //================================================================================
  public static testmethod void test_assignmentTeamRole() {

    Profile p = [SELECT Id FROM Profile WHERE Name =: Constants.PROFILE_SYS_ADMIN];
    testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'T-AE');
    testUser.CSDA_Team_Role__c = Constants.TEAM_ROLE_DELIVERY_TEAM;
    insert testUser;

  System.runAs(testUser) {
      createTestData();

      Test.StartTest();
      insert assignTeamMemWithoutRole;
      Test.StopTest();

      assignTeamMemWithoutRole = [SELECT User__c, Id, Assignment_Team_Role__c
                                   FROM Assignment_Team_Member__c
                                  WHERE ID =: assignTeamMemWithoutRole.ID];

      System.assertEquals(Constants.TEAM_ROLE_DELIVERY_TEAM , assignTeamMemWithoutRole.Assignment_Team_Role__c );
    }

  }

  //================================================================================
  // Test Data Creation
  //================================================================================
  private static void createTestData () {
    // Create accounts
    Account testAcc = Test_Utils.createAccount();
    List<Account> accountList = new List<Account>();
    accountList.add(testAcc);
    insert accountList;

    // Create assignment teams
    Assignment_Team__c assgnTeam = Test_Utils.insertAssignmentTeam(false, testUser.Id);

    List<Assignment_Team__c> assignmentTeams = new List<Assignment_Team__c>();
    assignmentTeams.add(assgnTeam);
    insert assignmentTeams;

    // Create assignment team members
    List<Assignment_Team_Member__c> lstAssgnTeamMem = new List<Assignment_Team_Member__c>();


    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, testUser.Id, Constants.TEAM_ROLE_CHANNEL_MANAGER);
    assignTeamMemWithoutRole = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, testUser.Id, null );
  }
}