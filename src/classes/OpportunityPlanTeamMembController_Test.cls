/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanTeamMembController_Test
 * Description: Test Class for Controller class for OpportunityPlanTeamMembersController.cls (for T-273984)
 * Created Date: April 28th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 * Oct 21st, 2014     Arpita Bose(Appirio)       Updated to remove IsDataAdmin__c
 =====================================================================*/
@isTest
private class OpportunityPlanTeamMembController_Test {

    static testMethod void testOpportunityTeamMembersPage() {
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
        
        Account account = Test_Utils.insertAccount();
        Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
        insert opportunity;
        
        OpportunityTeamMember oTM1 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser2.id, 'Sales Rep');
        insert oTM1;
        
        OpportunityTeamMember oTM2 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser3.id, 'Sales Manager');
        insert oTM2;
        
        Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
        insert oPlan;
        Integer totalOTMs = 3; // owner, otm1 and otm2
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(oPlan);
        OpportunityPlanTeamMembersController oppPlanTeamMembCont = new OpportunityPlanTeamMembersController(stdController);
        oppPlanTeamMembCont.doPageAction();
        List<OpportunityTeamMember> oppTeamMembersList = oppPlanTeamMembCont.oppTeamMembers; 
        System.assertEquals(oppTeamMembersList.size(), 3, 'list should contain 3 records in otm list such as owner, otm1 and otm2');        
        System.assertNotEquals(oppPlanTeamMembCont.addButtonURL.indexOf(opportunity.id), -1, 'validate that add button url has oppid defined');
        System.assertNotEquals(oppPlanTeamMembCont.addButtonURL.indexOf(oPlan.id), -1, 'validate that add button url has opp_plan_id defined');         
      }
      Test.stopTest();    
    }
}