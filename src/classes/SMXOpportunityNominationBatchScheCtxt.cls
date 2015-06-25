global class SMXOpportunityNominationBatchScheCtxt implements Schedulable{
    global SMXOpportunityNominationBatchScheCtxt(){}
    global void execute(SchedulableContext ctx){
        SMXProcessOpportunityBatch b = new  SMXProcessOpportunityBatch();
        if(!Test.isrunningTest()){
        database.executebatch(b); 
        }       
    }
    
}