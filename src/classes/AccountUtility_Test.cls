/**=====================================================================
 * Appirio, Inc
 * Name: AccountUtility_Test
 * Description: To test AccountUtility.cls
 * Created Date: Feb 05th 2015
 * Created By: Gaurav Kumar Chadha (Appirio)
 *
 * Date Modified              Modified By          Description of the update
 * Feb 16th, 2015             Noopur               T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
@isTest
private class AccountUtility_Test {

  //===========================================================================
  // Declaring static variables at class level
  //===========================================================================
  static map<String, List<AccountTeamMember>> testAccountIdListAccountTeamMemberMap;
  static map<String, AccountShare> testAccountidAccountShareMap = new map<String, AccountShare>();
  static set<Id> accIds;
  static Account acc;
  
  static {
    accIds = new set<Id>();
    for (Account accObj : [SELECT Id,Name 
                           FROM Account]) {
        if (accObj.Name != 'testAccount2') {
            acc = accObj;
        }
        accIds.add(accObj.Id);
    }
  }

  //============================================================================
  // Test method for testing fetchAccountTeamMember
  //============================================================================
  static testMethod void forFetchAccountTeamMember() {
    Test.startTest();
      testAccountIdListAccountTeamMemberMap = AccountUtility.fetchAccountTeamMember(accIds);
    Test.stopTest();
    system.assert(testAccountIdListAccountTeamMemberMap.containskey(String.valueOf(acc.id)));
    system.assertEquals(2, testAccountIdListAccountTeamMemberMap.get(String.valueOf(acc.id)).size());
  }

  //============================================================================
  // Test method for testing fetchAccountShare
  //============================================================================
  static testMethod void forFetchAccountShare() {
    Map<String, List<AccountShare>> testAccountIdListAccountShareMap;
    Test.startTest();
      testAccountIdListAccountTeamMemberMap = AccountUtility.fetchAccountTeamMember(accIds);
      testAccountIdListAccountShareMap = AccountUtility.fetchAccountShare(accIDs, testAccountIdListAccountTeamMemberMap);
    Test.stopTest();
    system.assert(testAccountIdListAccountShareMap.containskey(String.valueOf(acc.id)));
    system.assertEquals(2, testAccountIdListAccountShareMap.get(String.valueOf(acc.id)).size());
  }

  //============================================================================
  // Test method for testing populateAccShareMap
  //============================================================================
  static testMethod void forPopulateAccShareMap() {

   // createTestdata();
    Test.startTest();
      AccountUtility.populateAccShareMap(accIds, testAccountidAccountShareMap);
    Test.stopTest();
  }

  //============================================================================
  //  Method for creating test data to be used in various test methods
  //============================================================================
  @testSetup
  static void createTestdata() {

    AccountShare accShare;
    AccountShare accShare1;
    // Insert account
    acc = Test_Utils.insertAccount();
    Account acc1 = Test_Utils.insertAccount();
    acc1.Name = 'testAccount2';
    update acc1;

    accIds = new set<Id>();
    accIds.add(acc.id);
    accIds.add(acc1.id);

    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN];

    // Insert user
    User testUser = Test_Utils.createUser(p, 'test@gmail.com', 'test');
    insert testUser;
    // Insert user
    User testUser1 = Test_Utils.createUser(p, 'test1@gmail.com', 'test1');
    insert testUser1;

    // Create Account Team Members
    Test_Utils.createAccountTeamMembers(String.valueOf(acc.id) , String.valueOf(testUser.id) , true);
    Test_Utils.createAccountTeamMembers(String.valueOf(acc1.id) , String.valueOf(testUser1.id) , true);

    // Create account share
    accShare = Test_Utils.createAccountShare(String.valueOf(acc.id) , String.valueOf(testUser.id) , true);
    accShare1 = Test_Utils.createAccountShare(String.valueOf(acc1.id) , String.valueOf(testUser1.id) , true);

    // Populating account share map
    testAccountidAccountShareMap.put(acc.id, accShare);
    testAccountidAccountShareMap.put(acc1.id, accShare1);
  }
}