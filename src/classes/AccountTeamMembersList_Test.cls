/**=====================================================================
 * Appirio, Inc
 * Name: AccountTeamMembersList_Test
 * Description: T-366039: Test class for AccountTeamMembersList
 * Created Date: March 2nd, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By           Description of the update
 * Mar 4th,2015             Noopur                Added logic to verify the deletion of
 *                                                Confidential Information share records
 *                                                on the deletion of the Account Team Members.
 * Mar 11th,2015            Arpita Bose           T-368099: Updated code to verify auto-create Confidential_Information__Share
 *                                                records when ATM is created
  =====================================================================*/
@isTest
private class AccountTeamMembersList_Test {

    // Method to verify the functionality of AccountTeamMembersList controller
  static testMethod void basicTest() {

    //fetch the created Account and User
    Account acc = [SELECT Id FROM Account WHERE Name = 'testAccount'];
    User usr = [SELECT Id FROM User WHERE FirstName = 'Test Test User' limit 1];

      // Set the standard controller and call the constructor.
    ApexPages.Standardcontroller std = new ApexPages.Standardcontroller(acc);
    AccountTeamMembersList controller = new AccountTeamMembersList(std);

    // Call the methods and create new team member
    controller.addTeamMembers();
    controller.newAccountTeamMembers[0].member.UserId = usr.Id;
    controller.newAccountTeamMembers[0].member.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
    controller.newAccountTeamMembers[0].accountAccess = Label.AccountTeamMembersList_Edit;
    controller.newAccountTeamMembers[0].opportunityAccess = Label.AccountTeamMembersList_Read;
    controller.newAccountTeamMembers[0].caseAccess = Label.AccountTeamMembersList_Read;

    // Cancel (removes ATM from the list)
    controller.doCancel();

    List<AccountTeamMember> atm = [SELECT Id,TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.Id];
    System.assertEquals(0, atm.size());

    // Try again, and then save
    controller.addTeamMembers();
    controller.newAccountTeamMembers[0].member.UserId = usr.Id;
    controller.newAccountTeamMembers[0].member.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
    controller.newAccountTeamMembers[0].accountAccess = Label.AccountTeamMembersList_Edit;
    controller.newAccountTeamMembers[0].opportunityAccess = Label.AccountTeamMembersList_Read;
    controller.newAccountTeamMembers[0].caseAccess = Label.AccountTeamMembersList_Read;

    controller.saveAndMore();
    controller.showAccess();
    controller.showMoreRecords();

    // Verify that the new team member is created and has proper role as given by user
    atm = [SELECT Id,TeamMemberRole FROM AccountTeamMember WHERE UserId = :usr.Id];
    System.assertEquals(1, atm.size());
    System.assertEquals(atm.get(0).TeamMemberRole, Constants.TEAM_ROLE_SALES_MANAGER);

    // T-368099: Verify that the related confidential information share record is also deleted
    List<Confidential_Information__Share> coninfo = [ SELECT Id
                                                      FROM Confidential_Information__Share
                                                      WHERE RowCause = :Constants.ROWCAUSE_ACCOUNT_TEAM
                                                      AND Parent.Account__c = :acc.Id
                                                      AND UserOrGroupId = :usr.Id];

    System.assert(coninfo.size() == 1);

    // delete the Team Member created
    controller.selectedId = atm.get(0).Id;
    controller.doDelete();

    // Verify that the related confidential information share record is also deleted
    coninfo = [ SELECT Id FROM Confidential_Information__Share
                WHERE Parent.Account__c = :acc.Id
                AND UserOrGroupId = :usr.Id];
    System.assert(coninfo.size() == 0);

  }

    //=======================================================================
    // Create Test Data
    //=======================================================================
    @testSetup
  public static void createTestData() {
    Account acc = Test_Utils.createAccount();
    acc.Name = 'testAccount';
    insert acc;

    Confidential_Information__c conInfo = new Confidential_Information__c();
    conInfo.Account__c = acc.Id;
    conInfo.Synch_Account_Team_Members__c = true;
    insert conInfo;

    User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    testUser.FirstName = 'Test Test User';
    insert testUser;

  }
}