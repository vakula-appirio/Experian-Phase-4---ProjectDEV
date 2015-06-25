/**=====================================================================
 * Appirio, Inc
 * Name: TestOpportunityClosedLostExtension
 * Description: This test class is for testing the 'OpportunityClosedLostExtension.cls' class
				 Story:		S-153835
				 Task: 		T-205590
 * Created Date: 
 * Created By: Pankaj Mehra (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 05th, 2014               Arpita Bose(Appirio)             T-243282: Added Constants in place of String
 * Mar 14th, 2014               Arpita Bose(Appirio)             T-253906: Fixed error
 * Apr 24th, 2014               Arpita Bose                      Updated testmethod to increase the code coverage
 =====================================================================*/

@isTest
private class TestOpportunityClosedLostExtension {
		
		@isTest
    static void testOpportunityUpdate() {
    	
    	// Insert custom setting
    	Global_Settings__c setting = Test_Utils.insertGlobalSettings();
    	Test_Utils.insertIsDataAdmin(true);
    	Account account = Test_Utils.insertAccount();
    	Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
    	opportunity.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_COMPETITION;
    	insert opportunity;
    	
    	Account competitorAccount1 = Test_Utils.createAccount();
    	competitorAccount1.Is_Competitor__c = true;
    	insert competitorAccount1;
    	Competitor__c competitor1 = Test_Utils.createCompetitor(opportunity.Id);
    	competitor1.Account__c = competitorAccount1.Id;
    	insert competitor1;
    	Account competitorAccount2 = Test_Utils.createAccount();
    	competitorAccount2.Is_Competitor__c = true;
    	insert competitorAccount2;
    	Competitor__c competitor2 = Test_Utils.createCompetitor(opportunity.Id);
    	competitor2.Account__c = competitorAccount2.Id;
    	insert competitor2;
    	List<SelectOption> options = new List<SelectOption>();
    	
    	Test.startTest();
    	ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller(opportunity);
    	OpportunityClosedLostExtension extension = new OpportunityClosedLostExtension(controller);
    	
    	
    	// Create Competitor Select Option List
    	List<SelectOption> competitorSelectList = extension.getCompetitors();
    	System.assert(competitorSelectList.size() == 3);
    	
    	Boolean decision = extension.isNoDecisionType;
      decision=false;
      
      ApexPages.currentPage().getParameters().put('type', 'nodecision'); 
      
      Opportunity opp = [select Name,StageName,Primary_Reason_W_L__c,Type,isClosed, isWon, Other_Closed_Reason__c, Lost_To__c, Win_Back_Date__c, Primary_Winning_Competitor__c from Opportunity where id=:opportunity.Id];
      system.debug('#####opp#####' +opp);
      
    	List<SelectOption> PrimaryReasonsSelectList = extension.getPrimaryReasons();
    	// Set Selected Primary
    	extension.selectedPrimaryReason = 'Competition';
    	// Update Selected Primary
    	extension.primaryReasonChanged();
    	// Set Selected Comprtitor
    	extension.selectedCompetitor = competitor1.Id;
    	
    	// Set the Opportunity to closed and set status of selected Competitor
    	extension.saveRecord();
    	opportunity.Primary_Winning_Competitor__c = 'Abacus';
    	update opportunity;
    	decision=false;
    	extension.saveRecord();
    	Test.stopTest();
    	//Opportunity updatedOppty = [SELECT StageName FROM Opportunity WHERE Id =: opportunity.Id];
    	//System.assert(updatedOppty.StageName == Constants.OPPTY_CLOSED_LOST);
    	
    	//Competitor__c updatedCompetitor = [SELECT Lost_To__c FROM Competitor__c WHERE Id =: competitor1.Id];
    	//System.assert(updatedCompetitor.Lost_To__c == true);
    	
    	// Testing Errors :
    	Opportunity opportunitywithoutPrimaryReason = Test_Utils.createOpportunity(account.Id);
    	opportunitywithoutPrimaryReason.StageName = setting.Opp_Closed_Lost_Stagename__c;
    	opportunitywithoutPrimaryReason.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_TERMS;
    	insert opportunitywithoutPrimaryReason;
    	controller = new ApexPages.Standardcontroller(opportunitywithoutPrimaryReason);
    	extension = new OpportunityClosedLostExtension(controller);
    	List<ApexPages.Message> msgList = ApexPages.getMessages();
    	// Controller will generate page message as opportuntiy is closed
    	System.assert(msgList.size() > 0);
    	// No competitor so select list will have 2 options
    	List<SelectOption> competitorSelectList2 = extension.getCompetitors();
    	extension.createComp();
    	extension.opp.Primary_Reason_W_L__c = '';
    	// Save record will through a Error as Opportunity PrimaryReason is blank
    	extension.saveRecord();
    	msgList = ApexPages.getMessages();
    	System.assert(msgList.size() > 1);
    	// Save record will throw a Error as Opportunity PrimaryReason is Other and Other_Closed_Reason is null
    	extension.opp.Other_Closed_Reason__c = '';
    	extension.opp.Primary_Reason_W_L__c = 'Other';
    	extension.saveRecord();
    	msgList = ApexPages.getMessages();
      System.assert(msgList.size() > 1);
      
    	// Set Opportunity PrimaryReason 
    	extension.opp.Primary_Reason_W_L__c = Constants.PRIMARY_REASON_WLC_COMPETITION;
    	// Save record will through no competitor is selected
    	extension.saveRecord();
    	
    }
}