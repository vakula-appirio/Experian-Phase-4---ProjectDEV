/**=====================================================================
 * Appirio, Inc
 * Name: SolutionAtAGlanceExtension_Test
 * Description: T-278513: To test Solutions at a glance page.
 * Created Date: May 15th, 2016
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified      Modified By               Description of the update
 * Feb 02nd, 2015     Naresh Kr Ojha            T-356445: Updated class to test saveAttachment method of main class.
 =====================================================================*/
public with sharing class SolutionAtAGlanceExtension_Test {
  
  //Positive test, data entering and testing.
  static testMethod void testSolutionAtAGlance1 () {
    
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;   
   
    System.runAs(testUser1) {
      // insert account
      Account account = Test_Utils.insertAccount();
      // insert opportunity
      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
      insert opportunity;

      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
      insert oPlan;
      
      PageReference pageRef = Page.SolutionAtAGlance;
      Test.setCurrentPage(pageRef);
      Apexpages.currentPage().getParameters().put('Id' , oPlan.ID);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(oPlan);
      
      SolutionAtAGlanceExtension scExt = new SolutionAtAGlanceExtension(controller);
      
      System.assert(scExt.oppPlan.ID <> null);
      System.assert(scExt.oppPlan.Objectives_and_Requirements__c == null);
      System.assert(scExt.oppPlan.Solution__c == null);
      System.assert(scExt.oppPlan.Benefits__c == null);
      System.assert(scExt.oppPlan.Strengths__c == null);
      
      scExt.oppPlan.Objectives_and_Requirements__c = 'Test data test data test data';
      scExt.oppPlan.Solution__c = 'Test data test data';
      scExt.oppPlan.Benefits__c = 'Test data test data';
      scExt.oppPlan.Strengths__c = 'Test data test data';
      scExt.save();
      
      scExt = new SolutionAtAGlanceExtension(controller);
      
      System.assert(scExt.oppPlan.Objectives_and_Requirements__c <> null);
      System.assert(scExt.oppPlan.Solution__c <> null);
      System.assert(scExt.oppPlan.Benefits__c <> null);
      System.assert(scExt.oppPlan.Strengths__c <> null);
      scExt.Cancel();      
    }
  }
  
  //No opportunity plan ID supplied should show error
  static testMethod void testSolutionAtAGlance2 () {
    
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;   
   
    System.runAs(testUser1) {
      // insert account
      Account account = Test_Utils.insertAccount();
      // insert opportunity
      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
      insert opportunity;

      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      
      PageReference pageRef = Page.SolutionAtAGlance;
      Test.setCurrentPage(pageRef);

      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(oPlan);
      
      SolutionAtAGlanceExtension scExt = new SolutionAtAGlanceExtension(controller);
      
      System.assert(String.valueOf(Apexpages.getMessages()).contains(System.Label.SOLUTIONATGLANC_ERR_PLEASE_SELECT_PLAN));
    }
  }
  
  //Positive test, data entering and testing.
  static testMethod void testSolutionAtAGlance_PDF () {
    
    User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    insert testUser1;   
   
    System.runAs(testUser1) {
      // insert account
      Account account = Test_Utils.insertAccount();
      // insert opportunity
      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
      insert opportunity;

      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
      insert oPlan;
      
      PageReference pageRef = Page.SolutionAtAGlance;
      Test.setCurrentPage(pageRef);
      Apexpages.currentPage().getParameters().put('Id' , oPlan.ID);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(oPlan);
      
      SolutionAtAGlanceExtension scExt = new SolutionAtAGlanceExtension(controller);
      
      scExt.oppPlan.Objectives_and_Requirements__c = 'Test data test data test data';
      scExt.oppPlan.Solution__c = 'Test data test data';
      scExt.oppPlan.Benefits__c = 'Test data test data';
      scExt.oppPlan.Strengths__c = 'Test data test data';
      scExt.save();
 
      System.assert(scExt.generatePDF() <> null);
    }
  }

  //Test Save attachment method.
  static testMethod void testSaveAttachment () {
    // insert account
      Account account = Test_Utils.insertAccount();
      // insert opportunity
      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
      insert opportunity;

      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      oPlan.Opportunity_Client_Budget__c = '1,001 - 10,000';
      insert oPlan;
      
      Confidential_Information__c confInfo = new Confidential_Information__c();
      confInfo.Opportunity__c = opportunity.ID;
      confInfo.Name = 'Test Conf info001';
      insert confInfo;
      
      PageReference pageRef = Page.SolutionAtAGlance;
      Test.setCurrentPage(pageRef);
      Apexpages.currentPage().getParameters().put('Id' , oPlan.ID);
      Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(oPlan);
      
      SolutionAtAGlanceExtension scExt = new SolutionAtAGlanceExtension(controller);
      Test.startTest();
      //Calling saveAttachement
      scExt.saveAttachment();
      Test.stopTest();
      
      //Assert to cehck that Attachment has been created by saveAttachement method.
      System.assertEquals(confInfo.ID, [SELECT ParentId FROM Attachment].ParentId);
  }
}