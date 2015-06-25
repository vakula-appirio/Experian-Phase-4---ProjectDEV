global class ScheduleAccountTeamMemberUpdate implements Schedulable
{
	/*
	* Author: 		Shane Khublall (Appirio)
	* Description: 	The following class is for scheduling the 'BatchAccountTeamMemberUpdate.cls' class to run at specific intervals.
	* Story:		S-123907
	* Task: 		T-194927
	*/	
	
	global void execute(SchedulableContext sc)
	{
		BatchAccountTeamMemberUpdate batchToProcess = new BatchAccountTeamMemberUpdate();
		database.executebatch(batchToProcess);
	}
}