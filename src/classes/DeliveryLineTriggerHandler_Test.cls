/**=====================================================================
 * Appirio, Inc
 * Name: DeliveryLineTriggerHandler_Test
 * Description: T-311495: Test class for DeliveryLineTriggerHandler.cls
 * Created Date: Aug 11th, 2014
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified          Modified By                    Description of the update
 * Aug 19th, 2014         Arpita Bose                    T-313220: Added a test method testCreateDeliveryLineForQueue()
 * Sep 26th, 2014         Naersh Kr Ojha                 T-322781: Added test method test_CreateZeroHourTimecardEntry()
 * Oct 10th, 2014         Arpita Bose                    Updated method test_CreateZeroHourTimecardEntry() to fix failure
 * May 29th, 2015         Paul Kissick                   Adding tests for delivery line Estimated LOE/Revenue rollup to project
  =====================================================================*/
@isTest(SeeAllData = false)
private class DeliveryLineTriggerHandler_Test {
  private static User testUser;
  private static Project__c proj;
  private static Project_Resource__c projRes;
  
  //Scenario:1- Creation of a Delivery Line: verify the Owner gets a Project Resource created with his/her name
  static testmethod void testCreateDeliveryLine(){
    // start test
    Test.startTest();
    createTestData();
    List<Project_Resource__c> result = [SELECT Id, Resource__c, Project__c, Resource__r.Name
                                        FROM Project_Resource__c WHERE Project__c =:proj.Id ];                                                                     
    // stop test
    Test.stopTest();
    //Asserts to verify owner gets a Project Resource with his/her name
    system.assertEquals(result.get(0).Resource__c, testUser.Id);
  }
  
  //Scenario:2- Update of a Delivery Line, where the owner changes: verify the new Owner gets a Project Resource created with his/her name
  static testmethod void testUpdateDeliveryLine1(){
    createTestData();
    Delivery_Line__c delLine  = Test_Utils.insertDeliveryLine(true, proj.Id);
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;
    // start test
    Test.startTest();
    // change the owner on the Delivery Line
    delLine.OwnerId = testUser1.Id;
    update delLine;
                                    
    // stop test
    Test.stopTest();
    
    List<Project_Resource__c> testOwner = [SELECT Id, Resource__c, Project__c, Resource__r.Name 
                                           FROM Project_Resource__c WHERE Resource__c =:testUser1.Id ];
    // Asserts to verify the new Owner gets a Project Resource 
    system.assertEquals(testOwner.get(0).Resource__c, testUser1.Id);
    
    List<Project_Resource__c> result = [SELECT Id, Resource__c, Project__c, Resource__r.Name 
                                        FROM Project_Resource__c WHERE Project__c =:proj.Id ];                                   
    // Asserts to verify there are more than one Project Resource
    system.assertEquals(result.size() > 1, true);                                 
      
  }
  
  //Scenario:3- Update of a Delivery Line, where the owner does not change: verify the number of Project Resource remains the same
  static testmethod void testUpdateDeliveryLine2(){
    createTestData();
    Delivery_Line__c delLine  = Test_Utils.insertDeliveryLine(true, proj.Id);
    List<Project_Resource__c> result1 = [SELECT Id, Resource__c, Project__c, Resource__r.Name
                                         FROM Project_Resource__c WHERE Project__c =:proj.Id ];
    // start test
    Test.startTest();
    delLine.Start_Date__c = system.today();
    update delLine;
       
    List<Project_Resource__c> result2 = [SELECT Id, Resource__c, Project__c, Resource__r.Name
                                         FROM Project_Resource__c WHERE Project__c =:proj.Id ];                         
    // stop test                                                         
    Test.stopTest();
    //Asserts to verify the number of Project Resource remains the same
    system.assertEquals(result1.size(), result2.size());  
  }
  
  // T-313220: If Delivery Line Owner is Queue, it will not create any Project Resource
  static testmethod void testCreateDeliveryLineForQueue() {
    // start test
    Test.startTest();
    Group testGroup = new Group(Name='Test Group', type='Queue');
    insert testGroup;

    System.runAs(new User(Id=UserInfo.getUserId())) {
      QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = Constants.SOBJECT_PROJECT);
      insert testQueue;
    }

    Project__c proj1 = Test_Utils.insertProject(false);
    proj1.OwnerId = testGroup.Id;
    insert proj1;

    Delivery_Line__c dl = Test_Utils.insertDeliveryLine(true, proj1.Id);

    List<Project_Resource__c> result = [SELECT Id, Resource__c, Project__c, Resource__r.Name
                                        FROM Project_Resource__c WHERE Project__c =:proj1.Id ];

