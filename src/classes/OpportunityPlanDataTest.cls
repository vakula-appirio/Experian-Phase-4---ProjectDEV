/*
    Author      : Topcoder Developer
    Description : Test class for OpportunityPlanData.cls
*/

@isTest
private class OpportunityPlanDataTest {

    // method to test the functionality
    static testMethod void Test_OpportunityPlanData() {

        // Creating Test data
        //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false); // abose - Oct 21, 2014 
      User sysAdmin = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert sysAdmin;

	
       System.runAs(sysAdmin) {  

        // NLG - June 25, 2014
        Global_Settings__c custSettings = new Global_Settings__c(name='Global',Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER);
        insert custSettings;



        Opportunity_Plan__c objOpportunityPlan = createOpportunityPlan();
        system.assertNotEquals(null, objOpportunityPlan.Id, 'Failed to insert Opportunity Plan record');
        Contact contact1 = createContact('FN1', 'LN1');
        Contact contact2 = createContact('FN2', 'LN2');
        Contact contact3 = createContact('FN3', 'LN3');
        createOpportunityPlanContact(contact1.Id, objOpportunityPlan.Id);
        createOpportunityPlanContact(contact2.Id, objOpportunityPlan.Id);
        createOpportunityPlanContact(contact3.Id, objOpportunityPlan.Id);

        Competitor__c competitor1 = createCompetitor('comp1');
        Competitor__c competitor2 = createCompetitor('comp2');
        Competitor__c competitor3 = createCompetitor('comp3');
        createOpportunityPlanCompetitor(competitor1.Id, objOpportunityPlan.Id);
        createOpportunityPlanCompetitor(competitor2.Id, objOpportunityPlan.Id);
        createOpportunityPlanCompetitor(competitor3.Id, objOpportunityPlan.Id);

        createTask(objOpportunityPlan.Id);

        // Start Testing
        Test.startTest();
        OpportunityPlanData opportunityPlanDataExt = new OpportunityPlanData(new ApexPages.StandardController(objOpportunityPlan));
        opportunityPlanDataExt.init();
        system.assertEquals(false, ApexPages.hasMessages(), 'Failed to initialize : '+ApexPages.getMessages());
        Test.stopTest();
       }
    }

    //Create Test Account record
  /*  static Account createAccount() {
        Account objAccount = new Account (Name = 'Test Account');
        insert objAccount;
        system.assertNotEquals(null, objAccount.Id, 'Failed to insert Account record');
        return objAccount;
    } */

    private static Opportunity objOpportunity; // NLG - June 25, 2014
    //Create Test Opportunity record
   /* static Opportunity createOpportunity(Id accountId) {
       objOpportunity = new Opportunity(
                                     Name = 'Test Opportunity',
                                     StageName = Constants.OPPTY_STAGE_3, // NLG June 25, 2014
                                     CloseDate = Date.today(),
                                     Amount = 10,
                                     AccountId = accountId);
        insert objOpportunity;
        system.debug('objOpportunity>>' +objOpportunity.Id);
        system.assertEquals(null, objOpportunity.Id, 'Failed to insert Opportunity record');
        return objOpportunity;

    } */

