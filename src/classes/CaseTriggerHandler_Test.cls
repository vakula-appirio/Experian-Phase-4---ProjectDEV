/**=====================================================================
 * Appirio, Inc
 * Name: CaseTriggerHandler_Test
 * Description: Test class for CaseTriggerHandler.cls (for T-270394)
 * Created Date: April 23rd, 2014
 * Created By: Rahul Jain (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * May 1st, 2014                Arpita Bose (Appirio)        Merged the code of TestCaseTriggerHandler.cls in this
 * Sept 17th, 2014              Naresh Kr Ojha               T-319846: Adding case team members. Added method test_createCaseTeamMembersForCases()
 * Nov 17th, 2014               Arpita Bose                  Updated test_createCaseTeamMembersForCases() to fix the failure
 * Jan 02nd, 2015               Arpita Bose                  Updated method testCondition2() to fix the failure
 * Feb 05th, 2015               Naresh Kr Ojha               T-358487: Update class added new method test_createCaseHistory() to test Case_History__c being created.
 * Feb 24th, 2015               Naresh                       T-365485: Updated code to adopt History__c object instead Case_History__c as per task.
 * Apr 29th, 2015               Noopur                       T-376616 : Added the method to verify the updateChildCasesOnCaseResolved()
 =====================================================================*/
@isTest

