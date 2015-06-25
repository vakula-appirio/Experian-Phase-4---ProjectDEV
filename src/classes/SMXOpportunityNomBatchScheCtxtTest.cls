@istest(seeAllData=TRUE)
global class SMXOpportunityNomBatchScheCtxtTest{
    
    static testmethod void SmxOpportunityScheduler(){
        test.starttest();
        SMXOpportunityNominationBatchScheCtxt sc= new SMXOpportunityNominationBatchScheCtxt();
        String schedule = '0 0 4 * * ?';
        system.schedule('Scheduled Process Nomination Opportunity', schedule, sc);
        test.stoptest();
    }
    
}