    // stop test
    Test.stopTest();
    //Asserts to verify no Project Resource is created for Queue
    system.assertEquals(result.size(), 0);
  }

  // T-322781: If Delivery Line Owner is Queue, it will not create any Project Resource
  static testmethod void test_CreateZeroHourTimecardEntry() {
    // start test
    Test.startTest();
    List<Delivery_Line__c> allDLs = new List<Delivery_Line__c>();
    List<Delivery_Line__c> completedDLs = new List<Delivery_Line__c>();
    List<Delivery_Line__c> nonCompletedDLs = new List<Delivery_Line__c>();
    
    Project__c proj1 = Test_Utils.insertProject(false);
    insert proj1;
    Integer totalNonCompleted, totalCompleted;
    totalNonCompleted = totalCompleted = 0;
    //Non completed Delivery lines
    for (Integer i = 0; i<20; i++) {
      nonCompletedDLs.add(Test_Utils.insertDeliveryLine(false, proj1.Id));
      totalNonCompleted = i;
    }
    
    Delivery_Line__c dl;
    //Non completed Delivery lines
    for (Integer i = 0; i<20; i++) {
      dl = Test_Utils.insertDeliveryLine(false, proj1.Id);
      dl.Status__c = Constants.STATUS_COMPLETED;
      dl.Actual_End_Date__c = Date.today();
      completedDLs.add(dl);
      totalCompleted = i;
    }
    totalCompleted++;
    totalNonCompleted++;
                
    allDLs.addAll(completedDLs);
    allDLs.addAll(nonCompletedDLs);
    
    insert allDLs;
    
    // stop test
    Test.stopTest();
    //Asserts to verify that timecard created for only completed DLs (Insert case)
    System.assertEquals([SELECT ID FROM Timecard__c WHERE Project__c =: proj1.ID].size(), totalCompleted);
    
    for (Delivery_Line__c delLine : nonCompletedDLs) {
      delLine.Status__c = Constants.STATUS_COMPLETED;
      delLine.Actual_End_Date__c = Date.today();
    }
    
    update nonCompletedDLs;

    //Asserts to verify that timecard created for only completed DLs (Inserted earlier + updated) = total fetched
    System.assertEquals([SELECT ID FROM Timecard__c WHERE Project__c =: proj1.ID].size(), totalCompleted+totalNonCompleted);
    
  }
  
  static testMethod void deliveryLineRollupTest() {
    User tmpTestUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert tmpTestUser;
    Project__c proj1 = Test_Utils.insertProject(false);
    ProjectTriggerHandler.enableLoeRollup = true;
    proj1.OwnerId = tmpTestUser.Id;
    proj1.Type__c = 'Delivery';
    insert proj1;
    Test.startTest();
    
    Delivery_Line__c delLine1  = Test_Utils.insertDeliveryLine(false, proj1.Id);
    delLine1.Revenue__c = 1000;
    delLine1.Estimated_LOE_Hours__c = 40;
    delLine1.Service_Type__c = 'Delivery';
    insert delLine1;
    
    // Reset this after every dml
    ProjectTriggerHandler.calledUpdateLoe = false;
    
    Delivery_Line__c delLine2  = Test_Utils.insertDeliveryLine(false, proj1.Id);
    delLine2.Revenue__c = 1000;
    delLine2.Estimated_LOE_Hours__c = 40;
    delLine2.Service_Type__c = 'Internal';
    insert delLine2;
    
    // Reset this after every dml
    ProjectTriggerHandler.calledUpdateLoe = false;
    
    // At this point, the project should have been updated with the revenue and estimated loe for the first delivery line only, so check that.
    Project__c checkProj = [SELECT Estimated_LOE_Hours__c, Revenue__c FROM Project__c WHERE Id = :proj1.Id];
    system.assertEquals(1000,checkProj.Revenue__c);
    system.assertEquals(40,checkProj.Estimated_LOE_Hours__c);
    
    Delivery_Line__c delLine3  = Test_Utils.insertDeliveryLine(false, proj1.Id);
    delLine3.Revenue__c = 500;
    delLine3.Estimated_LOE_Hours__c = 20;
    delLine3.Service_Type__c = 'Delivery';
    insert delLine3;
    
    // Reset this after every dml
    ProjectTriggerHandler.calledUpdateLoe = false;
    
    checkProj = [SELECT Estimated_LOE_Hours__c, Revenue__c FROM Project__c WHERE Id = :proj1.Id];
    system.assertEquals(1500,checkProj.Revenue__c);
    system.assertEquals(60,checkProj.Estimated_LOE_Hours__c);
    
    delete delLine3;
    
    // Reset this after every dml
    ProjectTriggerHandler.calledUpdateLoe = false;
    
    checkProj = [SELECT Estimated_LOE_Hours__c, Revenue__c FROM Project__c WHERE Id = :proj1.Id];
    system.assertEquals(1000,checkProj.Revenue__c);
    system.assertEquals(40,checkProj.Estimated_LOE_Hours__c);
    
    
    delLine1.Revenue__c = 1200;
    delLine1.Estimated_LOE_Hours__c = 45;
    delLine1.Service_Type__c = 'Delivery';
    update delLine1;
    
    // Reset this after every dml
    ProjectTriggerHandler.calledUpdateLoe = false;
    
    checkProj = [SELECT Estimated_LOE_Hours__c, Revenue__c FROM Project__c WHERE Id = :proj1.Id];
    system.assertEquals(1200,checkProj.Revenue__c);
    system.assertEquals(45,checkProj.Estimated_LOE_Hours__c);
    
    Test.stopTest();
  }

  // Method to create test data
  private static void createTestData(){
    // create User
    testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser;
    // create Project
    proj = Test_Utils.insertProject(false);
    proj.OwnerId = testUser.Id;
    insert proj;
  }

}