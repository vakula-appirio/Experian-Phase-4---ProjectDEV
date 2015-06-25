/**********************************************************************************************
 * Appirio, Inc
 * Name         : ScheduleAccountSegmentPreviousFYTotals
 * Created By   : Rohit B. (Appirio)
 * Purpose      : Scheduler class of batch class "AccountSegmentationFiscalYearCalculation"
 * Created Date : April 07th, 2015
 *
 * Date Modified                Modified By                 Description of the update
 * [Date]                       [Name]                      [Description]
***********************************************************************************************/

global class ScheduleAccountSegmentPreviousFYTotals implements Schedulable {
  //===========================================================================
  //Execute method to schedule batch class
  //===========================================================================
  global void execute(SchedulableContext SC) {
    AccountSegmentationFiscalYearCalculation batchASFYC = new AccountSegmentationFiscalYearCalculation(); 
    Database.executeBatch(batchASFYC); 
  }
}