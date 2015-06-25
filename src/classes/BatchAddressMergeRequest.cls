/**=====================================================================
 * Appirio, Inc
 * Name: BatchAddressMergeRequest
 * Description: batch job to process all Address_Merge_Request__c that are ready to be processed
                T-250105
 * Created Date: Feb 17rd, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 17th, 2014               Original                     T-250105
 * Feb 19th, 2014               Nathalie Le Guay (Appirio)   query criteria
 * Feb 26th, 2014               Jinesh Goyal (Appirio)       modified to use 'AddressMerge.processMergeRequests'
 * Oct 25th, 2014               Nathalie Le Guay (Appirio)   Removing functionality
 =====================================================================*/
global class BatchAddressMergeRequest implements Database.Batchable<sObject> {
/*
  private final String addressQuery;
  //==============================================================
  // Constructor - will query for Address_Merge_Request__c pending
  // to be processed
  //==============================================================
  global BatchAddressMergeRequest() {
    addressQuery = 'SELECT Id, '+
                   'Master_Address__c, '+
                   'Slave_Address__c, '+
                   'Merge_Process_Status__c '+
                   'FROM Address_Merge_Request__c '+
                   'WHERE Perform_Auto_Merge__c = true '+
                   'AND Merge_Process_Status__c = \'Pending\' ';
  }*/
  //==============================================================
  // start method
  //==============================================================
  global Database.QueryLocator start(Database.BatchableContext BC) {
    // return Database.getQueryLocator(addressQuery);
    return null;
  }
  //==============================================================
  // execute method
  // Will build a map<String, String> pairing the Id of the record
  // to keep with the Id of the record to delete
  //==============================================================
  global void execute(Database.BatchableContext BC, List<Address_Merge_Request__c> scope) {
/*    System.debug('\n[BatchAddressMergeRequest: execute] : Scope size: '+scope.size());
	  //web-service call to process Address_Merge_Request__c and
	  //create a full copy by creating an entry in the Address_History__c table
	  AddressMerge.processMergeRequests(scope);
*/
  }
  //==============================================================
  // finish method
  // If successful processing of records, will delete the Address__c
  // records that were marked as the victims
  //==============================================================
  global void finish(Database.BatchableContext BC) {
  }
  
}