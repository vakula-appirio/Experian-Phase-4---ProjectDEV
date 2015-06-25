/**=====================================================================
 * Appirio, Inc
 * Name: BatchProdCountryRegionSearchAndDelete
 * Description: T-270944: This batch will query for Product_Country__c and
 *              where Product__c = null and delete them.
 * Created Date: Apr 11th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
  global class BatchProdCountryRegionSearchAndDelete implements Database.Batchable<sObject> {
    global String query;

    //==============================================================
    // Constructor - will query for Product_Country__c and 
    // Product_Region__c where Product__c is null
    //==============================================================
    global BatchProdCountryRegionSearchAndDelete(String paramQuery) {
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
    // Will build a List<String> pairing the Id of the record
    // to keep with the Id of the record to delete
    //==============================================================
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
      System.debug('\n[BatchProductSearch: execute] : Scope size: '+scope.size());

      if (!scope.isEmpty()) {
        delete scope;
      }
   }

    //==============================================================
    // finish method
    // If successful processing of records, will delete the Product_Country__c
    // records that were marked
    //==============================================================
    global void finish(Database.BatchableContext BC) {
      System.debug('\n[BatchProductSearch: finish] : Product_Country size: '+query);
    }
}