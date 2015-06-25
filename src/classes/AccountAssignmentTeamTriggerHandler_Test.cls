/**=====================================================================
 * Appirio, Inc
 * Name: AccountAssignmentTeamTriggerHandler_Test
 * Description: T-354803: Test class for AccountAssignmentTeamTriggerHandler
 * Created Date: Jan 21st, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 21rd, 2015               Noopur                       Added logic to test After Delete
 * Jan 21st, 2015               Nathalie Le Guay             Adding asserts
 * Jan 23rd, 2015               Noopur                       Modified the test class and added scenarios as per the task T-355759
 * Feb 3rd, 2015                Nathalie Le Guay             T-358842: Verify the Assignment_Team__c.Account_Executive__c no longer is on the ATM when AAT deleted
 * Feb 16th, 2015               Noopur                       T-360546 : modified the class to add the new features related to @testSetup
 * Apr 3rd, 2015                Nathalie Le Guay             I-154256: Add testdeleteAccountAssignmentTeamWithNoMembers()
 * Apr 28th, 2015               Arpita Bose                  Updated method testAddAccAssigTeamMemberToAccTeam() to fix failure
  =====================================================================*/
@isTest (seeAllData = false)
public class AccountAssignmentTeamTriggerHandler_Test {
  //private static List<User> lstUser;
  private static Account testAcc,testAcc2,testAcc3,testAcc4,testAcc5;
  private static Assignment_Team__c assgnTeam, assgnTeam2,assgnTeam3, assgnTeam4,assgnTeam5;

  //================================================================================
  // Test method to verify AccountTeamMembers and AccountShares are created properly 
  //================================================================================
  public static testmethod void testAddAccAssigTeamMemberToAccTeam(){
    setRecords();
    List<User> lstUser = [select Id, email , UserRole.Name,UserRoleId
                          from User 
                          where isActive = true 
                          AND email LIKE 'test1234@gmail.com%'
                          order by email];

    // create assignment team members
    createAssignmentTeamMembers(lstUser); 

    //start test
    Test.startTest();
    // create Account Assignment Team
    createAccountAssignmentTeams();

    set<Id> accountIds = new set<Id>{testAcc.Id, testAcc2.Id, testAcc3.Id, testAcc4.Id, testAcc5.Id};

    // stop test
    Test.stopTest();
    // Asserts to verify that AccounTeamMember records are created
    map<Id,set<Id>> atmAccUserIdMap = new map<Id,set<Id>>();
    List<AccountTeamMember> accTeamMembersAdded = new List<AccountTeamMember>();
    for (AccountTeamMember atm: [SELECT Id, UserId,AccountId, TeamMemberRole
                                 FROM AccountTeamMember
                                 WHERE AccountId IN :accountIds]) {
      if ( !atmAccUserIdMap.containsKey(atm.AccountId)) {
        atmAccUserIdMap.put(atm.AccountId,new set<Id>{atm.UserId});
      }
      else {
        atmAccUserIdMap.get(atm.AccountId).add(atm.UserId);
      }
      if (atm.UserId == lstUser.get(0).Id) {
        system.assertEquals(atm.TeamMemberRole, Constants.TEAM_ROLE_CHANNEL_MANAGER); 
      }
      else if (atm.UserId == lstUser.get(1).Id) {
        system.assertEquals(atm.TeamMemberRole, Constants.TEAM_ROLE_LEAD_QUALIFIER);
      }
     accTeamMembersAdded.add(atm);
    }
    system.assert(accTeamMembersAdded.size() >= 20);

    // Asserts to verify the AccountTeamMember records with active Assignment_Team_Member__c records
    system.assert(atmAccUserIdMap.get(testAcc.Id).contains(lstUser.get(0).Id));//testUser1.Id));
    system.assert(atmAccUserIdMap.get(testAcc2.Id).contains(lstUser.get(2).Id));//testUser3.Id));
    system.assert(atmAccUserIdMap.get(testAcc3.Id).contains(lstUser.get(4).Id));//testUser5.Id));
    system.assert(atmAccUserIdMap.get(testAcc4.Id).contains(lstUser.get(6).Id));//testUser7.Id));
    system.assert(atmAccUserIdMap.get(testAcc5.Id).contains(lstUser.get(8).Id));//testUser9.Id));

    // Verify that none of the User of a specific AT were assigned to an Account they were not supposed to
    system.assert(!atmAccUserIdMap.get(testAcc.Id).contains(lstUser.get(5).Id));//testUser6.Id));
    system.assert(!atmAccUserIdMap.get(testAcc2.Id).contains(lstUser.get(0).Id));//testUser1.Id));
    system.assert(!atmAccUserIdMap.get(testAcc3.Id).contains(lstUser.get(7).Id));//testUser8.Id));
    system.assert(!atmAccUserIdMap.get(testAcc4.Id).contains(lstUser.get(1).Id));//testUser2.Id));
    system.assert(!atmAccUserIdMap.get(testAcc5.Id).contains(lstUser.get(3).Id));//testUser4.Id));

    // Asserts to verify that AccountShare records are created
    List<AccountShare> accShare = [SELECT Id, AccountAccessLevel,AccountId, OpportunityAccessLevel, CaseAccessLevel,
                                   UserOrGroupId FROM AccountShare WHERE AccountId = :testAcc.Id];
    system.assertEquals(true, accShare.size() >= 4);
    for (AccountShare ac: accShare) {
      if (atmAccUserIdMap.get(ac.AccountId).contains(ac.UserOrGroupId) && ac.UserOrGroupId != userinfo.getUserId()) {
        system.assertEquals(Constants.ACCESS_LEVEL_EDIT, ac.AccountAccessLevel);
        system.assertEquals(Constants.ACCESS_LEVEL_EDIT, ac.OpportunityAccessLevel);
        system.assertEquals(Constants.ACCESS_LEVEL_NONE, ac.CaseAccessLevel); 
      }
    }
  }

