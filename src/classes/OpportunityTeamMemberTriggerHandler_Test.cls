/**=====================================================================
 * Appirio, Inc
 * Test Class Name: OpportunityTeamMemberTriggerHandler_Test
 * Class Name: OpportunityTeamMemberTriggerHandler  
 * Description: Test funcitonality of OpportunityTeamMemberTriggerHandler_Test
 * Created Date: Apr 22nd, 2014.
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * 30th Apr 2014                Rahul Jain                   Added testAddTeamMembersToOpportunityPlans, testDeleteTeamMembersFromOpportunityPlans test method for (T-273696)
 * Oct 21st, 2014               Arpita Bose (Appirio)        Updated testDeleteTeamMembersFromOpportunityPlans() and testAddTeamMembersToOpportunityPlans() to remove IsDataAdmin__c
 =====================================================================*/
@isTest
private class OpportunityTeamMemberTriggerHandler_Test {

  static testMethod void myUnitTest() {
    // create User
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
    insert testUser1;
    User testUser2 = Test_Utils.createUser(p, 'test2345@gmail.com', 'test2');
    insert testUser2;

    // create Account
    Account testAcc = Test_Utils.insertAccount();
    // create Opportunity
    Opportunity testOpp = Test_Utils.createOpportunity(testAcc.Id);
    insert testOpp;

    Confidential_Information__c conInfo = new Confidential_Information__c ();
    conInfo.Opportunity__c = testOpp.Id;
    conInfo.Synch_Opportunity_Team_Members__c = true;
    insert conInfo;

    // create Opp Team Member
    OpportunityTeamMember member1 = new OpportunityTeamMember ();
    member1.OpportunityId = testOpp.Id;
    member1.UserId = testUser1.Id;
    member1.TeamMemberRole ='Account Manager';

    OpportunityTeamMember member2 = new OpportunityTeamMember ();
    member2.OpportunityId = testOpp.Id;
    member2.UserId = testUser2.Id;
    member2.TeamMemberRole ='Sales Rep';

    List<OpportunityTeamMember> lstMember = new List<OpportunityTeamMember>();
    lstMember.add(member1);
    lstMember.add(member2);
    insert lstMember;
    
    //Assert to check confidential_information_share record has been created.
    System.assertEquals([SELECT ID 
                   FROM Confidential_Information__Share 
                   WHERE ParentId =: conInfo.ID 
                        AND (UserOrGroupId =: testUser1.ID 
                          OR UserOrGroupId =: testUser2.ID)].size(), 2);   
    
    update member2;
    delete member2;
    
    System.assertEquals([SELECT ID 
                   FROM Confidential_Information__Share 
                   WHERE ParentId =: conInfo.ID 
                        AND UserOrGroupId =: testUser2.ID].size(), 0);   

  }
  
  static testMethod void testAddTeamMembersToOpportunityPlans() {
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
	    TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPTYTEAMMEMBER_TRIGGER);
	    insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPORTUNITY_PLAN_TRIGGER);
	    //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
	    
	    Account account = Test_Utils.insertAccount();
	    Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
	    insert opportunity;
	    
	    //insert opp plan
	    Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      insert oPlan;
      
      
      List<Opportunity_Plan__Share> oppPlanShareList =  [Select UserOrGroupId, ParentId 
                                           From Opportunity_Plan__Share 
                                           WHERE ParentId =: oPlan.id
                                           AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      
      System.assertEquals(oppPlanShareList.size(), 0, 'validate that no manual sharing records are created as there are not team member');
	    
	    
	    OpportunityTeamMember oTM1 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser2.id, 'Sales Rep');
	    insert oTM1;
	    
	    OpportunityTeamMember oTM2 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser3.id, 'Sales Manager');
	    insert oTM2;
	     
	    
	    oppPlanShareList =  [Select UserOrGroupId, ParentId 
	                                         From Opportunity_Plan__Share 
	                                         WHERE ParentId =: oPlan.id
	                                         AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
	    
	    System.assertEquals(oppPlanShareList.size(), 2, 'validate that 2 sharing records for two team members are created');
	    for(Opportunity_Plan__Share shareRecord : oppPlanShareList){
	      System.assertEquals(userIds.contains(shareRecord.UserOrGroupId), true, 'validate that both the users defined in the set are having sharing on this record');
	    }
	     
	  }
	  Test.stopTest();  
  }
  
  
  
  
  static testMethod void testDeleteTeamMembersFromOpportunityPlans() {
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
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPTYTEAMMEMBER_TRIGGER);
      insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.OPPORTUNITY_PLAN_TRIGGER);
      //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      
      Account account = Test_Utils.insertAccount();
      Opportunity opportunity = Test_Utils.createOpportunity(account.Id);        
      insert opportunity;
      
      //insert opp plan
      Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(false, opportunity.id);
      insert oPlan;
      
      
      List<Opportunity_Plan__Share> oppPlanShareList =  [Select UserOrGroupId, ParentId 
                                           From Opportunity_Plan__Share 
                                           WHERE ParentId =: oPlan.id
                                           AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      
      System.assertEquals(oppPlanShareList.size(), 0, 'validate that no manual sharing records are created as there are not team member');
      
      
      OpportunityTeamMember oTM1 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser2.id, 'Sales Rep');
      insert oTM1;
      
      OpportunityTeamMember oTM2 = Test_Utils.insertOpportunityTeamMember(false, opportunity.id, testUser3.id, 'Sales Manager');
      insert oTM2;
       
      
      oppPlanShareList =  [Select UserOrGroupId, ParentId 
                                           From Opportunity_Plan__Share 
                                           WHERE ParentId =: oPlan.id
                                           AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      
      System.assertEquals(oppPlanShareList.size(), 2, 'validate that 2 sharing records for two team members are created');
      for(Opportunity_Plan__Share shareRecord : oppPlanShareList){
        System.assertEquals(userIds.contains(shareRecord.UserOrGroupId), true, 'validate that both the users defined in the set are having sharing on this record');
      }
       
      //lets delete these two opp team members from the opportunity
      delete oTM1; 
      oppPlanShareList =  [Select UserOrGroupId, ParentId 
                                           From Opportunity_Plan__Share 
                                           WHERE ParentId =: oPlan.id
                                           AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];      
      System.assertEquals(oppPlanShareList.size(), 1, 'validate that 1 sharing records for two team members exists'); 
      
      //lets delete left out opp team members from the opportunity
      delete oTM2; 
      oppPlanShareList =  [Select UserOrGroupId, ParentId 
                                           From Opportunity_Plan__Share 
                                           WHERE ParentId =: oPlan.id
                                           AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      
      System.assertEquals(oppPlanShareList.size(), 0, 'validate that no sharing records for two team members exists');
      
      
       
    }
    Test.stopTest();  
  }
}