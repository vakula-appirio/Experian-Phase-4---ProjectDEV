/**=====================================================================
 * Appirio, Inc
 * Test Class Name: ScheduleUserLastActivityUpdate_Test
 * Class Name: ScheduleUserLastActivityUpdate
 
 * Created Date: Sep 05th, 2014
 * Created By: Aditi Bhardwaj (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update

 =====================================================================*/

@isTest
private class ScheduleUserLastActivityUpdate_Test {
    static testMethod void scheduleUserLastActivityUpdate_Test() { 
   /* User testUserforInsert = Test_Utils.createUser('Standard User');
    testUserforInsert.Days_since_Activity__c = 1;
    insert testUserforInsert; */       
    String query = 'SELECT Id, LastLoginDate, Days_since_Activity__c FROM User WHERE IsActive = true AND LastLoginDate != null';
    BatchUserLastActivityUpdate batchToProcess = new BatchUserLastActivityUpdate(query ); 
       
     }

}