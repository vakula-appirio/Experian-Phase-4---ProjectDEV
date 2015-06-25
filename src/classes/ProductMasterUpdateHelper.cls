/**=====================================================================
 *  * Name: ProductMasterUpdateHelper 
 * Description: Helper to update Product Master records 
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 =====================================================================*/
 public class ProductMasterUpdateHelper {

 public static boolean isRecursive = false;
//===========================================================================
  //To run an update to SYNC product master data.
  //===========================================================================
 
 public static void updateProductMaster(set<ID> productMasterIdSet){
 

     if(!ProductMasterUpdateHelper.isRecursive ){
     
          ProductMasterUpdateHelper.isRecursive= true;
         List<Product_Master__c> updateProductMasterList = new List<Product_Master__c>();
         
         
         for(Product_Master__c productMasterRec :[Select id ,CpqTableEntryId__c  from Product_Master__c where id in :productMasterIdSet])
         {
             //if(productMasterRec.CpqTableEntryId__c != null )
                 updateProductMasterList.add(productMasterRec);
                 
                 System.debug(productMasterRec.CpqTableEntryId__c );
         }    
 
     if(updateProductMasterList.size()>0)
      update updateProductMasterList ;
      
     
      
      }
 }
 }