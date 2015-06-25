/**=====================================================================
 * Appirio, Inc
 * Name: AccountValueAreasExt_Test
 * Description: Test class for AccountValueAreasExt.cls
 * Created Date: June 2nd, 2014
 * Created By: Ceri Jones
 *
 * Date Modified      Modified By                Description of the update
 * Oct 29th, 2014     Arpita Bose(Appirio)       Updated to increase the code coverage
 =====================================================================*/
 @isTest
private class AccountValueAreasExt_Test {

	static testmethod void testValueAreas() {
		Account account = Test_Utils.insertAccount();

		Account_plan__c aPlan = Test_Utils.insertAccountPlan(false, Account.id);
		insert aPlan;

		Account_Plan_Opportunity__c accOpp = new Account_Plan_Opportunity__c(Account_plan__c=aPlan.id,Type__c='Total',
			Current_Year_Revenue__c=12345,Year_1_Revenue__c=12345,Year_2_Revenue__c=12345);
		Account_Plan_Opportunity__c accOpp2 = new Account_Plan_Opportunity__c(Account_plan__c=aPlan.id,Type__c='Potential Future Opps',
			Current_Year_Revenue__c=12345,Year_1_Revenue__c=12345,Year_2_Revenue__c=12345);
		
		//Account_Plan_Opportunity__c accOpp3 = new Account_Plan_Opportunity__c(Account_plan__c=aPlan.id, Type__c='Open Opps',
			//Current_Year_Revenue__c=12345,Year_1_Revenue__c=12345,Year_2_Revenue__c=12345, CurrencyISOCode='USD');
		//insert accOpp3;
		
		
		List<Account_Plan_Opportunity__c> listaccOpps = new list<Account_Plan_Opportunity__c>{accOpp,accOpp2};
		insert listAccOpps;

        PageReference pageRef = Page.AccountValueAreas;
        Test.setCurrentPage(pageRef);

        // call the constructor and wrapper classes
        ApexPages.StandardController sc = new ApexPages.standardController(aPlan);
        AccountValueAreasExt ave = new AccountValueAreasExt(sc);
        
        System.assertEquals(ave.listAPO[0].Type__c,'Potential Future Opps');
        System.assertEquals(ave.listAPO[1].Type__c,'Total');

	}

}