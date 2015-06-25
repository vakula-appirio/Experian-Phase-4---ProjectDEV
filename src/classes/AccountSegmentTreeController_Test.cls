/**
 * 19th June,2015    Noopur   Modified the class to increase coverage
 */
@isTest(seeAllData = false)
private class AccountSegmentTreeController_Test {

  //=============================================================================================
  // Test data on the BU Hierarchy object
  //=============================================================================================
  public static testmethod void testAccountSegmentTree1() {

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
      apexLogHandler.createLogAndSave('AccountSegmentTreeController_Test','testBUHierarchy1', ex.getStackTraceString(), ex);
    }
    AccountSegmentTreeController controller = new AccountSegmentTreeController();
    controller.getObjectStructure();
    controller.setaccId(testAcc1.id);
    controller.asm[0].setnodeId('test');
    controller.asm[0].setlevelFlag(true);
    controller.asm[0].setlcloseFlag(false);
    controller.asm[0].setnodeType('test');
    controller.asm[0].setcurrentNode(true);
    
    System.assert(controller.asm.size() == 5);
    //stop test
    Test.stopTest();
    
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
    AccountSegmentTreeController controller = new AccountSegmentTreeController();
    System.currentPageReference().getparameters().put('id',testAcc2.id);
    controller.getObjectStructure();
    controller.setaccId(testAcc2.id);
    
