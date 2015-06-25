/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleProdCountryRegionSearchAndDelete 
 * Description: Schedule BatchProdCountrySearchAndDelete to run daily
 * Created Date: Apr 11th, 2014
 * Created By: Arpita Bose (Appirio) - T-270944
 * 
 * Date Modified     Modified By        Description of the update
 
 =====================================================================*/
global class ScheduleProdCountryRegionSearchAndDelete implements Schedulable {
  global void execute(SchedulableContext SC) {
    //Delete product countries where Product__c = null
    String query = 'SELECT Id FROM Product_Country__c WHERE Product__c = null';
    BatchProdCountryRegionSearchAndDelete batch = new BatchProdCountryRegionSearchAndDelete(query); 
    Database.executeBatch(batch, 200); 
    //Delete product region where Product__c = null
    query = 'SELECT Id FROM Product_Region__c WHERE Product__c = null';
    batch = new BatchProdCountryRegionSearchAndDelete(query); 
    Database.executeBatch(batch, 200); 
  }
}