/**=====================================================================
 * Appirio, Inc
 * Name        : CompetitorTriggerHandler_Test
 * Description : Handler class for CompetitorTriggerHandler (for T-291592)
 * Created Date: Jul 4th, 2014
 * Created By  : Sonal Shrivastava (Appirio JDC)
 =====================================================================*/
@isTest 
private class CompetitorTriggerHandler_Test {
  
  static testMethod void testCompetitorTrigger() {
  	// insert accounts
    Account account1 = Test_Utils.insertAccount();
    Account account2 = Test_Utils.insertAccount();
    account2.Is_Competitor__c = true;
    update account2;
    
    // insert opportunity
    Opportunity opportunity = Test_Utils.createOpportunity(account1.Id);        
    insert opportunity;
    List<Opp_Plan_Score_Calc__c> opsc = new List<Opp_Plan_Score_Calc__c>();
       List<String> namelist = new List<String>{'Information Scoring','Qualification Scoring','Buying Centre','Competition Scoring','Summary Position','Solution at a Glance','Joint Action Plan','Value Proposition','Action Plan'};
       Integer i = 0;
       For(String name : namelist) {
       Opp_Plan_Score_Calc__c op1 = Test_Utils.insertOppPlanScoreCalc(name,true);
       Opp_Plan_Score_Sub_Calc__c op2 = Test_Utils.insertOppPlanScoreSubCalc(op1.Id,true);
      
       }
        
    // insert Opp Plan 
    Opportunity_Plan__c oppPlan = Test_Utils.insertOpportunityPlan(true, opportunity.id);
    
    Test.startTest();
    
    //Insert Competitor
    Competitor__c comp = new Competitor__c(Opportunity__c = opportunity.Id, Account__c = account2.Id);
    insert comp;
    
    //Verify that Opportunity Plan Competitor record is created on Opportunity Plan      
    System.assertEquals(1, [SELECT Id FROM Opportunity_Plan_Competitor__c WHERE Opportunity_Plan__c = :oppPlan.Id].size());
    
    //Delete Competitor
    delete comp;
    
    //Verify that Opportunity Plan Competitor record is deleted on Opportunity Plan      
    System.assertEquals(0, [SELECT Id FROM Opportunity_Plan_Competitor__c WHERE Opportunity_Plan__c = :oppPlan.Id].size());
    
    Test.stopTest();
  }
}