/**=====================================================================
 * Appirio, Inc
 * Test Class Name: Opportunity_ExitCriteriaUtility_Test
 * Class Name: [Class name for which test class created]
 * Description: [Task # with multi-line description here]
 * Created Date: [MM/DD/YYYY]
 * Created By: [FirstName LastName] (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 30, 2014                 Nathalie Le Guay             Use of Constants
 * Aug 01st, 2014               Arpita Bose                  T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Aug 18th, 2014               Arpita Bose                  T-312319: Updated method testOpportunitiesExitCriteriaNotMet()to fix the failure
 * Nov 12th, 2014               Arpita Bose                  Added Type in test data of Opportunity and OLI 
 =====================================================================*/
@isTest(seeAllData=true)
private class Opportunity_ExitCriteriaUtility_Test {

  private static Opportunity opp;
  private static List<OpportunityLineItem> olis; 
  private static PricebookEntry stdPricebookEntryObj;
  @isTest
  static void testExitCriteriaNotMetStage3(){
  	  //Creating admin user     
      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert testUser;
      System.runAs(testUser) { 
      	
      
	     // Create test data
	     Test.startTest();
	     // Create Account
	     Account testAccount = Test_Utils.insertAccount();
	     
	     // Create an opportunity
	     Opportunity sObjOpp = Test_utils.createOpportunity(testAccount.Id);
	     insert sObjOpp;
	     
	     sObjOpp.StageName = Constants.OPPTY_STAGE_5;
	     try {
	       update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_SKIPSTAGE));        
	     }
	     
	     User opptyOwner = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
	     opptyOwner.Region__c = Constants.REGION_UKI;
	     insert opptyOwner;
	     
