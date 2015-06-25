global class SMXCaseNominationBatchSchedulerContext implements Schedulable{
    global SMXCaseNominationBatchSchedulerContext(){}
    global void execute(SchedulableContext ctx){
        SMXProcessCaseBatch b = new  SMXProcessCaseBatch();
        if(!Test.isrunningTest()){
        database.executebatch(b); 
        }       
    }
    
}