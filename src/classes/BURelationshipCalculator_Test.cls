/**=====================================================================
 * Appirio, Inc
 * Name: BURelationshipCalculator_Test
 * Description: This class contains unit tests for validating the behavior of Apex classes BURelationshipCalculator
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 14, 2014                 Jinesh Goyal                 added METHOD 'testReAlignBUsOnOwnerChange' 
 * Feb 18, 2014                 Naresh Kr Ojha               Updated test class to fix too many soql issue.  
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 14th, 2014               Arpita Bose (Appirio)        T-253906: Fixed error
 * Apr 11th, 2014               Arpita Bose                  Updated method createData() to fix the failure
 * Apr 16th, 2014               Arpita Bose                  T-271695: Renamed field Has_Stage_4_Approval__c to Has_Stage_3_Approval__c
 =====================================================================*/

@isTest(seeAllData=true)
private class BURelationshipCalculator_Test {

  /*@isTest
  static void testBuCalculatorClass() {
    Set<Id> setBUIDs = createData();
    BURelationshipCalculator calculator = new BURelationshipCalculator();
    
    List<BU_Relationship__c> lstBURelationship = calculator.updateTypeAndAmountFieldOnBU(setBUIDs);

    List<BU_Relationship__c> buRelList = new List<BU_Relationship__c>();     
    for(BU_Relationship__c buRel : [SELECT ID, Relationship_Type__c FROM BU_Relationship__c WHERE Account__c =: account.Id limit 1]) {
      buRelList.add(buRel);
    }
    System.assert(account.id != null);
    //System.assertEquals(Constants.BU_RELATIONSHIP_TYPE_PROSPECT, buRelList.get(0).Relationship_Type__c);
    
    Test.stopTest();
  }

  @isTest
  static void testBuCalculatorBatchClass() {
    
    Set<Id> setBUIDs = createData();
    BURelationshipCalculator_Batch batchCalculator = new BURelationshipCalculator_Batch();
    //Database.executeBatch(batchCalculator);
    Database.QueryLocator QL;
    Database.BatchableContext BC;
    List<BU_Relationship__c> lstBURelationship = new List<BU_Relationship__c>();
    List<Account> AcctList = new List<Account>();
    QL = batchCalculator.start(bc);   
    Database.QueryLocatorIterator QIT =  QL.iterator();
    Integer i = 0;
    while (QIT.hasNext()) {
      BU_Relationship__c bu = (BU_Relationship__c)QIT.next();            
      lstBURelationship.add(bu);
      i++;
      if (i > 5)
        break;

    }        
    //Test.startTest();
    batchCalculator.execute(BC, lstBURelationship);
    batchCalculator.finish(BC);
    List<BU_Relationship__c> buRelList = new List<BU_Relationship__c>();     
    for(BU_Relationship__c buRel : [SELECT Account__c, Relationship_Type__c FROM BU_Relationship__c WHERE Account__c =: account.Id limit 3]) {
      buRelList.add(buRel);
      System.debug('\nBURELATOINSHIP:::::' + buRel);
    }
    System.assert(buRelList != null);
    //System.assertEquals(Constants.BU_RELATIONSHIP_TYPE_PROSPECT, buRelList.get(0).Relationship_Type__c);
    //System.assertEquals(Constants.BU_RELATIONSHIP_TYPE_CLIENT, buRelList.get(1).Relationship_Type__c);
    //System.assertEquals(Constants.BU_RELATIONSHIP_TYPE_CLIENT, buRelList.get(2).Relationship_Type__c);
    Test.stopTest();
  }

  //@isTest
  static void testBuCalculatorScheduledClass() {
    //Test.startTest();
    Set<Id> setBUIDs = createData();
    // Schedule the test job
    String CRON_EXP = '0 0 0 3 9 ? 2022';
    String jobId = System.schedule('BURelationshipCalculator_Schedule_Test', CRON_EXP, 
       new BURelationshipCalculator_Schedule());

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                      FROM CronTrigger 
                      WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);
    Test.stopTest();
  }
  

  private static Account account;
  public static Set<Id> createData() {
    List<Opportunity> opps = new List<Opportunity>();
    account = Test_Utils.insertAccount();   
    BU_Relationship__c bu = Test_Utils.insertBURelationship(account.Id);
    Opportunity opportunityBusinessUnit = Test_Utils.createOpportunity(account.Id);
    Opportunity opportunityGlobalLineOfBusiness = Test_Utils.createOpportunity(account.Id);
    opps.add(opportunityBusinessUnit);
    opps.add(opportunityGlobalLineOfBusiness);
    
    Opportunity opportunityBusinessUnit2 = Test_Utils.createOpportunity(account.Id);
    Opportunity opportunityGlobalLineOfBusiness2 = Test_Utils.createOpportunity(account.Id);
    opps.add(opportunityBusinessUnit2);
    opps.add(opportunityGlobalLineOfBusiness2);
    insert opps;
    
    
    Competitor__c c1 = Test_Utils.createCompetitor(opportunityGlobalLineOfBusiness.id);
    // Create Opportunity Line itemn
    Product2 product = Test_Utils.insertProduct();
    Pricebook2 pricebook = Test_Utils.getPriceBook2();
    PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, pricebook.Id, Constants.CURRENCY_USD);
    
    OpportunityLineItem  opportunityLineItem = new OpportunityLineItem (TotalPrice = 200,UnitPrice = null,Quantity = 1,
                                                   OpportunityId = opportunityBusinessUnit.Id,PricebookEntryId = pricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(-5),End_Date__c = Date.today().addDays(5));
    OpportunityLineItem  opportunityLineItem2 = new OpportunityLineItem (TotalPrice = 200,UnitPrice = null,Quantity = 1,
                                                   OpportunityId = opportunityGlobalLineOfBusiness.Id,PricebookEntryId = pricebookEntry.Id,
                                                   Start_Date__c = Date.today().addDays(-5),End_Date__c = Date.today().addYears(2));
    
    OpportunityLineItem opportunityLineItem3 = Test_Utils.createOpportunityLineItem(opportunityBusinessUnit2.Id, pricebookEntry.Id);
    OpportunityLineItem opportunityLineItem4 = Test_Utils.createOpportunityLineItem(opportunityGlobalLineOfBusiness2.Id, pricebookEntry.Id);
    insert new List<OpportunityLineItem>{opportunityLineItem, opportunityLineItem2, opportunityLineItem3, opportunityLineItem4};
    
    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                                                            AccountId = account.Id, Email = 'larrye@email.com');
    insert newcontact;
        //Inserting contact roles for opportunities
        List<OpportunityContactRole> oppContRoleList = new List<OpportunityContactRole>(); 
        OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = opportunityBusinessUnit.Id, IsPrimary = true, Role = Constants.DECIDER);
        oppContRoleList.add(oppContactRole);
        oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = opportunityGlobalLineOfBusiness.Id, IsPrimary = true, Role = Constants.DECIDER);
        oppContRoleList.add(oppContactRole);
    insert oppContRoleList;
    
    //opps = new List<Opportunity>();
    opportunityBusinessUnit.Amount = 10;
    opportunityBusinessUnit.Contract_End_Date__c = System.today().addDays(5);
    opportunityBusinessUnit.Business_Unit__c = bu.id;
    opportunityBusinessUnit.Has_Stage_3_Approval__c = true;
    //opps.add(opportunityBusinessUnit);
    
    opportunityGlobalLineOfBusiness.Amount = 10;
    opportunityGlobalLineOfBusiness.Contract_End_Date__c = System.today().addYears(2);
    opportunityGlobalLineOfBusiness.Global_Line_of_Business__c = bu.id;
    opportunityGlobalLineOfBusiness.Has_Stage_3_Approval__c = true;
    //opps.add(opportunityGlobalLineOfBusiness);
    update new List<Opportunity>{opportunityBusinessUnit, opportunityGlobalLineOfBusiness};
    
    
        //Inserting contact roles for opportunities
        oppContRoleList = new List<OpportunityContactRole>(); 
        oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = opportunityBusinessUnit2.Id, IsPrimary = true, Role = Constants.DECIDER);
        oppContRoleList.add(oppContactRole);
        oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = opportunityGlobalLineOfBusiness2.Id, IsPrimary = true, Role = Constants.DECIDER);
        oppContRoleList.add(oppContactRole);
    insert oppContRoleList;
    Competitor__c c2 = Test_Utils.createCompetitor(opportunityBusinessUnit2.id);
    Competitor__c c3 = Test_Utils.createCompetitor(opportunityGlobalLineOfBusiness2.id);
    insert new List<Competitor__c>{c1, c2, c3};
    
    
    
    opportunityBusinessUnit2.Amount = 10;
    opportunityBusinessUnit2.Contract_End_Date__c = System.today().addDays(-420);
    opportunityBusinessUnit2.Business_Unit__c = bu.id;
    opportunityBusinessUnit2.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    opportunityBusinessUnit2.StageName = Constants.OPPTY_STAGE_7;//'Closed Won';
    opportunityBusinessUnit2.Has_Stage_3_Approval__c = true;
   // opps.add(opportunityBusinessUnit2); 
    
    opportunityGlobalLineOfBusiness2.Amount = 10;
    opportunityGlobalLineOfBusiness2.Contract_End_Date__c = System.today().addYears(-2);
    opportunityGlobalLineOfBusiness2.Global_Line_of_Business__c = bu.id;
    opportunityGlobalLineOfBusiness2.StageName = Constants.OPPTY_STAGE_7;//'Closed Won';
    opportunityGlobalLineOfBusiness2.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    opportunityGlobalLineOfBusiness2.Has_Stage_3_Approval__c = true;
    //opps.add(opportunityGlobalLineOfBusiness2);
    
    
    
    List<Task> taskList = new List<Task>();
    for(Opportunity o : opps){
      taskList.addAll(Test_Utils.createOpptyTasks(o.id, false));
    }
    insert taskList;
    IsDataAdmin__c isDataAdmin = [Select Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];//IsDataAdmin__c.getInstance();
    isDataAdmin.IsDataAdmin__c = true;
    update isDataAdmin;
    Test.startTest();
    update new List<Opportunity>{opportunityBusinessUnit2, opportunityGlobalLineOfBusiness2};
    Set<Id> setBUIDs = new Set<Id>();
    setBUIDs.add(bu.id);
    return setBUIDs;
  }

   @isTest
  static void testReAlignBUsOnOwnerChange() {
    //IsDataAdmin__c isDataAdmin = Test_Utils.insertIsDataAdmin(false);
    
    
    IsDataAdmin__c isDataAdmin = [Select Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];//IsDataAdmin__c.getInstance();
    isDataAdmin.IsDataAdmin__c = true;
    update isDataAdmin;
     
    User oldUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    oldUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT ;
    oldUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES ;
    insert oldUser;
    User newUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    newUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT ;
    newUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES ;
    insert newUser;
    account = Test_Utils.insertAccount();
    Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
    opportunity.OwnerId = oldUser.Id;
    insert opportunity;
    
    Contact cntct = Test_Utils.insertContact(account.id);
    Order__c ordr = Test_Utils.insertOrder(true, account.id, cntct.id, opportunity.id);
    
    Test.StartTest();
    account.OwnerId = newUser.Id;
    update account;
    opportunity.OwnerId = newUser.Id;
    //update opportunity;
    Test.StopTest();
    // Check newly created BU record
    List<BU_Relationship__c> lstBu = [SELECT Id,Global_Line_of_Business_or_BU__c FROM BU_Relationship__c WHERE Account__c =: account.Id limit 1];
    system.debug('+++++++++++ ' + lstBu);
    BU_Relationship__c buRecord;
    if(lstBu.size() > 0) {
      ordr.Business_Unit__c = lstBu[0].id;
      ordr.OwnerId = newUser.Id;
      ordr.Contract_End_Date__c = Date.today().addDays(-20);
      update ordr;
      buRecord = lstBu[0];
    }
    if(buRecord == NULL) {
      return;
    }
    System.assert(buRecord != NULL);
    System.debug('>>>>'+buRecord.Global_Line_of_Business_or_BU__c);
    System.debug('>>>>'+buRecord.Global_Line_of_Business_or_BU__c); 
  }
  
  //Test method to test BURelationshipCalculator_Schedule.cls
  @isTest
  static void testBURelationshipCalculator_Schedule() {
    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    String CRON_EXP = '0 0 0 15 3 ? 2022';
	  // Schedule the test job
	  String jobId = System.schedule('BURelationshipCalculator_Schedule',
	                    CRON_EXP, 
	                    new BURelationshipCalculator_Schedule());
	  // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                             NextFireTime
                      FROM CronTrigger WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);
    // Verify the job has not run
    System.assertEquals(0, ct.TimesTriggered);
    // Verify the next time the job will run
    System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
  }*/
  }