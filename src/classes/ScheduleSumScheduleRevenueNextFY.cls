global class ScheduleSumScheduleRevenueNextFY implements Schedulable
{
  /*
  * Author:     Diego Olarte (Experian)
  * Description:  The following class is for scheduling the 'SumScheduleRevenueNextFY.cls' class to run at specific intervals.
  */  
  
  global void execute(SchedulableContext sc)
  {
    SumScheduleRevenueNextFY batchToProcess = new SumScheduleRevenueNextFY();
    database.executebatch(batchToProcess);
  }
}