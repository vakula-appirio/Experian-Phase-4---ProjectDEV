/**=====================================================================
 * Appirio, Inc
 * Name: BatchAssignmentTeam_Test
 * Description:  T-355035 : Test class to test the functionality of BatchAssignmentTeam
 *               and ScheduleAssignmentTeam class
 * Created Date: Jan 29th, 2015
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified              Modified By                  Description of the update
 * 6th, Feb                   Noopur                       Added test methods testBatchAssignmentTeam_New() 
 =====================================================================*/
@isTest(seeAllData=false)
private class BatchAssignmentTeam_Test {
	private static List<User> lstUser; 
  private static Account testAcc,testAcc2,testAcc3,testAcc4,testAcc5;
  private static Assignment_Team__c assgnTeam, assgnTeam2,assgnTeam3, assgnTeam4,assgnTeam5;
  private static List<Assignment_Team_Member__c> lstAssgnTeamMem ;
  private static Assignment_Team_Member__c assgnTeamMem1,assgnTeamMem2,assgnTeamMem3,assgnTeamMem4,assgnTeamMem5,assgnTeamMem6,assgnTeamMem7,assgnTeamMem8;
  
  // Method to test the case when isActive is set to true and role is modified.
	public static testmethod void testBatchAssignmentTeam() {
		createTestData2();
		set<Id> assignmentTeamIDs = new set<Id>();
		set<Id> accountIds = new set<Id> ();
		for ( Account_Assignment_Team__c atm : [SELECT Id ,Account__c, Assignment_Team__c
							                              FROM Account_Assignment_Team__c
							                              WHERE Account__c = :testAcc.Id OR 
					                                  Account__c = :testAcc2.Id]) {
			assignmentTeamIDs.add(atm.Assignment_Team__c);
			accountIds.add(atm.Account__c);
		}
		
		set<Id> userIDsTODel = new set<Id>();
		list<Assignment_Team_Member__c> assgnmentTeams = new List<Assignment_Team_Member__c> ();
		List<Assignment_Team_Member__c> assgnMembers = [SELECT Id, Assignment_Team_Role__c,IsActive__c,
					                                                 User__c
					                                          FROM Assignment_Team_Member__c 
					                                          WHERE Id IN :assignmentTeamIDs];
		integer i = 0;
		for ( Assignment_Team_Member__c atm: assgnMembers) {
		  if( atm.User__c != lstUser.get(6).Id) {
		  	atm.User__c = lstUser.get(6).Id;
		  }
		  else if( atm.Assignment_Team_Role__c != Constants.TEAM_ROLE_SALES_REP ) {
		  	atm.Assignment_Team_Role__c = Constants.TEAM_ROLE_SALES_REP;
		  }
		  if( i == assgnMembers.size() - 1){
		  	atm.IsActive__c = false;
		  	userIDsTODel.add(atm.User__c);
		  }
		  i++;
			assgnmentTeams.add(atm);
		}
		
		test.startTest();
		
		update assgnmentTeams;
		
		Database.executeBatch(new BatchAssignmentTeam());
		test.stopTest();
		
		map<Id,set<Id>> mapAccTeamMem = new map<Id,set<Id>>();
		
		for ( AccountTeamMember atm : [SELECT Id, UserId, AccountId, TeamMemberRole  
		                               FROM AccountTeamMember 
		                               WHERE AccountId IN : accountIds]) {
		  if ( mapAccTeamMem.containsKey(atm.AccountId) ) {
		  	mapAccTeamMem.get(atm.AccountId).add(atm.userId);
		  }
			mapAccTeamMem.put( atm.AccountId, new set<Id>{atm.userId} );
		}
		for ( Id delIds : userIDsTODel) {
			System.assert(!mapAccTeamMem.get(testAcc2.Id).contains(delIds));
		}
		
	}
	
