/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_SWOTTriggerHandler_Test
 * Description: Test class for Account_Plan_SWOTTriggerHandler (for T-276704)
 * Created Date: May 7th, 2014
 * Created By: Rahul Jain (Appirio)
 *
 * Date Modified      Modified By                Description of the update
 * Oct 21st, 2014     Arpita Bose(Appirio)       Updated to remove IsDataAdmin__c
 =====================================================================*/
@isTest
private class Account_Plan_SWOTTriggerHandler_Test {

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

		      Account_Plan_SWOT__c accountPlanSwot = Test_Utils.insertAccountPlanSwot(false, accountPlan.id);
          insert accountPlanSwot;

		      List<Account_Plan_Opportunity_SWOT__c> accPlanOppSwots1 = [select Account_Plan_Opportunity__c, id
                                                                    from Account_Plan_Opportunity_SWOT__c
                                                                    where Account_Plan_SWOT__c = : accountPlanSwot.id];

		      System.assertEquals(accPlanOppSwots1.size(), 0, 'there should be no account plan opp swot records created as there is no acc plan opp exists');


		       // Create an opportunity
		      Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
		      opp1.Has_Senior_Approval__c = true;
		      opp1.StageName = Constants.OPPTY_STAGE_3;
		      opp1.Amount = 500;
		      opp1.Starting_Stage__c = Constants.OPPTY_STAGE_3;
		      insert opp1;

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
                                                                    where Account_Plan_SWOT__c = : accountPlanSwot.id];

          System.assertEquals(accPlanOppSwots1.size(), 1, 'insertion of account plan opp should have created one account plan opp swot entry');


		      Account_Plan_SWOT__c accountPlanSwot1 = Test_Utils.insertAccountPlanSwot(false, accountPlan.id);
		      insert accountPlanSwot1;

		      List<Account_Plan_Opportunity_SWOT__c> accPlanOppSwots = [select Account_Plan_Opportunity__c, id
		                                                                from Account_Plan_Opportunity_SWOT__c
		                                                                where Account_Plan_SWOT__c = : accountPlanSwot1.id];

		      System.assertEquals(accPlanOppSwots.size(), 1, 'insertion of account plan swot should have created one account plan opp swot entry');
		      System.assertEquals(accPlanOppSwots[0].Account_Plan_Opportunity__c, accountPlanOpp.id, 'validate the association with account plan opp');




		    }
		    Test.stopTest();
    }
}