  private static List<Account_Assignment_Team__c> accAssgnTeamToDelete = new List<Account_Assignment_Team__c>{};
  
  //==========================================================================================
  // Test method that will verify that AccountTeamMember and AccountShare are deleted properly
  // when the Assignment Team has an Account Executive but NO Team Members
  //==========================================================================================
  public static testmethod void testdeleteAccountAssignmentTeamWithNoMembers() {
    setRecords();

    Test.startTest();
    // Create Account Assignment Team
    createAccountAssignmentTeams();

    set<Id> accountIds = new set<Id>{testAcc.Id, testAcc3.Id,testAcc4.Id,testAcc5.Id};

    delete accAssgnTeamToDelete;

    Test.stopTest();

    List<User> lstUser = [SELECT Id FROM User WHERE Email='test1234@gmail.com2' LIMIT 1];
    for (AccountTeamMember atm: [SELECT Id, UserId,AccountId, TeamMemberRole
                                 FROM AccountTeamMember
                                 WHERE AccountId IN :accountIds]) {
      system.assertNotEquals(lstUser.get(0).Id, atm.UserId);
    }
    
  }
  
  
  //==========================================================================================
  // Test method that will verify that AccountTeamMember and AccountShare are deleted properly
  //==========================================================================================
  public static testmethod void testdeleteRelatedAccountTeamMembers() {
    setRecords();
    List<User> lstUser = [select Id, email , UserRole.Name,UserRoleId
                          from User 
                          where isActive = true 
                          AND email LIKE 'test1234@gmail.com%'
                          order by email];

    // create assignment team members
    createAssignmentTeamMembers(lstUser);

    Test.startTest();
    // Create Account Assignment Team
    createAccountAssignmentTeams();

    set<Id> accountIds = new set<Id>{testAcc.Id, testAcc3.Id,testAcc4.Id,testAcc5.Id};

    delete accAssgnTeamToDelete;

    Test.stopTest();


    Map<Id, Set<Id>> atmAccUserIdMap = new Map<Id, Set<Id>>();
    List<AccountTeamMember> accTeamMembersAdded = new List<AccountTeamMember>();
    for (AccountTeamMember atm: [SELECT Id, UserId,AccountId, TeamMemberRole
                                 FROM AccountTeamMember
                                 WHERE AccountId IN :accountIds]) {
      if ( !atmAccUserIdMap.containsKey(atm.AccountId)) {
        atmAccUserIdMap.put(atm.AccountId,new set<Id>{atm.UserId});
      }
      else {
        atmAccUserIdMap.get(atm.AccountId).add(atm.UserId);
      }
     accTeamMembersAdded.add(atm);
    }
    system.assert(accTeamMembersAdded.size() >= 12); // testAcct: 1; testAcc2: 4; testAcc3:4; testAcc4: 4

    // Verify that common user in all the five AT is still in the Account team of the remaining 3 AccountTeams
    system.assert(atmAccUserIdMap.get(testAcc3.Id).contains(lstUser.get(10).Id));//testUser10.Id));
    system.assert(atmAccUserIdMap.get(testAcc4.Id).contains(lstUser.get(10).Id));//testUser10.Id));
    system.assert(atmAccUserIdMap.get(testAcc5.Id).contains(lstUser.get(10).Id));//testUser10.Id));

    // Verify that the Account Executive no longer is on the Account Team
    system.assert(!atmAccUserIdMap.get(testAcc.Id).contains(lstUser.get(2).Id)); // The Account Executive should be gone

    // Asserts to verify that AccountShare records are set appropriately
    List<AccountShare> accShare = [SELECT Id, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel,
                                   UserOrGroupId FROM AccountShare WHERE AccountId IN :accountIds];
    system.assertEquals(true, accShare.size() >= 13);
    Boolean foundMember = false;
    Boolean foundDeletedMember1 = false;
    Boolean foundDeletedMember2 = false;
    for (AccountShare ac: accShare) {
      if (ac.UserOrGroupId == lstUser.get(10).Id) {
        foundMember = true;
      }
      if (ac.UserOrGroupId == lstUser.get(0).Id || ac.UserOrGroupId == lstUser.get(1).Id) {
        foundDeletedMember1 = true;
      }
      if (ac.UserOrGroupId == lstUser.get(2).Id || ac.UserOrGroupId == lstUser.get(3).Id) {
        foundDeletedMember2 = true;
      }
    }
    system.assertEquals(true, foundMember);
    system.assertEquals(false, foundDeletedMember1);
    system.assertEquals(false, foundDeletedMember2);
  }


