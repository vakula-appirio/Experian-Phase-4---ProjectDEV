/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanTaskController_Test
 * Description: Test class for AccountPlanTaskController.cls
 * Created Date: May 29th, 2014
 * Created By: Ceri Jones
 *
 * Date Modified      Modified By                Description of the update
 =====================================================================*/
@isTest
private class AccountPlanTaskController_Test {
	static testMethod void testNextActionButtonClick_ExperianSales() {
		/**
		Ensure user can add either action item or other item and still proceed to task screen
		If user enters both it takes action item selction
		user can cancel and return to previous screen
		**/
	  Test.startTest();
	    // create User
	    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
	    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
	    insert testUser1;

	    System.runAs(testUser1){
	      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_TEAM_TRIGGER);
	      IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
	      List<String> categories = new List<String>{'ss1', 'ss2', 'ss3'};
	      List<String> actionItems = new List<String>{'ai1', 'ai2', 'ai3'};
	      // insert account
	      Account account = Test_Utils.insertAccount();

		    Account_plan__c aPlan = Test_Utils.insertAccountPlan(false, Account.id);
		    insert aPlan;

	      List<Action_Items__c> aItemList = new List<Action_Items__c>();
	      for(string cat : categories){
	      	for(string item : actionItems){
	      		Action_Items__c aItem = new Action_Items__c();
	      	  aItem.Name = cat + item;
	      	  aItem.Category__c = cat;
	      	  aItem.Action_Item__c = cat + ':' + item;
	      	  aItemList.add(aItem);
	      	}
	      }
	      insert aItemList;

	      ApexPages.Pagereference pg = Page.AccountPlanTask;
	      pg.getParameters().put('id', aPlan.id);
	      Test.setCurrentPage(pg);

	      AccountPlanTaskController accPlanCont = new AccountPlanTaskController();
	      System.assertEquals(accPlanCont.accountPlanId, aPlan.id, 'page should have opp plan id in url as key value parameter');
	      accPlanCont.doPageAction();
	      System.assertEquals(accPlanCont.categoryOptions.size(), categories.size()+1, 'there should be 4 categories in the dropdown');
	      //System.assertEquals(accPlanCont.actionItemsOptions.size(), actionItems.size() + 1, 'there should be 4 associated action items in the dropdown + none value');
	      //System.assertEquals(accPlanCont.selectedCategory, categories[0], 'verify that first record is selected automatically');

	      //change the selected stage
	      accPlanCont.selectedcategory = categories[1];
	      accPlanCont.onChangeCategories();
	      System.assertEquals(accPlanCont.actionItemsOptions.size(), actionItems.size() + 1, 'there should be 4 associated action items in the dropdown + none value');
	      System.assertEquals(accPlanCont.selectedcategory, categories[1], 'verify that correct sales stage record is selected');

		    // currently neither action item or if other value is populated
		    // the page should throw error in this case
	      PageReference pgNextAction = accPlanCont.nextAction();
	      System.assertEquals(pgNextAction, null, 'page should not redirect to another page');

	      // select action item
	      accPlanCont.selectedActionItem = accPlanCont.actionItemsOptions[1].getValue();
	      pgNextAction = accPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');

		    // remove selectedActionItem and add ifother
		    accPlanCont.selectedActionItem = '';
		    accPlanCont.selectedIfOther = 'Other Value';
		    pgNextAction = accPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');

		      // when both action item and if other is populated
		    accPlanCont.selectedActionItem = accPlanCont.actionItemsOptions[1].getValue();
		    accPlanCont.selectedIfOther = 'Other Value';
		    pgNextAction = AccPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');


	      PageReference pgCancel = accPlanCont.cancelAction();
	      System.assertEquals(pgCancel.getURL().contains(aPlan.id), true, 'should redirect to opp plan detail record');
	    }
	    Test.stopTest();
	}
}