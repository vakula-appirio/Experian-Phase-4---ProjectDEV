/**=====================================================================
 * Appirio, Inc
 * Name: BatchContractRenewalDate_Test
 * Description: T-370246: Test class for BatchContractRenewalDate.cls and ScheduleContractRenewalDate.cls
 * Created Date: Mar 16th, 2015
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified     Modified By        Description of the update

 =====================================================================*/
@isTest(seeAllData=false)
private class BatchContractRenewalDate_Test {
  public static Date previousDate1 = System.today().addDays(-1);
  public static Date previousDate2 = System.today().addDays(-2);

  @isTest
  static void testBatch() {
    // Actual test begins
    Test.StartTest();

    // Executing the batch job
    BatchContractRenewalDate batch = new BatchContractRenewalDate();
    ID batchprocessid = Database.executeBatch(batch);

    Test.StopTest();
    List<Contract__c> result1 = [SELECT ID, Next_Auto_Renewal_Date__c, Renewal_Term_Period__c, 
                                 Initial_Term_Period_End_Date__c FROM Contract__c
                                 WHERE Renewal_Term_Period__c = :3
                                 AND Next_Auto_Renewal_Date__c = :previousDate1.addMonths(3)];

    //Asserts to verify 'Next_Auto_Renewal_Date__c'
    System.assert(result1.size() == 10);
  }

  @testSetup
  private static void createTestData() {
    // Create Global Setting for datetime , for the test method.
    TestMethodUtilities.createTestGlobalSettings();
    Global_Settings__c lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);

    Datetime testBeforeDateTime = lastRun.Contract_Renewal_Job_Last_Run__c ;
    lastRun.Contract_Renewal_Job_Last_Run__c = lastRun.Contract_Renewal_Job_Last_Run__c.addMinutes(-60);
    update lastRun;

    lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);

    // put the datetime into a format that can be used by the SOQL query below
    String testDateSOQL = lastRun.Contract_Renewal_Job_Last_Run__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');

    Account testAcc = Test_Utils.insertAccount();

    List<Contract__c> lstContrct = new List<Contract__c>();

    for (Integer i=1; i<= 10; i++) {
      Contract__c cntrct1 =  Test_Utils.insertContract(false, testAcc.Id, Constants.AGENCY, Constants.STATUS_ACTIVE);
      cntrct1.Contract_Effective_Date__c = Date.today();
      cntrct1.Auto_Renew__c = Constants.PICKLISTVAL_YES;
      cntrct1.Renewal_Term_Period__c = 3;
      cntrct1.Next_Auto_Renewal_Date__c = previousDate1;
      lstContrct.add(cntrct1);
    }

    if (lstContrct.size() > 0){
     insert lstContrct;
    }
  }
}