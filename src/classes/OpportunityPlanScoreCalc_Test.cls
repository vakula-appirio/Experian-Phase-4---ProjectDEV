/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanScoreCalc_Test
 * Description: Test class for OpportunityPlanScoreCalc.cls
 * Created Date: May 14th, 2014
 * Created By: Sunil(Appirio)
=====================================================================*/
@isTest
private class OpportunityPlanScoreCalc_Test {
  static testMethod void testMethod1() {
	  Test.startTest();
	  // create User
	  Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
	  User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
	  insert testUser1;

	  User testUser2 = Test_Utils.createUser(p, 'test1234_2@gmail.com', 'test1_2');
	  insert testUser2;

	  User testUser3 = Test_Utils.createUser(p, 'test1234_3@gmail.com', 'test1_3');
	  insert testUser3;

	  Set<Id> userIds = new Set<Id>();
	  userIds.add(testUser2.id);
	  userIds.add(testUser3.id);

	  System.runAs(testUser1){
	    // insert account
	    Account account = Test_Utils.insertAccount();

	    // insert opportunity
	    Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
	    insert opportunity;
	    /*
	    List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
	    // insert first opportunity team member
	    OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
	    oppTeamMember.UserId = testUser2.Id;
	    oppTeamMember.OpportunityId = opportunity.Id;
	    oppTeamMember.TeamMemberRole = 'Sales Rep';
	    insert oppTeamMember;
	    */
	    /*List<Opp_Plan_Score_Calc__c> lstScore = new List<Opp_Plan_Score_Calc__c>();
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Information Scoring'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Competition Scoring'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Buying Centre'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Summary Position'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Solution at a Glance'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Joint Action Plan'));
	    lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Value Proposition'));
	    insert lstScore;

	    map<String, Opp_Plan_Score_Calc__c> mapScore = new Map<String, Opp_Plan_Score_Calc__c>();
	    for(Opp_Plan_Score_Calc__c objScore :lstScore){
	    	mapScore.put(objScore.Name, objScore);
	    }*/
	    List<Opp_Plan_Score_Calc__c> listOppPlanCalc = new List<Opp_Plan_Score_Calc__c>();

        Opp_Plan_Score_Calc__c oppPlanCalc_InformationScoring = Test_Utils.insertOppPlanScoreCalc('Information Scoring', false);
        listOppPlanCalc.add(oppPlanCalc_InformationScoring);
        Opp_Plan_Score_Calc__c oppPlanCalc_QualificationScoring = Test_Utils.insertOppPlanScoreCalc('Qualification Scoring', false);
        listOppPlanCalc.add(oppPlanCalc_QualificationScoring);
        Opp_Plan_Score_Calc__c oppPlanCalc_BuyingCentre = Test_Utils.insertOppPlanScoreCalc('Buying Centre', false);
        listOppPlanCalc.add(oppPlanCalc_BuyingCentre);
        Opp_Plan_Score_Calc__c oppPlanCalc_CompetitionScoring = Test_Utils.insertOppPlanScoreCalc('Competition Scoring', false);
        listOppPlanCalc.add(oppPlanCalc_CompetitionScoring);
        Opp_Plan_Score_Calc__c oppPlanCalc_SummaryPosition = Test_Utils.insertOppPlanScoreCalc('Summary Position', false);
        listOppPlanCalc.add(oppPlanCalc_SummaryPosition);
        Opp_Plan_Score_Calc__c oppPlanCalc_SolutionAtGlance = Test_Utils.insertOppPlanScoreCalc('Solution at a Glance', false);
        listOppPlanCalc.add(oppPlanCalc_SolutionAtGlance);
        Opp_Plan_Score_Calc__c oppPlanCalc_JointActionPlan = Test_Utils.insertOppPlanScoreCalc('Joint Action Plan', false);
        listOppPlanCalc.add(oppPlanCalc_JointActionPlan);
        Opp_Plan_Score_Calc__c oppPlanCalc_ValueProposition = Test_Utils.insertOppPlanScoreCalc('Value Proposition', false);
        listOppPlanCalc.add(oppPlanCalc_ValueProposition);
        Opp_Plan_Score_Calc__c oppPlanCalc_ActionPlan = Test_Utils.insertOppPlanScoreCalc('Action Plan', false);
        listOppPlanCalc.add(oppPlanCalc_ActionPlan);
        insert listOppPlanCalc;

		List<Opp_Plan_Score_Sub_Calc__c> listSubOppPlanScoreSubCalc = new List<Opp_Plan_Score_Sub_Calc__c>();
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc1 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_InformationScoring.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc2 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_QualificationScoring.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc3 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_BuyingCentre.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc4 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_SummaryPosition.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc5 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_SolutionAtGlance.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc6 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_JointActionPlan.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc7 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_ValueProposition.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc8 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_ActionPlan.Id, false);
		Opp_Plan_Score_Sub_Calc__c oppPlanScoreSubCalc9 = Test_Utils.insertOppPlanScoreSubCalc(oppPlanCalc_CompetitionScoring.Id, false);

		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc1);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc2);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc3);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc4);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc5);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc6);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc7);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc8);
		listSubOppPlanScoreSubCalc.add(oppPlanScoreSubCalc9);
		insert listSubOppPlanScoreSubCalc;

	    //insert opportunity plan
	    Opportunity_Plan__c oPlan = new Opportunity_Plan__c();
	    oPlan.Opportunity_Name__c = opportunity.Id;
	    oPlan.Opportunity_Expected_Close_Date__c = System.today().addDays(15);
	    oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
	    oPlan.Client_Goal_1__c = 'test';
	    oPlan.CG_1_Importance__c = '1';
	    insert oPlan;

	    Opp_Plan_Score_Sub_Calc__c obj = new Opp_Plan_Score_Sub_Calc__c();
			obj.Name = 'Client_Goal_1__c';
			obj.Calculation_Field__c = 'Client_Goal_1__c';
			obj.Controlling_Field__c = '';
			obj.Object_API_Name__c = 'Opportunity_Plan__c';
			//obj.Opp_Plan_Score_Calc__c = mapScore.get('Information Scoring').Id;
			obj.Opp_Plan_Score_Calc__c = oppPlanCalc_InformationScoring.Id;
			obj.Score__c = 1;
	    insert obj;

	    Opportunity_Plan_Competitor__c competitor = new Opportunity_Plan_Competitor__c();
	    competitor.Opportunity_Plan__c = oPlan.Id;
	    competitor.Exp_Adv_1__c = 'test';
	    competitor.Comp_Adv_1__c = 'test';
	    insert competitor;

	    Opportunity_Plan_Contact__c contact = new Opportunity_Plan_Contact__c();
      contact.Opportunity_Plan__c = oPlan.Id;
      contact.Business_Goal_1__c = 'test';
      contact.Confidence_BG_1__c = '1';
      insert contact;

	    Opportunity_Plan_Contact__c contact2 = new Opportunity_Plan_Contact__c();
	    contact2.Opportunity_Plan__c = oPlan.Id;
	    contact2.Business_Goal_1__c = 'test';
	    contact2.Confidence_BG_1__c = '1';
	    contact2.Reports_to__c = contact.Id;
	    insert contact2;

	    Opp_Plan_Score_Sub_Calc__c obj2 = new Opp_Plan_Score_Sub_Calc__c();
	    obj2.Name = 'Client_Goal_1__c';
	    obj2.Calculation_Field__c = 'Exp_Adv_1__c';
	    obj2.Controlling_Field__c = 'Comp_Adv_1__c';
	    obj2.Object_API_Name__c = 'Opportunity_Plan_Competitor__c';
	    //obj2.Opp_Plan_Score_Calc__c = mapScore.get('Competition Scoring').Id;
	    obj2.Opp_Plan_Score_Calc__c = oppPlanCalc_CompetitionScoring.Id;
	    obj2.Score__c = 1;
	    insert obj2;

	    Opp_Plan_Score_Sub_Calc__c obj3 = new Opp_Plan_Score_Sub_Calc__c();
      obj3.Name = 'Business_Goal_1__c';
      obj3.Calculation_Field__c = 'Business_Goal_1__c';
      obj3.Controlling_Field__c = 'Business_Goal_1__c';
      obj3.Object_API_Name__c = 'Opportunity_Plan_Contact__c';
      //obj3.Opp_Plan_Score_Calc__c = mapScore.get('Buying Centre').Id;
      obj3.Opp_Plan_Score_Calc__c = oppPlanCalc_BuyingCentre.Id;
      obj3.Score__c = 1;
      insert obj3;

      Opp_Plan_Score_Sub_Calc__c obj4 = new Opp_Plan_Score_Sub_Calc__c();
      obj4.Name = 'Contact__c';
      obj4.Calculation_Field__c = 'Contact__c';
      obj4.Controlling_Field__c = 'Contact__c';
      obj4.Object_API_Name__c = 'Opportunity_Plan_Contact__c';
      //obj4.Opp_Plan_Score_Calc__c = mapScore.get('Buying Centre').Id;
      obj4.Opp_Plan_Score_Calc__c = oppPlanCalc_BuyingCentre.Id;
      obj4.Score__c = 1;
      insert obj4;

      Opp_Plan_Score_Sub_Calc__c obj5 = new Opp_Plan_Score_Sub_Calc__c();
      obj5.Name = 'Reports_to__c';
      obj5.Calculation_Field__c = 'Reports_to__c';
      obj5.Controlling_Field__c = 'Reports_to__c';
      obj5.Object_API_Name__c = 'Opportunity_Plan_Contact__c';
      //obj5.Opp_Plan_Score_Calc__c = mapScore.get('Buying Centre').Id;
      obj5.Opp_Plan_Score_Calc__c = oppPlanCalc_BuyingCentre.Id;
      obj5.Score__c = 1;
      insert obj5;

	    //Check Information Scoring.
	    Map<String, Decimal> mapResult = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Information Scoring');
	    System.assertNOTEquals(mapResult.get('Score'), 0);
	    System.assertNOTEquals(mapResult.get('Percentage'), 0);

	    Map<String, Decimal> mapResult2 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Qualification Scoring');
	    Map<String, Decimal> mapResult3 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Buying Centre');
	    Map<String, Decimal> mapResult4 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Competition Scoring');
	    Map<String, Decimal> mapResult5 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Summary Position');
	    Map<String, Decimal> mapResult6 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Solution at a Glance');
	    Map<String, Decimal> mapResult7 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Joint Action Plan');
	    Map<String, Decimal> mapResult8 = OpportunityPlanScoreCalc.calculateScore(oPlan.Id, 'Value Proposition');


	  }
	  Test.stopTest();
	}
}