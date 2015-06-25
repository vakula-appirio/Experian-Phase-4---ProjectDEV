/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_OpportunTriggerHandler_Test
 * Description: Test Class for Account_Plan_OpportunityTriggerHandler (for T-276706)
 * Created Date: May 7th, 2014
 * Created By: Rahul Jain (Appirio)
 *
 * Date Modified      Modified By                Description of the update
 * Oct 27th, 2014     Arpita Bose(Appirio)       Updated to remove IsDataAdmin__c
 =====================================================================*/
@isTest
private class Account_Plan_OpportunTriggerHandler_Test {

 static testMethod void testCreateRelatedAccountPlanOppSwotEntries() {
    Test.startTest();
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;

    System.runAs(testUser1){
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER);
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_SWOT_TRIGGER);
      //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      Account_Plan_Opportunity__c accountPlanOpp;
      // insert account
      Account account = Test_Utils.insertAccount();

      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      insert accountPlan;


      List<Account_Plan_SWOT__c> accPlanSwots = new List<Account_Plan_SWOT__c>();

      Account_Plan_SWOT__c accountPlanSwot = Test_Utils.insertAccountPlanSwot(false, accountPlan.id);
      accPlanSwots.add(accountPlanSwot);
      Account_Plan_SWOT__c accountPlanSwot1 = Test_Utils.insertAccountPlanSwot(false, accountPlan.id);
      accPlanSwots.add(accountPlanSwot1);
      insert accPlanSwots;

      List<Account_Plan_Opportunity_SWOT__c> accPlanOppSwots1 = [select Account_Plan_Opportunity__c, id
                                                                from Account_Plan_Opportunity_SWOT__c
                                                                where Account_Plan_SWOT__c IN : accPlanSwots];

      System.assertEquals(accPlanOppSwots1.size(), 0, 'there should be no account plan opp swot records created as there is no acc plan opp exists');

      /*IsDataAdmin__c isDataAdmin = [SELECT Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];//IsDataAdmin__c.getInstance();
      isDataAdmin.IsDataAdmin__c = true;
      update isDataAdmin;*/

       // Create an opportunity
      Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
      opp1.Has_Senior_Approval__c = true;
      opp1.StageName = Constants.OPPTY_STAGE_3;
      opp1.Amount = 500;
      opp1.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      insert opp1;

      //isDataAdmin.IsDataAdmin__c = false;
      //update isDataAdmin;

      List<Account_Plan_Opportunity__c> accountPlanOppList = [select id
                                                              from Account_Plan_Opportunity__c
                                                              where Account_Plan__c = : accountPlan.id and Opportunity__c =: opp1.id];

      //system.assertEquals(accountPlanOppList.size(), 1, 'creation of opp should have created acc plan opp record');
      if(accountPlanOppList.size() > 0){
        accountPlanOpp = accountPlanOppList[0];
      }else{
        accountPlanOpp = Test_Utils.insertAccountPlanOpp(false, accountPlan.id, opp1.id);
        insert accountPlanOpp;
      }

      accPlanOppSwots1 = [select Account_Plan_Opportunity__c, id
                                                                from Account_Plan_Opportunity_SWOT__c
                                                                where Account_Plan_SWOT__c = : accPlanSwots];

