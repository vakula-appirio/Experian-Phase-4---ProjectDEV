/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountSegmentCreationViaATM_Test
 * Description: T-376237: Test class to verify the functionality of BatchAccountSegmentCreationViaATM
 *
 * Created Date: April 7th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 ======================================================================*/
@isTest(seeAllData = false)
private class BatchAccountSegmentCreationViaATM_Test {

    @isTest
    static void basicTest() {
      Test.startTest();
        Database.executeBatch( new BatchAccountSegmentCreationViaATM() );
      Test.stopTest();
      //Account acc = [select Id from Account where Name like 'Test Account%'];
      list<Account_Segment__c> accSegs = new list<Account_Segment__c>();
      for( Account_Segment__c accSeg : [select Id from Account_Segment__c ]){//Where Account__c =:acc.Id]) {
        accSegs.add(accSeg);
      }
      System.assertEquals(14, accSegs.size());
    }

    @testSetup
    private static void createTestData () {
      TestMethodUtilities.createTestGlobalSettings();
      Global_Settings__c lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
      lastRun.Batch_Failures_Email__c = '';
      Datetime testBeforeDateTime = lastRun.AccSegmentCreationViaATM_Job_Last_Run__c ;
      lastRun.AccSegmentCreationViaATM_Job_Last_Run__c = lastRun.AccSegmentCreationViaATM_Job_Last_Run__c.addMinutes(-60);
      update lastRun;

       Profile p = [SELECT Id FROM Profile WHERE Name = :Constants.PROFILE_SYS_ADMIN];

       List<User> usrList = new List<User>();
       User testUser1 = Test_Utils.createUser(p, 'test1@gmail.com', 'test1');
       testUser1.Business_Unit__c = 'testBU1';
       testUser1.Business_Line__c = 'testBL1';
       testUser1.Global_Business_Line__c = 'testGBL1';
       testUser1.Country__c = 'testCountry1';
       testUser1.Region__c = 'testRegion1';
       usrList.add( testUser1);
       User testUser2 = Test_Utils.createUser(p, 'test2@gmail.com', 'test2');
       testUser2.Business_Unit__c = 'testBU2';
       testUser2.Business_Line__c = 'testBL2';
       testUser2.Global_Business_Line__c = 'testGBL2';
       testUser2.Country__c = 'testCountry2';
       testUser2.Region__c = 'testRegion2';
       usrList.add( testUser2);
       User testUser3 = Test_Utils.createUser(p, 'test3@gmail.com', 'test3');
       testUser3.Business_Unit__c = 'testBU3';
       testUser3.Business_Line__c = 'testBL3';
       testUser3.Global_Business_Line__c = 'testGBL3';
       testUser3.Country__c = 'testCountry3';
       // Here we are reusing an existing segment on purpose, to make sure no dupe created
       testUser3.Region__c = 'testRegion2';
       usrList.add( testUser3);

       insert usrList;

       List<Hierarchy__c> hierarchyList = new List<Hierarchy__c>();
       for ( integer i=1; i<=3;i++) {
         Hierarchy__c hr1 = new Hierarchy__c();
         hr1.Type__c = 'Business Unit';
         hr1.Value__c = 'testBU'+i;
         hr1.Unique_Key__c = hr1.Type__c + '-'+ hr1.Value__c ;
         hierarchyList.add(hr1);
         Hierarchy__c hr2 = new Hierarchy__c();
         hr2.Type__c = 'Business Line';
         hr2.Value__c = 'testBL'+i;
         hr2.Unique_Key__c = hr2.Type__c + '-'+ hr2.Value__c ;
         hierarchyList.add(hr2);
         Hierarchy__c hr3 = new Hierarchy__c();
         hr3.Type__c = 'Global Business Line';
         hr3.Value__c = 'testGBL'+i;
         hr3.Unique_Key__c = hr3.Type__c + '-'+ hr3.Value__c ;
         hierarchyList.add(hr3);
         Hierarchy__c hr4 = new Hierarchy__c();
         hr4.Type__c = 'Country';
         hr4.Value__c = 'testCountry'+i;
         hr4.Unique_Key__c = hr4.Type__c + '-'+ hr4.Value__c ;
         hierarchyList.add(hr4);
         Hierarchy__c hr5 = new Hierarchy__c();
         hr5.Type__c = 'Region';
         hr5.Value__c = 'testRegion'+i;
         hr5.Unique_Key__c = hr5.Type__c + '-'+ hr5.Value__c ;
         hierarchyList.add(hr5);
       }

       insert hierarchyList;

       System.runAs(testUser1) {
         Account testAcc = Test_Utils.insertAccount();

         //Creating Account Team Members, which should be synched after execution of the batch
         AccountTeamMember mem1 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser1.Id, Constants.TEAM_ROLE_ACCOUNT_MANAGER );
         AccountTeamMember mem2 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser1.Id, Constants.TEAM_ROLE_CHANNEL_MANAGER );
         AccountTeamMember mem3 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser2.Id, Constants.TEAM_ROLE_LEAD_QUALIFIER );
         AccountTeamMember mem4 = Test_Utils.insertAccountTeamMember(false, testAcc.Id, testUser3.Id, Constants.TEAM_ROLE_SALES_REP );

         List <AccountTeamMember> testMembers = new List<AccountTeamMember>();
         testMembers.add(mem1);
         testMembers.add(mem2);
         testMembers.add(mem3);
         testMembers.add(mem4);
         insert testMembers;

         system.debug('Account Team Member=== ' + [Select Id from AccountTeamMember]);
       }
    }
}