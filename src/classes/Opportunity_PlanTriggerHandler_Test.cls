/**=====================================================================
 * Appirio, Inc
 * Name: Opportunity_PlanTriggerHandler_Test
 * Description: Test class for Opportunity_PlanTriggerHandler.cls (for T-273695)
 * Created Date: April 30th, 2014
 * Created By: Rahul Jain (Appirio)
 *
 * Date Modified          Modified By                    Description of the update
 * April 30th, 2014       Sonal Shrivastava (Appirio)    T-273788: Added test case for related Opportunity record update
 * Jun 13th, 2014         Arpita Bose (Appirio)          T-278485: Added testmethod testCreateOppPlanContactAndCompetitor1() and
 *                                                       testCreateOppPlanContactAndCompetitor2() to test the logic of T-278460
 * Oct 21st, 2014         Arpita Bose                    Updated method testOppPlanSharesCreated() to remove IsDataAdmin__c
  =====================================================================*/
@isTest
private class Opportunity_PlanTriggerHandler_Test {

    static testMethod void testOppPlanSharesCreated() {
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
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPORTUNITY_PLAN_TRIGGER);
        //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        // insert account
        Account account = Test_Utils.insertAccount();
        // insert opportunity
        Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
        insert opportunity;
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
        // insert first opportunity team member
        OpportunityTeamMember oTM1 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser2.id, 'Sales Rep');
        oppTeamMembers.add(oTM1);
        // insert second opportunity team member
        OpportunityTeamMember oTM2 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser3.id, 'Sales Manager');
        oppTeamMembers.add(oTM2);

        insert oppTeamMembers;

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
        Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
        oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
        insert oPlan;
        // retrieve list of opp plan share records
        List<Opportunity_Plan__Share> oppPlanShareList =  [Select UserOrGroupId, ParentId
                                             From Opportunity_Plan__Share
                                             WHERE ParentId =: oPlan.id
                                             AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];

        System.assertEquals(oppPlanShareList.size(), oppTeamMembers.size(), 'validate that 2 sharing records for two team members are created');
        for(Opportunity_Plan__Share shareRecord : oppPlanShareList){
        	System.assertEquals(userIds.contains(shareRecord.UserOrGroupId), true, 'validate that both the users defined in the set are having sharing on this record');
        }

			  //Update Opportunity plan
			  oPlan.OwnerId = testUser3.Id;
			  update oPlan;

			  //Check the related opportunity field has been updated
        for(Opportunity updatedOpportunity : [SELECT Id, Budget__c, OwnerId
                                              FROM Opportunity
                                              WHERE Id = :opportunity.Id ]){
          System.assertEquals(oPlan.Opportunity_Client_Budget__c, updatedOpportunity.Budget__c);
          //System.assertEquals(oPlan.OwnerId, updatedOpportunity.OwnerId);
        }

      }
      Test.stopTest();
    }
    //===========================================================================================
    //T-278485: Scenario1- create Opp Plan Contact and Opp Plan Competitor records for related Opp
    //when Oppty contact role and Competitor are attached with related oppty
    //============================================================================================
    public static testmethod void testCreateOppPlanContactAndCompetitor1(){
    	//create Test Data
    	Account testAcc = Test_Utils.insertAccount();
    	Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    	insert testOpp;
    	Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                         AccountId = testAcc.Id, Email = 'larrye@email.com');
        insert newcontact;

        OpportunityContactRole oppContactRole1 = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = testOpp.Id, IsPrimary = true, Role = 'Decider');
        insert oppContactRole1 ;

        OpportunityContactRole oppContactRole2 = new OpportunityContactRole(ContactId = newcontact.Id, OpportunityId = testOpp.Id, IsPrimary = true, Role = 'Coach');
        insert oppContactRole2 ;

        Competitor__c comp = new Competitor__c(Opportunity__c = testOpp.Id);
        insert comp;

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
       
       //start test
       Test.startTest();
      //create Opp Plan record for the related Oppty
      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, testOpp.id);
      oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
      oPlan.Opportunity_Expected_Close_Date__c = System.today().addDays(1);
      insert oPlan;
      //stop test
      Test.stopTest();

      List<Opportunity_Plan_Contact__c>  opp_Con = [SELECT Id, Name FROM Opportunity_Plan_Contact__c
                                                    WHERE Opportunity_Plan__c =: oPlan.Id];
      List<Opportunity_Plan_Competitor__c> opp_Comp = [SELECT Id, Name FROM Opportunity_Plan_Competitor__c
                                                       WHERE Opportunity_Plan__c =: oPlan.Id];
      //Asserts to check that Opp Plan Contact and Opp Plan Competitor records are created for related Opp Plan
      system.assertEquals(opp_Con.size(), 2);
      system.debug(opp_Con);
      system.assertEquals(opp_Comp.size(), 1);
      system.debug(opp_Comp);
    }
    //===========================================================================================
    //T-278485: Scenario2- there will be no Opp Plan Contact and Opp Plan Competitor records for related Opp
    //when Oppty contact role and Competitor are not attached with related oppty
    //============================================================================================
    public static testmethod void testCreateOppPlanContactAndCompetitor2(){
      //create Test Data
      Account testAcc = Test_Utils.insertAccount();
      Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
      insert testOpp;
      Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                         AccountId = testAcc.Id, Email = 'larrye@email.com');
      insert newcontact;

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
      //start test
      Test.startTest();
      //create Opp Plan record for the related Oppty
      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, testOpp.id);
      oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
      oPlan.Opportunity_Expected_Close_Date__c = System.today().addDays(1);
      insert oPlan;
      //stop test
      Test.stopTest();

      List<Opportunity_Plan_Contact__c>  opp_Con = [SELECT Id, Name FROM Opportunity_Plan_Contact__c
                                                    WHERE Opportunity_Plan__c =: oPlan.Id];
      List<Opportunity_Plan_Competitor__c> opp_Comp = [SELECT Id, Name FROM Opportunity_Plan_Competitor__c
                                                       WHERE Opportunity_Plan__c =: oPlan.Id];
      //Asserts to check that there are no Opp Plan Contact and Opp Plan Competitor records created for Opp Plan
      system.assertEquals(opp_Con.size(), 0);
      system.assertEquals(opp_Comp.size(), 0);
    }
}