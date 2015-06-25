/**=====================================================================
 * Appirio, Inc
 * Name: ConfidentialInfoTriggerHandler_Test
 * Description: To test functionality of ConfidentialInformationTriggerHandler.cls
 * Created Date: 31st March, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified            Modified By             Description of the update
 * Mar 31, 2014             Arpita Bose             testSynchOpptyTeamChecked(), testSynchOpptyTeamUnChecked(), testSynchOpptyTeamUnChecked2()
 * Mar 31, 2014             Nathalie Le Guay        Added call to Test_Utils when creating users
 * Jan 29th, 2015           Nathalie Le Guay        T-357396: Populate RT field
 * Feb 19th 2015            Peter Martin            T-363959: delete Evergreen field
 * Feb 24th, 2015           Gaurav Kumar Chadha     T-364943: added testSynchAccTeamChecked()
 =====================================================================*/
@isTest
public with sharing class ConfidentialInfoTriggerHandler_Test {
  private static RecordType confInfoOppRT = [SELECT Id,Name FROM RecordType WHERE SObjectType =: Constants.SOBJECT_CONFIDENTIAL_INFO
                                                      AND Name =: Constants.RECORDTYPE_CONF_INFO_OPPTY LIMIT 1];


  //============================================================================
  // Scenario-1 - checking Synch_Opportunity_Team_Members__c
  //============================================================================
  static testmethod void testSynchOpptyTeamChecked(){

    Confidential_Information__c conInfo = [ SELECT ID , Opportunity__c , Synch_Opportunity_Team_Members__c ,
                                            RecordTypeId , Contract__c
                                            FROM Confidential_Information__c
                                            LIMIT 1 ];

    list<OpportunityTeamMember > lstMember = [ SELECT ID , TeamMemberRole,OpportunityId
                                      FROM OpportunityTeamMember ];


    // start test
    Test.startTest();

    conInfo.Synch_Opportunity_Team_Members__c = true;
    update conInfo;

    List<Confidential_Information__Share> conShare ;
    conShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM ];

    // Assert to verify the # matches with the # of opportunityTeamMembers
    System.assertEquals(lstMember.size(), conShare.size());

    conInfo.Synch_Opportunity_Team_Members__c = false;
    update conInfo;

    // stop test
    Test.stopTest();

    List<Confidential_Information__Share> conShare1 ;
    conShare1 = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM];
    // Assert to verify there are no Confidential_Information__Share records left
    system.debug('\n[ConfidentialInfoTriggerHandler_Test : testSynchOpptyTeamUnChecked] ###Conshare1'+conShare1);
    system.assert(conShare1.size() == 0);

  }


  //============================================================================
  // Scenario-2 - unchecking Synch_Opportunity_Team_Members__c
  //============================================================================
  static testmethod void testSynchOpptyTeamUnChecked(){

    Confidential_Information__c conInfo = [ SELECT ID , Opportunity__c , Synch_Opportunity_Team_Members__c ,
                                            RecordTypeId , Contract__c
                                            FROM Confidential_Information__c
                                            LIMIT 1 ];

    // start test
    Test.startTest();
    List<Confidential_Information__Share> conShare ;
    conShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM ];
    system.debug('\n[ConfidentialInfoTriggerHandler_Test : testSynchOpptyTeamUnChecked] @@@Conshare'+conShare);
    // Assert to verify there are no Share Records on the Confidential Information record
    system.assert(conShare.size()== 0);

    conInfo.Synch_Opportunity_Team_Members__c = true;
    update conInfo;

    List<Confidential_Information__Share> ResultConShare ;
    ResultConShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                      FROM Confidential_Information__Share
                      WHERE ParentId =: conInfo.Id
                      AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM ];

    Test.stopTest();
    // Assert to verify there are Confidential_Information__Share records
    system.assert(ResultConShare.size() > 0);
  }

  //============================================================================
  // Scenario-3
  //============================================================================
  static testmethod void testSynchOpptyTeamUnChecked2(){

   Confidential_Information__c conInfo = [ SELECT ID , Opportunity__c , Synch_Opportunity_Team_Members__c ,
                                            RecordTypeId , Contract__c
                                            FROM Confidential_Information__c
                                            LIMIT 1 ];

    // start test
    Test.startTest();
    List<Confidential_Information__Share> conShare ;
    conShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM ];
    // Assert to verify there are no Share Records on the Confidential Information record
    system.assert(conShare.size() == 0);

    conInfo.Name = 'Test';
    update conInfo;

    List<Confidential_Information__Share> ResultConShare ;
    ResultConShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                      FROM Confidential_Information__Share
                      WHERE ParentId =: conInfo.Id
                      AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM ];

    Test.stopTest();

    // Assert to verify there are no Confidential_Information__Share records
    system.assert(ResultConShare.size() == 0);

  }

  //============================================================================
  // T-364943 - Unit test for ConfidentialInformationTriggerHandler.syncAccountTeam()
  //============================================================================
  static testmethod void testSynchAccTeamChecked(){
    Confidential_Information__c conInfo = [ SELECT ID , Account__c , Synch_Account_Team_Members__c  ,
                                            RecordTypeId , Contract__c
                                            FROM Confidential_Information__c
                                            LIMIT 1 ];

    list<AccountTeamMember > lstMember = [ SELECT ID , TeamMemberRole, AccountId
                                      FROM AccountTeamMember ];

    // start test
    Test.startTest();

    conInfo.Synch_Account_Team_Members__c = true;
    update conInfo;

    List<Confidential_Information__Share> conShare ;
    conShare = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM ];

    // Assert to verify the # matches with the # of opportunityTeamMembers
    System.assertEquals(lstMember.size(), conShare.size());

    conInfo.Synch_Account_Team_Members__c = false;
    update conInfo;

    // stop test
    Test.stopTest();

    List<Confidential_Information__Share> conShare1 ;
    conShare1 = [SELECT ID, ParentId, UserOrGroupId, AccessLevel
                FROM Confidential_Information__Share
                WHERE ParentId =: conInfo.Id
                AND RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM];
    // Assert to verify there are no Confidential_Information__Share records left
    system.debug('\n[ConfidentialInfoTriggerHandler_Test : testSynchOpptyTeamUnChecked] ###Conshare1'+conShare1);
    system.assert(conShare1.size() == 0);

  }

  //=============================================================================================
  // Create Test Data
  //=============================================================================================
  @testSetup static void testData() {
   // create User
    Profile p = [SELECT Id FROM Profile WHERE name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
    User testUser2 = Test_Utils.createUser(p, 'test2345@gmail.com', 'test2');
    insert testUser2;

    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    // create Acc Team Member
    AccountTeamMember accAccountTeamMember = Test_Utils.createAccountTeamMembers(testAcc.id,testUser1.id,true);
    AccountTeamMember accAccountTeamMember2 = Test_Utils.createAccountTeamMembers(testAcc.id,testUser2.id,true);


    // create Opp Team Member
    OpportunityTeamMember member1 = Test_Utils.insertOpportunityTeamMember(true, testOpp.Id, testUser1.Id, Constants.TEAM_ROLE_ACCOUNT_MANAGER);

    OpportunityTeamMember member2 = Test_Utils.insertOpportunityTeamMember(true, testOpp.Id, testUser2.Id, Constants.TEAM_ROLE_SALES_REP);

    List<OpportunityTeamMember> lstMember = new List<OpportunityTeamMember>();
    lstMember.add(member1);
    lstMember.add(member2);
    insert lstMember;

    Contract__c contract1 = new Contract__c();
    contract1.Account__c = testAcc.Id;
    //T-363959
    //contract1.Evergreen__c = 'Yes';
    insert contract1;

    Membership__c members1 = new Membership__c();
    members1.Account__c = testAcc.Id;
    members1.Opportunity__c = testOpp.Id;
    insert members1;

    Confidential_Information__c conInfo = new Confidential_Information__c ();
    conInfo.Opportunity__c = testOpp.Id;
    conInfo.Synch_Opportunity_Team_Members__c = false;
    conInfo.RecordTypeId = confInfoOppRT.Id;
    conInfo.Contract__c = contract1.Id;
    conInfo.Account__c = testAcc.Id;
    insert conInfo;

  }

}