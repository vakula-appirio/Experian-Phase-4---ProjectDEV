/*============================================================================
 * Appirio, Inc
 * Name: TimecardSetupController
 * Description: T-320438: Timecard: VF page to display custom settings.
 * Created Date: Sep 18th, 2014
 * Created By: Noopur(Appirio)
 * 
 * Date Modified        Modified By             Description 
==============================================================================*/
public class TimecardSetupController {

	Public User currentUser {get;set;}
	Public Timecard_Settings__c timecardSetting {get;set;}
	Public Boolean hasNoBU {get;set;}
	public String BU_Name {get;set;}
	public Date lockingDate {get;set;}

	// Constructor
	public TimecardSetupController () {
		
		// fetch the current user
		currentUser = [SELECT Id, Business_Unit__c, FirstName, LastName
					   FROM User
					   WHERE Id = : userInfo.getUserId()];
		hasNoBU = false;
		timecardSetting = new Timecard_Settings__c ();
		BU_Name = currentUser.Business_Unit__c;
		
		// check if there is a Business Unit defined for the user
		if ( String.isBlank(currentUser.Business_Unit__c) ) {

			// add error on the page telling that no BU is defined for user
			hasNoBU = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Timecard_Setting_No_BU_Defined));
		}
		else {

			// Check if the timecard setting record exists for the user's BU
			if ( Timecard_Settings__c.getValues(currentUser.Business_Unit__c) != null ) {
				timecardSetting = Timecard_Settings__c.getValues(currentUser.Business_Unit__c);
				lockingDate = timecardSetting.Locking_End_Date__c ;
			}
			else {

				// if no Timecard setting record exists, create a new one with the Name as user's BU
				timecardSetting.Name = currentUser.Business_Unit__c;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.Timecard_Setting_No_Record_Exists));
			}
		}
	}

	// Method for Cancel functionality
	public pageReference doCancel () {
		return new pageReference('/apex/timecardentry');
	}

	// Method to Update/Save the timecard setting
	public pageReference doSave () {
		try {

			// insert/update the Timesetting record for user
			timecardSetting.Name = BU_Name;
			timecardSetting.Locking_End_Date__c = lockingDate;
			upsert timecardSetting;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.Timecard_Setting_Successfully_Updated));
		}

		// catch the exception (if any)
		catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
			ApexLogHandler.createLogAndSave('TimecardSetupController','doSave', ex.getStackTraceString(), ex);
		}
		return null;
	}
  
}