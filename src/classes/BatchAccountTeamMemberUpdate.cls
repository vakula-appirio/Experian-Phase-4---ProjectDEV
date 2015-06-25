/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountTeamMemberUpdate
 * Description: The following batch class is designed to be scheduled to run once every hour, in the class
                    'ScheduleAccountTeamMemberUpdate.cls'
                    This class will get the datetime from the Global setting 'Global' to see the last time the job was run
                    Then it selects all new account team members where the created date is greater than this last run time
                    It then creates account team members on accounts where they have an ultimate parent that has had the same
                    account team members addded to it since the last run time (gotten from the global setting)
                    Story:      S-123907
                    Task:       T-194927
 * Created Date: 
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 28th, 2014               Arpita Bose (Appirio)        T-267517: Remove references to ContactAccessLevel - Contact Sharing setting is set as 'Controlled by Parent'
 * Jun 02nd, 2014               Richard Joseph               Added a condition to retrieve only Active Account Team members in child Account. 
 * Aug 05th, 2014               Naresh Kr Ojha               T-286024: Updated code not to use constants class for any constant variable. Eg. GLOBAL_SETTING
 * Aug 06th, 2014               Naresh kr Ojha               T-256833: Updated execute method to create AccountShares for new team members added on child account
 * Nov 11th, 2014               Noopur                       I-138219: modified the where clause of query, it was checking where CreatedDate = lastRunTime. Changed it to
                                                             createdDate >= lastRunTime. 
 =====================================================================*/
