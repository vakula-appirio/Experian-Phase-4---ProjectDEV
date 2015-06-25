/**=====================================================================
 * Appirio, Inc
 * Name: TimecardSetupController_Test 
 * Description: Test class for TimecardSetupController.cls
 * Created Date: Sep 18th, 2014
 * Created By: Noopur
 *
 * Date Modified      Modified By                Description of the update
=========================================================================*/
@isTest(seeAllData = false)
private class TimecardSetupController_Test {

    // Method to verify the functionality for user that has a BU defined and a record 
    // in the timecard setting 
    static Timecard_Settings__c timecardSetting ;
    static User testUser ;

    static testMethod void testTimecardSetup () {
        Test.startTest();
            createData();
            System.runAs (testUser) {
                TimecardSetupController con = new TimecardSetupController();
                con.doCancel();
                con.lockingDate = Date.today();
                con.doSave();
            }
            Timecard_Settings__c tcSetting ; 
            for (Timecard_Settings__c tc :[SELECT Id,Name,Locking_End_Date__c
                                           FROM Timecard_Settings__c
                                           WHERE Name = 'testBU'] ) {
                tcSetting = tc;
            }
            System.assert(tcSetting != null);
            System.assertEquals(tcSetting.Locking_End_Date__c , Date.today());
        Test.stopTest();
    }


    // Method to verify the functionality for user that does not have a BU defined 
    static testMethod void testTimecardSetupForBlankBU () {
        Test.startTest();
            createData();
            testUser.Business_Unit__c = '';
            update testUser;
            System.runAs (testUser) {
                TimecardSetupController con = new TimecardSetupController();
                con.doCancel();
                con.doSave();
                System.assertEquals(con.hasNoBU,true);
            }
        Test.stopTest();
    }

    // Method to verify the functionality for user that has a BU defined but no record 
    // created in the timecard setting 
    static testMethod void testTimecardSetupForNoSettingForBU () {
        Test.startTest();
            createData();
            delete timecardSetting;
            System.runAs (testUser) {
                TimecardSetupController con = new TimecardSetupController();
                con.doCancel();
                con.doSave();
            }
            Timecard_Settings__c tcSetting ; 
            for (Timecard_Settings__c tc :[SELECT Id,Name 
                                           FROM Timecard_Settings__c
                                           WHERE Name = 'testBU'] ) {
                tcSetting = tc;
            }
            System.assert(tcSetting != null);
            System.assertEquals(tcSetting.Name , 'testBU');
        Test.stopTest();
    }

    // Method to create test data
    static void createData () {

        // create timecard setting record
        timecardSetting = new Timecard_Settings__c();
        timecardSetting.Name = 'testBU';
        timecardSetting.locking_end_date__c = Date.today().addDays(-5);
        insert timecardSetting;

        // create a test user
        testUser = Test_Utils.createUser('System Administrator');
        testUser.Business_Unit__c = 'testBU';
        insert testUser;
    }

     
  
}