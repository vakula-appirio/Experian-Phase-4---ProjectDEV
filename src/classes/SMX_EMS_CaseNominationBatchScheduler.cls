/**=====================================================================
 * Appirio, Inc
 * Name: SMX_EMS_CaseNominationBatchScheduler
 * Description: T-375155
 * Created Date: 7th May, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By                  Description of the update
 *
 =====================================================================*/
global class SMX_EMS_CaseNominationBatchScheduler implements Schedulable{
  global SMX_EMS_CaseNominationBatchScheduler(){}
  
  global void execute(SchedulableContext ctx){
    SMX_EMS_ProcessCaseBatch b = new SMX_EMS_ProcessCaseBatch();
    if (!Test.isrunningTest()){
      database.executebatch(b); 
    }       
  }
    
}