/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessItemTriggerHandler_Test
 * Description: T-360800: Test class for BusinessProcessItemTriggerHandler
 * Created Date: Feb 16th, 2015
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified           Modified By                    Description of the update
 * March 12th, 2015        Gaurav Kumar Chadha            Changed COMPLETE_SUCCESS to 'Completed' From 'Success' as it is 'Completed'
                                                          in the class and changed bpiLink2.Status__c = COMPLETE_SUCCESS according to 
                                                          the requirement 
 * March 17th, 2015        Noopur                         Added the code to verify the skipped items functionality
 * Mar 26th, 2015          Nathalie Le Guay (Appirio)     T-373784: populate Business_Days_Ready__c test
 * Apr 08th, 2015          Terri Kellough                 T-375023
  =====================================================================*/
@isTest(seeAllData = false)
public class BusinessProcessItemTriggerHandler_Test {
  private static String COMPLETE_SUCCESS = 'Completed';
    
  //==============================================================
  // Verifies the next BPI in line gets set to Ready when the
  // previous one has been completed
  //==============================================================
  public static testmethod void testMoveItemsToReady(){
    Business_Process__c  buProcess = [Select Id FROM Business_Process__c WHERE Business_Process_Template__r.Name = 'Test Links'];
    list<Business_Process_Item__c> buProcsItems = [SELECT Final_State__c,Status__c, Id 
                                             FROM Business_Process_Item__c
                                             WHERE Business_Process__c =: buProcess.Id
                                             order by Sequence__c ASC];
                                             
    Business_Process_Item__c buProcsItem1 = buProcsItems[0];
    Business_Process_Item__c buProcsItem2 = buProcsItems[1];
    Business_Process_Item__c buProcsItem3 = buProcsItems[2];
    
    // start test
    Test.startTest();
    //buProcsItem1.Final_State__c = true;
    buProcsItem1.Status__c = COMPLETE_SUCCESS;
    buProcsItem1.Ready_Date__c = Date.today().addDays(-7);
    buProcsItem1.Completed_Date__c = Date.today();
    update buProcsItem1;
    
    Business_Process_Item__c bpiResult = [SELECT Id, Final_State__c, Status__c, Business_Days_Ready__c
                                          FROM Business_Process_Item__c
                                          WHERE Id =:buProcsItem2.Id];
    System.assertEquals(bpiResult.Status__c, Constants.READY);

    //Asserts to verify status changed to 'Ready'
    Business_Process_Item__c bpiAfterUpdate = [SELECT Id, Business_Days_Ready__c
                                          FROM Business_Process_Item__c
                                          WHERE Id =:buProcsItem1.Id];
    System.assertEquals(5, bpiAfterUpdate.Business_Days_Ready__c);
    
    BusinessProcessItemTriggerHandler.processing = false;
    // Change the third item to complete and check the Business Process status.
    buProcsItem3.Final_State__c = true;
    buProcsItem3.Status__c = COMPLETE_SUCCESS;
    update buProcsItem3;
    
    
    Business_Process__c bpResult2 = [SELECT ID, Status__c, Closed_Date__c FROM Business_Process__c WHERE ID =:buProcess.Id];
    
    //Asserts to verify status and closed date on Business Process changed
    System.assertEquals(bpResult2.Status__c, 'Closed');
    DateTime dT = bpResult2.Closed_Date__c;
    Date closedDate = date.newinstance(dT.year(), dT.month(), dT.day());
    System.assertEquals(closedDate, System.today());
    
    // stop test
    Test.stopTest();
  }
    
    
  //==============================================================
  // Method to verify that the items that are not completed on the
  // completion of Business Process are marked as skipped.
  //==============================================================
  public static testmethod void testMoveItemsToReady2(){
    Business_Process__c  buProcess = [Select Id FROM Business_Process__c WHERE Business_Process_Template__r.Name = 'Test Links'];
    list<Business_Process_Item__c> buProcsItems = [SELECT Final_State__c,Status__c, Id 
                                             FROM Business_Process_Item__c 
                                             WHERE Business_Process__c =: buProcess.Id
                                             order by Sequence__c ASC];
                                             
    Business_Process_Item__c buProcsItem1 = buProcsItems[0];
    Business_Process_Item__c buProcsItem2 = buProcsItems[1];
    
    // start test
    Test.startTest();
    buProcsItem2.Final_State__c = true;
    buProcsItem2.Status__c = COMPLETE_SUCCESS;
    update buProcsItem2;
    
    Business_Process__c bpResult2 = [SELECT ID, Status__c, Closed_Date__c FROM Business_Process__c WHERE ID =:buProcess.Id];
    
    //Asserts to verify status and closed date on Business Process changed
    System.assertEquals(bpResult2.Status__c, 'Closed');
    
    Business_Process_Item__c bpiResult2 = [SELECT Id, Status__c FROM Business_Process_Item__c WHERE Id =:buProcsItem1.Id];
    //Asserts to verify status changed to 'Ready'
    System.assertEquals(bpiResult2.Status__c, 'Skipped');
    Test.stopTest();
  }

