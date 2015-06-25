/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanCompetitorTriggerHandler
 * Description: I-120524
 * Created Date: Aug 18th, 2014
 * Created By: Bharti (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
 @isTest
 private class AccountPlanCompetitorTriggerHandler_Test {
 	static testMethod void testSyncCurrencyISOCodes(){
      User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert testUser1; 
      
      // insert account
      Account account = Test_Utils.insertAccount();
      
      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      accountPlan.Name = 'TestAccountPlan';
      insert accountPlan;
      
      Account_Plan_Competitor__c apc = new Account_Plan_Competitor__c(Account_Plan__c = accountPlan.id,
                                       CurrencyIsoCode = 'USD');
      insert apc;
               
      accountPlan.Name = 'TestAccountPlan1';
      accountPlan.CurrencyIsoCode = 'INR';    
      update accountplan;
  
      System.assertEquals([SELECT CurrencyIsoCode FROM Account_Plan_Competitor__c WHERE Account_Plan__c =: accountPlan.ID].CurrencyIsoCode, accountPlan.CurrencyIsoCode);
 	}

}