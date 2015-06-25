/*
  Scheduler Context for Nomination Processor batch class SMXNominationProcessorBatch 
*/
global class SMXNominationProcessorSchedulerContext implements Schedulable{
    global SMXNominationProcessorSchedulerContext(){}
    
    global void execute(SchedulableContext ctx){
        SMXNominationProcessorBatch b = new SMXNominationProcessorBatch();
        database.executebatch(b,1);        
    }
}