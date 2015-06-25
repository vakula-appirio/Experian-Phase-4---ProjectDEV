/**********************************************************************************************
 * Appirio, Inc 
 * Name         : ScheduleAccountSegmentCreationViaATMTest
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Test class of scheduler class "ScheduleAccountSegmentCreationViaATM"
 * Created Date : April 07, 2015
 *
 * Date Modified                Modified By                 Description of the update
 * [Date]                       [Name]                      [Description]
***********************************************************************************************/

@isTest
private class ScheduleAccountSegmentCreationViaATMTest {
    
    @isTest 
    static void test_method_one() {
        Global_Settings__c gs = new Global_Settings__c();
        gs.Name = 'Global';
        gs.Batch_Failures_Email__c = '';
        insert gs;
        
        test.startTest();
            // Schedule the test job
            String CRON_EXP = '0 0 0 * * ?';
            String jobId = System.schedule('Account Segment Creation Via ATM', CRON_EXP, new ScheduleAccountSegmentCreationViaATM());
            
            // Get the information from the CronTrigger API object  
            CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                                FROM CronTrigger 
                                WHERE id = :jobId];     
        test.stopTest();

        // Verify the expressions are the same  
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
    }   
}