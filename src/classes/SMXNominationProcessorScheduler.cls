/*
  Utility class to create process nomination jobs. 
  Process nomination job will process survey records in nominated status and publish them into Satmetrix thru WS call outs
*/
global class SMXNominationProcessorScheduler{
   
    public static void createJobsEveryFiveMin(){
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        System.schedule('Satmetrix Integration Job - Process Nominations 00', '0 0 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 05', '0 05 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 10', '0 10 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 15', '0 15 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 20', '0 20 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 25', '0 25 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 30', '0 30 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 35', '0 35 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 40', '0 40 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 45', '0 45 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 50', '0 50 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
        System.schedule('Satmetrix Integration Job - Process Nominations 55', '0 55 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());
    }
    
    public static void createJobsEveryFifteenMin(){
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        System.schedule('Satmetrix Integration Job - Process Nominations 00', '0 0 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());        
        System.schedule('Satmetrix Integration Job - Process Nominations 15', '0 15 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());        
        System.schedule('Satmetrix Integration Job - Process Nominations 30', '0 30 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());    
        System.schedule('Satmetrix Integration Job - Process Nominations 45', '0 45 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());        
    }
    public static void createJobEveryHour(){
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        System.schedule('Satmetrix Integration Job - Process Nominations Hly', '0 0 * * 1-12 ? *',  New SMXNominationProcessorSchedulerContext());       
    }
}