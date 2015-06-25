/**===========================================================================
 * Experian Plc
 * Name: ScheduleUserLastActivityUpdate 
 * Description: Case #5237 - Schedule BatchUserLastActivityUpdate to run daily
 * Created Date: Jul 30th, 2014
 * Created By: James Weatherall
 * 
 * Date Modified     Modified By        Description of the update
 
 ==============================================================================*/
global class ScheduleUserLastActivityUpdate implements Schedulable {
  global void execute(SchedulableContext SC) {
    String query = 'SELECT Id, LastLoginDate, Days_since_Activity__c FROM User WHERE IsActive = true AND LastLoginDate != null';
    BatchUserLastActivityUpdate batchToProcess = new BatchUserLastActivityUpdate(query); 
    Database.executeBatch(batchToProcess); 
  }
}