  //==========================================================
  // Creates test data: Assignment_Team__c & members
  // This method is also used by BatchAssignmentTeam_Test.cls
  //==========================================================
  @testSetup
  static void createTestData() {
    // create test data

    // create users
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN];
    List<User> lstUser = Test_Utils.createUsers(p, 'test1234@gmail.com', 'T-AE', 11);
    insert lstUser;

    // create accounts
    testAcc = Test_Utils.createAccount();
    testAcc.ownerId = userinfo.getuserId();
    testAcc2 = Test_Utils.createAccount();
    testAcc2.ownerId = userinfo.getuserId();
    testAcc3 = Test_Utils.createAccount();
    testAcc3.ownerId = userinfo.getuserId();
    testAcc4 = Test_Utils.createAccount();
    testAcc4.ownerId = userinfo.getuserId();
    testAcc5 = Test_Utils.createAccount();
    testAcc5.ownerId = userinfo.getuserId();
    List<Account> accountList = new List<Account>();
    accountList.add(testAcc);
    accountList.add(testAcc2);
    accountList.add(testAcc3);
    accountList.add(testAcc4);
    accountList.add(testAcc5);
    insert accountList;

    // create assignment teams
    assgnTeam = Test_Utils.insertAssignmentTeam(false, lstUser.get(2).Id);
    assgnTeam.ownerId = userinfo.getuserId();
    assgnTeam2 = Test_Utils.insertAssignmentTeam(false, null);
    assgnTeam2.ownerId = userinfo.getuserId();
    assgnTeam3 = Test_Utils.insertAssignmentTeam(false, null);
    assgnTeam3.ownerId = userinfo.getuserId();
    assgnTeam4 = Test_Utils.insertAssignmentTeam(false, null);
    assgnTeam4.ownerId = userinfo.getuserId();
    assgnTeam5 = Test_Utils.insertAssignmentTeam(false, null);
    assgnTeam5.ownerId = userinfo.getuserId();

