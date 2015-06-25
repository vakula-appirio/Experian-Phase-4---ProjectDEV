/**=====================================================================
 * Appirio, Inc
 * Name: ScheduledApexOnCase
 * Description: Class to calculate the case Age considering business hours
 *             (installed from Asset)
 * Created Date: 25 Apr 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * May, 12th 2015               Arpita Bose(Appirio)         T-375163: Updated for calulating Record_time__c on Case
 *========================================================================*/
global class ScheduledApexOnCase implements Schedulable { 
	public String SOBJECT_CASE = 'Case';
	public String RECORDTYPE_CASE_EMS = 'EMS'; 
	public String CASE_STATUS_IN_PROGRESS = 'In progress';
	public String CASE_STATUS_ON_HOLD = 'On Hold';   
 
    global void execute(SchedulableContext sc) {
        try {
        //variable declaration
        Decimal caseAge;
        Datetime startTime;
        Datetime endTime;
        
        //Create a list of newCases to update
        List<Case> newCases = new List<Case>();
        String EMSRecordTypeId = '';
        EMSRecordTypeId = DescribeUtility.getRecordTypeIdByName(SOBJECT_CASE, RECORDTYPE_CASE_EMS);
        //For loop to iterate through all the queried case records
        for(Case eachCase: [SELECT Id, CaseNumber, BusinessHoursId,Business_Hours_Afternoon__c, 
                                   IsClosed, CreatedDate, ClosedDate, BusinessHours.Name,
                                   Case_Age__c, Age_Calculated__c, Is_Age_Calculating__c, Case_Age_Text__c,
                                   X2_Hours_In_In_Progress__c, Status ,RecordTypeId, Type,
                                   Recording_Time__c,
                                   (SELECT Id, CaseId, CreatedDate, Field, OldValue, NewValue 
                                    FROM Histories
                                    WHERE Field = 'Status')
                             FROM  Case 
                             Where Age_Calculated__c = false 
                             AND RecordTypeId = :EMSRecordTypeId
                             limit 10000]) {
            system.debug('eachCase>>>' +eachCase);
            //variable initialization
            eachCase.Is_Age_Calculating__c = true; 
            eachCase.Age_Calculated__c = eachCase.IsClosed ? true : false;

            startTime = eachCase.CreatedDate;
            endTime = eachCase.IsClosed ? eachCase.ClosedDate : system.Now();
            
            if( eachCase.Business_Hours_Afternoon__c == null) {
	            //calculating the case age (Hours) considering Business Hours of Case
	            caseAge = BusinessHours.diff(eachCase.BusinessHoursId, startTime, endTime) / 1000 / 60;
            }
            else {
            	Decimal caseAgeMorning = BusinessHours.diff(eachCase.BusinessHoursId, startTime, endTime) / 1000 / 60;
            	Decimal caseAgeAfternoon = BusinessHours.diff(eachCase.Business_Hours_Afternoon__c, startTime, endTime) / 1000 / 60;
            	caseAge = caseAgeMorning + caseAgeAfternoon;
            }
            
            Integer hr = Integer.valueOf(caseAge/60);
            Integer min = Integer.valueOf(caseAge - (hr*60));
            eachCase.Case_Age_Text__c = hr+' hour '+min+' min';
            eachCase.Case_Age__c = caseAge/60;
            
            // 
            if( eachCase.Status == CASE_STATUS_IN_PROGRESS && eachCase.Case_Age__c >= 2) {
              eachCase.X2_Hours_In_In_Progress__c = true;
            }
            
            if ( eachCase.Status == CASE_STATUS_IN_PROGRESS) {
            	eachCase.Recording_Time__c = caseAge; //T-375163
            	system.debug('InProgress::Recording_Time__c>>>' +eachCase.Recording_Time__c);
            }
            // for Status ='On Hold' on Case
            else if( eachCase.Status == CASE_STATUS_ON_HOLD ) {
            	if ( eachCase.Histories != null && eachCase.Histories.size() > 0 &&
            	       eachCase.Histories[0].OldValue == CASE_STATUS_IN_PROGRESS && eachCase.Histories[0].NewValue == CASE_STATUS_ON_HOLD) {
            		startTime = eachCase.Histories[0].createdDate;
            	}
            	if( eachCase.Business_Hours_Afternoon__c == null) {
	              //calculating the case age (Hours) considering Business Hours of Case
	              caseAge = BusinessHours.diff(eachCase.BusinessHoursId, startTime, endTime) / 1000 / 60;
	            }
	            else {
	              Decimal caseAgeMorning = BusinessHours.diff(eachCase.BusinessHoursId, startTime, endTime) / 1000 / 60;
	              Decimal caseAgeAfternoon = BusinessHours.diff(eachCase.Business_Hours_Afternoon__c, startTime, endTime) / 1000 / 60;
	              caseAge = caseAgeMorning + caseAgeAfternoon;
	            }
	            eachCase.Recording_Time__c = caseAge;
	            system.debug('Onhold::Recording_Time__c>>>' +eachCase.Recording_Time__c); 
            }
            
            system.debug('=====Case Number: ' + eachCase.CaseNumber);
            system.debug('=====Is Closed?: ' + eachCase.IsClosed);
            system.debug('=====Case Age: ' + eachCase.Case_Age__c);
            system.debug('=====Recording_Time__c: ' + eachCase.Recording_Time__c);
            
            newCases.add(eachCase);
        }
        
        //updating cases
        update newCases;
        }
        catch ( Exception ex) {
        	System.debug('[ScheduledApexOnCase:execute]'+ex.getMessage()); 
          ApexLogHandler.createLogAndSave('ScheduledApexOnCase','execute', ex.getStackTraceString(), ex);
        }
    }
}