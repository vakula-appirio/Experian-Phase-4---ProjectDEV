/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleContractRenewalDate 
 * Description: T-370246: Schedule BatchContractRenewalDate to run daily
 * Created Date: Mar 16th, 2015
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleContractRenewalDate implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchContractRenewalDate batch = new BatchContractRenewalDate(); 
    Database.executeBatch(batch, 200); 
  }
}