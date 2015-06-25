/**=====================================================================
 * Appirio, Inc
 * Name: BUHierarchyController_Test
 * Description: To test the logic of BUHierarchyController
 * Created Date: Apr 25th, 2014
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified           Modified By           Description of the update
 * Feb 16th, 2015          Noopur                T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
 @isTest
 private class BUHierarchyController_Test {

  //=============================================================================================
  // Test data on the BU Hierarchy object
  //=============================================================================================
  public static testmethod void testBUHierarchy1() {

    Account testAcc1 = [SELECT Id
                        FROM Account
                        WHERE Name = 'forMethod1'];
    Opportunity opp1 = [SELECT Id,Amount
                        FROM Opportunity
                        WHERE AccountId = :testAcc1.Id];
    //start test
    Test.startTest();

    try {
      System.currentPageReference().getparameters().put('id', testAcc1.id);
    } catch(Exception ex) {
      apexLogHandler.createLogAndSave('BUHierarchyController_Test','testBUHierarchy1', ex.getStackTraceString(), ex);
    }
    BUHierarchyController controller = new BUHierarchyController();
    controller.getObjectStructure();
    controller.setaccId(testAcc1.id);
    //stop test
    Test.stopTest();
    //Assert to verify clientType,pipeLineAmount and closedWonAmount
    System.assertEquals(controller.gblBU_BusinessGroupMap.size(), 2);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).clientType,
                                                                                 Constants.BU_RELATIONSHIP_TYPE_PROSPECT);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).pipeLineAmount,
                                                                                 opp1.Amount);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).closedWonAmount, 0);
  }


  //=============================================================================================
  // Test data on the BU Hierarchy object
  //=============================================================================================
  public static testmethod void testBUHierarchy2(){

    Account testAcc2 = [SELECT Id
                        FROM Account
                        WHERE Name = 'forMethod2'];
    Order__c order1 = [SELECT Id
                       FROM Order__c
                       Where Account__c = :testAcc2.Id];
    //start test
    Test.startTest();
    BUHierarchyController controller = new BUHierarchyController();
    System.currentPageReference().getparameters().put('id',testAcc2.id);
    controller.getObjectStructure();
    controller.setaccId(testAcc2.id);
    List<Order_Split__c> lstOrderSplit = [Select Order__c, Split_Percentage__c, OwnerId, CurrencyIsoCode, Order__r.Amount_Corp__c,
                                          Split_Total__c, Order__r.Amount_PCU__c, Order__r.Contract_End_Date__c,
                                          Order__r.Account__c, Order__r.OwnerId
                                        From Order_Split__c
                                        Where Order__c =: order1.Id AND Order__r.Account__c =:testAcc2.Id];
    //stop test
    Test.stopTest();
    System.assert(lstOrderSplit.size() > 0);
    //Assert to verify clientType, pipeLineAmount and closedWonAmount
    System.assertEquals(controller.gblBU_BusinessGroupMap.size(), 2);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).clientType,
                                                                                 Constants.BU_RELATIONSHIP_TYPE_FORMER_CLIENT);
    //System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).pipeLineAmount,
    //                                                                             opp2.Amount);
    //System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).closedWonAmount,
    //                                                                             lstOrderSplit.get(0).Split_Total__c);
   }

  //=============================================================================================
  // Test data on the BU Hierarchy object
  //=============================================================================================
  public static testmethod void testBUHierarchy3() {

    Account testAcc3 = [SELECT Id
                        FROM Account
                        WHERE Name = 'forMethod3'];
    Opportunity opp3 = [SELECT Id,Amount
                        FROM Opportunity
                        WHERE AccountId = :testAcc3.Id];
    Order__c order2 = [SELECT Id
                       FROM Order__c
                       Where Account__c = :testAcc3.Id];

    Test.startTest();
    BUHierarchyController controller = new BUHierarchyController();
    System.currentPageReference().getparameters().put('id',testAcc3.id);
    controller.getObjectStructure();
    controller.setaccId(testAcc3.id);
    List<Order_Split__c> lstOrderSplit = [Select Order__c, Split_Percentage__c, OwnerId, CurrencyIsoCode, Split_Total__c, Order__r.Amount_Corp__c,
                                          Order__r.Amount_PCU__c, Order__r.Contract_End_Date__c, Order__r.Account__c, Order__r.OwnerId
                                          From Order_Split__c
                                          Where Order__c =: order2.Id AND Order__r.Account__c =:testAcc3.Id];
    Test.stopTest();
    System.assert(lstOrderSplit.size() > 0);
    //Assert to verify clientType, pipeLineAmount and closedWonAmount
    System.assertEquals(controller.gblBU_BusinessGroupMap.size(), 2);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).clientType,
                                                                                 Constants.BU_RELATIONSHIP_TYPE_CLIENT);
    System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).pipeLineAmount,
                                                                                 opp3.Amount);
    //System.assertEquals(controller.gblBU_BusinessGroupMap.get(Constants.GLOBAL_BUSINESS_MARKETING_SERVICES).closedWonAmount,
    //                                                                             lstOrderSplit.get(0).Split_Total__c);
  }

  //=============================================================================================
  // Create Test Data
  //=============================================================================================
  @testSetup
  private static void createData () {
    //create user
    User user = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    user.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    user.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    insert user;


    //create Account with 1 Open Opportunity

    List<Opportunity> oppList = new List<Opportunity>();
    List<Account> accList = new List<Account>();

    Account testAcc1 = Test_Utils.createAccount();
    testAcc1.Name = 'forMethod1';
    accList.add(testAcc1);

    //create Account with 1 Order with Contract_End_Date__c = 2 years ago
    Account testAcc2 = Test_Utils.createAccount();
    testAcc2.Name = 'forMethod2';
    accList.add(testAcc2);

    //create Account with 1 Order with Contract_End_Date__c = 2 months ago
    Account testAcc3 = Test_Utils.createAccount();
    testAcc3.Name = 'forMethod3';
    accList.add(testAcc3);

    insert accList;

    Opportunity opp1 = Test_Utils.createOpportunity(testAcc1.Id);
    opp1.OwnerId = user.Id;
    opp1.Amount = 3000.00;
    oppList.add(opp1);

    Opportunity opp2 = Test_utils.createOpportunity(testAcc2.Id);
    opp2.OwnerId = user.Id;
    opp2.Amount = 5000.00;
    oppList.add(opp2);

      Opportunity opp3 = Test_utils.createOpportunity(testAcc3.Id);
      opp3.OwnerId = user.Id;
      opp3.Amount = 4000.00;
      oppList.add(opp3);


      insert oppList;
      List<Contact> conList = new List<Contact>();

        Contact newcontact1  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = testAcc2.Id, Email = 'larrye@email.com');
        conList.add(newcontact1);

        Contact newcontact2  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                        AccountId = testAcc3.Id, Email = 'larrye@email.com');
      conList.add(newcontact2);

      insert conList;

      List<Order__c> orderList = new List<Order__c>();

        Order__c order1 = Test_Utils.insertOrder(false, testAcc2.id, newcontact1.id, opp2.id);
        order1.Contract_Start_Date__c = Date.today();
        order1.Contract_End_Date__c = Date.today().addYears(-2);
        order1.Amount_Corp__c = 12000.00;
        order1.Transactional_Sale__c = false;
        orderList.add(order1);

        Order__c order2 = Test_Utils.insertOrder(false, testAcc3.id, newcontact2.id, opp3.id);
        order2.Contract_Start_Date__c = Date.today();
        order2.Contract_End_Date__c = Date.today().addMonths(-2);
        order2.Amount_Corp__c = 10000.00;
        order2.Transactional_Sale__c = false;
        orderList.add(order2);

        insert orderList;

        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();

        Order_Line_Item__c ordrli = Test_Utils.insertOrderLineItems(false, order1.id, null);
        ordrli.Start_Date__c = Date.today();
        ordrli.End_Date__c = Date.today().addYears(-2);
        oliList.add(ordrli);

        Order_Line_Item__c ordrli2 = Test_Utils.insertOrderLineItems(false, order2.id, null);
        ordrli2.Start_Date__c = Date.today();
        ordrli2.End_Date__c = Date.today().addMonths(-2);
        oliList.add(ordrli2);

      insert oliList;

   }
}