    System.assert(controller.asm.size() == 5);
    //stop test
    Test.stopTest();
    
   }

  //=============================================================================================
  // Test data on the BU Hierarchy object
  //=============================================================================================
  public static testmethod void testBUHierarchy3() {

    Account testAcc3 = [SELECT Id
                        FROM Account
                        WHERE Name = 'forMethod3'];
    Opportunity opp3 = [SELECT Id,Amount,StageName,Type,Channel_Type__c,Has_Senior_Approval__c,
                               Starting_Stage__c,CloseDate,Contract_Start_Date__c,Contract_End_Date__c
                        FROM Opportunity
                        WHERE AccountId = :testAcc3.Id];
    Order__c order2 = [SELECT Id
                       FROM Order__c
                       Where Account__c = :testAcc3.Id];
    Test.startTest();
      
      Product2 product = Test_Utils.insertProduct();
      PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      
      //insert OLI
	    OpportunityLineItem opportunityLineItem1 = Test_Utils.createOpportunityLineItem(opp3.Id, stdPricebookEntry.Id, opp3.Type);
	    opportunityLineItem1.Start_Date__c = Date.today().addDays(5);
	    opportunityLineItem1.End_Date__c = System.today().addDays(10); 
	    insert opportunityLineItem1;
	    opp3.StageName = Constants.OPPTY_STAGE_7;
	    opp3.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
	    opp3.Amount = 100;
	    opp3.Has_Senior_Approval__c = true;
	    opp3.Starting_Stage__c = Constants.OPPTY_STAGE_6;
	    opp3.CloseDate = date.today();
	    opp3.Contract_Start_Date__c = date.today().addDays(1);
	    opp3.Contract_End_Date__c = date.today().addYears(1);
	    
	    
	    update opp3;
	    system.debug('---opportunity AMount---'+[select Amount from Opportunity where Id = :opp3.Id]);
    AccountSegmentTreeController controller = new AccountSegmentTreeController();
    System.currentPageReference().getparameters().put('id',testAcc3.id);
    controller.setaccId(testAcc3.id);
    controller.getObjectStructure();
    List<Order_Split__c> lstOrderSplit = [Select Order__c, Split_Percentage__c, OwnerId, CurrencyIsoCode, Split_Total__c, Order__r.Amount_Corp__c,
                                          Order__r.Amount_PCU__c, Order__r.Contract_End_Date__c, Order__r.Account__c, Order__r.OwnerId
                                          From Order_Split__c
                                          Where Order__c =: order2.Id AND Order__r.Account__c =:testAcc3.Id];
    Test.stopTest();
    System.assert(lstOrderSplit.size() > 0);
  }

  //=============================================================================================
  // Create Test Data
  //=============================================================================================
  @testSetup
  private static void createData () {
    //create user
    User usr = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    usr.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    usr.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    insert usr;
    
    TriggerSettings__c tsetting = Test_Utils.insertTriggerSettings('AccountTrigger');
    tsetting.IsActive__c = false;
    update tsetting;
    tsetting = Test_Utils.insertTriggerSettings('OpportunityLineItemTrigger');
    tsetting.IsActive__c = false;
    update tsetting;

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
    
    List<Hierarchy__c> hierarchyList = new List<Hierarchy__c>();
      for( integer i=0; i<5;i++) {
        Hierarchy__c hr = new Hierarchy__c();
        if( i == 0) {
          hr.Type__c = 'Global Business Line';
        }
        if( i == 1) {
          hr.Type__c = 'Business Unit';
        }
        if( i == 2) {
          hr.Type__c = 'Business Line';
        }
        if( i == 3) {
          hr.Type__c = 'Region';
        }
        if( i == 4) {
          hr.Type__c = 'Country';
        }
        hr.Value__c = 'testHR'+i;
        hr.Unique_Key__c = 'Key'+i;
        hierarchyList.add(hr);
      }
       
      insert hierarchyList;
      
      hierarchyList[1].Parent__c = hierarchyList[0].Id;
      hierarchyList[1].Parent__c = hierarchyList[0].Id;
      update hierarchyList;
      
      List<Account_Segment__c> accSegments = new List<Account_Segment__c>();
      accSegments.add(Test_Utils.insertAccountSegment(false, accList[0].Id, hierarchyList[0].Id, null));
      accSegments.add(Test_Utils.insertAccountSegment(false, accList[0].Id, hierarchyList[1].Id, null));
      accSegments.add(Test_Utils.insertAccountSegment(false, accList[0].Id, hierarchyList[2].Id, null));
      accSegments.add(Test_Utils.insertAccountSegment(false, accList[0].Id, hierarchyList[3].Id, null));
      accSegments.add(Test_Utils.insertAccountSegment(false, accList[0].Id, hierarchyList[4].Id, null));
      
      Account_Segment__c accSeg1 = Test_Utils.insertAccountSegment(false, accList[1].Id, hierarchyList[0].Id, null);
      accSegments.add(accSeg1);
      Account_Segment__c accSeg2 = Test_Utils.insertAccountSegment(false, accList[1].Id, hierarchyList[1].Id, null);
      accSegments.add(accSeg2);
      Account_Segment__c accSeg3 = Test_Utils.insertAccountSegment(false, accList[1].Id, hierarchyList[2].Id, null);
      accSegments.add(accSeg3);
      Account_Segment__c accSeg4 = Test_Utils.insertAccountSegment(false, accList[1].Id, hierarchyList[3].Id, null);
      accSegments.add(accSeg4);
      Account_Segment__c accSeg5 = Test_Utils.insertAccountSegment(false, accList[1].Id, hierarchyList[4].Id, null);
      accSegments.add(accSeg5);
      
      insert accSegments;
      accSeg2.Parent_Account_Segment__c = accSeg1.Id;
      accSeg3.Parent_Account_Segment__c = accSeg1.Id;
      accSeg5.Parent_Account_Segment__c = accSeg4.Id;
      update accSegments;

    Opportunity opp1 = Test_Utils.createOpportunity(testAcc1.Id);
    opp1.OwnerId = usr.Id;
    opp1.Amount = 3000.00;
    opp1.Segment_Business_Unit__c = accSeg2.Id;
    oppList.add(opp1);

    Opportunity opp2 = Test_utils.createOpportunity(testAcc2.Id);
    opp2.OwnerId = usr.Id;
    opp2.Amount = 5000.00;
    opp2.Segment_Region__c = accSeg4.Id;
    oppList.add(opp2);

      Opportunity opp3 = Test_utils.createOpportunity(testAcc3.Id);
      opp3.OwnerId = usr.Id;
      opp3.Amount = 4000.00;
      opp3.Type = Constants.OPPTY_TYPE_FREE_TRIAL ; 
      oppList.add(opp3);


      insert oppList;
      List<Contact> conList = new List<Contact>();
      
        Contact newcontact  = new Contact (FirstName = 'Larry1', LastName = 'Ellison1',
                                            AccountId = testAcc1.Id, Email = 'larrye1@email.com');
        conList.add(newcontact);

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
        ordrli.Total__c = 1000.00;
        oliList.add(ordrli);

        Order_Line_Item__c ordrli2 = Test_Utils.insertOrderLineItems(false, order2.id, null);
        ordrli2.Start_Date__c = Date.today();
        ordrli2.End_Date__c = Date.today().addMonths(-2);
        ordrli.Total__c = 2000.00;
        oliList.add(ordrli2);

        insert oliList;
     
	    Address__c address = Test_Utils.insertAddress(true);
	    Test_Utils.insertAccountAddress(true, address.Id, accList[0].Id);
	    Test_Utils.insertContactAddress(true, address.Id, newcontact.Id);
	    OpportunityContactRole oppContactRole = Test_Utils.insertOpportunityContactRole(true, opp3.Id, newcontact.Id, Constants.DECIDER, true);
      
   }
}