  //==============================================================
  // Test adding an ad hoc template item
  //==============================================================
  public static testMethod void test_InsertAdHocWithTemplate() {
    //get membership bpti
    Map<Id, Business_Process_Template_Item__c>  adHocBPTIMap = new Map<Id, Business_Process_Template_Item__c>(
                                                            [SELECT Id, Name, Description__c, Business_Hours__c, 
                                                                    Assign_To_Queue_when_Ready__c, Default_Owner__c, Update_Status_When__c, 
                                                                    Queue__c, Send_Owner_Email__c, Time_Quota__c,Expire__c, CSDA_Type__c,
                                                                    CSDA_Service_Type__c, Business_Process_Template__c
                                                             FROM Business_Process_Template_Item__c
                                                             WHERE Name = 'Test Mem']);
    //get bp applied to a case
    Business_Process__c caseBp = [SELECT Id, Case__c, 
                                         (SELECT Id, Sequence__c 
                                          FROM Business_Process_Items__r 
                                          ORDER BY Sequence__c DESC LIMIT 1)
                                  FROM Business_Process__c
                                  WHERE Case__c != null LIMIT 1];

    Id caseId = caseBp.Case__c;
    Decimal maxSeq = caseBp.Business_Process_Items__r[0].Sequence__c;
    Id bpId = caseBp.Id;
    System.assert(bpId != null, 'Checking for BP id');
    System.assert(caseId != null, 'Checking for Case Id');
    System.assert(maxSeq != null, 'Checking maxSeq of current items associated with the case bp ' + maxSeq);

    //Create adhoc bpi using membership bpti
    Id bptMemId;
    List<Business_Process_Item__c> bpiList = new List<Business_Process_Item__c>();
    for (Business_Process_Template_Item__c adhocBPTI : adHocBPTIMap.values()) {
      Business_Process_Item__c bpi = new Business_Process_Item__c();
      bpi.Case__c = caseId;
      bpi.Business_Process_Template_Item__c = adhocBPTI.Id;
      maxSeq++;
      bpiList.add(bpi);
      bptMemId = adhocBPTI.Business_Process_Template__c;
    }

    System.assert(bpiList.size() > 0, 'Checking adhoc bpi list size before insert');
    Test.startTest();
    insert bpiList;
    Test.stopTest();

    List<Business_Process_Item__c> adHocBPTIList = [SELECT Id, BPI_Name__c, Description__c, Business_Hours__c, Business_Process_Template_Item__c,
                                                      Assign_To_Queue_when_Ready__c, Default_Owner__c, Update_Status_When__c, 
                                                      Queue__c, Send_Owner_Email__c, Time_Quota__c,Expire__c, CSDA_Type__c,
                                                      CSDA_Service_Type__c, OwnerId, Sequence__c, Case__c, Business_Process__c
                                                    FROM Business_Process_Item__c
                                                    WHERE Case__c =: caseId AND Business_Process_Template_Item__r.Business_Process_Template__c =: bptMemId
                                                    ORDER BY Sequence__c ASC];


    Boolean match = true;
    Decimal expectedSeq = maxSeq;
    Decimal actualSeq;
    String matchMessage = '';

    if (adHocBPTIList.size() == 0) {
      match = false;
      matchMessage = ' No results returned for ad hoc list query';      
    }
   
    for (Business_Process_Item__c bpiAdHoc : adHocBPTIList) {
      
      actualSeq = bpiAdHoc.Sequence__c;
      Business_Process_Template_Item__c templateItem = adHocBPTIMap.get(bpiAdHoc.Business_Process_Template_Item__c);

      if (bpiAdHoc.Description__c != templateItem.Description__c) {
        match = false;
        matchMessage += ' Description ' + bpiAdHoc.Description__c ;
      } 
      if (bpiAdHoc.BPI_Name__c!= templateItem.Name) {
        match = false;
        matchMessage += ' Name ' + bpiAdHoc.BPI_Name__c;
      } 
      if (bpiAdHoc.Business_Hours__c != templateItem.Business_Hours__c) {
        match = false;
        matchMessage += ' Business Hours';
      } 
      if (bpiAdHoc.Assign_To_Queue_when_Ready__c != templateItem.Assign_To_Queue_when_Ready__c) {
        match = false;
        matchMessage += ' Assign To Queue when Ready';
      } 
      if (bpiAdHoc.Default_Owner__c != templateItem.Default_Owner__c) {
        match = false;
        matchMessage += ' Default Owner';
      } 
      if (bpiAdHoc.Update_Status_When__c != templateItem.Update_Status_When__c) {
        match = false;
        matchMessage += ' Update Status When';
      } 
      if (bpiAdHoc.Queue__c != templateItem.Queue__c) {
        match = false;
        matchMessage += ' Queue';
      } 
      if (bpiAdHoc.Send_Owner_Email__c != templateItem.Send_Owner_Email__c) {
        match = false;
        matchMessage += ' Send Owner Email';
      } 
      if (bpiAdHoc.Time_Quota__c != templateItem.Time_Quota__c) {
        match = false;
        matchMessage += ' Time Quota';
      } 
      if (bpiAdHoc.Expire__c != templateItem.Expire__c) {
        match = false;
        matchMessage += ' Expire';
      } 
      if (bpiAdHoc.CSDA_Type__c != templateItem.CSDA_Type__c) {
        match = false;
        matchMessage += ' CSDA Type';
      } 
      if (bpiAdHoc.CSDA_Service_Type__c != templateItem.CSDA_Service_Type__c) {
        match = false;
        matchMessage += ' CSDA Service Type';
      } 
      if (bpiAdHoc.Case__c != caseId) {
        match = false;
        matchMessage += ' Case';
      } 
      if (bpiAdHoc.Business_Process__c != bpId) {
        match = false;
        matchMessage += ' Business Process';
      }
    }


   //check field level matches
    System.assertEquals(true, match, matchMessage);  
    //check seq
    System.assertEquals(expectedSeq, actualSeq); 
 
  }