    //Create Test Opportunity Plan record
    static Opportunity_Plan__c createOpportunityPlan() {
        //Account objAccount = createAccount();
        Account objAccount = Test_Utils.insertAccount();
        //system.assertNotEquals(null, objAccount.Id, 'Failed to insert Account record');
        system.debug('acc>>' +objAccount);

        objOpportunity = Test_Utils.insertOpportunity(objAccount.Id);
        system.debug('objOpportunity>>' +objOpportunity.Id);
        //system.assertEquals(null, objOpportunity.Id, 'Failed to insert Opportunity record');
        //objOpportunity = createOpportunity(objAccount.Id);
        system.debug('opp>>' +objOpportunity.Id);

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

        /*Opp_Plan_Score_Calc__c oppPlnScore = new Opp_Plan_Score_Calc__c ();
        oppPlnScore.Name = 'Information Scoring';
        oppPlnScore.Expected_Score__c = 2;
        insert oppPlnScore;
        system.debug('oppPlnScore>>' +oppPlnScore);

        Opp_Plan_Score_Sub_Calc__c oppPlnScoreSub = new Opp_Plan_Score_Sub_Calc__c();
        oppPlnScoreSub.Name = 'Benefits';
        oppPlnScoreSub.Calculation_Field__c = 'Benefits__c';
        oppPlnScoreSub.Object_API_Name__c = 'Opportunity_Plan__c';
        insert oppPlnScoreSub;*/

        Opportunity_Plan__c objOpportunityPlan = new Opportunity_Plan__c(
            Name = 'Test Plan - 001',
            Account_Name__c = objAccount.Id,
            Opportunity_Name__c = objOpportunity.Id,
            Client_Goal_1__c = 'client goal 1',
            Client_Goal_2__c = 'client goal 2',
            Client_Goal_3__c = 'client goal 3',
            Client_Goal_4__c = 'client goal 4',
            Client_Goal_5__c = 'client goal 5',
            Exp_Risk_1__c = 'Exp risk 1',
            Exp_Risk_2__c = 'Exp risk 2',
            Exp_Risk_3__c = 'Exp risk 3',
            Exp_Risk_4__c = 'Exp risk 4',
            Exp_Risk_5__c = 'Exp risk 5',
            Exp_Strength_1__c = '',
            Exp_Strength_2__c = '',
            Exp_Strength_3__c = '',
            Exp_Strength_4__c = '',
            Exp_Strength_5__c = '',
            Sales_Objective_1__c = 'objective 1',
            Sales_Objective_2__c = 'objective 2',
            Sales_Objective_3__c = 'objective 3',
            Sales_Objective_4__c = 'objective 4',
            Sales_Objective_5__c = 'objective 5',
            CG_1_Importance__c = '1',
            CG_2_Importance__c = '2',
            CG_3_Importance__c = '3',
            CG_4_Importance__c = '4',
            CG_5_Importance__c = '5',
            Opportunity_Expected_Close_Date__c = Date.today(), // NLG June 25, 2014
            Risk_1_Rating__c = '1',
            Risk_2_Rating__c = '2',
            Risk_3_Rating__c = '3',
            Risk_4_Rating__c = '4',
            Risk_5_Rating__c = '5',
            SO_1_Importance__c = '1',
            SO_2_Importance__c = '2',
            SO_3_Importance__c = '3',
            SO_4_Importance__c = '4',
            SO_5_Importance__c = '5',
            Solution_Fulfils_Requirements__c = '',
            Opportunity_Client_Budget__c = '1,001 - 10,000'
        );
        insert objOpportunityPlan;
        system.assertNotEquals(null, objOpportunityPlan.Id, 'Failed to insert Opportunity Plan record');
        return objOpportunityPlan;
    }

    //Create Test Contact record
    static Contact createContact(String firstName, String lastName) {
        Contact objContact = new Contact(FirstName = firstName, LastName = lastName);
        insert objContact;
        system.assertNotEquals(null, objContact.Id, 'Failed to insert Contact record');
        return objContact;
    }

    //Create Test Opportunity Plan Contact record
    static Opportunity_Plan_Contact__c createOpportunityPlanContact(Id contactId, Id opportunityPlanId) {
        Opportunity_Plan_Contact__c objOpportunityPlanContact = new Opportunity_Plan_Contact__c(
            Contact__c = contactId,
            Opportunity_Plan__c = opportunityPlanId,
            Business_Goal_1__c = 'Based on our experience 1',
            Business_Goal_2__c = 'Based on our experience 2',
            Business_Goal_3__c = 'Based on our experience 3',
            Business_Goal_4__c = 'Based on our experience 4',
            Business_Goal_5__c = 'Based on our experience 5',
            Decision_Criteria_1__c = 'The solution you choose 1',
            Decision_Criteria_2__c = 'The solution you choose 2',
            Decision_Criteria_3__c = 'The solution you choose 3',
            Decision_Criteria_4__c = 'The solution you choose 4',
            Decision_Criteria_5__c = 'The solution you choose 5',
            Exp_Differentiator_1__c = 'From our conversations 1',
            Exp_Differentiator_2__c = 'From our conversations 2',
            Exp_Differentiator_3__c = 'From our conversations 3',
            Exp_Differentiator_4__c = 'From our conversations 4',
            Exp_Differentiator_5__c = 'From our conversations 5',
            Personal_Goal_1__c = '',
            Personal_Goal_2__c = '',
            Personal_Goal_3__c = '',
            Personal_Goal_4__c = '',
            Personal_Goal_5__c = '',
            Solution_Benefits_1__c = 'The solution we have designed 1',
            Solution_Benefits_2__c = 'The solution we have designed 2',
            Solution_Benefits_3__c = 'The solution we have designed 3',
            Solution_Benefits_4__c = 'The solution we have designed 4',
            Solution_Benefits_5__c = 'The solution we have designed 5',
            Confidence_BG_1__c = '1',
            Confidence_BG_2__c = '2',
            Confidence_BG_3__c = '3',
            Confidence_BG_4__c = '4',
            Confidence_BG_5__c = '5',
            Confidence_DC_1__c = '1',
            Confidence_DC_2__c = '2',
            Confidence_DC_3__c = '3',
            Confidence_DC_4__c = '4',
            Confidence_DC_5__c = '5',
            Confidence_PG_1__c = '1',
            Confidence_PG_2__c = '2',
            Confidence_PG_3__c = '3',
            Confidence_PG_4__c = '4',
            Confidence_PG_5__c = '5',
            Importance_BG_1__c = '1',
            Importance_BG_2__c = '2',
            Importance_BG_3__c = '3',
            Importance_BG_4__c = '4',
            Importance_BG_5__c = '5',
            Importance_DC_1__c = '1',
            Importance_DC_2__c = '2',
            Importance_DC_3__c = '3',
            Importance_DC_4__c = '4',
            Importance_DC_5__c = '5',
            Importance_ED_1__c = '1',
            Importance_ED_2__c = '2',
            Importance_ED_3__c = '3',
            Importance_ED_4__c = '4',
            Importance_ED_5__c = '5',
            Importance_PG_1__c = '1',
            Importance_PG_2__c = '2',
            Importance_PG_3__c = '3',
            Importance_PG_4__c = '4',
            Importance_PG_5__c = '5',
            Importance_SB_1__c = '1',
            Importance_SB_2__c = '2',
            Importance_SB_3__c = '3',
            Importance_SB_4__c = '4',
            Importance_SB_5__c = '5'
        );
        insert objOpportunityPlanContact;
        system.assertNotEquals(null, objOpportunityPlanContact.Id, 'Failed to insert Opportunity Plan Contact record');
        return objOpportunityPlanContact;
    }

