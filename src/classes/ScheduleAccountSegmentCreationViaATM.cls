/*******************************************************************************
 * Appirio, Inc
 * Name         : ScheduleAccountSegmentCreationViaATM
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Scheduler class of batch class "BatchAccountSegmentCreationViaATM"
 * Created Date : April 07th, 2015
 *
 * Date Modified                Modified By         Description of the update
 * 
*******************************************************************************/

global class ScheduleAccountSegmentCreationViaATM implements Schedulable {
  
  //===========================================================================
  //Execute method to schedule batch class
  //===========================================================================
  global void execute(SchedulableContext SC) {
    BatchAccountSegmentCreationViaATM  batchASCVATM = 
                                       new BatchAccountSegmentCreationViaATM (); 
    Database.executeBatch(batchASCVATM); 
  }
}