	// Method to test the case when isActive is set to true and role is modified.
	public static testmethod void testBatchAssignmentTeam2() {
    createTestData2();
    
    List<AccountTeamMember> atm = [select id,AccountId from AccountTeamMember where UserId = : lstAssgnTeamMem[0].User__c];
    Id accId = atm[0].AccountId;
    Delete atm;
    
    
    
    test.startTest();
    
    lstAssgnTeamMem[0].IsActive__c = true;
    lstAssgnTeamMem[0].IsActive_Starting_Value__c = false;
    lstAssgnTeamMem[0].IsActive_Updated__c = true;
    lstAssgnTeamMem[1].Assignment_Team_Role__c = Constants.TEAM_ROLE_SALES_REP;
    lstAssgnTeamMem[5].User__c = lstUser.get(3).Id;
    
    update lstAssgnTeamMem;
    
    Database.executeBatch(new BatchAssignmentTeam());
    test.stopTest();
    List<AccountTeamMember> atm1 = [select Id from AccountTeamMember 
                                   where AccountId = :accId 
                                   AND userId =:lstAssgnTeamMem[0].User__c];
    system.assert(atm1.size() > 0);
  }
	
	// Method to test the case When a single record has all the three fields modified
	public static testmethod void testBatchAssignmentTeam3() {
    createTestData2();
    lstAssgnTeamMem[0].IsActive__c = true;
    lstAssgnTeamMem[0].Assignment_Team_Role__c = Constants.TEAM_ROLE_SALES_REP;
    lstAssgnTeamMem[0].User__c = lstUser.get(3).Id;
    lstAssgnTeamMem[4].IsActive__c = false;
    lstAssgnTeamMem[4].Assignment_Team_Role__c = Constants.TEAM_ROLE_LEAD_QUALIFIER;
    lstAssgnTeamMem[4].User__c = lstUser.get(7).Id;
    update lstAssgnTeamMem;
    
    test.startTest();
    
   // update assgnmentTeams;
    
    Database.executeBatch(new BatchAssignmentTeam());
    test.stopTest();
    
    for ( Account_Assignment_Team__c aat : [SELECT Id,Account__c,Assignment_Team__c
                                            FROM Account_Assignment_Team__c
                                            WHERE Assignment_Team__c = :lstAssgnTeamMem[0].Assignment_Team__c
                                            OR Assignment_Team__c = :lstAssgnTeamMem[4].Assignment_Team__c]) {
    	
    }
    
    // Verify the results
    List<AccountTeamMember> atm = [select Id,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id AND UserId = :lstUser.get(3).Id];
    system.assert( atm.size() > 0 );
    system.assertEquals(atm[0].TeamMemberRole,Constants.TEAM_ROLE_SALES_REP);
    
	}
	
	
	public static testmethod void testBatchAssignmentTeam_New() {
		
		//create data
		createTestData2();
		
		//run the test
		test.startTest();
		List<Assignment_Team_Member__c> lstATMUpdate = new List<Assignment_Team_Member__c>();
		assgnTeamMem1.User__c = lstUser.get(7).Id;
		assgnTeamMem1.Assignment_Team_Role__c = Constants.TEAM_ROLE_LEAD_QUALIFIER;
		lstATMUpdate.add(assgnTeamMem1);
    assgnTeamMem5.Assignment_Team_Role__c = Constants.TEAM_ROLE_LEAD_QUALIFIER;
    lstATMUpdate.add(assgnTeamMem5);
    assgnTeamMem3.IsActive__c = false;
    lstATMUpdate.add(assgnTeamMem3);
    assgnTeamMem4.IsActive__c = false;
    lstATMUpdate.add(assgnTeamMem4);
    update lstATMUpdate;
    Database.executeBatch(new BatchAssignmentTeam());
		test.StopTest();
		
		//verify the result
		map<Id,List<AccountTeamMember>> accTeamMap = new map<Id,List<AccountTeamMember>>();
		for( AccountTeamMember atm : [SELECT Id,UserId,AccountId,TeamMemberRole
		                              FROM AccountTeamMember 
		                              WHERE AccountId = :testAcc.Id 
		                              OR AccountId = :testAcc2.Id]) {
			if( accTeamMap.containsKey(atm.AccountId) ) {
				accTeamMap.get(atm.AccountId).add(atm);
			}
			else {
				accTeamMap.put(atm.AccountId,new List<AccountTeamMember> {atm});
			}
		}
		
		
		// variable to verify that user is not deleted if it is related to Account
		// by some other Assignment team.
		boolean foundMemberInactiveOnlyInOneTeam = false;
		
		for ( AccountTeamMember atm : accTeamMap.get(testAcc2.Id) ) {
			if( atm.UserId == lstUser.get(5).Id ) {
				System.assert(atm.TeamMemberRole == Constants.TEAM_ROLE_LEAD_QUALIFIER);
			}
			else if ( atm.UserId == lstUser.get(4).Id ) {
				foundMemberInactiveOnlyInOneTeam = true;
			}
		}
		
		System.assert(foundMemberInactiveOnlyInOneTeam == true);
		
		boolean foundInactiveMember = false;
		boolean foundDeletedMember = false;
		boolean foundNewMember = false;
		for ( AccountTeamMember atm : accTeamMap.get(testAcc.Id) ) {
			if( atm.UserId == lstUser.get(3).Id ) {
				foundInactiveMember = true;
			}
			else if ( atm.UserId == lstUser.get(1).Id ) {
				foundDeletedMember = true;
			}
			else if( atm.UserId == lstUser.get(7).Id ) {
				foundNewMember = true;
			}
		}
		system.assert( foundInactiveMember == true );
		system.assert( foundDeletedMember == false );
		system.assert( foundNewMember == true );
	}
  
