global class ScheduleSumScheduleRevenueCFYandNFY implements Schedulable
{
  /*
  * Author:     Diego Olarte (Experian)
  * Description:  The following class is for scheduling the 'SumScheduleRevenueCFYandNFY.cls' class to run at specific intervals.
  */  
  
  global void execute(SchedulableContext sc)
  {
    SumScheduleRevenueCFYandNFY batchToProcess = new SumScheduleRevenueCFYandNFY();
    database.executebatch(batchToProcess);
  }
}