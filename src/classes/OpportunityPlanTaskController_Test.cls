/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanTaskController_Test
 * Description: Test class for OpportunityPlanTaskController.cls (for T-273988)
 * Created Date: May 2nd, 2014
 * Created By: Rahul Jain (Appirio)
 *
 * Date Modified      Modified By                Description of the update
 * Oct 21st, 2014     Arpita Bose(Appirio)       Updated to remove IsDataAdmin__c
 * Mar 17th, 2015     Gaurav Kumar Chadha        Added test data (lstopprtSalesProcesses)
 =====================================================================*/
@isTest
private class OpportunityPlanTaskController_Test {
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
	      //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
	      List<String> salesStages = new List<String>{'ss1', 'ss2', 'ss3'};
	      List<String> actionItems = new List<String>{'ai1', 'ai2', 'ai3'};
	      // insert account
	      Account account = Test_Utils.insertAccount();
	      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
		    insert opportunity;

		    Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
		    insert oPlan;
		    
		    List<Opportunity_Sales_Process__c> lstopprtSalesProcesses = new List<Opportunity_Sales_Process__c>();
		    
		    Opportunity_Sales_Process__c opprtSalesProcess1 = Test_Utils.insertOpportunitySalesProcess(false,  'TestOpportunitySalesProcess1');
		    opprtSalesProcess1.Sales_Process_Name__c = Constants.SALES_PROCESS_LEAD;
		    lstopprtSalesProcesses.add(opprtSalesProcess1);
		    
		    Opportunity_Sales_Process__c opprtSalesProcess2 = Test_Utils.insertOpportunitySalesProcess(false , 'TestOpportunitySalesProcess2');
        opprtSalesProcess2.Sales_Process_Name__c = Constants.SALES_PROCESS_LEAD;
        lstopprtSalesProcesses.add(opprtSalesProcess2);
        
        Opportunity_Sales_Process__c opprtSalesProcess3 = Test_Utils.insertOpportunitySalesProcess(false,  'TestOpportunitySalesProcess3');
        opprtSalesProcess3.Sales_Process_Name__c = Constants.SALES_PROCESS_LEAD;
        lstopprtSalesProcesses.add(opprtSalesProcess3);
        
		    insert lstopprtSalesProcesses;
		    

	      List<Action_Items__c> aItemList = new List<Action_Items__c>();
	      for(string stage : salesStages){
	      	for(string item : actionItems){
	      		Action_Items__c aItem = new Action_Items__c();
	      	  aItem.Name = stage + item;
	      	  aItem.Sales_Stage__c = stage;
	      	  aItem.Action_Item__c = stage + ':' + item;
	      	  aItemList.add(aItem);
	      	}
	      }
	      insert aItemList;

	      ApexPages.Pagereference pg = Page.OpportunityPlanTask;
	      pg.getParameters().put('id', oPlan.id);
	      Test.setCurrentPage(pg);

	      OpportunityPlanTaskController oppPlanCont = new OpportunityPlanTaskController();
	      System.assertEquals(oppPlanCont.opportunityPlanId, oPlan.id, 'page should have opp plan id in url as key value parameter');
	      oppPlanCont.doPageAction();
	      System.assertEquals(oppPlanCont.salesStagesOptions.size(), salesStages.size(), 'there should be 3 sales stages in the dropdown');
	      //System.assertEquals(oppPlanCont.actionItemsOptions.size(), actionItems.size() + 1, 'there should be 4 associated action items in the dropdown + none value');
	      //System.assertEquals(oppPlanCont.selectedSalesStage, salesStages[0], 'verify that first record is selected automatically');

	      //change the selected stage
	      oppPlanCont.selectedSalesStage = salesStages[1];
	      oppPlanCont.onChangeSalesStages();
	      System.assertEquals(oppPlanCont.actionItemsOptions.size(), actionItems.size() + 1, 'there should be 4 associated action items in the dropdown + none value');
	      System.assertEquals(oppPlanCont.selectedSalesStage, salesStages[1], 'verify that correct sales stage record is selected');

		    // currently neither action item or if other value is populated
		    // the page should throw error in this case
	      PageReference pgNextAction = oppPlanCont.nextAction();
	      System.assertEquals(pgNextAction, null, 'page should not redirect to another page');

	      // select action item
	      oppPlanCont.selectedActionItem = oppPlanCont.actionItemsOptions[1].getValue();
	      pgNextAction = oppPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');

		    // remove selectedActionItem and add ifother
		    oppPlanCont.selectedActionItem = '';
		    oppPlanCont.selectedIfOther = 'Other Value';
		    pgNextAction = oppPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');

		      // when both action item and if other is populated
		    oppPlanCont.selectedActionItem = oppPlanCont.actionItemsOptions[1].getValue();
		    oppPlanCont.selectedIfOther = 'Other Value';
		    pgNextAction = oppPlanCont.nextAction();
		    System.assertNotEquals(pgNextAction, null, 'page redirect to another page');


	      PageReference pgCancel = oppPlanCont.cancelAction();
	      System.assertEquals(pgCancel.getURL().contains(oPlan.id), true, 'should redirect to opp plan detail record');
	    }
	    Test.stopTest();
	}
}