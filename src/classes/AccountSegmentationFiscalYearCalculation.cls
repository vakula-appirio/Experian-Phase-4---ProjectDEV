/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentationFiscalYearCalculation
 * Description:
 *              T-374227: Account Segmentation: Fiscal Year batch: Apr 06th, 2015 Nikhil
 * Created Date: April 06th, 2015
 * Created By: Nikhil Sharma (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * Apr 14th, 2015               Naresh Kumar Ojha            T-375000: Updated finish method to send mail to GCS team for error.
 ======================================================================*/
global class AccountSegmentationFiscalYearCalculation implements  Database.Batchable<sObject>  {
  private static Map<ID, List<Order__c>> accSegID_ListOfOrdersMap;
  private static Set<String> fieldNameSet = new Set<String> {
                                               'Segment_Global_Business_Line__c',
                                               'Segment_Business_Line__c',
                                               'Segment_Business_Unit__c',
                                               'Segment_Region__c',
                                               'Segment_Country__c'
  };

  global AccountSegmentationFiscalYearCalculation() {
    
  }

  //===========================================================================
  // Method to get Order__c record for last fiscal year
  //===========================================================================
  global Database.QueryLocator start(Database.BatchableContext BC){
    Date lastYearDate = Date.today().addYears(-1);
    List<FiscalYearSettings> fiscalYears = [SELECT Id, Name, StartDate, EndDate
                                            FROM FiscalYearSettings 
                                            WHERE StartDate <= :lastYearDate and EndDate >= :lastYearDate];
    Integer lastYearFiscalYear = Integer.valueOf(fiscalYears.get(0).Name);
    Date lastFYendDate = fiscalYears.get(0).EndDate;
    System.debug('\n[AccountSegmentationFiscalYearCalculation: execute] Last Fiscal Year: ' + fiscalYears.get(0));

    // Generate the query, which will include all the segment fields as well as the amount we care for
    String query = 'SELECT Id, Amount_Corp__c, EDQ_Margin__c, Status__c ';
    for (String fieldName: fieldNameSet) {
      query += ', ' + fieldName;
    }
    query += ' FROM Order__c ' +
             ' WHERE FISCAL_YEAR(Contract_End_Date__c) = :lastYearFiscalYear ' +
             ' AND (Cancellation_Date__c = null OR Cancellation_Date__c > : lastFYendDate)'+ 
             ' AND Credited__c = false ' +
             ' AND RecordType.Name = \'Read Only\' ORDER BY Account__c';
    return Database.getQueryLocator(query);
  }


  //===========================================================================
  // Method to update Previous_FY_Order_Amount__c on Account_Segment__c
  //===========================================================================
  global void execute(Database.BatchableContext BC, List<sObject> scope) {

    // Map between Account segment Id and related Order__c
    accSegID_ListOfOrdersMap = new Map<ID, List<Order__c>>();
    Set<Id> accountIds = new Set<Id>();

    for (Order__c order1 : (list<Order__c>)scope) {
      populateAStoOrderMap(order1, fieldNameSet);
      system.debug('\n[AccountSegmentationFiscalYearCalculation: execute]: OrderId: '+ order1.Id + '\nOrder:' + order1);
    }
    

    // List of Account Segment records to update
    List<Account_Segment__c> listAccSegment = new List<Account_Segment__c>();
    System.debug('\n[AccountSegmentationFiscalYearCalculation: execute] accSegID_ListOfOrdersMap: ' + accSegID_ListOfOrdersMap);

    // Logic to update Previous_FY_Order_Amount__c on Account_Segment__c with sum of all related Order's Amount_Corp__c
    for (Account_Segment__c accSeg : [SELECT Id, Previous_FY_Order_Amount__c, Value__c
                                      FROM Account_Segment__c
                                      WHERE Id IN : accSegID_ListOfOrdersMap.keySet()]) {
      Decimal amount = 0;
      Decimal edqAmount = 0;
      for (Order__c order1 : accSegID_ListOfOrdersMap.get(accSeg.Id)) {
        if (order1.Amount_Corp__c != null) {
          amount += order1.Amount_Corp__c;
        }
        if (order1.Status__c != 'Credited' && order1.EDQ_Margin__c != 0 && order1.EDQ_Margin__c != null) {
          edqAmount += order1.EDQ_Margin__c;
        }
//          System.debug('\n[AccountSegmentationFiscalYearCalculation: execute] amountcorp: ' + order1.Amount_Corp__c);
      }
      System.debug('\n[AccountSegmentationFiscalYearCalculation: execute] amount: ' + amount);
      accSeg.Previous_FY_Order_Amount__c = amount;
      accSeg.EDQ_Margin__c = edqAmount;
      listAccSegment.add(accSeg);
    }

    update listAccSegment;
//    System.debug('\n[AccountSegmentationFiscalYearCalculation: execute] accSegments: ' + 
//                 [Select Previous_FY_Order_Amount__c From Account_Segment__c where ID IN : accSegID_ListOfOrdersMap.keySet()]);
  }


  //===========================================================================
  // Method to populate the map of AccountSegmentId => List<Order__c>\
  // @param ord Order going through the loop
  // @param fieldNames is a set of fields to enter in the map as keys
  //===========================================================================
  private static void populateAStoOrderMap(Order__c ord, Set<String> fieldNames) {
    for (String fieldName: fieldNames) {
      Id fieldValue = (Id) ord.get(FieldName);
      if (fieldValue != null) {
        if (!accSegID_ListOfOrdersMap.containsKey(fieldValue)) {
          accSegID_ListOfOrdersMap.put(fieldValue, new List<Order__c>());
        }
        accSegID_ListOfOrdersMap.get(fieldValue).add(ord);
      }
    }
  }

  //===========================================================================
  // Will send an email notification if any failure
  //===========================================================================
  global void finish(Database.BatchableContext BC) {
    String GLOBAL_SETTING = 'Global';
    Global_Settings__c globalSetting = Global_Settings__c.getInstance(GLOBAL_SETTING);
    List<String> toAddresses = new List<String>();
    toAddresses.add(globalSetting.Batch_Failures_Email__c);
 
    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                             TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =: BC.getJobId()];

    System.debug('\n[AccountSegmentationFiscalYearCalculation: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.]]');

    String emailBody = 'The AccountSegmentationFiscalYearCalculation batch job completed the processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                       + ' jobs, and generated ' + a.NumberOfErrors + ' error(s).';
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setSaveAsActivity(false);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setToAddresses(toAddresses);
    mail.setSubject('Force.com Batch: AccountSegmentationFiscalYearCalculation Error(s)');
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