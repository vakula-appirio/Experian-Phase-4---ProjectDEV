/**
 * 
 */
@isTest(seeAllData = false)
private class BatchAccountSegmentationSetUp_Test {
    
    static testMethod void testForrunAccountSegmentCreation() {
       
      Delete [Select Id from Account_Segment__c];
      Test.startTest();
        Database.executeBatch(new BatchAccountSegmentationSetUp(true,false));
      Test.stopTest();
    }
    
    static testMethod void testForrunAccountSegmentPopulationLogic() {
        // TO DO: implement unit test
      Delete [Select Id from Account_Segment__c];
      Test.startTest();
        Database.executeBatch(new BatchAccountSegmentationSetUp(false,true));
      Test.stopTest();
    }
    
    
    @testSetup
    private static void createTestData () {
      TestMethodUtilities.createTestGlobalSettings();
      Global_Settings__c lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
      lastRun.Batch_Failures_Email__c = '';
      Datetime testBeforeDateTime = lastRun.AccSegmentCreationViaATM_Job_Last_Run__c ;
      lastRun.AccSegmentCreationViaATM_Job_Last_Run__c = lastRun.AccSegmentCreationViaATM_Job_Last_Run__c.addMinutes(-60);
      update lastRun;

      lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);

      // put the datetime into a format that can be used by the SOQL query below
       String testDateSOQL = lastRun.AccSegmentCreationViaATM_Job_Last_Run__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');

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
         hr1.Type__c = 'BU';
         hr1.Value__c = 'testBU'+i;
         hr1.Unique_Key__c = hr1.Type__c + hr1.Value__c ;
         hierarchyList.add(hr1);
         Hierarchy__c hr2 = new Hierarchy__c();
         hr2.Type__c = 'BL';
         hr2.Value__c = 'testBL'+i;
         hr2.Unique_Key__c = hr2.Type__c + hr2.Value__c ;
         hierarchyList.add(hr2);
         Hierarchy__c hr3 = new Hierarchy__c();
         hr3.Type__c = 'GBL';
         hr3.Value__c = 'testGBL'+i;
         hr3.Unique_Key__c = hr3.Type__c + hr3.Value__c ;
         hierarchyList.add(hr3);
         Hierarchy__c hr4 = new Hierarchy__c();
         hr4.Type__c = 'Country';
         hr4.Value__c = 'testCountry'+i;
         hr4.Unique_Key__c = hr4.Type__c + hr4.Value__c ;
         hierarchyList.add(hr4);
         Hierarchy__c hr5 = new Hierarchy__c();
         hr5.Type__c = 'Region';
         hr5.Value__c = 'testRegion'+i;
         hr5.Unique_Key__c = hr5.Type__c + hr5.Value__c ;
         hierarchyList.add(hr5);
       }

       insert hierarchyList;

       System.runAs(testUser1) {
         List<Account> accList = new List<Account>();
          Account acc = Test_Utils.createAccount();
          accList.add(acc);
          Account acc2 = Test_Utils.createAccount();
          accList.add(acc2);
          insert accList;
         List<Opportunity> oppList = new List<Opportunity>();
      Opportunity opp1 = Test_Utils.createOpportunity(accList[0].Id);
      //opp1.Segment_Business_Line__c = accSeg1.Id;
      opp1.Amount = 1000;
      opp1.Amount_Corp__c = 1000;
      opp1.Name = 'this opp to test delete as well';
      oppList.add(opp1);
      Opportunity opp2 = Test_Utils.createOpportunity(accList[0].Id);
    //  opp2.Segment_Business_Unit__c = accSeg1.Id;
      //opp2.Segment_Business_Line__c = accSeg5.Id;
      opp2.Amount = 80;
      oppList.add(opp2);
      Opportunity opp3 = Test_Utils.createOpportunity(accList[0].Id);
      //opp3.Segment_Global_Business_Line__c = accSeg1.Id;
      //opp3.Segment_Business_Unit__c = accSeg2.Id;
      //opp3.Segment_Business_Line__c = accSeg5.Id;
      //opp3.Segment_Region__c = accSeg4.Id;
      opp3.Amount = 50;
      opp3.OwnerId = usrList[0].Id;
      opp3.Name = 'testWonOpp';
      oppList.add(opp3);
      Opportunity opp4 = Test_Utils.createOpportunity(accList[0].Id);
      //opp4.Segment_Region__c = accSeg1.Id;
      //opp4.Segment_Country__c = accSeg3.Id;
      opp4.Amount = 60;
      oppList.add(opp4);
      Opportunity opp5 = Test_Utils.createOpportunity(accList[0].Id);
      //opp5.Segment_Country__c = accSeg1.Id;
      opp5.Amount = 200;
      opp5.Starting_Stage__c = Constants.OPPTY_STAGE_6;
      opp5.Type = Constants.OPPTY_NEW_FROM_NEW;
      opp5.OwnerId = usrList[1].Id;
      //opp5.Name = 'testWonOpp';
      oppList.add(opp5);
      insert oppList;
      }
     }
}