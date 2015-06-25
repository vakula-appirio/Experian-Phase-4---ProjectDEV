/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleAssignmentTeam 
 * Description: T-355035: Schedule BatchAssignTeam to run daily
 * Created Date: Jan 28th, 2015
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified     Modified By        Description of the update
 * May 28th, 2015    Nathalie Le Guay   Set batch size to 1
 =====================================================================*/
global class ScheduleAssignmentTeam implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchAssignmentTeam batch = new BatchAssignmentTeam(); 
    Database.executeBatch(batch, 1); 
  }
}