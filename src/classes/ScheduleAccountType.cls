/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleAccountType 
 * Description: Schedule BatchAccountType to run daily
 * Created Date: Apr 24th, 2014
 * Created By: Nathalie Le Guay (Appirio) - T-275037
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleAccountType implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchAccountType batch = new BatchAccountType(); 
    Database.executeBatch(batch, 200); 
  }
}