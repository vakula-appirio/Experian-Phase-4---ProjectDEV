/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleSegmentType 
 * Description: T-371862: Schedule BatchSegmentType to run daily
 * Created Date: Mar 20th, 2015
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleSegmentType implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchSegmentType batch = new BatchSegmentType(false); 
    Database.executeBatch(batch, 200); 
  }
}