	     Test_Utils.createOpptyTasks(sObjOpp.Id, true);
	     Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
	                                     AccountId = testAccount.Id, Email = 'larrye@email.com');
	     insert newcontact;
	  
	     OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, 
	                              OpportunityId = sObjOpp.Id, IsPrimary = true, Role = Constants.DECIDER);
	     insert oppContactRole ;
	     
	     Competitor__c comp = new Competitor__c(Opportunity__c = sObjOpp.Id);
	     insert comp;
	     
	     sObjOpp.Budget__c = 'Client will not disclose';
	     sObjOpp.OwnerId = opptyOwner.ID;
	     sObjOpp.Amount = 600000;
	     sObjOpp.StageName = Constants.OPPTY_STAGE_4;
	     
	     try {
	       update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_STAGE_3_APPROVER));
	     }
	     
	     sObjOpp.Stage_3_Approver__c = UserInfo.getUserId();
	     try {
	       update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_STAGE_3_TO_4_AMOUNTORTAA_OVER_APPROVAL));
	     }
	     
	     sObjOpp.Has_Stage_3_Approval__c = true;
	     sObjOpp.StageName = Constants.OPPTY_STAGE_4;
	     update sObjOpp;
	     
	     System.assert([SELECT ID, StageName FROM Opportunity WHERE ID =: sObjOpp.ID].StageName == Constants.OPPTY_STAGE_4);
     }
  }
  
  @isTest
  static void testExitCriteriaNotMetStage4(){
    //Creating admin user     
    User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser;
    System.runAs(testUser) {    
    
	     // Create test data
	     Test.startTest();
	     // Create Account
	     Account testAccount = Test_Utils.insertAccount();
	     
	     // Create an opportunity
	     Opportunity sObjOpp = Test_utils.createOpportunity(testAccount.Id);
	     insert sObjOpp;
	     
	     User opptyOwner = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
	     opptyOwner.Region__c = Constants.REGION_UKI;
	     insert opptyOwner;
	     
	     Test_Utils.createOpptyTasks(sObjOpp.Id, true);
	     Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
	                                     AccountId = testAccount.Id, Email = 'larrye@email.com');
	     insert newcontact;
	  
	     OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, 
	                              OpportunityId = sObjOpp.Id, IsPrimary = true, Role = Constants.DECIDER);
	     insert oppContactRole ;
	     
	     Competitor__c comp = new Competitor__c(Opportunity__c = sObjOpp.Id);
	     insert comp;
	     
	     sObjOpp.Budget__c = 'Client will not disclose';
	     sObjOpp.Amount = 10000;
	     sObjOpp.StageName = Constants.OPPTY_STAGE_4;
	     sObjOpp.OwnerId = opptyOwner.ID;
	     update sObjOpp;
	     
	     try {
	       sObjOpp.StageName = Constants.OPPTY_STAGE_5;
	       update sObjOpp;
	     } catch(Exception ex) {
	        System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_RISK_FIELDS));
	     }
    }
  }

  @isTest
  static void testExitCriteriaNotMetStage5(){
    //Creating admin user     
    User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser;
    System.runAs(testUser) {      
	     // Create test data
	     
	     // Create Account
	     Account testAccount = Test_Utils.insertAccount();
	     
	     // Create an opportunity
	     Opportunity sObjOpp = Test_utils.createOpportunity(testAccount.Id);
	     sObjOpp.Starting_Stage__c = Constants.OPPTY_STAGE_6;
	     insert sObjOpp;
	     
	     User opptyOwner = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
	     opptyOwner.Region__c = Constants.REGION_UKI;
	     insert opptyOwner;
	     
	     Test_Utils.createOpptyTasks(sObjOpp.Id, true);
	     Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
	                                     AccountId = testAccount.Id, Email = 'larrye@email.com');
	     insert newcontact;
	  
	     OpportunityContactRole oppContactRole = new OpportunityContactRole(ContactId = newcontact.Id, 
	                              OpportunityId = sObjOpp.Id, IsPrimary = true, Role = Constants.DECIDER);
	     insert oppContactRole ;
	     
	     /*Competitor__c comp = new Competitor__c(Opportunity__c = sObjOpp.Id);
	     insert comp;*/
	
	     sObjOpp.Budget__c = 'Client will not disclose';
	     sObjOpp.Amount = 10000;
	     sObjOpp.StageName = Constants.OPPTY_STAGE_4;
	     update sObjOpp;
	
	     /*Task t = Test_Utils.createTask(newContact.Id, sObjOpp.Id);
	     t.Type = Constants.ACTIVITY_TYPE_QUOTE_DELIVERED;
	     t.Status = Constants.STATUS_COMPLETED;
	     insert t;
	     Product2 product = Test_Utils.insertProduct();
	     Pricebook2 pricebook = Test_Utils.getPriceBook2();
	     Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
	     stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
	     //insert OLI
	     olis = new List<OpportunityLineItem>();
	     olis.add(Test_Utils.createOpportunityLineItem(sObjOpp.Id, stdPricebookEntryObj.Id));
	     olis.add(Test_Utils.createOpportunityLineItem(sObjOpp.Id, stdPricebookEntryObj.Id));
	*/
	     Test.startTest();
	     sObjOpp.StageName = Constants.OPPTY_STAGE_5;
	     update sObjOpp;
	
	     sObjOpp.StageName = Constants.OPPTY_STAGE_6;
	     sObjOpp.Amount = 600000;
	     //Assert to check senior approver to be filled as amount is > 500000
	     try {
	       update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_SENIOR_APPROVER));
	     }
	     
	     sObjOpp.Senior_Approver__c = UserInfo.getUserId();
	     //Assert to check approval to be taken as amount is > 500000
	     try {
	       update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_STAGE_5_TO_6_OPPTY_APPROVAL));
	     }
	     //Owner has region UKI, so all risk fields has to be populated.
	     try {
	       sObjOpp.OwnerId = opptyOwner.ID;
	       sObjOpp.StageName = Constants.OPPTY_STAGE_6;
	       sObjOpp.Stage_3_Approver__c = UserInfo.getUserId();
	       sObjOpp.Has_Stage_3_Approval__c = true;
	       sObjOpp.Has_Senior_Approval__c = true;
	      update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_RISK_FIELDS));
	     }     
	     
	     //Everything is well so Oppty should be in Stage 6
	     sObjOpp.OwnerId = UserInfo.getUserId();
	     sObjOpp.Has_Senior_Approval__c = true;
	     update sObjOpp;
	     
	     //Check significant change to be populated.
	     try {
	       sObjOpp.StageName = Constants.OPPTY_STAGE_6;
	      update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_SIGNIFICANT_CHANGE));
	     }
	     //Check If significant change is populated than should have Senior Approver.     
	     sObjOpp.Has_There_Been_Significant_Change__c = 'Yes';
	     sObjOpp.Senior_Approver__c = null;
	     try {
	       sObjOpp.StageName = Constants.OPPTY_STAGE_6;
	      update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_POPULATE_SENIOR_APPROVER));
	     }
	     
	     //Check If significant change & Senior Approver is populated than should have senior approval true.
	     sObjOpp.Has_There_Been_Significant_Change__c = 'Yes';
	     sObjOpp.Senior_Approver__c = UserInfo.getUserId();
	     try {
	       sObjOpp.StageName = Constants.OPPTY_STAGE_6;
	      update sObjOpp;
	     } catch (Exception ex) {
	       System.assert(ex.getMessage().contains(System.Label.OECS_MSG_STAGE_6_TO_7_OPPTY_APPROVAL));
	     }
	     Test.stopTest();
    }
  }
    
   //test methods to check the functionality of Opportunity_ExitCriteriaUtility.cls
    @isTest (seealldata=true)
    static void testOpportunitiesExitCriteriaNotMet(){
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
      
      System.runAs(testUser1) {
        User user1= Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        insert user1;
        
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Has_Senior_Approval__c = true;
        testOpp.StageName = Constants.OPPTY_STAGE_3;
        //testOpp.Below_Review_Thresholds__c = 'Yes';  T-271695: Removed reference to Below_Review_Thresholds__c field
        testOpp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
        testOpp.Type = Constants.OPPTY_TYPE_RENEWAL;
        insert testOpp;
        Test_Utils.insertCompetitor(testOpp.Id);
        Contact contact = new Contact(FirstName = 'Test-Contact', LastName = 'J');
        insert contact;
        
        Test_Utils.createOpptyTasks(testOpp.Id, true);
      
        OpportunityContactRole OppRole = new OpportunityContactRole(OpportunityId = testOpp.Id, ContactId = contact.Id, 
                                                                    Role = Constants.DECIDER, IsPrimary = true );
        insert OppRole;
        
        //create opportunity line item
        Product2 product = Test_Utils.insertProduct();
        product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;    
        product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;    
        product.NumberOfRevenueInstallments = 2;    
        //product.CanUseQuantitySchedule = false;
        product.CanUseRevenueSchedule = true;
      
        update product;
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);
        //insert OLI
        olis = new List<OpportunityLineItem>();
        olis.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        olis.add(Test_Utils.createOpportunityLineItem(testOpp.Id, stdPricebookEntryObj.Id, testOpp.Type));
        for(OpportunityLineItem oli : olis){
            oli.Start_Date__c = System.today().addDays(-5);
            oli.End_Date__c = System.today(); 
         }
        insert olis;
      
        Test.startTest();
                       
        Opportunity newtestOpp= [SELECT Id, Has_Senior_Approval__c, StageName,  Starting_Stage__c, Competitor_Count__c, //Below_Review_Thresholds__c, T-271695:Removed reference to Below_Review_Thresholds__c 
                                 Turn_Off_Contact_Role_Criteria_Check__c from Opportunity where Id = :testOpp.Id];                         
        Test_Utils.createOpptyTasks(newtestOpp.Id, true);
        newtestOpp.StageName = Constants.OPPTY_STAGE_4;
        newtestOpp.Turn_Off_Contact_Role_Criteria_Check__c = false;
        newtestOpp.Senior_Approver__c = user1.Id;
        //newtestOpp.Has_Completed_Task__c = false;
        try { 
          update newtestOpp;
        } catch(Exception ex) {
              System.assert(ex.getMessage().contains(System.Label.Opp_Stage_3_Stage_Exit_Failure));
        } 
                
        Opportunity test4stage = [SELECT Id, Has_Stage_3_Approval__c, Has_Senior_Approval__c, StageName, Starting_Stage__c //Below_Review_Thresholds__c, T-271695:Removed reference to Below_Review_Thresholds__c 
                                  from Opportunity where Id = :testOpp.Id];
        test4stage.Has_Stage_3_Approval__c = false; 
        test4stage.StageName = Constants.OPPTY_STAGE_5;
        test4stage.Senior_Approver__c = user1.Id;
        update test4stage;
        
        Task t = Test_Utils.createTask(contact.Id, testOpp.Id);
        t.Type = Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED;
        t.Status = Constants.STATUS_COMPLETED;
        t.Outcomes__c = 'Quote delivered';
        insert t;
     
        Opportunity test5stage =[SELECT Id, Senior_Approver__c, Has_Senior_Approval__c, StageName, Starting_Stage__c,  
                                   Has_There_Been_Significant_Change__c, Amount FROM Opportunity where Id =:testOpp.Id]  ;
        test5stage.Senior_Approver__c = user1.Id;
        test5stage.Has_Senior_Approval__c =true;
        test5stage.Has_There_Been_Significant_Change__c = 'No';
        test5stage.Amount = 600000;
        update test5stage;
        
        test5stage.StageName = Constants.OPPTY_STAGE_6;
        update test5Stage;
                   
        Test.stopTest();
      }
    }  
}