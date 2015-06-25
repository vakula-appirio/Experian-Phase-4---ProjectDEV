/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleAccountTeamMemberCI 
 * Description: Story:      S-277737
 *              Task:       T-357474
 *              The purpose is to Sync the Account Team Member with the sharing records on the
 *              Confidential Information, since we can't have triggers on Account Team Member
 * Created Date: Mar 23rd, 2015
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleAccountTeamMemberCI implements Schedulable {
  global void execute(SchedulableContext SC) {
    BatchAccountTeamMemberCI batch = new BatchAccountTeamMemberCI(); 
    Database.executeBatch(batch, 200); 
  }
}