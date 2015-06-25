@isTest(seeAllData = true)
    global class SMXNominationBatchSchedulerContextTest{
    static testMethod void testExecute() {
        Test.startTest();
        SMXNominationProcessorSchedulerContext schedulerContext = new SMXNominationProcessorSchedulerContext();
        String schedule = '0 0 8 * * ?';
        system.schedule('Scheduled Update', schedule, schedulerContext);
        test.stopTest();
    }
}