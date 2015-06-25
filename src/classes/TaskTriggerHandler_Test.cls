/**================================================================================
 * Experian plc
 * Name: CustomerPortal
 * Description: Used by the Customer Portal to identify pipeline Opps
 * Created Date: 9th September 2014
 * Created By: James Weatherall
 * 
 * Date Modified        Modified By         Description of the update
 * Sep 8, 2014          James Weatherall    Case 1949 - Created tests for the new
 *                                          setCampaignWhenConverted method.
 * Apr 17th,2015        Arpita Bose(Appirio) Updated testSetCampaignWhenConverted() to fix failure
=================================================================================**/

@IsTest
private class TaskTriggerHandler_Test {
    
  
  //1. As per test scnario of T-311659: verify no Project Resource gets created
  static testMethod void test_no_ProjectResourceGetsCreated() {
    
    User testUser = Test_Utils.insertUser('System Administrator');
    
    System.runAs(testUser) {
      Account accnt = Test_Utils.insertAccount();
      Contact testContact = Test_Utils.insertContact(accnt.ID);

      Task testTask = Test_Utils.insertTask(testContact.ID, accnt.ID);
      //No project resource has been created.
      System.assertEquals([SELECT count() FROM Project_Resource__c], 0);
    }
  }
  
  //2. As per test scnario of T-311659: verify Project Resource gets created for each of the Task's Owner
  static testMethod void test_projectResourceGetsCreatedForEachOwner () {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    User testUser2 = Test_Utils.insertUser('System Administrator');
    Project__c testProject;
    Delivery_Line__c dl;
    RecordType projDevRT = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name = 'Project and Delivery'];
    
    System.runAs(testUser1) {
      testProject = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      Task projectTask = new Task(WhatId = testProject.ID, RecordTypeId = projDevRT.ID);
      projectTask.Assign_Resource__c = true;
      insert projectTask;
    }
    
    Project_Resource__c assertCheck = [SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID];
    System.assertEquals(assertCheck.Resource__c, testUser1.ID);

    System.runAs(testUser2) {
      dl = Test_Utils.insertDeliveryLine(true, testProject.ID);
      delete [SELECT ID FROM Project_Resource__c];
      Task delLineTask = new Task(WhatId = dl.ID, RecordTypeId = projDevRT.ID);
      delLineTask.Assign_Resource__c = true;
      insert delLineTask;
    }
    
