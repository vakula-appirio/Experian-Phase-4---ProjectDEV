/**=====================================================================
 * Appirio, Inc
 * Name: CaseTrigger_ResolutionTime_Test 
 * Description: Test class for CaseTrigger_ResolutionTime.cls (T-405528)
 * Created Date: June 18th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class CaseTrigger_ResolutionTime_Test {
  /*private static Profile p;
  private static User testUser;
  private static User testUser2;

  @testSetup
  static void createTestData() {
     p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
     testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;


     testUser2 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test2');
    insert testUser2;   
  } */
   //=============================================================================
  // Verify that History__c records gets created for CSDA Record Type Cases
  //=============================================================================
  
   static testMethod void test_createCaseHistory() {
     Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
     User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
     insert testUser;


     User testUser2 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test2');
     insert testUser2;   

    System.runAs(testUser) {
  
      List<Case> caseList = new List<Case>();
      // Create Global settings
      Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
      custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
      update custSetting;

      // Create 1 account
      Account acc1 = Test_Utils.insertAccount();
      Opportunity testOppty = Test_Utils.insertOpportunity(acc1.ID);
      Case newCase;
      String recordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.CASE_REC_TYPE_CSDA_CONT_REQ);
      for (Integer i = 0; i < 10; i++) {
        newCase = new Case();
        newCase.RecordTypeID = recordTypeId;
        caseList.add(newCase);
      }

      Test.startTest();

        if (caseList.size() > 0){
          insert caseList;
        }

      Test.stopTest();

      //Assert to check case history records created on insert
      List<History__c> result = [SELECT Id
                                     FROM History__c
                                     WHERE Case__c IN : caseList];

      System.assertEquals(result.size(), 10);

      for (Case c : caseList) {
        c.OwnerId = testUser2.ID;
      }
      update caseList;

      //Assert to check case history records created on update
      result = [SELECT Id FROM History__c WHERE Case__c IN : caseList];

      System.assertEquals(result.size(), 20);


      for (Case c : caseList) {
        c.Status = 'In progress';
      }
      update caseList;

      //Assert to check case history records created on update
      result = [SELECT Id FROM History__c WHERE Case__c IN : caseList];

      System.assertEquals(result.size(), 30);
    }
  }

  //=============================================================================
  // Verify that History__c records gets created for CSDA Record Type Cases
  //=============================================================================
   static testMethod void test_createCaseHistory2 () {

     Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
     User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
     insert testUser;


     User testUser2 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test2');
     insert testUser2;   
    System.runAs(testUser) {

      List<Case> caseList = new List<Case>();

      
      Group qu = Test_Utils.createGroup(true);

      QueueSObject testQueue = new QueueSObject();
      testQueue.QueueId = qu.id;
      testQueue.SObjectType = 'Case';
      insert testQueue;
      System.debug('===queueId=='+qu.ID);
      Case newCase;
      String recordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.CASE_REC_TYPE_CSDA_CONT_REQ);
      for (Integer i = 0; i < 10; i++) {
        newCase = new Case();
        newCase.RecordTypeID = recordTypeId;
        newCase.OwnerId = qu.ID;
        /*if( i == 0) {
        	newCase.Status = 'Closed';
        }*/
        caseList.add(newCase);
      }
  
      Test.startTest();

          if (caseList.size() > 0){
            insert caseList;
          }

      Test.stopTest();

      //Assert to check case history records created on insert
      List<History__c> result = [SELECT Id
                                     FROM History__c
                                     WHERE Case__c IN : caseList];

      System.assertEquals(result.size(), 10);
      
      for (Case c : caseList) {
        c.OwnerId = testUser2.ID;
      }
      update caseList;

      //Assert to check case history records created on update
      result = [SELECT Id FROM History__c WHERE Case__c IN : caseList];

      
      System.assertEquals(result.size(), 20); 
      
      String recordSupportTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_CSDA_CIS_SUPPORT);
      
      Case parentCase = new Case();
      parentCase.RecordTypeID = recordSupportTypeId;
      parentCase.Service_Desk_Parent_Case__c = caseList.get(0).ID;
      //parentCase.Status = 'Closed';
      insert parentCase;
      
     // caseList.get(1).Service_Desk_Parent_Case__c = caseList.get(2).ID;
      caseList.get(1).Service_Desk_Parent_Case__c = parentCase.Id;
      
      Integer i = 0; 
      for (Case c : caseList) {
        c.IsParent__c = true;
        c.Status = 'In Progress';
        c.Case_Owned_by_Queue__c = true; 
      }
      //caseList.get(1).Status = 'Closed';
      update caseList;

    }
  }
  
/*
  //==========================================================
  // Creates test data: Assignment_Team__c & members
  // This method is also used by BatchAssignmentTeam_Test.cls
  //==========================================================
  @testSetup
  static void createTestData() {
    // create test data

    userProfile = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN ];
    testUser = Test_Utils.createUser(userProfile, 'test1234@gmail.com', 'test1');
    insert testUser;

    testUser2 = Test_Utils.createUser(userProfile, 'test1234@gmail.com', 'test2');
    insert testUser2;

      // Create Global settings
      Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
      custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
      update custSetting; 

      // Create 1 account
      Account acc1 = Test_Utils.insertAccount();
      Opportunity testOppty = Test_Utils.insertOpportunity(acc1.ID);

  }*/
}