      System.assertEquals(accPlanOppSwots1.size(), 2, 'insertion of account plan opp should have created two account plan opp swot entries for both swots');


    }
    Test.stopTest();
 }

  static testMethod void testUpdateRelatedOpptyShouldUpdateFields() {

    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;

    System.runAs(testUser1){
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER);
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_SWOT_TRIGGER);
      //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      Account_Plan_Opportunity__c accountPlanOpp;
      // insert account
      Account account = Test_Utils.insertAccount();

      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      insert accountPlan;


      /*IsDataAdmin__c isDataAdmin = [SELECT Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];//IsDataAdmin__c.getInstance();
      isDataAdmin.IsDataAdmin__c = true;
      update isDataAdmin;*/

      Opportunity opp2 = Test_Utils.createOpportunity(account.Id);
      opp2.Has_Senior_Approval__c = true;
      opp2.StageName = Constants.OPPTY_STAGE_3;
      opp2.Amount = 1500;
      opp2.Starting_Stage__c = Constants.OPPTY_STAGE_7;
      opp2.Contract_Start_Date__c = Date.today().addDays(10);
      opp2.Contract_End_Date__c = Date.today().addDays(20);
      insert opp2;

      //isDataAdmin.IsDataAdmin__c = false;
      //update isDataAdmin;

      Test.startTest();

	    accountPlanOpp = Test_Utils.insertAccountPlanOpp(false, accountPlan.id, null);
  	  insert accountPlanOpp;

      //Not equal to opportunity amount
      System.assertNotEquals([SELECT TCV__C, ID FROM Account_Plan_Opportunity__c WHERE ID =: accountPlanOPp.ID].TCV__c, opp2.Amount);

      accountPlanOpp.Opportunity__c = opp2.ID;
      update accountPlanOpp;

      //Equal to opportunity amount
      System.assertEquals([SELECT TCV__C, ID FROM Account_Plan_Opportunity__c WHERE ID =: accountPlanOPp.ID].TCV__c, opp2.Amount);
      Test.stopTest();

      delete accountPlanOpp;
      undelete accountPlanOpp;
    }
  }

  static testMethod void testUpdateAccountPlanParentOpportunity() {

    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;

    System.runAs(testUser1){
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_OPPORTUNITY_TRIGGER);
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_SWOT_TRIGGER);
      IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      Account_Plan_Opportunity__c accountPlanOpp;

      // insert account
      Account account = Test_Utils.insertAccount();

      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      insert accountPlan;


      /*IsDataAdmin__c isDataAdmin = [SELECT Id, IsDataAdmin__c FROM IsDataAdmin__c limit 1];//IsDataAdmin__c.getInstance();
      isDataAdmin.IsDataAdmin__c = true;
      update isDataAdmin;*/

      Opportunity opp2 = Test_Utils.createOpportunity(account.Id);
      opp2.Has_Senior_Approval__c = true;
      opp2.StageName = Constants.OPPTY_STAGE_3;
      opp2.Amount = 1500;
      opp2.Starting_Stage__c = Constants.OPPTY_STAGE_3;
      opp2.Contract_Start_Date__c = Date.today().addDays(10);
      opp2.Contract_End_Date__c = Date.today().addDays(20);
      insert opp2;

      Opportunity opp3 = Test_Utils.createOpportunity(account.Id);
      opp3.Has_Senior_Approval__c = true;
      opp3.StageName = Constants.OPPTY_STAGE_3;
      opp3.Amount = 1500;
      //opp3.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
      opp3.Starting_Stage__c = Constants.OPPTY_STAGE_3;
      opp3.Contract_Start_Date__c = Date.today().addDays(10);
      opp3.Contract_End_Date__c = Date.today().addDays(20);
      insert opp3;

      //isDataAdmin.IsDataAdmin__c = false;
      //update isDataAdmin;

      Test.startTest();     
	    accountPlanOpp = Test_Utils.insertAccountPlanOpp(false, accountPlan.id, null);
      insert accountPlanOpp;

      accountplanOpp.Opportunity__c = opp2.Id;
      update accountPlanOpp;

      Account_Plan_Opportunity__c accountPlanOpp2 = Test_Utils.insertAccountPlanOpp(false, accountPlan.id, null);
      insert accountPlanOpp2;

      accountplanOpp2.Opportunity__c = opp3.id;
      update accountPlanOpp2;

      Account_Plan_Parent_Opportunities__c appo = new Account_Plan_Parent_Opportunities__c();
      appo.Account_Plan__c = accountPlan.ID;
      insert appo;

      accountPlanOpp.Account_Plan_Parent_Opportunity__c  = appo.ID;
      update accountPlanOpp;

      accountPlanOpp2.Account_Plan_Parent_Opportunity__c  = appo.ID;
      update accountPlanOpp2;

      List<Account_Plan_Parent_Opportunities__c> listappo = [SELECT Annualised_Open_Revenue__c, Annualised_Won_Revenue__c, ID 
                                                             FROM Account_Plan_Parent_Opportunities__c WHERE ID =: appo.ID];
      system.debug('listappo>>>' +listappo);
      
      // Is Opp Amount added to Parent Opp
      System.assertEquals(listappo[0].Annualised_Won_Revenue__c, null);
      System.assertNotEquals(listappo[0].Annualised_Open_Revenue__c, null);

      Account_Plan_Parent_Opportunities__c appo2 = new Account_Plan_Parent_Opportunities__c();
      appo2.Account_Plan__c = accountPlan.ID;
      insert appo2;

      accountPlanOpp.Account_Plan_Parent_Opportunity__c  = appo2.ID;
      update accountPlanOpp;

      accountPlanOpp2.Account_Plan_Parent_Opportunity__c  = appo2.ID;
      update accountPlanOpp2;

      //Is Opp amount removed
      System.assertNotEquals(listappo[0].Annualised_Open_Revenue__c, [SELECT Annualised_Open_Revenue__c, ID FROM Account_Plan_Parent_Opportunities__c WHERE ID =: appo.ID].Annualised_Open_Revenue__c);

      accountPlanOpp.Account_Plan_Parent_Opportunity__c  = null;
      update accountPlanOpp;

      accountPlanOpp2.Account_Plan_Parent_Opportunity__c  = null;
      update accountPlanOpp2;

      //Is Opp amount removed
      System.assertEquals(0.00, [SELECT Annualised_Open_Revenue__c, ID FROM Account_Plan_Parent_Opportunities__c WHERE ID =: appo.ID].Annualised_Open_Revenue__c);
    }
  }
}