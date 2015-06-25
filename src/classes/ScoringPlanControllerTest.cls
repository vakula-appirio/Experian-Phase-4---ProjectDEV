/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */

  /* 
  * Date Modified      Modified By                  Description of the update
  * Feb 12th, 2015     Paul Kissick                 Case #383855 - Replaced Strings with Constants for stages, also added attachments to test scoring plan retrieval.
  * Feb 12th, 2015     Paul Kissick                 Added Bad test for invalid url ID.
  * Mar 27th, 2015	   Suminder Singh(Appirio)      Task- T-369703
  */
@isTest
private class ScoringPlanControllerTest {
  /*
  This test method is responsible to test the Scoring plan functionality and all other aspects of the percentage analysis.
  */
  static testMethod void ScoringPlanPositiveTest() {
    // create User
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN );
    insert testUser1;   
      
    System.runAs(testUser1){

      
        // insert account
        Account account = Test_Utils.insertAccount();
    	Address__c addrs1 = Test_Utils.insertAddress(true);      
    	Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, account.Id);
    	      
        // insert opportunity
        Opportunity opportunity = Test_Utils.createOpportunity(account.Id);
        opportunity.Has_Senior_Approval__c = true;
        opportunity.StageName = Constants.OPPTY_STAGE_3;
        opportunity.Starting_Stage__c = Constants.OPPTY_STAGE_7 ;
        opportunity.Amount = 100;
        opportunity.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
        insert opportunity;
        