    List<Assignment_Team__c> assignmentTeams = new List<Assignment_Team__c>();
    assignmentTeams.add(assgnTeam);
    assignmentTeams.add(assgnTeam2);
    assignmentTeams.add(assgnTeam3);
    assignmentTeams.add(assgnTeam4);
    assignmentTeams.add(assgnTeam5);

    insert assignmentTeams;


  }

  //==========================================================
  // create assignment team members
  //==========================================================
  private static void createAssignmentTeamMembers(List<User> lstUser) {
    List<Assignment_Team_Member__c> lstAssgnTeamMem = new List<Assignment_Team_Member__c>();
    Assignment_Team_Member__c assgnTeamMem;
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(0).Id, Constants.TEAM_ROLE_CHANNEL_MANAGER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(1).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(2).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(3).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam3.Id, lstUser.get(4).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam3.Id, lstUser.get(5).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam4.Id, lstUser.get(6).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam4.Id, lstUser.get(7).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam5.Id, lstUser.get(8).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam5.Id, lstUser.get(9).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(10).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(10).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam3.Id, lstUser.get(10).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam4.Id, lstUser.get(10).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem);
    assgnTeamMem = Test_Utils.insertAssignmentTeamMember(false, assgnTeam5.Id, lstUser.get(10).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem);
    insert lstAssgnTeamMem;
  }

  //==========================================================
  // CreateAccountAssignmentTeams
  //==========================================================
  public static void createAccountAssignmentTeams() {
  	
    List<Account_Assignment_Team__c> accountAssignTeamList= new List<Account_Assignment_Team__c>();
    Account_Assignment_Team__c accAssgnTeam1 = Test_utils.insertAccAssignmentTeam(false, assgnTeam.Id, testAcc.Id);
    Account_Assignment_Team__c accAssgnTeam2 = Test_utils.insertAccAssignmentTeam(false, assgnTeam2.Id, testAcc2.Id);
    Account_Assignment_Team__c accAssgnTeam3 = Test_utils.insertAccAssignmentTeam(false, assgnTeam3.Id, testAcc3.Id);
    Account_Assignment_Team__c accAssgnTeam4 = Test_utils.insertAccAssignmentTeam(false, assgnTeam4.Id, testAcc4.Id);
    Account_Assignment_Team__c accAssgnTeam5 = Test_utils.insertAccAssignmentTeam(false, assgnTeam5.Id, testAcc5.Id);

    accountAssignTeamList.add(accAssgnTeam1);
    accountAssignTeamList.add(accAssgnTeam2);
    accountAssignTeamList.add(accAssgnTeam3);
    accountAssignTeamList.add(accAssgnTeam4);
    accountAssignTeamList.add(accAssgnTeam5);

    insert accountAssignTeamList;

    accAssgnTeamToDelete.add(accAssgnTeam1);
    accAssgnTeamToDelete.add(accAssgnTeam2);
  }

  //==========================================================
  // Set records to be used by methods
  //==========================================================
  public static void setRecords() {
    List<Assignment_Team__c> assignmentTeams = [SELECT Id,Account_Executive__c,Primary_Team__c
                                                FROM Assignment_Team__c];
    assgnTeam = assignmentTeams[0];
    assgnTeam2 = assignmentTeams[1];
    assgnTeam3 = assignmentTeams[2];
    assgnTeam4 = assignmentTeams[3];
    assgnTeam5 = assignmentTeams[4];

    List<Account> accounts = [SELECT Id,Name
                              FROM Account];
    testAcc = accounts[0];
    testAcc2 = accounts[1];
    testAcc3 = accounts[2];
    testAcc4 = accounts[3];
    testAcc5 = accounts[4];
  }
}