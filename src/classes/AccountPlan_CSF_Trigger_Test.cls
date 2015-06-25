/**=====================================================================
 * Appirio, Inc
 * Name:         AccountPlan_CSF_Trigger_Test
 * Description:  Test Class for AccountPlan_CSF_Trigger
 * Created Date: 31 July 2014
 * Created By:   Parul Gupta
 =====================================================================*/
@isTest
private class AccountPlan_CSF_Trigger_Test {

	// This method tests for functionality of trigger on before insert
    static testMethod void testBeforeInsert() {
        Account account = Test_utils.insertAccount();
        Account_Plan__c aplan = Test_utils.insertAccountPlan(false, account.id);
        aplan.CurrencyIsoCode = 'USD';
        insert aplan;
        // Create test data in util
        Account_Plan_Critical_Success_Factor__c acctPlanCSF = new Account_Plan_Critical_Success_Factor__c();
        acctPlanCSF.Account_Plan__c= aplan.Id;
        acctPlanCSF.Description__c = 'Test Description';
        insert acctPlanCSF ;
        
        //Query currencyisocode
      
    }
    
    static testMethod void testBeforeUpdate() {
        Account account = Test_utils.insertAccount();
        Account_Plan__c aplan = test_utils.insertAccountPlan(true , account.id);
        Account_Plan_Critical_Success_Factor__c apcsf = new Account_Plan_Critical_Success_Factor__c();
        apcsf.Account_Plan__c = aplan.Id;
        apcsf.Description__c = 'hello';
        insert apcsf;
        apcsf.Description__c = 'hi';
        update apcsf;
    }
}