        Test_Utils.createOpptyTasks(opportunity.Id, true);
        Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                            AccountId = account.Id, Email = 'larrye@email.com');
        
        insert newcontact;
        Contact_Address__c conAdd = Test_Utils.insertContactAddress(true, addrs1.id, newcontact.id);
        
        OpportunityContactRole oppContactRole1 = new OpportunityContactRole(ContactId = newcontact.Id, 
                                                 OpportunityId = opportunity.Id, IsPrimary = true, 
                                                 Role = Constants.DECIDER);
        insert oppContactRole1;
        
       
                                        
        
        Opportunity_Plan__c oPlan = test_utils.insertOpportunityPlan(false , opportunity.id);
        insert oPlan; 
    
    Attachment scoringPlan1Att = new Attachment(ParentId = oPlan.Id, Name = 'ScoringPlan1', Body = Blob.valueOf('SomeData'));
        Attachment scoringPlan2Att = new Attachment(ParentId = oPlan.Id, Name = 'ScoringPlan2', Body = Blob.valueOf('SomeData')); 
        insert new List<Attachment>{scoringPlan1Att, scoringPlan2Att};
       
          
        List<Opp_Plan_Score_Calc__c> lstScore = new List<Opp_Plan_Score_Calc__c>();
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Information Scoring'));
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Competition Scoring'));
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Summary Position'));
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Solution at a Glance'));
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Joint Action Plan'));
        lstScore.add(new Opp_Plan_Score_Calc__c(Expected_Score__c = 20, Name = 'Value Proposition'));
        insert lstScore;
                
        map<String, Opp_Plan_Score_Calc__c> mapScore = new Map<String, Opp_Plan_Score_Calc__c>();
        for(Opp_Plan_Score_Calc__c objScore :lstScore){
          mapScore.put(objScore.Name, objScore);
        }
        
        
        
        Opp_Plan_Score_Sub_Calc__c obj = new Opp_Plan_Score_Sub_Calc__c();
        obj.Name = 'Client_Goal_1__c';
        obj.Calculation_Field__c = 'Client_Goal_1__c';
        obj.Controlling_Field__c = '';
        obj.Object_API_Name__c = 'Opportunity_Plan__c';
        obj.Opp_Plan_Score_Calc__c = mapScore.get('Information Scoring').Id;
        obj.Score__c = 1;
        insert obj;
                
        Opportunity_Plan_Competitor__c competitor = new Opportunity_Plan_Competitor__c();
        competitor.Opportunity_Plan__c = oPlan.Id;
        competitor.Exp_Adv_1__c = 'test';
        competitor.Comp_Adv_1__c = 'test';
        insert competitor;
        
        Opp_Plan_Score_Sub_Calc__c obj2 = new Opp_Plan_Score_Sub_Calc__c();
        obj2.Name = 'Client_Goal_1__c';
        obj2.Calculation_Field__c = 'Exp_Adv_1__c';
        obj2.Controlling_Field__c = 'Comp_Adv_1__c';
        obj2.Object_API_Name__c = 'Opportunity_Plan_Competitor__c';
        obj2.Opp_Plan_Score_Calc__c = mapScore.get('Competition Scoring').Id;
        obj2.Score__c = 1;
        insert obj2;
        
        Test.startTest();
        
        Pagereference pageRef = Page.ScoringPlan;
        pageRef.getParameters().put('planId', oPlan.id);
         pageRef.getParameters().put('Id', oPlan.id);
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(oPlan);

        ScoringPlanController ctrl = new ScoringPlanController(stdController);
        
        ScoringPlanController ctrl1 = new ScoringPlanController();
        PageReference pg = ctrl.cancelAction(); 
        system.assertNotEquals(pg,null);
        system.assertNotEquals(ctrl.informationScoringScore, null);
        //system.assertNotEquals(ctrl.qualificationScoringScore, null);
        //system.assertNotEquals(ctrl.buyingCentreScore, null);
        system.assertNotEquals(ctrl.competitionScoringScore, null);
        system.assertNotEquals(ctrl.summaryPositionScore, null);
        system.assertNotEquals(ctrl.solutionAtGlanceScore, null);
        system.assertNotEquals(ctrl.jointActionPlanScore, null);
        system.assertNotEquals(ctrl.valuePropositionScore, null);
        //system.assertNotEquals(ctrl.actionPlanScore, null);
        
        opportunity.stageName = Constants.OPPTY_STAGE_4;
        opportunity.Budget__c = '';
        update opportunity;
         
        ScoringPlanController ctrl12 = new ScoringPlanController(stdController);        
        ScoringPlanController ctrl11 = new ScoringPlanController();
        PageReference pg1 = ctrl.cancelAction(); 
        system.assert(ctrl12.radarChartImageFirstId != null,'Chart image not found');
        system.assert(ctrl12.radarChartImageSecondId != null,'Chart image not found');

        

        opportunity.stageName = Constants.OPPTY_STAGE_5;
        opportunity.Budget__c = '';
        update opportunity;
        ScoringPlanController ctrl13 = new ScoringPlanController(stdController);        
        ScoringPlanController ctrl133 = new ScoringPlanController();
        PageReference pg2 = ctrl.cancelAction(); 
        
        opportunity.stageName = Constants.OPPTY_STAGE_6;
        opportunity.Budget__c = '';
        update opportunity;
        
        ScoringPlanController ctrl14 = new ScoringPlanController(stdController);
        ScoringPlanController ctrl144 = new ScoringPlanController();
        PageReference pg3 = ctrl.cancelAction(); 
        
        opportunity.stageName = Constants.OPPTY_STAGE_7;
        opportunity.Budget__c = '';
        update opportunity;
        
        ScoringPlanController ctrl15 = new ScoringPlanController(stdController);
        ScoringPlanController ctrl155 = new ScoringPlanController();
        PageReference pg4 = ctrl.cancelAction(); 
        
         
        Test.stopTest();
    }
  }
  
  static testMethod void ScoringPlanBadTest() {
    // create User
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN );
    insert testUser1;   
    
    System.runAs(testUser1){
      
        // insert account
        Account account = Test_Utils.insertAccount();
        
        Test.startTest();
        
        Pagereference pageRef = Page.ScoringPlan;
        pageRef.getParameters().put('planId', account.id);
        pageRef.getParameters().put('Id', account.id);
        Test.setCurrentPage(pageRef);
        try {
          ScoringPlanController ctrl1 = new ScoringPlanController();
        }
        Catch (Exception e) {
          system.assert(true);
        }
        Test.stopTest();
    }
  } 
}