    //Create Test Competitor record
    static Competitor__c createCompetitor(String competitorName) {
        Competitor__c objCompetitor = new Competitor__c(Opportunity__c=objOpportunity.Id); // NLG - added Opportunity__c
        insert objCompetitor;
        system.assertNotEquals(null, objCompetitor.Id, 'Failed to insert Competitor record');
        return objCompetitor;
    }

    //Create Test Opportunity Plan Competitor record
    static Opportunity_Plan_Competitor__c createOpportunityPlanCompetitor(Id competitorId, Id opportunityPlanId) {
        Opportunity_Plan_Competitor__c objOpportunityPlanCompetitor = new Opportunity_Plan_Competitor__c(
            Competitor__c = competitorId,
            Opportunity_Plan__c = opportunityPlanId,
            Comp_Adv_1__c = 'Much lower pricing 1',
            Comp_Adv_2__c = 'Much lower pricing 2',
            Comp_Adv_3__c = 'Much lower pricing 3',
            Comp_Adv_4__c = 'Much lower pricing 4',
            Comp_Adv_5__c = 'Much lower pricing 5',
            Comp_Strat_1__c = 'Emphasis on personal skills',
            Comp_Strat_2__c = 'not methodology Aggressive procing',
            Comp_Strat_3__c = '',
            Comp_Strat_4__c = '',
            Comp_Strat_5__c = '',
            Exp_Adv_1__c = 'Complete offering',
            Exp_Adv_2__c = 'Customer know-how',
            Exp_Adv_3__c = '',
            Exp_Adv_4__c = '',
            Exp_Adv_5__c = '',
            Exp_Strat_1__c = 'Illustrate high ROI of our comprehensive',
            Exp_Strat_2__c = 'solution combining skills, methodology and coaching',
            Exp_Strat_3__c = '',
            Exp_Strat_4__c = '',
            Exp_Strat_5__c = '',
            Importance_Comp_Adv_1__c = '1',
            Importance_Comp_Adv_2__c = '2',
            Importance_Comp_Adv_3__c = '3',
            Importance_Comp_Adv_4__c = '4',
            Importance_Comp_Adv_5__c = '5',
            Importance_Comp_Strat_1__c = '1',
            Importance_Comp_Strat_2__c = '2',
            Importance_Comp_Strat_3__c = '3',
            Importance_Comp_Strat_4__c = '4',
            Importance_Comp_Strat_5__c = '5',
            Importance_Exp_Adv_1__c = '1',
            Importance_Exp_Adv_2__c = '2',
            Importance_Exp_Adv_3__c = '3',
            Importance_Exp_Adv_4__c = '4',
            Importance_Exp_Adv_5__c = '5',
            Importance_Exp_Strat_1__c = '1',
            Importance_Exp_Strat_2__c = '2',
            Importance_Exp_Strat_3__c = '3',
            Importance_Exp_Strat_4__c = '4',
            Importance_Exp_Strat_5__c = '5'
        );
        insert objOpportunityPlanCompetitor;
        system.assertNotEquals(null, objOpportunityPlanCompetitor.Id, 'Failed to insert Opportunity Plan Competitor record');
        return objOpportunityPlanCompetitor;
    }

    //Create Test Task record
    static Task createTask(Id opportunityPlanId) {
        Task objTask = new Task(
                       WhatId = opportunityPlanId,
                       Subject = 'Call',
                       Status = 'Not Started',
                       ActivityDate = Date.today(),
                       Priority = 'Normal',
                       Result__c = 'This is test result');
        insert objTask;
        system.assertNotEquals(null, objTask.Id, 'Failed to insert Task record');
        return objTask;
    }
}