global class BatchAccountTeamMemberUpdate implements Database.Batchable<sObject> {

  public static final String GLOBAL_SETTING = 'Global';   
  public Global_Settings__c lastRun = Global_Settings__c.getInstance(GLOBAL_SETTING);
  private DateTime holdRunTime = lastrun.Account_Team_Member_Job_Last_Run__c;
  private static String NA_CREDIT_SERVICES = 'NA Credit Services';
  private static String NA_DECISION_ANALYTICS = 'NA Decision Analytics';
    
  global Database.Querylocator start ( Database.Batchablecontext bc ) {
    DateTime lastRunTime = lastrun.Account_Team_Member_Job_Last_Run__c;
    lastRun.Account_Team_Member_Job_Last_Run__c = system.now();
    update lastRun;         // we need to implement functionality to roll this back if the batch was unsuccessful
    system.debug('*****lastRun*****' +lastRun);
            
    return Database.getQueryLocator ([SELECT Id, UserId, AccountId, AccountAccessLevel, 
                                             TeamMemberRole, IsDeleted, CreatedDate 
                                      FROM AccountTeamMember 
                                      WHERE User.IsActive= true
                                        AND User.Business_Line__c !=: NA_CREDIT_SERVICES
                                        AND User.Business_Line__c !=: NA_DECISION_ANALYTICS
                                        AND CreatedDate >= :lastRunTime]); // added User.IsActive condition.
  }

  global void execute (Database.BatchableContext bc, List<AccountTeamMember> scope) {
    Set<Id> accIds = new Set<Id>();

    Map<Id, List<AccountTeamMember>> accIdToListTeamMember = new Map <Id, List<AccountTeamMember>>();
    Map<String, AccountShare> accIdUserId_AccountShareMap = new Map<String, AccountShare>();

    for (AccountTeamMember atm : scope) {
      accIds.add(atm.accountId);         

      if (accIdToListTeamMember.containsKey(atm.accountId)) {
        //Add team member to the existing list (e.g. ATM2 to the list for A1)
        //Getting the key, and then adding the Account Team Member to the Account Team Member list
        accIdToListTeamMember.get(atm.accountId).add(atm);
      } else {
        //Add team member in a new list
        accIdToListTeamMember.put(atm.accountId, new List<AccountTeamMember>{atm});
      }
    }

    //Populating accountShare records in map
    AccountUtility.populateAccShareMap(accIdToListTeamMember.keySet(), accIdUserId_AccountShareMap);

      // Lists of AccountTeamMembers
      
      // At this stage we have a map containing account IDs, and related AccountTeamMembers to each account ID.
      // Each ID is unique thanks to the Set we created.
      
      //Select all child accounts where Ultimate parent is in accIds set
      // select all accounts where Ultimate parent Id = an id in the accIds set
      // could have an error here, accIds is a set of IDs, and we have not iterated through each value in it.
      System.debug('::accIds'+accIds);
      List<Account> childAccounts = new List<Account>();
      for (Account acc : [SELECT ID, Name, Ultimate_Parent_Account__c 
                          FROM Account 
                          WHERE Ultimate_Parent_Account__c =:accIds]) {
        childAccounts.add(acc);                      
      }
      // NOTE 18 CHAR IDS required on field in Salesforce for this to work correctly      
      
      //Team members that are against the child accounts that are to be created
      List<AccountTeamMember> teamMembersToInsert = new List<AccountTeamMember>();
      List<AccountShare> accountShareList = new List<AccountShare>();
      
      system.debug('*****childAccounts*****' +childAccounts);  
      //Iterate through the child accounts
      for (Account a : childAccounts) {
        //Retrieve the list of team members against the child accounts ultimate parent
        //List<AccountTeamMember> listOfTeamMembers = accIdToListTeamMember.get(a.UltimateParent?);
        
        //this line may not be correct
        
        // the .get means getting the ultimate parentID of the account (top level account in other words),
        // and retrieving it's associated Account Team Member List
        // this list needs to be copied, and then associated with all of the child accounts
        List<AccountTeamMember> listOfTeamMembers = accIdToListTeamMember.get(a.Ultimate_Parent_Account__c);
        AccountTeamMember newATM;
        AccountShare newShare;
        //Adding team members
        for (AccountTeamMember atm : listOfTeamMembers) {
          newATM = atm.clone();
          newATM.AccountId = a.Id;
          system.debug('*****newATM*****' +newATM);  
          // my addition to this piece, idea here is to add a team member to the teamMembersToInsert AccountTeamMember list.
          teamMembersToInsert.add(newATM);
          if (accIdUserId_AccountShareMap.containsKey(a.Ultimate_Parent_Account__c+'~~'+newATM.UserId)) {
            AccountShare masterShare = accIdUserId_AccountShareMap.get(a.Ultimate_Parent_Account__c+'~~'+newATM.UserId);
            
            newShare = new AccountShare();
            newShare.UserOrGroupId = atm.UserId;
            newShare.AccountId = a.ID;
            newShare.AccountAccessLevel = masterShare.AccountAccessLevel;
            newShare.OpportunityAccessLevel = masterShare.OpportunityAccessLevel;
            
            //T-267517:Remove references to ContactAccessLevel
            //newShare.ContactAccessLevel = accIdUserId_AccountShareMap.get(a.Ultimate_Parent_Account__c+'~~'+newATM.UserId).ContactAccessLevel;
            newShare.CaseAccessLevel = masterShare.CaseAccessLevel;
            system.debug('*****newShare*****' +newShare);
            accountShareList.add(newShare);
            
            
          }
        }
        
      }
      
      //Insert team members and account share records
      if (!teamMembersToInsert.isEmpty()) {      
        insert teamMembersToInsert;
      }
      if (!accountShareList.isEmpty()) {
        insert accountShareList;
      }
    }

    //To process things after finishing batch
    global void finish (Database.BatchableContext bc) {
      //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
      List<String> toAddresses = new List<String>();
      toAddresses.add(lastRun.Batch_Failures_Email__c);
      //Added by Rohit B on 15/Apr/2015 for T-375000        --END--

      AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id =: BC.getJobId()];
      
      System.debug('\n[BatchAccountTeamMemberUpdate: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

      if (a.NumberOfErrors > 0) {
        lastRun.Account_Team_Member_Job_Last_Run__c =holdRunTime;
        update lastRun; //only needs to have its value reset if there were errors
      }
      //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
      if (a.NumberOfErrors > 0 || Test.isRunningTest()) {
      String emailBody = 'The Batch job BatchAccountTeamMemberUpdate is completed successful processing of '
               + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
             + ' and generated ' + a.NumberOfErrors ;
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSaveAsActivity(false);
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSubject('Force.com BatchAccountTeamMemberUpdate Job Status');
      mail.setToAddresses(toAddresses);
      mail.setBccSender(false);
      mail.setUseSignature(false);
      mail.setPlainTextBody(emailBody);
      if (!Test.isRunningTest()) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
    //Added by Rohit B on 15/Apr/2015 for T-375000        --END--
    }
}