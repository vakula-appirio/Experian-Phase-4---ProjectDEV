/**=====================================================================
 * Appirio, Inc
 * Name: BatchAddressMergeRequest_Schedule 
 * Description: Schedule BatchAddressMergeRequest to run daily
 * Created Date: Feb 24th, 2014
 * Created By: Nathalie Le Guay (Appirio) - T-251891
 * 
 * Date Modified     Modified By                  Description of the update
 * Oct 25th, 2014    Nathalie Le Guay (Appirio)   Removing functionality
 =====================================================================*/
global class BatchAddressMergeRequest_Schedule implements Schedulable {
   global void execute(SchedulableContext SC) {
      /*
      BatchAddressMergeRequest batch = new BatchAddressMergeRequest(); 
      Database.executeBatch(batch, 200);
      */
   }
}