    assertCheck = [SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser2.ID];
    System.assertEquals(assertCheck.Resource__c, testUser2.ID);
  }
  
  //3. As per test scnario of T-311659: verify Project Resource should not get created for Task.Assign_Resource__c = false
  static testMethod void test_projectResourceNotCreatedForAssignResFalse () {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    User testUser2 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Project__c testProject2;
    Delivery_Line__c dl;
    RecordType projDevRT = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name = 'Project and Delivery'];
    
    System.runAs(testUser1) {
      testProject1 = Test_Utils.insertProject(true);
      testProject2 = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      Task projectTask = new Task(WhatId = testProject1.ID, RecordTypeId = projDevRT.ID);
      projectTask.Assign_Resource__c = false;
      insert projectTask;
    }
    //Should not have any Project Resource as Assign Resource = false
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 0);

    System.runAs(testUser2) {
      dl = Test_Utils.insertDeliveryLine(true, testProject2.ID);
      delete [SELECT ID FROM Project_Resource__c];
      Task delLineTask = new Task(WhatId = dl.ID, RecordTypeId = projDevRT.ID);
      delLineTask.Assign_Resource__c = false;
      insert delLineTask;
    }
    //Should not have any Project Resource as Assign Resource = false
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser2.ID].size(), 0);
  }

  //4. As per test scnario of T-311659: Task updated and Owner get changed should create Project Resource
  static testMethod void test_projectResourceGetCreatedForNewUser() {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    User testUser2 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Delivery_Line__c dl;
    RecordType projDevRT = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name = 'Project and Delivery'];
    
    System.runAs(testUser1) {
      testProject1 = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      dl = Test_Utils.insertDeliveryLine(true, testProject1.ID);
      Task testTask = new Task(WhatId = dl.ID, RecordTypeId = projDevRT.ID);
      testTask.Assign_Resource__c = false;
      insert testTask;

      //Should have already project resource for testUser1 as the current owner.
      System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser2.ID].size(), 0);
  
      //Updating task and changing user.
      testTask.OwnerId = testUser2.ID;
      testTask.Assign_Resource__c = true;
      update testTask;
    }
    
    //Should create Project Resource as Assign Resource = true and Owner get changed.
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser2.ID].size(), 1);
  }

  //5. As per test scnario of T-311659: verify Project Resource get created for Task.Assign_Resource__c changes to true from false
  static testMethod void test_projectResourceCreatedForAssignResTrue () {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Delivery_Line__c dl;
    RecordType projDevRT = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name = 'Project and Delivery'];
    
    System.runAs(testUser1) {
      testProject1 = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      Task projectTask = new Task(WhatId = testProject1.ID, RecordTypeId = projDevRT.ID);
      projectTask.Assign_Resource__c = false;
      insert projectTask;
      //Should not have any Project Resource as Assign Resource = false
      System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 0);

      projectTask.Assign_Resource__c = true;
      update projectTask;
    }
    
    //Should not have any Project Resource as Assign Resource = false
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 1);
  }


  //6. As per test scnario of T-311659: verify Project resource gets created when RT is changed to Project and Delivery
  static testMethod void test_projectResourceCreatedForRecTypeProjDelvery() {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Delivery_Line__c dl;
    RecordType recordType = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name != 'Project and Delivery' LIMIT 1];
    
    System.runAs(testUser1) {
      testProject1 = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      Task projectTask = new Task(WhatId = testProject1.ID, RecordTypeId = recordType.ID);
      projectTask.Assign_Resource__c = true;
      insert projectTask;
      
      //Should not have any Project Resource as Assign Resource = false
      System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 0);
      
      recordType = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name = 'Project and Delivery' LIMIT 1];
      
      projectTask.RecordTypeId = recordType.ID;
      update projectTask;
    }
    
    //Should not have any Project Resource as Assign Resource = false
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 1);
  }  
  
  //7. As per test scnario of T-311659: verify Project resource do not get created when RT is other than Project and Delivery and Owner changed
  static testMethod void test_projectResourceCreatedForRecTypeNonProjDelvery() {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    User testUser2 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Delivery_Line__c dl;
    RecordType recordType = [Select Id From RecordType 
                                 WHERE SObjectType = 'Task' 
                                 AND Name != 'Project and Delivery' LIMIT 1];
    
    System.runAs(testUser1) {
      testProject1 = Test_Utils.insertProject(true);
      delete [SELECT ID FROM Project_Resource__c];
      Task projectTask = new Task(WhatId = testProject1.ID, RecordTypeId = recordType.ID);
      projectTask.Assign_Resource__c = true;
      insert projectTask;
      
      //Should not have any Project Resource as Assign Resource = false
      System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser1.ID].size(), 0);
      
      
      projectTask.OwnerID = testUser2.ID;
      update projectTask;
    }
    
    //Should not have any Project Resource as Assign Resource = false
    System.assertEquals([SELECT Resource__c, Project__c, Id  FROM Project_Resource__c WHERE Resource__c =: testUser2.ID].size(), 0);
  } 
  
  //7. As per test scnario of T-311659: verify Project resource do not get created when RT is other than Project and Delivery and Owner changed
  static testMethod void test_refreshOppScoreCalculations() {
    User testUser1 = Test_Utils.insertUser('System Administrator');
    User testUser2 = Test_Utils.insertUser('System Administrator');
    Project__c testProject1;
    Delivery_Line__c dl;
    
    
    System.runAs(testUser1) {
      Account accnt = Test_Utils.insertAccount();
      Opportunity oppty = Test_Utils.insertOpportunity(accnt.ID);
      Opportunity_Plan__c oppPlan = Test_Utils.insertOpportunityPlan(true, oppty.ID);
      
      String oppPlanOldModifiedDate = String.valueOf(oppPlan.LastModifiedDate);
      
      Task projectTask = new Task(WhatId = oppPlan.ID);
      insert projectTask;
            
      oppPlan = [SELECT LastModifiedDate FROM Opportunity_Plan__c WHERE ID =: oppPlan.ID];
      
      //Should not have any Project Resource as Assign Resource = false
      System.assertNotEquals(oppPlanOldModifiedDate, String.valueOf(oppPlan.LastModifiedDate));
      
      delete projectTask;

      oppPlan = [SELECT LastModifiedDate FROM Opportunity_Plan__c WHERE ID =: oppPlan.ID];
      
      //Should not have any Project Resource as Assign Resource = false
      System.assertNotEquals(oppPlanOldModifiedDate, String.valueOf(oppPlan.LastModifiedDate));
    }
  } 

  public static testmethod void testSetCampaignWhenConverted() {
  
    Integer i = 0;  
    Id campaignId; 
    Id leadToConvertId;
    List<Lead> leads = new List<Lead>();
    List<CampaignMember> campaignMembers = new List<CampaignMember>();
      
    Test.startTest();
    
    while(i < 5)
    {
      leads.add(Test_Utils.createLead());
      i++;    
    }
    insert leads;  
    
    Campaign newCampaign = new Campaign(Name = 'Test Campaign', Business_Unit__c = 'Credit Services', /*Audience__c = 'Testing',*/ Campaign_Code__c = 'TEST-123', IsActive = true, StartDate = System.today(), EndDate = System.today().addDays(7));
    newCampaign.Audience__c = 'Test Audience';
    insert newCampaign;
      
    campaignId = newCampaign.Id;
      
    for(Lead l : leads)
    {
      campaignMembers.add(new CampaignMember(CampaignId = campaignId, LeadId = l.Id, Status = 'Sent'));
    }
    insert campaignMembers;
    
    //Conversion process
    Database.leadConvert lc = new Database.leadConvert();  
    leadToConvertId = leads[0].Id; 
    lc.setLeadId(leadToConvertId);
    lc.setConvertedStatus('Converted');
    lc.setDoNotCreateOpportunity(true);
    Database.convertLead(lc);
      
    Lead testLead = [select Id, Status from Lead where Id =: leadToConvertId];
    Contact testContact = [select Id, Email from Contact where Email = 'test@test.com' and CreatedDate = TODAY];
    
    // Create Task as leadConvert() method doesn't create it be default
    Task testTask = new Task(WhoId = testContact.Id, Subject = 'Test Lead', Type = 'Other', ActivityDate = System.today());
    insert testTask;
    
    Task testInsertedTask = [select Id, WhatId from Task where Id = : testTask.Id];
    
    Test.stopTest();
      
    System.assertEquals('Converted', testLead.Status);
    System.assertEquals('test@test.com', testContact.Email);
    System.assertEquals(campaignId, testInsertedTask.WhatId);                      
  }

}