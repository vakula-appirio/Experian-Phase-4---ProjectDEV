/**=====================================================================
 *  * Name: ProductRegionTriggerHandler 
 * Description: Handler for Product_Region__c Trigger
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
 public class ProductRegionTriggerHandler {
 
 //===========================================================================
  // After Insert
  //===========================================================================
  public static void afterInsert(Map<ID, Product_Region__c> newMap) {
  
      processProductRegion(newMap.values());
    
  }

  //===========================================================================
  //After Update
  //===========================================================================
  public static void afterUpdate(Map<ID, Product_Region__c> newMap, Map<ID, Product_Region__c> oldMap) {
  
         processProductRegion(newMap.values());
 }
 
 //===========================================================================
  //To run an update to SYNC product master data.
  //===========================================================================
 
 public static void processProductRegion(List<Product_Region__c > productRegionList){
 
  If(!ProductMasterUpdateHelper.isRecursive){
         set<Id> updateProductMasterIDSet = new set<Id>();
         
         
         for(Product_Region__c productRegionRec :productRegionList)
         {
             if(productRegionRec.Product_Master__c != null  )
                 updateProductMasterIDSet.add(productRegionRec.Product_Master__c);
                 
                 
         }    
 
     if(updateProductMasterIDSet.size()>0)
      ProductMasterUpdateHelper.updateProductMaster(updateProductMasterIDSet);
      
     } 
 }
 }