/*======================================================================================
 * Experian Plc.
 * Name: BatchUserLastActivityUpdate
 * Description: Case #5237 - Batch job to update the Days since Activity field based on 
 * 						     LastLoginDate
 * Created Date: July 30th, 2014
 * Created By: James Weatherall
 * 
 * Date Modified                Modified By                  Description of the update
 * 
 =======================================================================================*/

global class BatchUserLastActivityUpdate implements Database.Batchable<sObject> {
  global String query;
  
  global BatchUserLastActivityUpdate(String paramQuery)
  {
    query = paramQuery;  
  }
    
  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }
  
  //==============================================================
  // execute method
  //==============================================================
  global void execute(Database.BatchableContext BC, List<User> scope) {
    System.debug('\n[BatchUserLastActivityUpdate: execute] : Scope size: '+scope.size());
    List<User>  userList = (List<User>)scope;
    List<User> usersToUpdate = new List<User>();
    Integer daysSinceActivity;
    Date lastLogin;  
      
    for(User user : userList)
    {
      System.debug('\n[BatchUserLastActivityUpdate: execute] : LastLoginDate : '+user.LastLoginDate);
      lastLogin = Date.valueOf(user.LastLoginDate);
      System.debug('\n[BatchUserLastActivityUpdate: execute] : Days Between : '+lastLogin.daysBetween(system.today()));
      daysSinceActivity = lastLogin.daysBetween(system.today());
      user.Days_since_Activity__c = daysSinceActivity;
      usersToUpdate.add(user);
    }
    
    try {
      update usersToUpdate;
    } catch (Exception e) {
      ApexLogHandler.createLogAndSave('BatchUserLastActivityUpdate','execute', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        System.debug('\nError when updating User #' + i);
      }
    }
  }

  //==============================================================
  // finish method
  //==============================================================
  global void finish(Database.BatchableContext BC) {
    
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];
      
    System.debug('\n[BatchAccountType: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

    if (a.NumberOfErrors > 0) {
      String emailBody = 'The Batch User Last Activity Update job completed successful processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' and generated ' + a.NumberOfErrors;
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
      mail.setSaveAsActivity(false);
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSubject('Force.com Error Handler');
      mail.setBccSender(false);
      mail.setUseSignature(false);
      mail.setPlainTextBody(emailBody);
      if (!Test.isRunningTest()) {  
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }  
}