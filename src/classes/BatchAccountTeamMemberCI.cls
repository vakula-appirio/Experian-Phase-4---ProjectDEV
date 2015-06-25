/******************************************************************************
 * Appirio, Inc
 * Name: BatchAccountTeamMemberUpdate
 * Description:  Sync the Account Team Member with the sharing records on the Confidential Information.
 *
 *                  Story:      S-277737
 *                  Task:       T-357474
 * Created Date: Feb 03rd, 2015.
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Apr 15th, 2015               Rohit B                      T-375000: Updated finish method to send mail to GCS team for error.
 * May 5th, 2015                Nathalie Le Guay             Query only ATM where user is active
 * May 11th, 2015               Noopur                       I-162122 - modified the code to send failed record Ids in the email
 * Jun 17th, 2015               Naresh                       Updated finish method to have Test.isRunning check for sending mail.
 ******************************************************************************/
global class BatchAccountTeamMemberCI implements Database.Batchable<sObject>, Database.Stateful {

  public static final String GLOBAL_SETTING = 'Global';
  public Global_Settings__c lastRun = Global_Settings__c.getInstance(GLOBAL_SETTING);
  private DateTime holdRunTime = lastrun.Account_Team_Member_CI_Job_Last_Run__c;
  global Set<String> failedConInfoIDs = new set<String>(); 

  //=================================================
  // Query all ATM since last run
  //=================================================
  global Database.Querylocator start ( Database.Batchablecontext bc ) {
    DateTime lastRunTime = lastrun.Account_Team_Member_CI_Job_Last_Run__c;
    
    if ( Test.isRunningTest() ) {
      return Database.getQueryLocator ([SELECT Id, UserId, AccountId, AccountAccessLevel,
                                             TeamMemberRole, IsDeleted, CreatedDate
                                      FROM AccountTeamMember
                                      WHERE User.IsActive= true AND 
                                      ( CreatedDate >= :lastRunTime OR LastModifiedDate >: lastRunTime) limit 200]);
    }
    
    return Database.getQueryLocator ([SELECT Id, UserId, AccountId, AccountAccessLevel,
                                             TeamMemberRole, IsDeleted, CreatedDate
                                      FROM AccountTeamMember
                                      WHERE User.IsActive= true AND 
                                      ( CreatedDate >= :lastRunTime OR LastModifiedDate >: lastRunTime)]);
    
  }

  //===================================================================
  // Execute - will loop through ATM and provide access to CI records
  //===================================================================
  global void execute (Database.BatchableContext bc, List<AccountTeamMember> scope) {
    Set<ID> accountIDs = new Set<ID>();

    for (AccountTeamMember atm : (List<AccountTeamMember>) scope) {
      accountIDs.add(atm.AccountId);
    }
    synchAccountWithConfidentialInformation(accountIDs);    
  }

  //===================================================================
  // Finish - Revert update to Custom Settings if necessary
  //===================================================================
  //To process things after finishing batch
  global void finish (Database.BatchableContext bc) {
    //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
    List<String> toAddresses = new List<String>();
    toAddresses.add(lastRun.Batch_Failures_Email__c);
    //Added by Rohit B on 15/Apr/2015 for T-375000        --END--

    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                             TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =: BC.getJobId()];
    if (a.NumberOfErrors > 0 || Test.isRunningTest()) {
      Integer numberOfErrors = a.NumberOfErrors + failedConInfoIDs.size();
      if (a != null && a.NumberOfErrors <= 0) {
        lastRun.Account_Team_Member_CI_Job_Last_Run__c = system.now();
        update lastRun; //only needs to have its value reset if there were errors
      }
      //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
      else if (a != null && a.NumberOfErrors > 0 ) {
        String emailBody = 'The Batch job to Sync the Account Team Member with the sharing records on the Confidential Information is completed successful processing of '
                 + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
               + ' and generated ' + a.NumberOfErrors ;
      
	      if ( failedConInfoIDs != null && failedConInfoIDs.size() > 0) {
	        emailBody += '<br /> Confidential Information Share records insert failed: '; 
	        emailBody += '<table><tr ><td width="15%">Confidential Information Id</td><td width="15%">User Id</td><td width="*">Exception</td></tr>';
	        for (String currentRow : failedConInfoIDs) {
	          emailBody += currentRow;
	        }
	        emailBody += '</table>';       
	      }
	      //emailBody += '\nConfidential Information Share Insert failed for following Confidential Information records: ' + failedConInfoIDs;
	      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	      mail.setSaveAsActivity(false);
	      mail.setTargetObjectId(UserInfo.getUserId());
	      mail.setSubject('Force.com BatchAccountTeamMemberCI Job Status');
	      mail.setToAddresses(toAddresses);
	      mail.setBccSender(false);
	      mail.setUseSignature(false);
	      mail.setPlainTextBody(emailBody);
	      mail.setHtmlBody(emailBody);
	      if (numberOfErrors > 0 && !Test.isRunningTest()) {
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	      }
      }
    }
    //Added by Rohit B on 15/Apr/2015 for T-375000        --END--
  }

  //===================================================================
  // Delete Shares and recreate them
  //===================================================================
  private void synchAccountWithConfidentialInformation (Set<Id> accountIDs) {
    List<Confidential_Information__c> confInfoList = new List<Confidential_Information__c>();
    List<Confidential_Information__Share> confShares = new List<Confidential_Information__Share>();
    
    for (Confidential_Information__c confidential : [SELECT Id, Account__c,
                                                            (SELECT Id
                                                             FROM Shares
                                                             WHERE RowCause = 'Account_Team__c')//Constants.ROWCAUSE_ACCOUNT_TEAM)
                                                     FROM Confidential_Information__c
                                                     WHERE Account__c IN: accountIDs
                                                           AND Synch_Account_Team_Members__c = true]) {
      confInfoList.add(confidential);
      if (confidential.Shares.size() > 0) {
        confShares.addAll(confidential.Shares);
      }
    }

    if (confShares.size() > 0) {
      Database.delete(confShares, false);
    }

    createConfidentialInfoShare (accountIDs, confInfoList);
  }

  //============================================================================
  // Create Confidentials Information shares
  //============================================================================
  public void createConfidentialInfoShare(Set<ID> accountIDs, List<Confidential_Information__c> filteredConfInfos) {

    Map<String, Account> accountID_AccountMap = new Map<String, Account>();
    Map<String, AccountShare> accIdUid_accShareMap = new Map<String, AccountShare>();

    failedConInfoIDs = new set<String>();
    // Getting Account share record
    for (Account account : [SELECT Id,
                                   (SELECT UserOrGroupId, RowCause, OpportunityAccessLevel, Id,
                                           ContactAccessLevel, CaseAccessLevel, AccountId,
                                           AccountAccessLevel
                                    FROM Shares),
                                   (SELECT UserId, TeamMemberRole, Id,
                                           AccountId, AccountAccessLevel, User.Name
                                    FROM AccountTeamMembers
                                    WHERE User.IsActive = true)
                            FROM Account
                            WHERE Id IN: accountIDs]) {
        accountID_AccountMap.put(account.ID, account);
        for (AccountShare accShare : account.Shares) {
          if (!accIdUid_accShareMap.containsKey(account.ID + '~~' + accShare.UserOrGroupId)) {
            accIdUid_accShareMap.put(account.ID + '~~' + accShare.UserOrGroupId, accShare);
          }
        }
      }

      // Creating the Confidential_Information__Share according to the AccountShare
      List<Confidential_Information__Share> confInfoShares = new List<Confidential_Information__Share>();
      Confidential_Information__Share newConfInfoShare;
      for (Confidential_Information__c confInfo : filteredConfInfos) {
        for (AccountTeamMember teamMember : accountID_AccountMap.get(confInfo.Account__c).AccountTeamMembers) {
          String accessLevel = 'Read'; //Constants.ACCESS_LEVEL_READ; //Default to be set.

          if (accIdUid_accShareMap.containsKey(teamMember.AccountID + '~~' + teamMember.UserId)) {
            accessLevel = accIdUid_accShareMap.get(teamMember.AccountID + '~~' + teamMember.UserId).AccountAccessLevel;
          }
          // All access level is not on the ConfInfoShare picklist so it will have edit.
          if (accessLevel == 'All') {//Constants.ACCESS_LEVEL_ALL) {
            accessLevel = 'Edit'; //Constants.ACCESS_LEVEL_EDIT;
          }

          System.debug('[ConfidentialInformationTriggerHandler:CreateShares][~~~~teamMember.UserId~~~]:'+teamMember.UserId+'--[~~~accessLevel~~~]:'+accessLevel);

          newConfInfoShare = new Confidential_Information__Share();

          newConfInfoShare.AccessLevel    = accessLevel;
          newConfInfoShare.ParentId       = confInfo.Id;
          newConfInfoShare.RowCause       = Constants.ROWCAUSE_ACCOUNT_TEAM;
          newConfInfoShare.UserOrGroupId  = teamMember.UserId;
          confInfoShares.add(newConfInfoShare);
          System.debug('\n[ConfidentialInformationTriggerHandler:CreateShares]Creating new Share: '+ newConfInfoShare);
        }
      }
      // Insert confidentials information share records
      if (!confInfoShares.isEmpty()) {
        
        List<Database.SaveResult> insertedConInfoShares = Database.insert(confInfoShares, false);
        Set<String> succeededRecrds = new Set<String>();
        
        for(Integer i = 0; i < insertedConInfoShares.size(); i++){
  
          if (insertedConInfoShares.get(i).isSuccess()){
            succeededRecrds.add(insertedConInfoShares.get(i).getId());
          }
          else if (!insertedConInfoShares.get(i).isSuccess()){
            // DML operation failed
            Database.Error error = insertedConInfoShares.get(i).getErrors().get(0);
            String failedDML = error.getMessage();
            //confInfoShares.get(i);//failed record from the list
            //system.debug('Failed ID'+confInfoShares.get(i).ParentId);
            
            //String failedDML = 'This is not an error, testing is going on: nojha';
            String errorStr = '<tr><td>' + confInfoShares.get(i).ParentId + '</td><td>' + confInfoShares.get(i).UserOrGroupId + '</td>';
            errorStr += '<td>' + failedDML + '</td></tr>';
            failedConInfoIDs.add(errorStr);
          }
        }
        System.debug('===failedConInfoIDs.0=='+failedConInfoIDs);
      }
   }
}