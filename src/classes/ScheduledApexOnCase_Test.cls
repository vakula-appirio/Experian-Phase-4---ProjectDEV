/**=====================================================================
 * Appirio, Inc
 * Name: ScheduledApexOnCase_Test
 * Description: Class to verify the functionality of ScheduledApexOnCase_Test
 *             (installed from Asset)
 * Created Date: 27 Apr 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * May, 13th 2015               Arpita Bose(Appirio)         T-375163: Updated for calulating Record_time__c on Case
 *========================================================================*/
@isTest(seeAllData = false)
private class ScheduledApexOnCase_Test {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    static testMethod void testschedule() {
    
    List<Case> lstCases = new List<Case>();
        lstCases.add(createTestCase('Test Case 1')); 
        lstCases.add(createTestCase('Test Case 2')); 
        insert lstCases;
        
        for(Case cs: lstCases) {
          system.assert(cs.Case_Age__c == null);
            system.assert(!cs.Age_Calculated__c);
          system.assert(!cs.IsClosed);
        }
        
        lstCases[0].Status = 'On Hold';
        update lstCases[0];
        
        //Test ScheduledApexOnCase class
        Test.StartTest();
          //ScheduledApexOnCase skedule = new ScheduledApexOnCase();
         // skedule.execute(null);
          //String timeOfRun = '0 0 * * * ?'; //every hour is scheduling 
          String jobId = System.schedule('ScheduleApexClassTest',
                         CRON_EXP, 
                         new ScheduledApexOnCase());
         
		      // Get the information from the CronTrigger API object
		      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
		                        NextFireTime
		                        FROM CronTrigger WHERE id = :jobId];

		      // Verify the expressions are the same
		      System.assertEquals(CRON_EXP, ct.CronExpression);

		      // Verify the job has not run
		      System.assertEquals(0, ct.TimesTriggered);
		
		      // Verify the next time the job will run
		      System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
        
        lstCases = [Select CreatedDate, Is_Age_Calculating__c, Age_Calculated__c, IsClosed, Case_Age__c, Status, 
                    X2_Hours_In_In_Progress__c, Recording_Time__c
                    From Case Where Id IN :lstCases];
        
        
        for(Case cs: lstCases) {
          system.assert(cs.Case_Age__c != null);
            if(cs.IsClosed){
              system.assert(cs.Age_Calculated__c);
            } else {
              system.assert(!cs.Age_Calculated__c);
            }
        }
        
        for(Case cs: lstCases) {
          if (cs.Status == 'In progress') {
            system.assert(cs.Recording_Time__c != null);
          } else if (cs.Status == 'On Hold'){
            system.assert(cs.Recording_Time__c != null);
          }
        }

  }   
  
  public static Case createTestCase(String subject){
        String EMSRecordTypeId = '';
        EMSRecordTypeId = DescribeUtility.getRecordTypeIdByName('Case', 'EMS');
        Case cs = new Case(
                            BusinessHoursId = [select id from businesshours where isDefault = true].Id,
                            Subject = subject,
                            Origin = 'Phone',
                            Status = 'In progress',
                            Age_Calculated__c = false,
                            RecordtypeId = EMSRecordTypeId
                          );  
        return cs;
    }
  
  @testSetup
  public static void createData () {
  	
  	// create users
    Profile p = [SELECT Id FROM Profile WHERE Name=: Constants.PROFILE_SYS_ADMIN];
    //List<User> lstUser = Test_Utils.createUsers(p, 'test1234@gmail.com', 'T-AE', 1);
    //insert lstUser;
    User user1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'T-AE');
    List<User> lstUser = new List<User>();
    lstUser.add(user1);
    insert lstUser;
    
  	system.runAs( lstUser[0] ) {
	  	CaseTeamRole cst = new CaseTeamRole();
	    cst.Name = 'Decider';
	    cst.AccessLevel = 'Read';
	    insert cst;
    }
    
    Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
    custSetting.Case_Access_Request_TeamRole__c = 'Decider';
    update custSetting;
   
  }
}