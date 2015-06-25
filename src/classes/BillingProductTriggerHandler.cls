/**=====================================================================
 *  * Name: BillingProductTriggerHandler 
 * Description: Handler for Billing_Product__c Trigger
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
 public class BillingProductTriggerHandler {
 
 //===========================================================================
  // After Insert
  //===========================================================================
  public static void afterInsert(Map<ID, Billing_Product__c> newMap) {
  
      processBillingProduct(newMap.values());
    
  }

  //===========================================================================
  //After Update
  //===========================================================================
  public static void afterUpdate(Map<ID, Billing_Product__c> newMap, Map<ID, Billing_Product__c> oldMap) {
  
         processBillingProduct(newMap.values());
 }
 
 //===========================================================================
  //To run an update to SYNC product master data.
  //===========================================================================
 
 public static void processBillingProduct(List<Billing_Product__c > BillingProductList){
 If(!ProductMasterUpdateHelper.isRecursive)
 {
         set<Id> updateProductMasterIDSet = new set<Id>();
         
         
         for(Billing_Product__c BillingProductRec :BillingProductList)
         {
             if(BillingProductRec.Product_Master__c != null  )
                 updateProductMasterIDSet.add(BillingProductRec.Product_Master__c);
                 
                 
         }    
 
     if(updateProductMasterIDSet.size()>0)
      ProductMasterUpdateHelper.updateProductMaster(updateProductMasterIDSet);
      
  }    
 }
 }