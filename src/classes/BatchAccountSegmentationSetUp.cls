/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountSegmentationSetUp
 * Description: Batch job for go-live
 * Created Date: Apr 3rd, 2015
 * Created By: Noopur Sundariyal
 *
 * Date Modified                Modified By                  Description of the update
 * Apr 14th, 2015               Naresh Kumar Ojha            T-375000: Updated finish method to send mail to GCS team for error.
 * Apr 28th, 2015               Arpita Bose                  Updated the query of Opportunity to fix test class failure
 * May 11th, 2015               Naresh Kumar Ojha            I-162122: Modified batch class to have Stageful interface.
 =====================================================================*/
global class BatchAccountSegmentationSetUp implements  Database.Batchable<sObject>, Database.Stateful {

  global boolean runAccountSegmentCreationAndPopulationFromOpp;
  global boolean runAccountSegmentCreationAndPopulationFromOrder;
  global Set<String> failedOrderRecrdIDs, failedOpptyRecrdIDs, failedAccountSegmentRdcrdIDs;
   
  private static Set<String> fieldNameSet = new Set<String> {
                                               'Segment_Global_Business_Line__c',
                                               'Segment_Business_Line__c',
                                               'Segment_Business_Unit__c',
                                               'Segment_Region__c',
                                               'Segment_Country__c'
  };

  global BatchAccountSegmentationSetUp(Boolean runAccountSegmentCreationAndPopulationFromOpp,
                                       Boolean runAccountSegmentCreationAndPopulationFromOrder
                                       ) {
    this.runAccountSegmentCreationAndPopulationFromOpp   = runAccountSegmentCreationAndPopulationFromOpp;
    this.runAccountSegmentCreationAndPopulationFromOrder = runAccountSegmentCreationAndPopulationFromOrder;
  }

  //========================================================================================
  // Start
  //========================================================================================
  global Database.QueryLocator start(Database.BatchableContext BC){
    // This will create Account Segments given existing Opp's Segment* fields
    String qry = '';
    if (runAccountSegmentCreationAndPopulationFromOpp) {
      qry = 'SELECT Id, Name, AccountId, OwnerId, IsClosed, IsWon,' +
                          'Segment_Business_Line__c, Segment_Business_Unit__c, Segment_Country__c,' +
                          ' Segment_Global_Business_Line__c, Segment_Region__c, ' +
                          'Owner_GBL_on_Opp_Close_Date__c, Owner_BL_on_Opp_Close_Date__c,' +
                          'Owner_BU_on_Opp_Close_Date__c, Owner_Region_on_Opp_Close_Date__c,' +
                          'Owner_Country_on_Opp_Close_Date__c' +
                   ' FROM Opportunity ' +
                   ' ORDER BY Account.Name';
                   
      
    }
    else if (runAccountSegmentCreationAndPopulationFromOrder) {
        qry = 'SELECT Id, Name, Account__c, OwnerId, RecordTypeId, ' +
                          'Segment_Business_Line__c, Segment_Business_Unit__c, Segment_Country__c,' +
                          ' Segment_Global_Business_Line__c, Segment_Region__c, ' +
                          'Owner_GBL_on_Order_Create_Date__c, Owner_BL_on_Order_Create_Date__c,' +
                          'Owner_BU_on_Order_Create_Date__c, Owner_Region_on_Order_Create_Date__c,' +
                          'Owner_Country_on_Order_Create_Date__c' +
                   ' FROM Order__c ' +
                   ' ORDER BY Account__r.Name';
    }
    if ( Test.isRunningTest() ) {
      qry += ' limit 200';
    }
   
    return Database.getQueryLocator(qry);
  }

  //========================================================================================
  // Execute
  //========================================================================================
  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    Set<String> segmentIds = new Set<String>();
    failedOrderRecrdIDs = new Set<String>();
    failedOpptyRecrdIDs = new Set<String>();
    
    failedAccountSegmentRdcrdIDs = new Set<String>();
    
    if ( runAccountSegmentCreationAndPopulationFromOrder ) {
      List<Order__c> orders = new List<Order__c>();
      orders.addAll((List<Order__c>) scope);
      OrderTrigger_AccountSegmentation.populateSegmentsOnOrders(orders, null);
      OrderTrigger_AccountSegmentation.hasRunBatch = true;
      
      List<Database.SaveResult> updatedOrdersResults = Database.update(orders, false);
      Set<String> succeededOrdRecrds = new Set<String>();
      
      System.debug('===orders1.0=='+orders);
      System.debug('===updatedOrdersResults=='+updatedOrdersResults);

      for(Integer i = 0; i < updatedOrdersResults.size(); i++){

        if (updatedOrdersResults.get(i).isSuccess()){
          succeededOrdRecrds.add(updatedOrdersResults.get(i).getId());
        }
        else if (!updatedOrdersResults.get(i).isSuccess()){
          // DML operation failed
          Database.Error error = updatedOrdersResults.get(i).getErrors().get(0);
          String failedDML = error.getMessage();
          system.debug('Failed ID'+orders.get(i).Id);
          String failedStr = '<tr><td>'+orders.get(i).Id+'</td><td>'+orders.get(i).Name+'</td><td>Error: ['+failedDML+']</td></tr>';
          failedOrderRecrdIDs.add(failedStr);
        }
      }
      System.debug('===failedOrderRecrdIDs.0=='+failedOrderRecrdIDs);
      for (Order__c ordr: orders) {
        if (succeededOrdRecrds.contains(ordr.ID)) { //If order has been updated
          for (String fieldName: fieldNameSet) {
            if (ordr.get(fieldName) != null) {
              segmentIds.add((String) ordr.get(fieldName));
            }
          }
        }
      }
    }
    
    if (runAccountSegmentCreationAndPopulationFromOpp) {
      Set <Id> owners = new Set<Id>();
      map<Id,User> usersMap = new map<Id,User>();
      List<Opportunity> opportunities = new List<Opportunity>();
      opportunities.addAll((List<Opportunity>) scope);

      OpportunityTrigger_AccountSegmentation.populateSegmentsOnOppty(opportunities, null);
      OpportunityTrigger_AccountSegmentation.hasRunBatch = true;
      List<Database.SaveResult> updatedOpptyResults = Database.update(opportunities, false);
      Set<String> succeededOpptyRecrds = new Set<String>();
      
      for(Integer i = 0; i < updatedOpptyResults.size(); i++){

        if (updatedOpptyResults.get(i).isSuccess()){
          succeededOpptyRecrds.add(updatedOpptyResults.get(i).getId());
        }
        else if (!updatedOpptyResults.get(i).isSuccess()){
          // DML operation failed
          Database.Error error = updatedOpptyResults.get(i).getErrors().get(0);
          String failedDML = error.getMessage();
          system.debug('Failed ID'+opportunities.get(i).Id);
          String failedStr = '<tr><td>'+opportunities.get(i).Id+'</td><td>'+opportunities.get(i).Name+'</td><td>Error: ['+failedDML+']</td></tr>';
          failedOpptyRecrdIDs.add(failedStr);
        }
      }
      
      for (Opportunity opp: opportunities) {
        if (succeededOpptyRecrds.contains(opp.ID)) {
          for (String fieldName: fieldNameSet) {
            if (opp.get(fieldName) != null) {
              segmentIds.add((String) opp.get(fieldName));
            }
          }
        }
      }
    }
    
    // No need for further processing if IsDataAdmin is turned off, as the trigger will take care
    // of recalculating the Account Segments
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
      return;
    }

    // If IsDataAdmin is turned on, we need to 'manually' have the Account Segments rollups calculated
    // Given the collected Account Segment Ids, launch the recalculation of the amounts
    Map<Id,Account_Segment__c> accountSegmentMap = new Map<Id,Account_Segment__c>();
    for ( Account_Segment__c accSegment : [SELECT Account__c, Id, Total_Won__c, Total_Open_Pipeline__c
                                           FROM Account_Segment__c
                                           WHERE Id in: segmentIds] ) {
      accountSegmentMap.put( accSegment.Id, accSegment);
    }

    List<Account_Segment__c> updatedSegments = AccountSegmentationUtility.segmentRecalculation(accountSegmentMap);
    if ( updatedSegments != null && updatedSegments.size() > 0 ) {
      List<Database.Saveresult> segmentResults = Database.update(updatedSegments, false);
      
      for (Integer i = 0; i < segmentResults.size(); i++) {
        if (!segmentResults.get(i).isSuccess()) {
          Database.Error error = segmentResults.get(i).getErrors().get(0);
          String failedDML = error.getMessage();
          String failedStr = '<tr><td>' + updatedSegments.get(i).Id + '</td><td>' + updatedSegments.get(i).Name + '</td><td>' + failedDML + '</td></tr>';
          failedAccountSegmentRdcrdIDs.add(failedStr);
        }
      }
      system.debug('====updatedSegments>>>' +updatedSegments);
    }

  }

  //========================================================================================
  // Finish
  //========================================================================================
  global void finish(Database.BatchableContext BC) {
    String GLOBAL_SETTING = 'Global';
    Global_Settings__c globalSetting = Global_Settings__c.getInstance(GLOBAL_SETTING);

    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                             TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =: BC.getJobId()];

    System.debug('=Finish:==failedOrderRecrdIDs=='+failedOrderRecrdIDs);
    //System.debug('=Finish:==failedAccountSegmentRdcrdIDs=='+failedAccountSegmentRdcrdIDs);
    Integer numOfError = a.NumberOfErrors;
    
    if ( numOfError != null && failedOrderRecrdIDs != null && failedOpptyRecrdIDs != null && failedAccountSegmentRdcrdIDs != null) {
       numOfError = a.NumberOfErrors + failedOrderRecrdIDs.size() + failedOpptyRecrdIDs.size() + failedAccountSegmentRdcrdIDs.size();
    }
    
    List<String> toAddresses = new List<String>();
    toAddresses.add(globalSetting.Batch_Failures_Email__c);
    String emailBody = 'The BatchAccountSegmentationSetUp batch job processed of ' + a.JobItemsProcessed + ' batch out of ' + a.TotalJobItems
                       + ', and generated ' + numOfError + ' error(s). ';
    
    
    if (failedOpptyRecrdIDs != null && failedOpptyRecrdIDs.size() > 0) {
      emailBody += '<br />Opportunities failed on update: <br />';
      emailBody += '<table><tr><td width="20%">Record Id</td><td width="30%">Name</td><td width="*">Exception</td></tr>';
      for (String currentRow : failedOpptyRecrdIDs) {
        emailBody += currentRow;
      }
      emailBody += '</table>';
    }
    
    if (failedOrderRecrdIDs != null && failedOrderRecrdIDs.size() > 0) {
      emailBody += '<br />Orders failed on update: <br />';
      emailBody += '<table><tr><td width="20%">Record Id</td><td width="30%">Name</td><td width="*">Exception</td></tr>';
      for (String currentRow : failedOrderRecrdIDs) {
        emailBody += currentRow;
      }
      emailBody += '</table>';
    }

    if (failedAccountSegmentRdcrdIDs != null && failedAccountSegmentRdcrdIDs.size() > 0) {
      emailBody += '<br />Account Segments failed on update: <br />';
      emailBody += '<table><tr><td  width="20%">Record Id</td><td width="30%">Name</td><td width="*">Exception</td></tr>';
      for (String currentRow : failedAccountSegmentRdcrdIDs) {
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
    if (numOfError > 0) {
      if (!Test.isRunningTest()) {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    }
  }

}