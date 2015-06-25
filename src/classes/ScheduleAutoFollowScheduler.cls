global class ScheduleAutoFollowScheduler {
    global void ScheduleAutoFollowScheduler() {}
    public static void start()
    {
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        //Schedules the job every midnight....
        //[RJ]- Updated the Job name to handle testcalss scheduling
        String JobName = 'Auto Follow Schedule';
        if (Test.isRunningTest())
        JobName = 'Auto Follow Schedule - Test';
         
        System.schedule(JobName , '0 0 0 * * ?', new ScheduleAutoFollow());
    }
    
}