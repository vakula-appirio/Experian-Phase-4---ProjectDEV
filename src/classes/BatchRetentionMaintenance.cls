/**=====================================================================
 * Appirio, Inc
 * Name: BatchRetentionMaintenance
 * Description: T-335169: Batch to delete old Retention Line Items records that belong to 
                historical months, to keep data volumes low
                Historical months are all the months that are prior to the previous fiscal year's start date
 * Created Date: Nov 19th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 *  
 =====================================================================*/
global class BatchRetentionMaintenance implements Database.Batchable<sObject> {
  public static final String GLOBAL_SETTING = 'Global';
  public Retention_Settings__c lastRun = Retention_Settings__c.getInstance(GLOBAL_SETTING);
  private Date holdRunDate = lastrun.Last_RLI_Removal_Batch_Run__c;
  public Integer currentYear = System.Today().year();
  public Integer currentMonth = System.Today().month(); 
   
  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
  	// retrieve Retention__c records for historical month 	
    return Database.getQueryLocator ([SELECT Id, Lock__c 
                                      FROM Retention__c
                                      WHERE ((Year__c <= :(currentYear - 3))
                                      OR (Year__c =:(currentYear - 2) AND Month__c <= :(currentMonth - 1)))
                                      AND Lock__c = :false]); 
  }
  
  //==============================================================
  // execute method
  //==============================================================
  global void execute(Database.BatchableContext BC, List<Retention__c> scope) {
    System.debug('\n[BatchRetentionMaintenance: execute] : Scope size: '+scope.size());
    List<Retention__c> retentionIds = new List<Retention__c>();
    List<Retention_Line_Item__c> rliToDelete = new List<Retention_Line_Item__c>();
    Savepoint sp = Database.setSavepoint();
    try {
	    //Set Retention__c records to Locked
	    for (Retention__c ret : scope) {
	      ret.Lock__c = true;
	      retentionIds.add(ret);
	    }
    
	    if (retentionIds.size() > 0) {
	      update retentionIds;
	    }
		    // get RetentionLineItem for Locked Retention records
		    for (Retention_Line_Item__c rli : [SELECT Id FROM Retention_Line_Item__c WHERE Retention__c IN :retentionIds]){
		    	rliToDelete.add(rli);
		    }
		    try {
		      if (rliToDelete.size() > 0) {
		        delete rliToDelete;
		      }
	      } catch (Exception e) {
	        ApexLogHandler.createLogAndSave('BatchRetentionMaintenance','execute', e.getStackTraceString(), e);
	        for (Integer i = 0; i < e.getNumDml(); i++) {
	          System.debug('\nError when deleting Retention Line Item #' + i);
	        }
	      }
    } catch (Exception e) {
      Database.rollback(sp);
      ApexLogHandler.createLogAndSave('BatchRetentionMaintenance','execute', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        System.debug('\nError when deleting Retention Line Item #' + i);
      }
    }
    
  }
  
  //==============================================================
  // finish method
  //==============================================================
  global void finish(Database.BatchableContext BC) {
    
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                      TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob 
                      WHERE Id =: BC.getJobId()];
     
    System.debug('\n[BatchRetentionMaintenance: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');
    
    String emailBody = 'The Batch Retention Line Item job completed the successful processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' batch(es) and generated ' + a.NumberOfErrors + ' error(s).';
                                        
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setSubject('Retention Maintenance Batch Results');
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setPlainTextBody(emailBody);
    
    //On success
    if (a.NumberOfErrors == 0) {
    	// custom setting will hold the date for which the Retention line Items were deleted
    	Date lastRunDate = lastrun.Last_RLI_Removal_Batch_Run__c;
      lastRun.Last_RLI_Removal_Batch_Run__c = Date.newInstance((currentYear - 2), (currentMonth - 1), 1);
      update lastRun;
      system.debug('****lastRun***' +lastRun);
      
      // if Receive_Email_Notification__c field on the custom setting is TRUE, send an email
      if (lastRun.Receive_Email_Notification__c == true){
      	if (!Test.isRunningTest()) {  
          Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
      }
    }
    //On failure: send an email notification
    if (a.NumberOfErrors > 0) {
      lastRun.Last_RLI_Removal_Batch_Run__c = holdRunDate;
      update lastRun;
      if (!Test.isRunningTest()) {  
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }

}