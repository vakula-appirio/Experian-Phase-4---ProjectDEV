global class ScheduleAccountSubCode implements Schedulable
{
  /*
  * Author:     Terri Kellough (Appirio)
  * Description:  The following class is for scheduling the 'BatchAccountSubCode.cls' class to run at specific intervals.
  * Story:    S-292550
  * Task:     T-366637
  */  
  
  global void execute(SchedulableContext sc)
  {
    BatchAccountSubCode batchToProcess = new BatchAccountSubCode();
    database.executebatch(batchToProcess);
  }
}