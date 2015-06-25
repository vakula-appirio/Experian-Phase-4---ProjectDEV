/**********************************************************************************************
 * Appirio, Inc 
 * Name         : ScheduleAccountSegmentRelationshipType
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Scheduler class of batch class "BatchSegmentType"
 * Created Date : April 07th 2015
 *
 * Date Modified                Modified By                 Description of the update
 * [Date]                       [Name]                      [Description]
***********************************************************************************************/

global class ScheduleAccountSegmentRelationshipType implements Schedulable {
  //===========================================================================
  //Execute method to schedule batch class
  //===========================================================================
  global void execute(SchedulableContext SC) {
    BatchSegmentType batchSegType = new BatchSegmentType(false); // false means to take only a subset of Orders
    Database.executeBatch(batchSegType); 
  }
}