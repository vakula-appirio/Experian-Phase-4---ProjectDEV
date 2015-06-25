/**=====================================================================
 * Appirio, Inc
 * Name: BatchRetentionMaintenance_Test
 * Description: T-335169: Test class to verify the behaviour of BatchRetentionMaintenance.cls
 *              and ScheduleRetentionMaintenance.cls
 * Created Date: Nov 19th, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified         Modified By          Description of the update
 * Feb 17th, 2015        Noopur               T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
@isTest (seeAllData = false)
private class BatchRetentionMaintenance_Test {
  public static List<Retention_Line_Item__c> rliList = new List<Retention_Line_Item__c>();

  static testmethod void testRetentionLineItemDeletion(){
    // start test
    Test.startTest();

    BatchRetentionMaintenance retDel = new BatchRetentionMaintenance();
    ID batchprocessid = Database.executeBatch(retDel);

    // stop test
    Test.stopTest();
    List<Retention_Line_Item__c> result = [SELECT Id FROM Retention_Line_Item__c];
    // Assert to verify that Retention_Line_Item__c records are deleted where Retention__c record with Lock__c = false,
    // Year__c = currentYear - 1,Month__c = currentMonth - 1
    system.assertEquals(result.size(), 100);
  }

  @isTest
  static void test_ScheduleRetentionMaintenance() {
    Test.startTest();
    //createData();
    // Schedule the test job
    String CRON_EXP = '0 0 0 3 9 ? 2022';
    String jobId = System.schedule('ScheduleRetentionLineItemDeletion_Test', CRON_EXP,
       new ScheduleRetentionMaintenance());

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                      FROM CronTrigger
                      WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, ct.CronExpression);
    Test.stopTest();
  }

  @testSetup
  public static void createData() {
    //Integer currentYear = 2345;
    //Integer currentMonth = 10;
    Integer currentYear = System.Today().year();
    Integer currentMonth = System.Today().month();

    Retention_Settings__c rsettings = new Retention_Settings__c();
    rsettings.Last_RLI_Removal_Batch_Run__c = Date.Today().addDays(-1000);
    rsettings.Receive_Email_Notification__c = false;
    rsettings.Name = 'Global';
    insert rsettings;

    Account testAcc = Test_Utils.insertAccount();

    // Retention__c record with Lock__c = false, Year__c = currentYear - 2, Month__c = currentMonth - 1
    Retention__c ret = new Retention__c();
    ret.Account__c = testAcc.Id;
    ret.Lock__c = false;
    ret.Year__c = currentYear - 3;
    ret.Month__c = currentMonth - 1;
    insert ret;

    for (Integer i=0; i <50; i++) {
      Retention_Line_Item__c retLineItem1 = new Retention_Line_Item__c();
      retLineItem1.Retention__c = ret.Id;
      rliList.add(retLineItem1);
    }

    for (Integer i=0; i <50; i++) {
      Retention_Line_Item__c retLineItem2 = new Retention_Line_Item__c();
      retLineItem2.Retention__c = ret.Id;
      rliList.add(retLineItem2);
    }

    // Retention__c record with Lock__c = false, Year__c = currentYear, Month__c = currentMonth
    Retention__c ret1 = new Retention__c();
    ret1.Account__c = testAcc.Id;
    ret1.Lock__c = false;
    ret1.Year__c = currentYear;
    ret1.Month__c = currentMonth;
    insert ret1;

    for (Integer i=0; i <50; i++) {
      Retention_Line_Item__c retLineItem3 = new Retention_Line_Item__c();
      retLineItem3.Retention__c = ret1.Id;
      rliList.add(retLineItem3);
    }

    // Retention__c record with Lock__c = true, Year__c = currentYear, Month__c = currentMonth
    Retention__c ret2 = new Retention__c();
    ret2.Account__c = testAcc.Id;
    ret2.Lock__c = true;
    ret2.Year__c = currentYear;
    ret2.Month__c = currentMonth;
    insert ret2;

    for (Integer i=0; i <50; i++) {
      Retention_Line_Item__c retLineItem4 = new Retention_Line_Item__c();
      retLineItem4.Retention__c = ret2.Id;
      rliList.add(retLineItem4);
    }
    if (rliList.size() > 0) {
      insert rliList;
    }
  }

}