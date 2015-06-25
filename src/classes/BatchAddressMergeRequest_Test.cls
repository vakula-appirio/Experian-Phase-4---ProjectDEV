/**=====================================================================
 * Appirio, Inc
 * Name: BatchAddressMergeRequest_Test
 * Description: T-250105: Test class to verify the behaviour of BatchProcessAddressMergeRequest.cls 
 * Created Date: Feb 18th, 2014
 * Created By: Jinesh Goyal(Appirio)
 * 
 * Date Modified         Modified By                  Description of the update
 * Feb 24th, 2014        Nathalie Le Guay (Appirio)   Added test for schedule testBatchProcessAddressMergeRequestScheduleClass()
 *                                                    as well as createData() method
 * Feb 27th, 2014        Jinesh Goyal (Appirio)       Fixing test class
 * Oct 25th, 2014        Nathalie Le Guay (Appirio)   Removing functionality
 =====================================================================*/
@isTest(seeAllData=false)
private class BatchAddressMergeRequest_Test {

/*
  static testMethod void batchTest() {
    createData();
    //actual test begins
    Test.StartTest();
    //executing the batch job
    BatchAddressMergeRequest addMerge = new BatchAddressMergeRequest();
    ID batchprocessid = Database.executeBatch(addMerge);
    Test.StopTest();
    System.AssertEquals(100, [SELECT count() FROM Address_History__c] );
    System.AssertEquals(0, [SELECT count() FROM Address__c WHERE Id IN :lstSlaveAddresses] );
    System.AssertEquals(Constants.MERGE_PROCESS_STATUS_SUCCESS,
                         [SELECT Merge_Process_Status__c FROM Address_Merge_Request__c LIMIT 1].get(0).Merge_Process_Status__c);
    System.AssertEquals(lstMasterAddresses[0].Id, [SELECT Address__c FROM Account_Address__c WHERE Id = :lstAccountAddress[0].Id].get(0).Address__c );
    System.AssertEquals(lstMasterAddresses[0].Id, [SELECT Address__c FROM Contact_Address__c WHERE Id = :lstContactAddress[0].Id].get(0).Address__c);
  }

  private static List <Address__c> lstMasterAddresses = new List<Address__c>();
  private static List <Address__c> lstSlaveAddresses = new List<Address__c>();
  private static List <Address_Merge_Request__c> lstAddMergeReqst = new List <Address_Merge_Request__c>();
  private static Address__c masterAddress;
  private static Address__c slaveAddress;
  private static Address_Merge_Request__c addressMergeRequest;
  private static Account_Address__c accAddress;
  private static Contact_Address__c conAddress;
  private static List <Account_Address__c> lstAccountAddress = new List<Account_Address__c>();
  private static List <Contact_Address__c > lstContactAddress = new List<contact_Address__c>();

  @isTest
  static void testBatchProcessAddressMergeRequestScheduleClass() {
    Test.startTest();
    createData();
    // Schedule the test job
    String CRON_EXP = '0 0 0 3 9 ? 2022';
    String jobId = System.schedule('BatchAddressMergeRequest_Schedule_Test', CRON_EXP, 
       new BatchAddressMergeRequest_Schedule());

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                      FROM CronTrigger 
                      WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);
    Test.stopTest();
  }
  
  public static void createData() {
     // Create 100 test records - this simulates one execute.
      // Important - the Salesforce.com test framework only allows you to
      // test one execute.

      //creating dummy data
      //insert Account
      Account acc = Test_Utils.insertAccount();
      //insert Contact
      Contact con = Test_Utils.insertContact(acc.Id);
      for (integer i = 0; i<100; i++) {
        masterAddress = Test_Utils.insertAddress(false);
        lstMasterAddresses.add(masterAddress);
        slaveAddress = Test_Utils.insertAddress(false);
        lstSlaveAddresses.add(slaveAddress);
      }
      if (lstMasterAddresses.size() > 0) insert lstMasterAddresses;
      if (lstSlaveAddresses.size() > 0) insert lstSlaveAddresses;
      //creating Address Merge Request
      for (integer i = 0; i < 100; i++) {
        addressMergeRequest = Test_Utils.insertAddressMergeRequest(false, lstMasterAddresses.get(i).id, lstSlaveAddresses.get(i).id);
        addressMergeRequest.Perform_Auto_Merge__c = true;
        //addressMergeRequest.Is_Address_Merged__c = false; NLG - deleting field
        addressMergeRequest.Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_PENDING;
        lstAddMergeReqst.add(addressMergeRequest);
        //insert Account Address
        accAddress = Test_Utils.insertAccountAddress(false, lstSlaveAddresses[i].Id, acc.Id);
        lstAccountAddress.add(accAddress);
        //insert Contact Address
        conAddress = Test_Utils.insertContactAddress(false, lstSlaveAddresses[i].Id, con.Id);
        lstContactAddress.add(conAddress);
      }
      if (lstAddMergeReqst.size() > 0) insert lstAddMergeReqst;
      if (lstAccountAddress.size() > 0) insert lstAccountAddress;
      if (lstContactAddress.size() > 0) insert lstContactAddress;
  }
  */
}