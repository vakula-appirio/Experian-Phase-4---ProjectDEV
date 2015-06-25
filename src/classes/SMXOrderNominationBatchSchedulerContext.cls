global class SMXOrderNominationBatchSchedulerContext implements Schedulable{
    global SMXOrderNominationBatchSchedulerContext(){}
    global void execute(SchedulableContext ctx){
        SMXProcessOrderBatch b = new  SMXProcessOrderBatch();
        if(!Test.isrunningTest()){
        database.executebatch(b); 
        }       
    }
    
}