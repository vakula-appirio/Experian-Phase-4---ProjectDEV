/******************************************************************************
 * Appirio, Inc
 * Name: BatchAccountTeamMemberCI_Test
 * Description:  Story:     S-277737
 *               Task:      T-357474
 *               The following test class is designed to test the 'BatchAccountTeamMemberCI.cls' class.
 * Created Date: Feb 04th, 2015
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Feb 04th, 2015               Arpita Bose(Appirio)         Updated method testBatch()
 * Mar 27th, 2015               Suminder Singh(Appirio)      Updated method testBatch() to check Assert
 ******************************************************************************/
@isTest
public with sharing class BatchAccountTeamMemberCI_Test {

  //==========================================================================
  // Create AccountTeamMember records, and make sure the batch creates
  // Confidential_Information__Share records
  //==========================================================================
  @isTest
  static void testBatch() {
    // Create Global Setting for datetime , for the test method.
    TestMethodUtilities.createTestGlobalSettings();
    Global_Settings__c lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
    lastRun.Batch_Failures_Email__c = '';
    Datetime testBeforeDateTime = lastRun.Account_Team_Member_Job_Last_Run__c ;
    lastRun.Account_Team_Member_CI_Job_Last_Run__c = lastRun.Account_Team_Member_CI_Job_Last_Run__c.addMinutes(-60);
    update lastRun;

    lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);

    // put the datetime into a format that can be used by the SOQL query below
     String testDateSOQL = lastRun.Account_Team_Member_CI_Job_Last_Run__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');

     Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_SYS_ADMIN];

     User testUser1 = Test_Utils.createUser(p, 'test1@gmail.com', 'test1');
     insert testUser1;
     User testUser2 = Test_Utils.createUser(p, 'test2@gmail.com', 'test2');
     insert testUser2;
     User testUser3 = Test_Utils.createUser(p, 'test3@gmail.com', 'test3');
     insert testUser3;
     
     Account testAcc = Test_Utils.insertAccount();
     
     Confidential_Information__c conInfo = new Confidential_Information__c ();
     conInfo.Account__c = testAcc.Id;
     conInfo.Synch_Account_Team_Members__c = true;
     insert conInfo;
          
     // start test
     Test.StartTest();
     //Line from 56 to 64 Commented by Rohit B because trigger is not active so these records will not be created.
     /*List<Confidential_Information__Share> conShare ;
     conShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM ];        
     
     // Assert to verify there are Share Records on the Confidential Information record (Created By Trigger)
     System.debug('=================='+conShare);
     system.assert(conShare.size()> 0);*/

     //Creating Account Team Members, which should be synched after execution of the batch
     AccountTeamMember mem1 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser1.Id, Constants.TEAM_ROLE_ACCOUNT_MANAGER );
     AccountTeamMember mem2 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser1.Id, Constants.TEAM_ROLE_CHANNEL_MANAGER );
     AccountTeamMember mem3 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser2.Id, Constants.TEAM_ROLE_LEAD_QUALIFIER );
     AccountTeamMember mem4 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser3.Id, Constants.TEAM_ROLE_SALES_REP );

     List <AccountTeamMember> testMembers = new List<AccountTeamMember>();
     testMembers.add(mem1);
     testMembers.add(mem2);
     testMembers.add(mem3);
     testMembers.add(mem4);
     insert testMembers;
     
     //Execution of the batch
     BatchAccountTeamMemberCI batu = new BatchAccountTeamMemberCI();
     ID batchprocessid = Database.executeBatch(batu);
     batu.execute((Database.BatchableContext) null, testMembers);

     //Stop test
     Test.StopTest();

     List<Confidential_Information__Share> ResultConShare ;
     ResultConShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                       FROM Confidential_Information__Share
                       WHERE ParentId =: conInfo.Id
                       AND RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM ];
     
     //Assert to check that batch has executed successfully and last run time updated
     System.assert(testBeforeDateTime != batu.lastRun.Account_Team_Member_CI_Job_Last_Run__c);

     // Assert to verify there are Confidential_Information__Share records created for each ATM
     System.assert(ResultConShare.size() == 4);

  }
}