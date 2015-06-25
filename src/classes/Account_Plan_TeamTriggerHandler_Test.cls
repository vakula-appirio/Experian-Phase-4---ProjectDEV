/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_TeamTriggerHandler_Test
 * Description: Test class for Account_Plan_TeamTriggerHandler_Test.cls(for T-275542)
 * Created Date: May 2nd, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 =====================================================================*/
@isTest
private class Account_Plan_TeamTriggerHandler_Test {

	
	static testMethod void testInsertAccountPlanTeam() {
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
	    TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_TEAM_TRIGGER);
	    IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
	    // insert account
	    Account account = Test_Utils.insertAccount();
	    
	    List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
	    List<Account_Plan_Team__c> accountPlanTeamList = new List<Account_Plan_Team__c>();
	    
	    // insert first account team member
	    AccountTeamMember aTM1 = Test_Utils.insertAccountTeamMember(false, account.id, testUser2.id, 'Sales Rep');
	    insert aTM1;
	    accTeamMembers.add(aTM1);	    	    
	    // create account plan
	    Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
	    insert accountPlan;	    
	    // create account plan team
	    Account_Plan_Team__c accountPlanTeam = Test_Utils.insertAccountPlanTeam(false, accountPlan.id, testUser2.id);
	    Account_Plan_Team__c accountPlanTeam1 = Test_Utils.insertAccountPlanTeam(false, accountPlan.id, testUser3.id);
	    accountPlanTeamList.add(accountPlanTeam);
	    accountPlanTeamList.add(accountPlanTeam1);	   
	    Database.SaveResult[] srList = Database.insert(accountPlanTeamList, false);
			// Iterate through each returned result
			for (Database.SaveResult sr : srList) {
			    if (!sr.isSuccess()) {			      
			       for(Database.Error err : sr.getErrors()) {
			       	System.assertEquals(err.getMessage().contains(Account_Plan_TeamTriggerHandler.USER_NOT_IN_RELATED_ACCOUNT_TEAM), true, 'one record should throw error');
			       }
			    }
			}	 
			List<Account_Plan_Team__c> accountPlanTeams = [select id from Account_Plan_Team__c where Account_Plan__c =: accountPlan.id];
			System.assertNotEquals(accountPlanTeams.size(), accountPlanTeamList.size(), 'Only one record should be inserted');
			   
