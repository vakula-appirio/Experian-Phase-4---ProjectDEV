/**=====================================================================
 *  * Name: ProductCountryTriggerHandler 
 * Description: Handler for Product_Country__c Trigger
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
 public class ProductCountryTriggerHandler {
 
 //===========================================================================
  // After Insert
  //===========================================================================
  public static void afterInsert(Map<ID, Product_Country__c> newMap) {
  
      processProductCountry(newMap.values());
    
  }

  //===========================================================================
  //After Update
  //===========================================================================
  public static void afterUpdate(Map<ID, Product_Country__c> newMap, Map<ID, Product_Country__c> oldMap) {
  
         processProductCountry(newMap.values());
 }
 
 //===========================================================================
  //To run an update to SYNC product master data.
  //===========================================================================
 
 public static void processProductCountry(List<Product_Country__c > ProductCountryList){
 
     If(!ProductMasterUpdateHelper.isRecursive){
         set<Id> updateProductMasterIDSet = new set<Id>();
         
         
         for(Product_Country__c ProductCountryRec :ProductCountryList)
         {
             if(ProductCountryRec.Product_Master__c != null  )
                 updateProductMasterIDSet.add(ProductCountryRec.Product_Master__c);
                 
                 
         }    
 
     if(updateProductMasterIDSet.size()>0)
      ProductMasterUpdateHelper.updateProductMaster(updateProductMasterIDSet);
      
      
 }
 }
 }