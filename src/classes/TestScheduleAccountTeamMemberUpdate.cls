@isTest
private class TestScheduleAccountTeamMemberUpdate
{
	/*
	* Author: 		Shane Khublall (Appirio)
	* Description: 	The following test class is for testing the 'ScheduleAccountTeamMemberUpdate.cls' class
	* Story:		S-123907
	* Task: 		T-194927
	*/	
	
   static testMethod void testSuccessfulScheduleExecute()
   {    	
   	  TestMethodUtilities.createTestGlobalSettings();
    	
      //Test.startTest();
        
      string sch ='0 0 0 3 9 ? 2022';
      ScheduleAccountTeamMemberUpdate satmu = new ScheduleAccountTeamMemberUpdate();
      system.debug('XXXXXXXXXXXXXX' + satmu);
        
      // schedule the test job
      System.schedule('testSchAccTeamMemberUpdate', sch, satmu);
        
      //test.stopTest();
    }
}