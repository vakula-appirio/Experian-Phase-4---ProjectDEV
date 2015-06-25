global class ScheduleSumScheduleRevenueCurrentFY implements Schedulable
{
  /*
  * Author:     Diego Olarte (Experian)
  * Description:  The following class is for scheduling the 'SumScheduleRevenueCurrentFY.cls' class to run at specific intervals.
  */  
  
  global void execute(SchedulableContext sc)
  {
    SumScheduleRevenueCurrentFY batchToProcess = new SumScheduleRevenueCurrentFY();
    database.executebatch(batchToProcess);
  }
}