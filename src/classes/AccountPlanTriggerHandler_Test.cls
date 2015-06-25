/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanTriggerHandler_Test
 * Description: Test class to test AccountPlanTrigger and its handler class.
 * Created Date: May 30th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Oct 27th, 2014               Arpita Bose(Appirio)         Updated createAccountPlanOppsTest(), synchCurrencyISOCodes_Test() and 
 *                                                           createTestDataForSynch()to fix failure 
 =====================================================================*/
@isTest
public with sharing class AccountPlanTriggerHandler_Test {
  static testMethod void createAccountPlanOppsTest() {
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;   
    
    System.runAs(testUser1) {
    	Test.startTest();
		  // insert account
		  Account account = Test_Utils.insertAccount();
	
		  Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
		  opp1.Has_Senior_Approval__c = true;
		  opp1.StageName = Constants.OPPTY_STAGE_3;       
		  opp1.Amount = 500;
		  opp1.Starting_Stage__c = Constants.OPPTY_STAGE_7;
		  opp1.Contract_Start_Date__c = Date.today().addDays(10);
      opp1.Contract_End_Date__c = Date.today().addDays(20);
		  insert opp1;
                         
	    
		  // create account plan
		  Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
		  accountPlan.Name = 'TestAccountPlan';
		  insert accountPlan;

		  Test.stopTest();
	    System.assertEquals([SELECT count() FROM Account_Plan_Opportunity__c WHERE Account_Plan__c =: accountPlan.ID], 1);
    }   	
  }
  //Test method for SynchCurrencyISOCodes 
  static testMethod void synchCurrencyISOCodes_Test() {
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;   
    
    System.runAs(testUser1) {
      // insert account
      Account account = Test_Utils.insertAccount();
      Contact testContact = Test_Utils.insertContact(account.ID);
      
      Opportunity opp1 = Test_Utils.createOpportunity(account.Id);
      opp1.Has_Senior_Approval__c = true;
      opp1.StageName = Constants.OPPTY_STAGE_3;       
      opp1.Amount = 500;
      opp1.Starting_Stage__c = Constants.OPPTY_STAGE_3;
      insert opp1;
  
      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      accountPlan.Name = 'TestAccountPlan';
      accountPlan.CurrencyISOCode = 'USD';
      insert accountPlan;
    	
    	Test.startTest();
      createTestDataForSynch (accountPlan);
      
    	List<Account_Plan__c> accPlanList = [SELECT Id, CurrencyIsoCode, (SELECT Id, CurrencyIsoCode From Account_Plan_Competitors__r), 
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Contacts__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Critical_Success_Factors__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Opportunity__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Parent_Opportunities__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Penetrations__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_SWOT__r),
						                                 (Select Id, CurrencyIsoCode From Account_Plan_Teams__r)
						                                 From Account_Plan__c 
						                                 WHERE ID =: accountPlan.ID];
			                                 
      //Current ISO Code is EUR on all the records.
    	System.assertEquals(accPlanList.get(0).CurrencyISOCode, 'USD');
    	System.assertEquals(accPlanList.get(0).Account_Plan_Competitors__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Contacts__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Critical_Success_Factors__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Opportunity__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Parent_Opportunities__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Penetrations__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_SWOT__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    	System.assertEquals(accPlanList.get(0).Account_Plan_Teams__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode); 
    	
    	accPlanList.get(0).CurrencyISOCode = 'EUR';
    	update accPlanList;

    	Test.stopTest();

      accPlanList = [SELECT Id, CurrencyIsoCode, (SELECT Id, CurrencyIsoCode From Account_Plan_Competitors__r), 
                                             (Select Id, CurrencyIsoCode From Account_Plan_Contacts__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_Critical_Success_Factors__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_Opportunity__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_Parent_Opportunities__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_Penetrations__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_SWOT__r),
                                             (Select Id, CurrencyIsoCode From Account_Plan_Teams__r)
                                             From Account_Plan__c 
                                             WHERE ID =: accountPlan.ID];
                                             
      //Updated ISO Code is USD on all the records.
      System.assertEquals(accPlanList.get(0).CurrencyISOCode, 'EUR');
      System.assertEquals(accPlanList.get(0).Account_Plan_Competitors__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Contacts__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Critical_Success_Factors__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Opportunity__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Parent_Opportunities__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Penetrations__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_SWOT__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
      System.assertEquals(accPlanList.get(0).Account_Plan_Teams__r.get(0).CurrencyISOCode, accPlanList.get(0).CurrencyISOCode);
    }
  }
  
  //Creating account plan's related records
  private static void createTestDataForSynch (Account_Plan__c accPlan) {
  	String accPlanID = accPlan.ID;
    
    Account_Plan_Competitor__c testAPCompetitor = new Account_Plan_Competitor__c(
                            Account_Plan__c = accPlanID);
    insert testAPCompetitor;
    
    Account_Plan_Contact__c testAPContact = new Account_Plan_Contact__c(
                            Account_Plan__c = accPlanID);
    insert testAPContact;

    Account_Plan_Critical_Success_Factor__c acctPlanCSF = new Account_Plan_Critical_Success_Factor__c();
    acctPlanCSF.Account_Plan__c= accPlanID;
    acctPlanCSF.Description__c = 'Test Description';
    insert acctPlanCSF ;
    
    Account_Plan_Opportunity__c accOpp = new Account_Plan_Opportunity__c(Account_plan__c = accPlanID);
    insert accOpp;
    
	  Account_Plan_Parent_Opportunities__c appo = new Account_Plan_Parent_Opportunities__c();
	  appo.Account_Plan__c = accPlanID;
	  insert appo;
    
    Account_Plan_Penetration__c accPlanPen = Test_Utils.insertAccountPlanPenetration(false, accPlanID);
    insert accPlanPen;

    User teamUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert teamUser;   
    
    AccountTeamMember atm = Test_Utils.insertAccountTeamMember(true, accPlan.Account__c, teamUser.ID, 'Account Manager');
    
    Account_Plan_SWOT__c accountPlanSwot = Test_Utils.insertAccountPlanSwot(false, accPlanID);
    insert accountPlanSwot;
    
    Account_Plan_Team__c accountPlanTeam = Test_Utils.insertAccountPlanTeam(false, accPlanID, teamUser.id);
    insert accountPlanTeam;
  }
}