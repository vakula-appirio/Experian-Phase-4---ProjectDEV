/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleRetentionMaintenance 
 * Description: T-335169: Schedule BatchRetentionMaintenance to run daily
 * Created Date: Nov 19th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleRetentionMaintenance implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchRetentionMaintenance batch = new BatchRetentionMaintenance(); 
    Database.executeBatch(batch, 200); 
  }
}