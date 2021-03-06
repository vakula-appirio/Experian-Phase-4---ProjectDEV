/**********************************************************************************************
 * Appirio, Inc 
 * Name         : ScheduleAccountSubCode_Test
 * Created By   : Naresh Kr Ojha (Appirio)
 * Purpose      : Test class of scheduler class "ScheduleAccountSubCode "
 * Created Date : June 17, 2015
 *
 * Date Modified                Modified By                 Description of the update
 * [Date]                       [Name]                      [Description]
***********************************************************************************************/

@isTest
private class ScheduleAccountSubCode_Test {
    @isTest 
    static void test_ScheduleAccountSubCode() {
        Global_Settings__c gs = new Global_Settings__c();
        gs.Name = 'Global';
        gs.Batch_Failures_Email__c = '';
        insert gs;
        
        test.startTest();
            // Schedule the test job
            String CRON_EXP = '0 0 0 * * ?';
            String jobId = System.schedule('Batch Account Sub Code', CRON_EXP, new ScheduleAccountSubCode());
            
            // Get the information from the CronTrigger API object  
            CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                                FROM CronTrigger 
                                WHERE id = :jobId];     
        test.stopTest();

        // Verify the Schedule has been scheduled with the same time specified  
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run, but scheduled  
        System.assertEquals(0, ct.TimesTriggered);
    } 
}