private class CaseTriggerHandler_Test {
  
  
  static testmethod void testCondition1(){
    // Condition 1: Check when case is Closed and Type = Spain Delivery Task
    // if Case.ESDEL_Billing_Order_Line_Id__c <> NULL   &  Case.ESDEL_Send_to_Billing_Date__c = NULL
    // Update: Case.ESDEL_Send_to_Billing_Date__c = TODAY & Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
    Test.startTest();
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      System.runAs(testUser1){
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id);
        // get the closed statuses of case object
        List<String> closedStatuses = new List<String>();
        for(CaseStatus cStatus : CaseTriggerHandler.getClosedCaseStatuses()){
          closedStatuses.add(cStatus.MasterLabel);
        }

        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
        // insert new case of type spain delivery task
        Case newCase = Test_Utils.insertCase (false, deliveryProject.id, acc1.id, 'bord1');
        newCase.Type = Constants.CASE_TYPE_SPAIN_DELIVERY_TASK;
        insert newCase;
        // populate billing units and order line id and close the case
        newCase.ESDEL_Billing_Units__c = 1;
        newCase.ESDEL_Billing_Order_Line_Id__c = 'BXIQN1';
        newCase.ESDEL_Send_to_Billing_Date__c = null;
        newCase.status = closedStatuses[0];
        update newCase;
        newCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : newCase.id];
        System.assertEquals(newCase.ESDEL_Send_to_Billing_Date__c, system.today(), 'validate that send to billing date is set to today');
        System.assertEquals(newCase.ESDEL_Calculated_Billing_Units__c, newCase.ESDEL_Billing_Units__c, 'validate that calculated billing is set with billing units');
    
      }
    Test.stopTest();
  }

  static testmethod void testCondition2(){
    // Condition 2.Check when case is Closed and Type = Spain Delivery Task
    // Case.ESDEL_Billing_Order_Line_Id__c = NULL & Case.Parent <> NULL
    // Update Case.ESDEL_Send_to_Billing_Date__c = TODAY & Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
    // AND if Parent.Case.ESDEL_Send_to_Billing_Date__c = Prior Month
    // Update Parent.Case.ESDEL_Send_to_Billing_Date__c = TODAY & Parent.Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
    
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      System.runAs(testUser1){
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id);
        // get the closed statuses of case object
        List<String> closedStatuses = new List<String>();
        for(CaseStatus cStatus : CaseTriggerHandler.getClosedCaseStatuses()){
          closedStatuses.add(cStatus.MasterLabel);
        }
        Test.startTest();
        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');
        // insert parent case
        Case parentCase = Test_Utils.insertCase (false, deliveryProject.id, acc1.id, 'bord1');
        parentCase.Type = Constants.CASE_TYPE_SPAIN_DELIVERY_TASK;
        parentCase.ESDEL_Send_to_Billing_Date__c = null;
        insert parentCase;
        // insert child case and associate parent with it
        Case newCase = Test_Utils.insertCase (false, deliveryProject.id, acc1.id, 'bord2');
        newCase.Type = Constants.CASE_TYPE_SPAIN_DELIVERY_TASK;
        newCase.parentId = parentCase.id;
        newCase.Requestor_Email__c = 'test@testmail.com';
        insert newCase;
        // populate billing units and set order line id to null and close the case
        parentCase.ESDEL_Billing_Units__c = 1;
        parentCase.ESDEL_Billing_Order_Line_Id__c = null;
        parentCase.status = closedStatuses[0];
        update parentCase;

        newCase.ESDEL_Billing_Units__c = 1;
        newCase.ESDEL_Billing_Order_Line_Id__c = null;
        newCase.ESDEL_Send_to_Billing_Date__c = null;
        newCase.status = closedStatuses[0];
        newCase.Requestor_Email__c = 'test@gmail.com';
        update newCase;
        newCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,Requestor_Email__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : newCase.id];
        System.assertEquals(newCase.ESDEL_Send_to_Billing_Date__c, system.today(), 'validate that send to billing date is set to today');
        System.assertEquals(newCase.ESDEL_Calculated_Billing_Units__c, newCase.ESDEL_Billing_Units__c, 'validate that calculated billing is set with billing units');
        // get updated parent case
        parentCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : parentCase.id];

        //validate that if Parent.Case.ESDEL_Send_to_Billing_Date__c = priorMonth
        //Parent.Case.ESDEL_Send_to_Billing_Date__c = TODAY     &
        //Parent.Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
        System.assertEquals(parentCase.ESDEL_Send_to_Billing_Date__c, system.today(), 'validate that send to billing date is set to today');
        System.assertEquals(parentCase.ESDEL_Calculated_Billing_Units__c, newCase.ESDEL_Billing_Units__c, 'validate that calculated billing is set with billing units');

      }
    Test.stopTest();
  }



  static testmethod void testCondition3(){
    // Condition 3.Check when case is Closed and Type = Spain Delivery Task
    // if Case.ESDEL_Billing_Order_Line_Id__c = NULL   & Case.Parent <> NULL
    // Update Case.ESDEL_Send_to_Billing_Date__c = TODAY & Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
    // AND if Case.ESDEL_Send_to_Billing_Date__c = Current Month
    // Update Parent.Case.ESDEL_Calculated_Billing_Units__c = Parent.Case.ESDEL_Calculated_Billing_Units__c + Case.ESDEL_Billing_Units__c
    Test.startTest();
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      System.runAs(testUser1){
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ESDEL_TIMECARD_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        //create 1 account
        Account acc1 = Test_Utils.insertAccount();
        //create 3 addresses
        Address__c address1 = Test_Utils.insertAddress(false);
        address1.Address_id__c = 'testExternalId1';
        Address__c address2 = Test_Utils.insertAddress(false);
        address2.Address_id__c = 'testExternalId2';
        List<Address__c> listAddresses = new List<Address__c>();
        listAddresses.add(address1);
        listAddresses.add(address2);
        insert listAddresses;
        //create 1 account address
        Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
        //create contact
        Contact contact1 = Test_Utils.insertContact(acc1.Id);
        List<String> closedStatuses = new List<String>();
        for(CaseStatus cStatus : CaseTriggerHandler.getClosedCaseStatuses()){
          closedStatuses.add(cStatus.MasterLabel);
        }

        ESDEL_Delivery_Project__c deliveryProject = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, contact1.id, 'bord1');

        Case parentCase = Test_Utils.insertCase (false, deliveryProject.id, acc1.id, 'bord1');
        parentCase.Type = Constants.CASE_TYPE_SPAIN_DELIVERY_TASK;
        parentCase.ESDEL_Send_to_Billing_Date__c = System.today();
        parentCase.ESDEL_Calculated_Billing_Units__c = 1;
        insert parentCase;

        parentCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : parentCase.id];

        Decimal parentCaseCalculatedBillingUnits = parentCase.ESDEL_Calculated_Billing_Units__c;
        System.debug('__' + parentCase.ESDEL_Send_to_Billing_Date__c);

        Case newCase = Test_Utils.insertCase (false, deliveryProject.id, acc1.id, 'bord2');
        newCase.Type = Constants.CASE_TYPE_SPAIN_DELIVERY_TASK;
        newCase.parentId = parentCase.id;
        insert newCase;


        newCase.ESDEL_Billing_Units__c = 1;
        newCase.ESDEL_Billing_Order_Line_Id__c = null;
        newCase.ESDEL_Send_to_Billing_Date__c = null;
        newCase.status = closedStatuses[0];
        update newCase;
        newCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : newCase.id];
        System.assertEquals(newCase.ESDEL_Send_to_Billing_Date__c, system.today(), 'validate that send to billing date is set to today');
        System.assertEquals(newCase.ESDEL_Calculated_Billing_Units__c, newCase.ESDEL_Billing_Units__c, 'validate that calculated billing is set with billing units');

        parentCase = [SELECT Id, ESDEL_Calculated_Billing_Units__c,
                              ESDEL_Send_to_Billing_Date__c, ESDEL_Billing_Units__c,
                              ESDEL_Billing_Order_Line_Id__c
                              FROM Case
                              WHERE Id = : parentCase.id];

        //AND if Parent.Case.ESDEL_Send_to_Billing_Date__c = currentMonth
        //Parent.Case.ESDEL_Send_to_Billing_Date__c = TODAY     &
        //Parent.Case.ESDEL_Calculated_Billing_Units__c   = Case.ESDEL_Billing_Units__c
        System.assertEquals(parentCase.ESDEL_Send_to_Billing_Date__c, system.today(), 'validate that send to billing date is set to today');
        System.assertEquals(parentCase.ESDEL_Calculated_Billing_Units__c, parentCaseCalculatedBillingUnits + newCase.ESDEL_Billing_Units__c, 'validate that calculated billing is added with billing units');

      }
    Test.stopTest();
  }

   static testMethod void testAfterUpdate()
  {
    // Create Global settings
    Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
    CaseTeamRole ctrTest = new CaseTeamRole();
    ctrTest.Name ='Requestor';
    // ctrTest.AccessLevel= '';  // may be required

    Group caseDQTeamQueue = new Group(Name='DQ Team Queue', Type='Queue');
    insert caseDQTeamQueue;

    QueueSobject mappingObject = new QueueSobject(QueueId = caseDQTeamQueue.Id, SobjectType = 'Case');
    System.runAs(new User(Id = UserInfo.getUserId()))
    {insert mappingObject;}

    User newUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    newUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    newUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    insert newUser;

    String emsRecordType = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.CASE_REC_TYPE_ACCESS_REQUEST);
    // Create a case record here.
    Case testCase = new Case(OwnerId = caseDQTeamQueue.Id);
    //testCase.OwnerId = caseDQTeamQueue.Id;
    testCase.RecordTypeId = emsRecordType;
    insert testCase;

    testCase.OwnerId = newUser.Id;
    testCase.Status = Constants.CASE_STATUS_APPROVED;
    update testCase;

    // needs more added to cover lines 37 and 44 of caseTriggerHandler.cls

    }

   //===========================================================================
   // Test method to test functionality mentioned in the task T-319846
   //===========================================================================
   @isTest(SeeAllData=false)
   static void  test_createCaseTeamMembersForCases() {
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser;

    User requestor = Test_Utils.createUser(p, 'test1234@gmail.com', 'test2');
    insert requestor;

    System.runAs(testUser) {
      Test.startTest();
      // Create Global settings
      Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
      custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
      update custSetting;

      //create 1 account
      Account acc1 = Test_Utils.insertAccount();
      Opportunity testOppty = Test_Utils.insertOpportunity(acc1.ID);

      CaseTeamRole ctrTest;
      for (CaseTeamRole caseTeam : [SELECT Name , AccessLevel
                                    FROM CaseTeamRole
                                    WHERE Name =: custSetting.Case_Access_Request_TeamRole__c]){
        ctrTest = caseTeam;
      }
      if (ctrTest == null){
        ctrTest = new CaseTeamRole();
        ctrTest.Name = custSetting.Case_Access_Request_TeamRole__c;
        ctrTest.AccessLevel = 'Edit';
        insert ctrTest;
      }

      List<Case> caseList = new List<Case>();

      Case newCase;
      for (Integer i = 0; i < 10; i++) {
        newCase = new Case();
        newCase.Requestor__c = requestor.ID;
        if (i < 4) {
          newCase.RecordTypeID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_EDQ_GPD );
          caseList.add(newCase);
        }
        if (4 <= i && i < 10) {
          newCase.RecordTypeID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_ONBOARDING );
          caseList.add(newCase);
        }

      }

      if (caseList.size() > 0){
        insert caseList;
      }

      Test.stopTest();

      //Assert to check team created and has Role as Requestor
      List<CaseTeamMember> result = [SELECT Id, ParentId, MemberId, TeamRoleId
                                     FROM CaseTeamMember
                                     WHERE ParentId IN : caseList];

      System.assert(result.size()<= 10);
      System.assertEquals(result.get(0).TeamRoleId, ctrTest.Id);
    }
  }

  //============================================================================
  //  @Description : test add the requestor user to the case teams
  //                ADDED FROM A TOP CODER CHALLENGE - Mass Transfer
  //  @param caseIds set of case ids
  //  @return void
  //============================================================================
  /*
    @isTest static void testFutureMethod(){
        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        CaseTeamRole ctrTest = new CaseTeamRole();
        ctrTest.Name ='Test Role';
        ctrTest.AccessLevel='Edit';
        insert ctrTest;

       // CaseTeamTemplate cttTest = new CaseTeamTemplate();
       // cttTest.Name ='Test_Template';
       // insert cttTest;

        User thisUser = Test_Utils.createUser('System Administrator');

        Group caseDQTeamQueue = new Group(Name='DQ Team Queue', Type='Queue');
        insert caseDQTeamQueue;

        QueueSobject mappingObject = new QueueSobject(QueueId = caseDQTeamQueue.Id, SobjectType = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert mappingObject;}

        Case case1 = new Case(OwnerId = caseDQTeamQueue.Id);
        insert case1;
        Case case2 = new Case(OwnerId = caseDQTeamQueue.Id);
        insert case2;

        Set<Id> caseIds = new Set<Id>();
        caseIds.add(case1.Id);
        caseIds.add(case2.Id);
        //insert caseIds;

       // CaseTeamTemplateMember cttMember = new CaseTeamTemplateMember();
       // cttMember.MemberId = case1.Requestor__c ;
       // cttMember.TeamRoleId = cttTest.Id ;
       // cttMember.TeamTemplateId = ctrTest.Id;
       // insert cttMember;

       // System.runAs() allows mixed DML operations in test context
        System.runAs(thisUser) {
            // startTest/stopTest block to run future method synchronously
            Test.startTest();
            CaseTriggerHandler.addUsersToCaseTeams(caseIds);
            Test.stopTest();
        }
        // The future method will run after Test.stopTest();

     }*/

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
      Test.startTest();
      // Create Global settings
      Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
      custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
      update custSetting;

      // Create 1 account
      Account acc1 = Test_Utils.insertAccount();
      Opportunity testOppty = Test_Utils.insertOpportunity(acc1.ID);

      List<Case> caseList = new List<Case>();

      Case newCase;
      String recordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.CASE_REC_TYPE_CSDA_CONT_REQ);
      for (Integer i = 0; i < 10; i++) {
        newCase = new Case();
        newCase.RecordTypeID = recordTypeId;
        caseList.add(newCase);
      }

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

    }
  }

  // Added for EMS / Gleam
  // Tests CaseTriggerHandler.updateChildCasesOnCaseResolved
  static testMethod void Test_updateChildCasesOnCaseResolved() {
    
    Account acc = Test_Utils.insertAccount();
    
    String emsRecordType = '';
    emsRecordType = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.RECORDTYPE_CASE_EMS);
    
    Case parentCase = new Case();
    parentCase.RecordTypeId = emsRecordType;
    parentCase.Status = Constants.CASE_STATUS_IN_PROGRESS;
    parentCase.Type = Constants.CASE_TYPE_INCIDENT;
    parentCase.Account__c = acc.Id;
    insert parentCase;
    
    List<Case> childCases = new List<Case>();
    for ( Integer i=0;i<5;i++) {
      Case childCase = new Case();
      childCase.ParentId = parentCase.Id;
      childCase.Status = Constants.CASE_STATUS_IN_PROGRESS;
      childCase.Type = Constants.CASE_TYPE_INCIDENT;
      childCase.Account__c = acc.Id;
      childCase.RecordTypeId = emsRecordType;
      childCases.add(childCase);
    }
    insert childCases;
    
    Test.startTest();
    parentCase.Status = Constants.CASE_STATUS_CLOSED_RESOLVED;
    update parentCase;
    Test.stopTest();
    
    for ( Case cs : [SELECT Id,Status,ParentId 
                     FROM Case 
                     WHERE ParentId = :parentCase.Id]) {
      system.assert( cs.Status == Constants.CASE_STATUS_CLOSED_RESOLVED);
    }
  }
}