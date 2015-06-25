/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanPenetrationTest
 * Description: Test class to verify the behavior of AccountPlanPenetration
 * Created Date: 3rd June' 2014
 * Created By: Jinesh Goyal (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Feb 16th, 2015        Noopur               T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
@isTest (seeAllData = false)
private class AccountPlanPenetrationTest {
private static Account testAccount;
private static Account_Plan__c testAccountPlan;
private static Account_Plan_Penetration__c testAPP;
private static Opportunity testOpp;

  //=============================================================================================
  // Will go over most controller methods
  //=============================================================================================
  static testMethod void baseTest() {
    //Use the PageReference Apex class to instantiate a page
    testAccount = [SELECT Id FROM Account];
    testAccountPlan = [SELECT Id FROM Account_Plan__c];
    PageReference pageRef = Page.AccountPlanPenetration;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('id', testAccountPlan.Id);

    Test.startTest();
    ApexPages.StandardController sc = new ApexPages.StandardController(testAccountPlan);
    AccountPlanPenetration controller =  new AccountPlanPenetration(sc);
    AccountPlanPenetration controller1 =  new AccountPlanPenetration();

    List<String> listCapPicklist = new List<String> ();
    for(Schema.PicklistEntry pe: Account_Plan_Penetration__c.sObjectType.getDescribe().fields.getMap().get('Capability__c').getDescribe().getPicklistValues()) {
      listCapPicklist.add(pe.getLabel());
    }
    //save
    controller.save();
    List <Account_Plan_Penetration__c> lstAPP = [SELECT Id FROM Account_Plan_Penetration__c
                                                 WHERE Account_Plan__c= :testAccountPlan.Id];
    System.assertEquals(listCapPicklist.size()*6, lstAPP.size());

    controller.gerrevenueAggregateResult();

    controller.getOpenOpps(testAccount.Id);
    controller.getWonOpps(testAccount.Id);
    controller.backToPlan();
    Test.stopTest();
  }

  //=============================================================================================
  // Create test data: Account, Account Plan, Opp
  //=============================================================================================
  @testSetup
  private static void createTestData() {
      testAccount = Test_Utils.insertAccount();
      testAccountPlan = Test_Utils.insertAccountPlan(true, testAccount.Id);
      testAPP = Test_Utils.insertAccountPlanPenetration(true, testAccountPlan.Id);

      testOpp = Test_Utils.createOpportunity(testAccount.Id);
      //testOpp.StageName = Constants.OPPTY_STAGE_7;
      testOpp.CloseDate = system.today().addYears(-1);
      testOpp.Amount = 1000;
      testOpp.Capability__c = 'Application Processing';
      insert testOpp;

    }
}