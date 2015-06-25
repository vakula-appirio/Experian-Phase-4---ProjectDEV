/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountType
 * Description: batch job to process all Account and define the Account Type value
 * Created Date: April 24th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jun 6th, 2014                Richard Joseph                Added logic to skip accounts with No_Longer_In_Business__c flag checked.
 * Aug 1st, 2014                Arpita Bose(Appirio)          T-286028: Modified method finish() to increase the code coverage in Test Class.
 =====================================================================*/
global class BatchAccountType implements Database.Batchable<sObject> {
  private static String prospect = 'Prospect';
  private static String formerClient = 'Former Client';
  private static String client = 'Client';

  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
  //[RJ] Added field No_Longer_In_Business__c
    return Database.getQueryLocator('SELECT Id, Account_Type__c,No_Longer_In_Business__c FROM Account');
  }
  
  //==============================================================
  // execute method
  //==============================================================
  global void execute(Database.BatchableContext BC, List<Account> scope) {
    System.debug('\n[BatchAccountType: execute] : Scope size: '+scope.size());
    List<Account>  accountList = (List<Account>) scope;
    List<Account> accountsToUpdate = new List<Account>();

    Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Account_Type__c,
                                    (SELECT Id, Contract_End_Date__c FROM Orders__r WHERE Total__c > 0)
                             FROM Account
                             WHERE Id in : accountList]);
    
    for (Account account : accountList) {
    //[RJ] Added Logic to skip No_Longer_In_Business__c check accounts
    if(!( account.No_Longer_In_Business__c))
    {
      Account acct = accountMap.get(account.Id);
      System.debug('\n[BatchAccountType : execute] START : accountId: '+ acct.Id + '; account client type: '+ acct.Account_Type__c);
      if (acct == null || acct.Orders__r == null || acct.Orders__r.size() == 0) {
        if (acct.Account_Type__c == null || !acct.Account_Type__c.equalsIgnoreCase(prospect)) {
          acct.Account_Type__c = prospect;
          accountsToUpdate.add(acct);
        }
      } else {
        String accountType = prospect;
        Date contractEndDate;
        for (Order__c ord: acct.Orders__r) {
          contractEndDate = ord.Contract_End_Date__c;
          if (contractEndDate > System.today().addYears(-1)) {
          	accountType = client;
            break;
          }
          if (contractEndDate < System.today().addYears(-1) && !accountType.equalsIgnoreCase(client)) {
            accountType = formerClient;
          }
        }
        if (acct.Account_Type__c == null || !acct.Account_Type__c.equalsIgnoreCase(accountType)) {
          acct.Account_Type__c = accountType;
          accountsToUpdate.add(acct);
        }
      }      
      System.debug('\n[BatchAccountType : execute] END : accountId: '+ acct.Id + '; account client type: '+ acct.Account_Type__c);
      }
    }
    try {
      update accountsToUpdate;
    } catch (Exception e) {
      ApexLogHandler.createLogAndSave('BatchAccountType','execute', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        System.debug('\nError when updating Account #' + i);
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

      String emailBody = 'The Batch Account Type job completed successful processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' and generated ' + a.NumberOfErrors;
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setSubject('Force.com Error Handler');
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setPlainTextBody(emailBody);
    if (a.NumberOfErrors > 0) {
      if (!Test.isRunningTest()) {  
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }
}