  //==============================================================
  // Create test data for all test methods
  //==============================================================
  @testSetup
  static void createData() {
    Account acc = Test_Utils.insertAccount();
    Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
    Business_Process_Template__c bpTemplate = new Business_Process_Template__c();
    bpTemplate.Name = 'Test Links';
    bpTemplate.Related_To__c = 'Opportunities';    
    insert bpTemplate;
 
    // create test data 
    Business_Process__c buProcess = new Business_Process__c();
    buProcess.Status__c = Constants.OPEN;
    buProcess.Opportunity__c = opp.Id;
    buProcess.Business_Process_Template__c = bpTemplate.Id;
    insert buProcess;
        
    Business_Process_Item__c buProcsItem1 = new Business_Process_Item__c();
    buProcsItem1.Business_Process__c = buProcess.Id;
    buProcsItem1.Status__c = Constants.STATUS_WAIT;
    buProcsItem1.Sequence__c = 1;
    insert buProcsItem1;
        
    Business_Process_Item__c buProcsItem2 = new Business_Process_Item__c();
    buProcsItem2.Business_Process__c = buProcess.Id;
    buProcsItem2.Status__c = Constants.STATUS_WAIT;
    buProcsItem2.Sequence__c = 2;
    insert buProcsItem2;
    
    Business_Process_Item__c buProcsItem3 = new Business_Process_Item__c();
    buProcsItem3.Business_Process__c = buProcess.Id;
    buProcsItem3.Status__c = Constants.STATUS_WAIT;
    buProcsItem3.Sequence__c = 2;
    insert buProcsItem3;
        
    Business_Process_Item_Link__c bpiLink1 = new Business_Process_Item_Link__c();
    bpiLink1.Predecessor__c = buProcsItem1.Id; 
    bpiLink1.Successor__c = buProcsItem2.Id;
    bpiLink1.Status__c = COMPLETE_SUCCESS;
    bpiLink1.Loop_Back_Link__c = true;
    insert bpiLink1;
        
    Business_Process_Item_Link__c bpiLink2 = new Business_Process_Item_Link__c();
    bpiLink2.Predecessor__c = buProcsItem2.Id;
    bpiLink2.Successor__c = buProcsItem3.Id;
    bpiLink2.Status__c = COMPLETE_SUCCESS;
    bpiLink2.Loop_Back_Link__c = true;
    insert bpiLink2;

    //Apr 08th, 2015 TTK
    //--------------------------------------------------------------------
    //Business Process for Case
    //--------------------------------------------------------------------    
    //create case business process template and items
    Case cas = Test_Utils.insertCase(true, acc.Id);
    Business_Process_Template__c bptCase = 
      Test_Utils.insertBusinessProcessTemplate(false, Constants.RELATED_TO_CASES,
        Constants.BU_CSDA, Constants.SUB_BU_BIS);
    bptCase.Name = 'Test Case';
    bptCase.Description__c = 'Test Case Descrption';
    insert bptCase;

    //create case template items with no owner specified
    List<Business_Process_Template_Item__c> bptiCaseList = new List<Business_Process_Template_Item__c>();
    for (Integer i = 0 ; i < 200 ; i++) {
      Business_Process_Template_Item__c bptiCase = Test_Utils.insertBusinessProcessTemplateItem(false, bptCase.Id, i);
      bptiCase.Name = 'Test Case';
      bptiCase.Description__c = 'Test Case Description';
      bptiCase.CSDA_Type__c = 'test';
      bptiCase.CSDA_Service_Type__c = 'test';
      bptiCaseList.add(bptiCase);
    }
    insert bptiCaseList;

    //apply business process to case
    Business_Process__c bpC = Test_Utils.insertBusinessProcess(true, bptCase.Id, cas.Id, null, null, null);

    //--------------------------------------------------------------------
    //Business Process for Membership
    //--------------------------------------------------------------------
    //create membership business process template and items
    Membership__c mem = Test_Utils.insertMembership(true, acc.Id);
    Business_Process_Template__c bptMem = 
      Test_Utils.insertBusinessProcessTemplate(false, Constants.RELATED_TO_MEMBERSHIPS, 
        Constants.BU_CSDA, Constants.SUB_BU_CIS);
    bptMem.Name = 'Test Mem';
    bptMem.Description__c = 'Test Mem Description';
    insert bptMem;

    //create membership items with queue specified
    Group qu = Test_Utils.createGroup(true);
    List<Business_Process_Template_Item__c> bptiMemList = new List<Business_Process_Template_Item__c>();
    for (Integer i = 0 ; i < 200 ; i++) {
      Business_Process_Template_Item__c bptiMem = Test_Utils.insertBusinessProcessTemplateItem(false, bptMem.Id, i);
      bptiMem.Name = 'Test Mem';
      bptiMem.Description__c = 'Test Mem Description';
      bptiMem.CSDA_Type__c = 'test';
      bptiMem.CSDA_Service_Type__c = 'test';
      //bptiMem.Queue__c = qu.Name;
      bptiMem.Assign_To_Queue_when_Ready__c = true;
      bptiMemList.add(bptiMem);
    }
    insert bptiMemList;

    //apply business process to membership
    Business_Process__c bpM = Test_Utils.insertBusinessProcess(true, bptMem.Id, null, mem.Id, null, null);

    //--------------------------------------------------------------------
    //Business Process for Account
    //--------------------------------------------------------------------
    //create account business process template and items   
    Business_Process_Template__c bptAcc =
      Test_Utils.insertBusinessProcessTemplate(false, Constants.RELATED_TO_ACCOUNTS, 
        Constants.BU_CSDA, Constants.SUB_BU_BIS);
    bptAcc.Name = 'Test Acc';
    bptAcc.Description__c = 'Test Acc Description';
    insert bptAcc;

    //create account items with default owner specified
    User testUser = Test_Utils.createUser(Constants.PROFILE_EXP_ATTORNEY_MEMBERSHIP);
    insert testUser;
    List<Business_Process_Template_Item__c> bptiAccList = new List<Business_Process_Template_Item__c>();
    for (Integer i = 0 ; i < 200 ; i++) {
      Business_Process_Template_Item__c bptiAcc = Test_Utils.insertBusinessProcessTemplateItem(false, bptAcc.Id, i);
      bptiAcc.Name = 'Test Acc';
      bptiAcc.Description__c = 'Test Acc Description';
      bptiAcc.CSDA_Type__c = 'test';
      bptiAcc.CSDA_Service_Type__c = 'test';
      //bptiAcc.Default_Owner__c = testUser.Id;
      bptiAccList.add(bptiAcc);
    }
    insert bptiAccList;

    //apply business process to account
    Business_Process__c bpA = Test_Utils.insertBusinessProcess(true, bptAcc.Id, null, null, acc.Id, null);


    //--------------------------------------------------------------------
    //Business Process for Opportunity
    //--------------------------------------------------------------------
    //apply business process to Opportunity
    Opportunity opp2 = Test_Utils.insertOpportunity(acc.Id);
    Business_Process_Template__c bptOpp =
      Test_Utils.insertBusinessProcessTemplate(false, Constants.RELATED_TO_OPPORTUNITIES, 
        Constants.BU_CSDA, Constants.SUB_BU_BIS);
    bptOpp.Name ='Test Opp';
    bptOpp.Description__c = 'Test Opp Description';
    insert bptOpp;

    //create opportunity items
    List<Business_Process_Template_Item__c> bptiOppList = new List<Business_Process_Template_Item__c>();
    for (Integer i = 0 ; i < 200 ; i++) {
      Business_Process_Template_Item__c bptiOpp = Test_Utils.insertBusinessProcessTemplateItem(false, bptOpp.Id, i);
      bptiOpp.Name = 'Test Opp';
      bptiOpp.Description__c = 'Test Opp Description';
      bptiOpp.CSDA_Type__c = 'test';
      bptiOpp.CSDA_Service_Type__c = 'test';
      //bptiOpp.Default_Owner__c = testUser.Id;
      bptiAccList.add(bptiOpp);
    }
    insert bptiOppList;

    //apply business process to opportunity
    Business_Process__c bpO = Test_Utils.insertBusinessProcess(true, bptOpp.Id, null, null, null, opp2.Id);



  }

}