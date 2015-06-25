/**********************************************************************************
 * Appirio, Inc
 * Name: BatchAccountSubCode
 * Description: S-292550 - Population of CSDA Company Id, T-366637
 * Created Date: Mar 7th, 2015
 * Created By: Terri Kellough (Appirio)
 *
 * Summary:
 * - The purpose of this class is the populate the CSDA Company Id
 *   with the most recent account's subcode's company id.
 * - This is needed so it can be used on a formula field on the Account to
 *   create a web url to the CSDA business unit's Data Reporter.
 * - The most recent subcode associated with an account is determined by the subcode's Sub Code Id (an auto number)
 * - Subcodes are pushed to salesforce via a Boomi integration from the billing system
 *
 * Date Modified                Modified By                  Description of the update
 * Mar 8th, 2015                Terri Kellough               altered so most recent sub code is determined by Sub Code Id instead of CreatedDate
 * Apr 15th, 2015               Rohit B                      T-375000: Updated finish method to send mail to GCS team for error.
 * Apr 22nd, 2015               Terri Kellough               I-156565: Replaced ORDER BY Sub_Code_Id__c with ORDER BY Name
 * May 20th, 2015               Terri Kellough               I-163259: Refactored code to reduce CPU Limit Error
 * Jun 3rd, 2015                Paul Kissick                 Case #952245 - Fix for updating every single account!
 **********************************************************************************/

global class BatchAccountSubCode implements Database.Batchable<sObject> {


  global Database.QueryLocator start(Database.BatchableContext BC){
    //Get Account and the most recent sub code associated with the account
    //For now, the most recent sub code is determined by the Sub Code Id (auto number field) )
    //String query = 'SELECT Id, CSDA_Company_Id__c, '
    //                      + '(SELECT Id, Company_Id__c, Account__c, Sub_Code_ID__c FROM Sub_Codes__r WHERE Company_Id__c != null ORDER BY Name Desc Limit 1) '
    //             + 'FROM Account';
    String query = 'SELECT Id FROM Account';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Account> scope) {
    List<Account> accountsToUpdate = new List<Account>();
    List<Account> accounts = (List<Account>) scope;
    // PK Case #952245 - Added CSDA_Company_Id__c to query
    Map<Id, Account> accSubCodeLookup = new Map<Id, Account>([SELECT Id, CSDA_Company_Id__c, 
                                                              (SELECT Id, Company_Id__c 
                                                                FROM Sub_Codes__r 
                                                                ORDER BY NAME 
                                                                DESC LIMIT 1) 
                                                              FROM Account
                                                              WHERE Id In: scope]);


    for (Account a: (List<Account>) scope) {
      Account acc = accSubCodeLookup.get(a.Id);
      
      // PK Case #952245 - Refactored the code below to only update Sub Codes if they have changed on accounts.
      // Given that all accounts have now been updated (3rd Jun, '15), this should keep them up to date.
      
      if (acc.Sub_Codes__r != null && acc.Sub_Codes__r.size() > 0) {
        if (acc.Sub_Codes__r[0].Company_Id__c != acc.CSDA_Company_Id__c) {
          acc.CSDA_Company_Id__c = acc.Sub_Codes__r[0].Company_Id__c;
          accountsToUpdate.add(acc);
        }
      }
      else {
        if (acc.CSDA_Company_Id__c != null) {
          acc.CSDA_Company_Id__c = null;
          accountsToUpdate.add(acc);
        }
      }
    }
    update accountsToUpdate;
  }

  global void finish(Database.BatchableContext BC) {
      //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
      String GLOBAL_SETTING = 'Global';
      Global_Settings__c globalSetting = Global_Settings__c.getInstance(GLOBAL_SETTING);
      List<String> toAddresses = new List<String>();
      toAddresses.add(globalSetting.Batch_Failures_Email__c);
      //Added by Rohit B on 15/Apr/2015 for T-375000        --END--

      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];

      System.debug('\n[BatchAccountSubCode : finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

      if (a.NumberOfErrors > 0 || Test.isRunningTest()) {
          String emailBody = 'The Batch job to Update the Account\'s CSDA Company Id with the most recent sub code\'s company id is completed successful processing of '
                             + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' and generated ' + a.NumberOfErrors ;
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          mail.setSaveAsActivity(false);
          mail.setTargetObjectId(UserInfo.getUserId());
          mail.setSubject('Force.com BatchAccountSubCode Job Status');
          mail.setToAddresses(toAddresses);         //Added by Rohit B on 15/Apr/2015 for T-375000
          mail.setBccSender(false);
          mail.setUseSignature(false);
          mail.setPlainTextBody(emailBody);
          if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
          }
      }
  }

}