	    List<Account_Plan__Share> accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), accTeamMembers.size(), 'only one share should be created');  
      System.assertEquals(accountPlanShares[accountPlanShares.size() - 1].UserOrGroupId, testUser2.id, 'share record for only account team member should be inserted');                                 
	    
	  }
    Test.stopTest();    
	}

	static testMethod void testUpdateAccountPlanTeam() {
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
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_TEAM_TRIGGER);
      IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      // insert account
      Account account = Test_Utils.insertAccount();
      
      List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
      List<Account_Plan_Team__c> accountPlanTeamList = new List<Account_Plan_Team__c>();
      
      // insert first account team member
      AccountTeamMember aTM1 = Test_Utils.insertAccountTeamMember(false, account.id, testUser2.id, 'Sales Rep');
      insert aTM1;
      accTeamMembers.add(aTM1);           
      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      insert accountPlan;     
      // create account plan team
      Account_Plan_Team__c accountPlanTeam = Test_Utils.insertAccountPlanTeam(false, accountPlan.id, testUser2.id);      
      accountPlanTeamList.add(accountPlanTeam);         
      insert accountPlanTeamList;
        
      List<Account_Plan_Team__c> accountPlanTeams = [select id, Account_Plan__c, User__c from Account_Plan_Team__c where Account_Plan__c =: accountPlan.id];
      System.assertEquals(accountPlanTeams.size(), accountPlanTeamList.size(), 'Only one record should be inserted');
         
      List<Account_Plan__Share> accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), accTeamMembers.size(), 'only one share should be created');  
      System.assertEquals(accountPlanShares[accountPlanShares.size() - 1].UserOrGroupId, testUser2.id, 'share record for only account team member should be inserted');                                 
      
      accountPlanTeamList.clear();
      
      accountPlanTeam = accountPlanTeams[0];
      // change the user look up field; since this user is still not the member in the account team; the update should 
      // fail and should not allow to create any sharing record for 
      accountPlanTeam.User__c = testUser3.id;       
      accountPlanTeamList.add(accountPlanTeam);     
      Database.SaveResult[] srList = Database.update(accountPlanTeamList, false);
      // Iterate through each returned result
      for (Database.SaveResult sr : srList) {
          if (!sr.isSuccess()) {            
             for(Database.Error err : sr.getErrors()) {
              System.assertEquals(err.getMessage().contains(Account_Plan_TeamTriggerHandler.USER_NOT_IN_RELATED_ACCOUNT_TEAM), true, 'one record should throw error');
             }
          }
      } 
      accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), accTeamMembers.size(), 'only one share should exists');  
      System.assertNotEquals(accountPlanShares[accountPlanShares.size() - 1].UserOrGroupId, testUser3.id, 'verify that sharing for testuser3 is not created'); 
      
      
      // insert testUser 3 to as account team member
      AccountTeamMember aTM2 = Test_Utils.insertAccountTeamMember(false, account.id, testUser3.id, 'Sales Manager');
      insert atM2;
      accTeamMembers.add(aTM2);     
      
      
      
      accountPlanTeamList.clear();
       // change the user look up field; since this user is member in the account team; the update should 
      // success and should create new sharing record remove the previous one
      accountPlanTeam.User__c = testUser3.id;       
      accountPlanTeamList.add(accountPlanTeam);     
      update accountPlanTeamList;
      
      
      accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), 1, 'only one share should exists');  
      System.assertEquals(accountPlanShares[accountPlanShares.size() - 1].UserOrGroupId, testUser3.id, 'verify that sharing for testuser3 is created and testUser2 is removed'); 
       
    }
    Test.stopTest(); 
	}
 	
	static testMethod void testDeleteAndUnDeleteAccountPlanTeam() {
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
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_PLAN_TEAM_TRIGGER);
      IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      // insert account
      Account account = Test_Utils.insertAccount();
      
      List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
      List<Account_Plan_Team__c> accountPlanTeamList = new List<Account_Plan_Team__c>();
      
      // insert first account team member
      AccountTeamMember aTM1 = Test_Utils.insertAccountTeamMember(false, account.id, testUser2.id, 'Sales Rep');
      insert aTM1;
      accTeamMembers.add(aTM1);           
      // create account plan
      Account_Plan__c accountPlan = Test_Utils.insertAccountPlan(false, account.id);
      insert accountPlan;     
      // create account plan team
      Account_Plan_Team__c accountPlanTeam = Test_Utils.insertAccountPlanTeam(false, accountPlan.id, testUser2.id);      
      accountPlanTeamList.add(accountPlanTeam);         
      insert accountPlanTeamList;
        
      List<Account_Plan_Team__c> accountPlanTeams = [select id, Account_Plan__c, User__c from Account_Plan_Team__c where Account_Plan__c =: accountPlan.id];
      System.assertEquals(accountPlanTeams.size(), accountPlanTeamList.size(), 'Only one record should be inserted');
         
      List<Account_Plan__Share> accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), accTeamMembers.size(), 'only one share should be created');  
      System.assertEquals(accountPlanShares[accountPlanShares.size() - 1].UserOrGroupId, testUser2.id, 'share record for only account team member should be inserted');                                 
      
      
      delete accountPlanTeamList;
      
      accountPlanTeams = [select id, Account_Plan__c, User__c from Account_Plan_Team__c where Account_Plan__c =: accountPlan.id];
      System.assertEquals(accountPlanTeams.size(), 0, 'no record should exists');
      
      accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), 0, 'no share should exists now');  
      
      
      undelete accountPlanTeamList;
      
      accountPlanTeams = [select id, Account_Plan__c, User__c from Account_Plan_Team__c where Account_Plan__c =: accountPlan.id];
      System.assertEquals(accountPlanTeams.size(), 1, 'one record should be undeleted');
      
      accountPlanShares =  [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share                                       
                                       WHERE ParentId = : accountPlan.id
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual];
      System.assertEquals(accountPlanShares.size(), 1, 'sharing of undeleted should be re-created');  
       
    }
    Test.stopTest();
	}
	
}