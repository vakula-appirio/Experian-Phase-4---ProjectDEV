/**=====================================================================
 * Appirio, Inc
 * Name: BatchSegmentType
 * Description: T-371862
 * Created Date: Mar 19th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Apr 14th, 2015               Naresh Kr Ojha               T-375000: Updated finish method to send error mail to GCS team
 * Apr 27th, 2015               Noopur                       Update batch to fix setting the Relationship Type field
 * Apr 27th, 2015               Nathalie Le Guay             Refactoring batch to remove unnecessary structures
 * Apr 28th, 2015               Nathalie Le Guay             Removing "Free Trial" orders from the query results
 * May 11th, 2015               Noopur                       I-162122 - modified the code to send failed record Ids in the email
 * Jun 3rd, 2015                Paul Kissick                 Case #926385 - Prod Fixes for P3 - Fixed null exception
 * Jun 3rd, 2015                Arpita Bose                  I-166329: added check for Clientset 
 =====================================================================*/
global class BatchSegmentType implements Database.Batchable<sObject>, Database.Stateful {
  private static String client = 'Client';
  private static String formerClient = 'Former Client';
  private static String FREE_TRIAL = 'Free Trial';
  global Boolean runAllOrders = false;
  global Set<String> failedAccountSegmentRdcrdIDs;  
  
  private static Set<String> fieldNameSet = new Set<String> {
                                               'Segment_Global_Business_Line__c',
                                               'Segment_Business_Line__c',
                                               'Segment_Business_Unit__c',
                                               'Segment_Region__c',
                                               'Segment_Country__c'};

  global BatchSegmentType(Boolean runAllOrders) {
    this.runAllOrders   = runAllOrders;
  }

  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
    Date startDate = System.today().addYears(-1);
    // This will allow us to process Orders up to 10 times, to allow to catch any failure to the update
    startDate = startDate.addDays(-10);
    Date endDate = System.today().addYears(-1);
    
    if ( Test.isRunningTest() ) {
      return Database.getQueryLocator([SELECT Id, Account__c
                                     FROM Order__c
                                     WHERE Contract_End_Date__c >: startDate 
                                     AND Type__c !=: FREE_TRIAL
                                     AND Contract_End_Date__c <=: System.today() ORDER BY Account__c
                                     limit 200]);
    }
    if (runAllOrders) {
      return Database.getQueryLocator([SELECT Id, Account__c
                                     FROM Order__c 
                                     WHERE Type__c !=: FREE_TRIAL
                                     ORDER BY Account__c]);
    }

    return Database.getQueryLocator([SELECT Id, Account__c
                                     FROM Order__c
                                     WHERE Contract_End_Date__c >: startDate
                                     AND Type__c !=: FREE_TRIAL
                                     AND Contract_End_Date__c <=: System.today() ORDER BY Account__c]);
  }

  //==============================================================
  // execute method
  //==============================================================
  global void execute(Database.BatchableContext BC, List<Order__c> scope) {
    List<Order__c>  orderList = (List<Order__c>) scope;
    Set<Id> accIds = new Set<Id>();
    Set<Id> previousClientSet = new Set<Id>();
    set<Id> clientSet = new set<Id>();
    List<Account_Segment__c> lstAccSegToUpdate = new List<Account_Segment__c>();
    system.debug('====orderList>>>' +orderList);

    for (Order__c ordr : orderList) {
        if (ordr.Account__c <> null) {
          accIds.add(ordr.Account__c);
        }
    }

    for (Order__c orderRec : [SELECT Id, // Owner_Global_Business_Line__c, Owner_Business_Unit__c,
                                Contract_End_Date__c, Account__c, Opportunity__c, Segment_Region__c,
                                Segment_Global_Business_Line__c, Segment_Country__c,
                                Segment_Business_Unit__c,
                                Segment_Business_Line__c
                              FROM Order__c
                              WHERE Account__c IN : accIds
                                AND Type__c !=: FREE_TRIAL
                                AND Contract_End_Date__c != null]) {
      System.debug('\n[BatchSegmentType: execute] Going through Order:\n' + orderRec);

      // If the order's End Date is within the past year for the given Account Segment,
      // the Account can be considered a 'Client'
      if ( orderRec.Contract_End_Date__c <= System.today().addYears(-1)) {
        for (String fieldName: fieldNameSet) {
          if ((Id) orderRec.get(fieldName) != null) {
            previousClientSet.add((Id) orderRec.get(fieldName));
          }
        }
      }
      // Otherwise, we will add the order to the 'previous client' bucket
      else if ( orderRec.Contract_End_Date__c > System.today().addYears(-1)){
        for (String fieldName: fieldNameSet) {
          if ((Id) orderRec.get(fieldName) != null) {
            clientSet.add ((Id) orderRec.get(fieldName) );
          }
        }
      }
    }

    for (Account_Segment__c accSeg : [SELECT Id, Name, Segment__c, Relationship_Type__c, Account__c
                                      FROM Account_Segment__c
                                      WHERE Account__c IN :accIds 
                                      AND (Id IN: previousClientSet
                                      OR Id IN :clientSet)]) {
      if (accSeg.Id <> null ) {
        // If the account segment is considered to be a 'client'
        if ( clientSet.contains(accSeg.Id) &&
            (String.isEmpty(accSeg.Relationship_Type__c) || !accSeg.Relationship_Type__c.equalsIgnoreCase(client))) {
          accSeg.Relationship_Type__c = client;
          lstAccSegToUpdate.add(accSeg);
        }
        // If the account segment isn't considered to be a 'client'
        //I-166329 added check for clientset
        else if (previousClientSet.contains(accSeg.Id) && !clientSet.contains(accSeg.Id)) {
          if (String.isEmpty(accSeg.Relationship_Type__c) || !accSeg.Relationship_Type__c.equalsIgnoreCase(formerClient)) {
            // update Relationship_Type__c to 'Former Client'
            accSeg.Relationship_Type__c = formerClient;
            lstAccSegToUpdate.add(accSeg);
          }
        }
      }
    }
    system.debug('lstAccSegToUpdate>>>' +lstAccSegToUpdate);
    //try {
    
      failedAccountSegmentRdcrdIDs = new set<String> ();
      
      List<Database.SaveResult> updatedSegmentsResult = Database.update(lstAccSegToUpdate, false);
      Set<String> succeededRecrds = new Set<String>();
      
      for(Integer i = 0; i < updatedSegmentsResult.size(); i++){

        if (updatedSegmentsResult.get(i).isSuccess()){
          succeededRecrds.add(updatedSegmentsResult.get(i).getId());
        }
        else if (!updatedSegmentsResult.get(i).isSuccess()){
          // DML operation failed
          Database.Error error = updatedSegmentsResult.get(i).getErrors().get(0);
          String failedDML = error.getMessage();

          system.debug('Failed ID'+lstAccSegToUpdate.get(i).Id);
          
          String failedStr = '<tr><td>' + lstAccSegToUpdate.get(i).Id + '</td><td>' + lstAccSegToUpdate.get(i).Name + '</td><td>' + failedDML + '</td></tr>';
          failedAccountSegmentRdcrdIDs.add(failedStr);
        }
      }
      System.debug('===failedAccountSegmentRdcrdIDs.0=='+failedAccountSegmentRdcrdIDs);
    /* If exception, will send email to GCS team
    } catch(DMLException e) {
        ApexLogHandler.createLogAndSave('BatchSegmentType','execute', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
          System.debug('\nError when updating Account_Segment__c #' + i);
        }
    }*/
  }


  //==============================================================
  // finish method
  //==============================================================
  global void finish(Database.BatchableContext BC) {
    String GLOBAL_SETTING = 'Global';
    Global_Settings__c globalSetting = Global_Settings__c.getInstance(GLOBAL_SETTING);
    List<String> toAddresses = new List<String>();
    toAddresses.add(globalSetting.Batch_Failures_Email__c);
    
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                             TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =: BC.getJobId()];
    
    Integer numberOfError = a.NumberOfErrors;
    if (failedAccountSegmentRdcrdIDs != null && failedAccountSegmentRdcrdIDs.size() > 0) {
      numberOfError += failedAccountSegmentRdcrdIDs.size();
    }
    
    System.debug('\n[BatchSegmentType: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

    String emailBody = 'The BatchSegmentType batch job completed the processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' batches, and generated ' + a.NumberOfErrors + ' error(s).';
    //emailBody += '\nAccount Segments failed on update: ' + failedAccountSegmentRdcrdIDs;
    
    if (failedAccountSegmentRdcrdIDs != null && failedAccountSegmentRdcrdIDs.size() > 0) {
      emailBody += '<br />Account Segments failed on update: <br />';
      emailBody += '<table><tr width="20%"><td>Record Id</td><td width="30%">Name</td><td width="*">Exception</td></tr>';
      for (String currentRow : failedAccountSegmentRdcrdIDs) {
        emailBody += currentRow;
      }
      emailBody += '</table>';
    }
    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setToAddresses(toAddresses);
    mail.setSubject('Force.com Batch Error: BatchSegmentType');
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setPlainTextBody(emailBody);
    mail.setHtmlBody(emailBody);
    if (numberOfError > 0) {
      if (!Test.isRunningTest()) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }

}