  //==========================================================
  // Creates test data: Assignment_Team__c & members
  //==========================================================
  
  public static void createTestData2 (){
  	// create users 
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN];
    lstUser = Test_Utils.createUsers(p, 'test1234@gmail.com', 'T-AE', 8);
    insert lstUser; 
    
    testAcc = Test_Utils.createAccount();
    testAcc2 = Test_Utils.createAccount();
    List<Account> accountList = new List<Account>();
    accountList.add(testAcc);
    accountList.add(testAcc2);
    insert accountList;
    
    Global_Settings__c settings = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
    if( settings != null ) {
      settings.Assignment_Team_Member_Job_Last_Run__c = system.now().addSeconds(-20);
      update settings;
    }
    else {
      settings = new Global_Settings__c(name=Constants.GLOBAL_SETTING,Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER);
      settings.Assignment_Team_Member_Job_Last_Run__c = system.now().addSeconds(-20);
      insert settings;
    }
    
    assgnTeam = Test_Utils.insertAssignmentTeam(false, lstUser.get(0).Id);
    assgnTeam2 = Test_Utils.insertAssignmentTeam(false, null);
    assgnTeam3 = Test_Utils.insertAssignmentTeam(false, null);
    
    List<Assignment_Team__c> assignmentTeams = new List<Assignment_Team__c>();
    assignmentTeams.add(assgnTeam);
    assignmentTeams.add(assgnTeam2);
    assignmentTeams.add(assgnTeam3);
    
    insert assignmentTeams;
    
    // create assignment team members
    lstAssgnTeamMem = new List<Assignment_Team_Member__c>();
    
    assgnTeamMem1 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(1).Id, Constants.TEAM_ROLE_CHANNEL_MANAGER);   
    lstAssgnTeamMem.add(assgnTeamMem1);

    assgnTeamMem2 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(2).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem2);

    assgnTeamMem3 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam.Id, lstUser.get(3).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem3);

    assgnTeamMem4 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(4).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem4);
    
    assgnTeamMem5 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(5).Id, Constants.TEAM_ROLE_SALES_REP);
    lstAssgnTeamMem.add(assgnTeamMem5);

    assgnTeamMem6 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam2.Id, lstUser.get(6).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem6);
    
    assgnTeamMem7 = Test_Utils.insertAssignmentTeamMember(false, assgnTeam3.Id, lstUser.get(4).Id, Constants.TEAM_ROLE_LEAD_QUALIFIER);
    lstAssgnTeamMem.add(assgnTeamMem7);
    
    insert lstAssgnTeamMem;
    
    List<Account_Assignment_Team__c> accountAssignTeamList= new List<Account_Assignment_Team__c>();
    Account_Assignment_Team__c accAssgnTeam1 = Test_utils.insertAccAssignmentTeam(false, assgnTeam.Id, testAcc.Id);
    Account_Assignment_Team__c accAssgnTeam2 = Test_utils.insertAccAssignmentTeam(false, assgnTeam2.Id, testAcc2.Id);
    Account_Assignment_Team__c accAssgnTeam3 = Test_utils.insertAccAssignmentTeam(false, assgnTeam3.Id, testAcc2.Id);
    
    accountAssignTeamList.add(accAssgnTeam1);
    accountAssignTeamList.add(accAssgnTeam2);
    accountAssignTeamList.add(accAssgnTeam3);
    
    insert accountAssignTeamList ;
  }
  
}