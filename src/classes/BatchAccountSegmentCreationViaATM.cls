/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountSegmentCreationViaATM
 * Description: T-376237: Account Segmentation: Account Team Member batch.
 *                        Batch creates Account Segment records on the basis of new 
 *                        Account Team Members created.
 *
 * Created Date: April 7th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * Apr 13th, 2015           Nathalie Le Guay            Updated to populate Parent_Segment_Account__c
 * Apr 14th, 2015           Naresh Kr Ojha              As per T-375000 Updated finish method to 
 *                                                      send mail on error to GCS team email address
 * Apr 15th, 2015           Nathalie Le Guay            Change segment keys to be AccountId + segmentType + segmentValue
 ======================================================================*/
global class BatchAccountSegmentCreationViaATM implements Database.Batchable<sObject>, Database.Stateful {
  
  public static final String GLOBAL_SETTING = 'Global';
  public Global_Settings__c lastRun = Global_Settings__c.getInstance(GLOBAL_SETTING);
  private DateTime holdRunTime = lastrun.AccSegmentCreationViaATM_Job_Last_Run__c;
  global Set<String> failedAccSegmentInsertRecords;

  // User fields, by 'level' in which we want to create them
  private static Set<String> level3Fields = new Set<String>{
                                                   'Global_Business_Line__c',
                                                   'Region__c', 'Country__c'
                                                   };
  private static Set<String> level2Fields = new Set<String>{'Business_Line__c'};
  private static Set<String> level1Fields = new Set<String>{'Business_Unit__c'};
  private static Integer level = 3;

  // User fields used for segmentation
  private static Map<String, String> segmentFieldNames = new Map<String, String>{
                                                  'Global_Business_Line__c'=>'Global Business Line',
                                                  'Business_Line__c'=>'Business Line',
                                                  'Business_Unit__c'=>'Business Unit',
                                                  'Region__c'=>'Region',
                                                  'Country__c'=>'Country'
                                                 };
  // Store Account Segments that are either in the db or to be created
  private static map<String, Account_Segment__c> accountSegmentMap;
  // Used to populate Account_Segment__c.Segment__c
  private static map<String, Hierarchy__c> hierarchyMap;

  //=================================================
  // Query all ATM since last run
  //=================================================
  global Database.Querylocator start ( Database.Batchablecontext bc ) {
    DateTime lastRunTime = lastrun.AccSegmentCreationViaATM_Job_Last_Run__c;
    if (lastRunTime == null) {
      lastRunTime = Date.newInstance(1970, 01, 01);
    }
    
    if ( Test.isRunningTest() ) {
      return Database.getQueryLocator ([SELECT Id, UserId, AccountId, AccountAccessLevel,
                                             TeamMemberRole, IsDeleted, CreatedDate,
                                             User.Business_Line__c, User.Business_Unit__c,
                                             User.Global_Business_Line__c, User.Country__c,
                                             User.Region__c, Account.Name
                                      FROM AccountTeamMember
                                      WHERE CreatedDate >= :lastRunTime 
                                      OR LastModifiedDate >: lastRunTime
                                      ORDER BY AccountId limit 200]);
    }

    return Database.getQueryLocator ([SELECT Id, UserId, AccountId, AccountAccessLevel,
                                             TeamMemberRole, IsDeleted, CreatedDate,
                                             User.Business_Line__c, User.Business_Unit__c,
                                             User.Global_Business_Line__c, User.Country__c,
                                             User.Region__c, Account.Name
                                      FROM AccountTeamMember
                                      WHERE CreatedDate >= :lastRunTime 
                                      OR LastModifiedDate >: lastRunTime
                                      ORDER BY AccountId]);
  }

  //===================================================================
  // Execute - will loop through ATM and provide access to 
  //===================================================================
  global void execute (Database.BatchableContext bc, List<AccountTeamMember> scope) {
    set<Id> accIds = new set<Id>();
    set<String> segmentValues = new set<String>();
    accountSegmentMap = new map<String,Account_Segment__c>();
    hierarchyMap = new map<String,Hierarchy__c>();
    List<Account_Segment__c> newAccountSegments = new List<Account_Segment__c>();
    failedAccSegmentInsertRecords = new Set<String>();
    
    // Gather all the user record's segment values
    for ( AccountTeamMember atm : scope ) {
      User atmUser = atm.User;
      accIds.add(atm.AccountId);
      for (String segmentName : segmentFieldNames.keySet()) {
        segmentValues.add((String) atmUser.get(segmentName));
      }
    }

    // Store Hierarchy and Account Segment in structures
    String accountSegmentMapString = '';
    String hierarchyMapString = '';
    for ( Hierarchy__c hr : [SELECT Id, Value__c, Name , Parent__r.Value__c, 
                                    Parent__r.Type__c, Parent__r.Name, Parent__c
                             FROM Hierarchy__c
                             WHERE Value__c IN :segmentValues]) {
      hierarchyMap.put(hr.Name , hr);
      hierarchyMapString += '\n' + hr.Name;
    }

    for ( Account_Segment__c accSeg : [SELECT Id, Name, Account__c, Segment__c,
                                              Segment__r.Value__c, Segment__r.Name, Account__r.Name
                                       FROM Account_Segment__c
                                       WHERE Account__c IN :accIds
                                       AND Segment__r.Value__c IN :segmentValues]) {
      String key = accSeg.Account__c + '-' + accSeg.Segment__r.Name;
      if ( segmentValues.contains(accSeg.Segment__r.Value__c) ) {
        accountSegmentMap.put(key , accSeg);
        accountSegmentMapString += '\n'+key;
      }
    }
    system.debug('\n[BatchAccountSegmentCreationViaATM: execute]==> hierarchyMapString:'+hierarchyMapString);
    system.debug('\n[BatchAccountSegmentCreationViaATM: execute]==> accountMapString: '+ accountSegmentMapString);


    // This will create the 3 levels of Account Segment hierarchy
    while (level > 0) {
      processATMByLevel((List<AccountTeamMember>) scope);
      level--;
    }

  }


  //========================================================================
  // Method to create Account Segments level by level
  //========================================================================
  public void processATMByLevel(List<AccountTeamMember> atms) {
    List<Account_Segment__c> newSegments = new List<Account_Segment__c>();
    if (level == 3) {
      newSegments = processATM(atms, level3Fields); // GBL/Region/Country first
    }
    if (level == 2) {
      newSegments = processATM(atms, level2Fields); // BL
    }
    if (level == 1) {
      newSegments = processATM(atms, level1Fields); // BU
    }

    // Insert records and store them in map to reference them as parents for other Account Segments
    List<Database.Saveresult> segmentInsertResults = Database.insert(newSegments, false);
    
    for(Integer i = 0; i < segmentInsertResults.size(); i++){
      if (!segmentInsertResults.get(i).isSuccess()) {
        // DML operation failed
        Database.Error error = segmentInsertResults.get(i).getErrors().get(0);
        String failedDML = error.getMessage();
        String errorStr = '<tr><td>' + newSegments.get(i).Account__c + '</td><td>' + newSegments.get(i).Type__c + '</td>';
        errorStr += '<td>' + newSegments.get(i).Value__c + '</td><td>' + failedDML + '</td></tr>';
        
        failedAccSegmentInsertRecords.add(errorStr);
        
      } else if(segmentInsertResults.get(i).isSuccess()) {
        Account_Segment__c accSegment = newSegments.get(i); 
        accountSegmentMap.put(accSegment.Account__c + '-' + accSegment.Type__c + '-' + accSegment.Value__c, accSegment);
      }
    }
    /*
    for (Account_Segment__c accSegment: newSegments) {
      accountSegmentMap.put(accSegment.Account__c + '-' + accSegment.Type__c + '-' + accSegment.Value__c, accSegment);
    }
    */
  }

  //========================================================================
  // Method to create - if necessary - and add new Account Segments to a map
  //========================================================================
  private static List<Account_Segment__c> processATM(List<AccountTeamMember> atms,  Set<String> segmentNames) {
    List<Account_Segment__c> newSegments = new List<Account_Segment__c>();
    User user;
    for (AccountTeamMember atm: atms) {
      user = atm.User;

      for (String segmentName: segmentNames) {
        if (!String.isEmpty((String) user.get(segmentName))) {
          String key = atm.AccountId + '-' + segmentFieldNames.get(segmentName) + '-' + user.get(segmentName);
          String segmentType = segmentFieldNames.get(segmentName);

          // Create an Account Segment if one does not exist yet for the Account+type+value
          if (!accountSegmentMap.containsKey(key)) {
            Account_Segment__c segment = createAccountSegmentRecord(atm, (String) user.get(segmentName), segmentType);
            if (segment != null) {
              newSegments.add(segment);
            }
          }
        }
      }
    }
    return newSegments;
  }


  //===================================================================
  // Method to create Account Segment if it does not exist already
  //===================================================================
  private static Account_Segment__c createAccountSegmentRecord( AccountTeamMember atm, String segmentName, String segmentType) {
    Account_Segment__c accSeg;
    String key = atm.AccountId + '-' + segmentType + '-' + segmentName;
    String hierarchyKey = segmentType + '-' + segmentName;
    system.debug('\n[BatchAccountSegmentCreationViaATM: createAccountSegmentRecord]==> FULL Key: ' + key + ' and hierarchy key:' + hierarchyKey);
    String accSegName = atm.Account.Name.length() > 20? atm.Account.Name.subString(0,19)+'-'+segmentName :atm.Account.Name+'-'+segmentName;

    if( !accountSegmentMap.containsKey(key) && hierarchyMap != null && hierarchyMap.containsKey(hierarchyKey)) {

      String parentSegKey = (hierarchyMap != null && hierarchyMap.containsKey(hierarchyKey) && hierarchyMap.get(hierarchyKey).Parent__c != null) ?
                            atm.AccountId + '-'+ hierarchyMap.get(hierarchyKey).Parent__r.Name : '';

      accSeg = new Account_Segment__c();
      accSeg.Name = accSegName;
      accSeg.CurrencyIsoCode = 'USD';
      accSeg.Account__c = atm.AccountId;
      accSeg.Relationship_Type__c = 'Prospect'; // Cannot call Constants as it will no longer be modifiable if this batch is scheduled
      accSeg.Segment__c = hierarchyMap.get(hierarchyKey).Id;
      accSeg.Type__c = segmentType; // Will be overriden by the WF Rule, but useful to populate accountSegmentMap
      accSeg.Value__c = hierarchyMap.get(hierarchyKey).Value__c;
      
      // Populating the Parent Account Segment here
      system.debug('====Parent key==='+parentSegKey + '====accountSegmentMap==='+accountSegmentMap.get(parentSegKey));
      if ( parentSegKey != '' && accountSegmentMap.containsKey(parentSegKey) ) {
        accSeg.Parent_Account_Segment__c = accountSegmentMap.get(parentSegKey).Id;
      }
      system.debug('----'+accSegName+'===='+accSeg.Parent_Account_Segment__c);

      accountSegmentMap.put(key, accSeg);
    }
    return accSeg;
  }

  //===================================================================
  // Finish - Revert update to Custom Settings if necessary
  // Send error email if error during the processing
  //===================================================================
  global void finish (Database.BatchableContext bc) {
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                             TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =: BC.getJobId()];
    
    Integer numberOfErrors;
    if ( failedAccSegmentInsertRecords != null) {
     numberOfErrors = a.NumberOfErrors + failedAccSegmentInsertRecords.size();
    }
    System.debug('\n[BatchAccountSegmentCreationViaATM: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ numberOfErrors + ' failures.]]');
    List<String> toAddresses = new List<String>();
    toAddresses.add(lastrun.Batch_Failures_Email__c);
    String emailBody = 'The BatchAccountSegmentCreationViaATM batch job processed of ' + a.JobItemsProcessed + ' batch out of ' + a.TotalJobItems
                       + ', and generated ' + a.NumberOfErrors + ' error(s).';
    if (failedAccSegmentInsertRecords != null && failedAccSegmentInsertRecords.size() > 0) {
      emailBody += '<br />Account Segment record insert failed : ';  
      emailBody += '<table><tr ><td width="15%">Account Id</td><td width="15%">Type</td><td width="15%">Value</td><td width="*">Exception</td></tr>';
      for (String currentRow : failedAccSegmentInsertRecords) {
        emailBody += currentRow;
      }
      emailBody += '</table>';
    }
        
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setToAddresses(toAddresses);
    mail.setSubject('Force.com Error Handler');
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setHtmlBody(emailBody);
    mail.setPlainTextBody(emailBody);
    
    if (numberOfErrors > 0) {
      if (!Test.isRunningTest()) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }

    if (a.NumberOfErrors <= 0) {
      lastRun.AccSegmentCreationViaATM_Job_Last_Run__c = system.now();
      update lastRun; //only needs to have its value reset if there were errors
    }     
    
  }

}