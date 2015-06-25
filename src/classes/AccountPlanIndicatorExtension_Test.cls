/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanIndicatorExtension
 * Description: To show AccountPlanIndicatorPage's stages with hover tooltip.
 * Created Date: Jan 07th 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest(SeeAllData=true)
private class AccountPlanIndicatorExtension_Test {
	private static Account testAccount;
	private static Account_Plan__c testAccountPlan;

  static testMethod void myUnitTest() {
    testAccount = Test_Utils.insertAccount();
    testAccountPlan = Test_Utils.insertAccountPlan(true, testAccount.Id);
    
		//Use the PageReference Apex class to instantiate a page
		PageReference pageRef = Page.AccountPlanIndicatorPage;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('Id', testAccountPlan.Id);
		
		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlan);
		AccountPlanIndicatorExtension controller =  new AccountPlanIndicatorExtension(sc);
    
    Test.stopTest();
    //Assert
    System.assert(controller.lstStages.size() > 0);
  }
  
}