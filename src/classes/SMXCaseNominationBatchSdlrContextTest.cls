@istest(seeAllData=TRUE)
global class SMXCaseNominationBatchSdlrContextTest{
    
    static testmethod void SmxcaseScheduler(){
        test.starttest();
        SMXCaseNominationBatchSchedulerContext sc= new SMXCaseNominationBatchSchedulerContext();
        String schedule = '0 0 4 * * ?';
        system.schedule('Scheduled Process Nomination Cases', schedule, sc);
        test.stoptest();
    }
    
}