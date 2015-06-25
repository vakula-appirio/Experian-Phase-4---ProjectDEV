@istest(seeAllData=TRUE)
global class SMXOrderNominationBatchSdlrContextTest{
    
    static testmethod void SmxOrderScheduler(){
        test.starttest();
        SMXOrderNominationBatchSchedulerContext sc= new SMXOrderNominationBatchSchedulerContext();
        String schedule = '0 0 4 * * ?';
        system.schedule('Scheduled Process Nomination Order', schedule, sc);
        test.stoptest();
    }
    
}