/**=====================================================================
 *  * Name: ProductMasterTriggerHandler 
 * Description: Handler for Product_Master__c Trigger
 * Created Date: Oct 13th 2014
 * Created By: Richard
 * 
 * Business Case- To Sync Product Master details to Salesforce product2 and CPQ product objects.
 *Change log
 *March 10th 2015 - Richard Joseph - To include Discover_Experian_Name__c and Include_in_Discover_Experian__c 
 *                                    Fields to Sync to Products. Case # 584066   
 *                                    Including CSDA fields CSDA_Product_Group__c,CSDA_Product_Org__c,CSDA_Product_Suite__c     
 *May 13th 2015- Richard Joseph - Use Product_Name__c  to map in Products   
 =====================================================================*/
 public class ProductMasterTriggerHandler {
 
 public static boolean aSyncRRecursiveRUN = false;
 
 //===========================================================================
  // After Insert
  //===========================================================================
  public static void afterInsert(Map<ID, Product_Master__c> newMap) {
  
      createProducts(newMap.values());
    
  }

  //===========================================================================
  //After Update
  //===========================================================================
  public static void afterUpdate(Map<ID, Product_Master__c> newMap, Map<ID, Product_Master__c> oldMap) {
    
    If(!aSyncRRecursiveRUN) {
    Map<Id,Id> existingProductMasterProductMap = new map<id,id>();
    List<Product_Master__c> toCreateProductMasterList =new List<Product_Master__c>();
    List<Product_Master__c> toUpdateProductMasterList =new List<Product_Master__c>();
    
    List<Product2> existingProductList = new List<Product2>([Select id,Product_Master__c,Product_Master__r.id from Product2 where Product_Master__c in :newMap.keySet()  ]);
    
    For(Product2 productRec : existingProductList )
    {
        existingProductMasterProductMap.put(productRec.Product_Master__r.id,productRec .id );
    }
    
    For(Product_Master__c productMasterRec : newmap.values() ){
        
        If(productMasterRec.Product_life_cycle__c != 'Idea' && productMasterRec.Product_life_cycle__c != 'Beta')
        //&& productMasterRec.Product_life_cycle__c!= oldMap.get(productMasterRec.id).Product_life_cycle__c)
        {
            If(existingProductMasterProductMap.containsKey(productMasterRec.id))
                    toUpdateProductMasterList.add(productMasterRec);
             else
                   toCreateProductMasterList .add(productMasterRec);     
        }
         //else If(productMasterRec.Product_life_cycle__c != 'Idea' && productMasterRec.Product_life_cycle__c != 'Beta' && existingProductMasterProductMap.containsKey(productMasterRec.id)
          //&& productMasterRec.CpqTableEntryId__c == oldMap.get(productMasterRec.id).CpqTableEntryId__c
        //)
          //       toUpdateProductMasterList.add(productMasterRec);
                 
    }
        
        If(toCreateProductMasterList.size() > 0)  
        {
            aSyncRRecursiveRUN= true;   
            createProducts(toCreateProductMasterList);  
        }
        If (toUpdateProductMasterList.size() > 0 && !aSyncRRecursiveRUN)   
        {
                aSyncRRecursiveRUN= true;
                updateProducts( toUpdateProductMasterList , existingProductMasterProductMap);
                
        }
    }
  }
 //Create Products in both SFDC and CPQ
  Private static void createProducts(List<Product_Master__c> newproductMasterList ) {
      
      List<Product2> productList = new List<Product2>();
      
      Set<id> productMasterIdSet = new set<id>();
      Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.allowFieldTruncation = true;
      
     
      
          For(Product_Master__c productMasterRec : newproductMasterList){
              If(productMasterRec.Product_life_cycle__c != 'Idea' && productMasterRec.Product_life_cycle__c != 'Beta')
              {
                 
                 Product2 newProductRec = mapProductFields(productMasterRec);   
                  newProductRec.setOptions(dmlOptions);
                  productList.add(newProductRec) ; 
                  productMasterIdSet.add(productMasterRec.id); 
                  If( productList.size() < (Limits.getLimitFutureCalls() - Limits.getFutureCalls()) )
                  SFDCToCPQProductMasterSyncServiceClass.callCPQProductMasterService(productMasterRec);
              }
          }  
          
          if (productList.size()>0  )
          {
              insert productList;
              
              productRelatedListMapping(productList);  
              
              If (productMasterIdSet .size() < (Limits.getLimitFutureCalls() - Limits.getFutureCalls()))
              {
              For(Id productMasterId: productMasterIdSet )
              {
                 SFDCToCPQProductMasterSyncServiceClass.callCPQProductMasterAsync(productMasterId);
                 
              }
                 
               }
              
          }
          
          
      
  
  } 
 //Updates/Creates Products in both SFDC and CPQ 
   Private static void updateProducts(List<Product_Master__c> newproductMasterList, Map<Id,Id> existingProductMasterProductMap ) {
      
     List<Product2> productList = new List<Product2>();
      Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.allowFieldTruncation = true;
     
      
      Set<id> productMasterIdSet = new set<id>();
      
          For(Product_Master__c productMasterRec : newproductMasterList){
              If(productMasterRec.Product_life_cycle__c != 'Idea' && productMasterRec.Product_life_cycle__c != 'Beta'
                               
              )
              {
                  Product2 exstingProduct = new Product2 ();
                  exstingProduct =mapProductFields(productMasterRec);
                  exstingProduct.id=existingProductMasterProductMap.get(productMasterRec.id) ;
                  exstingProduct.setOptions(dmlOptions);
                  productList.add(exstingProduct ) ; 
                  productMasterIdSet.add(productMasterRec.id); 
              }
          }  
          
          if (productList.size()>0)
          {
            
            
               upsert productList;
              
              productRelatedListMapping(productList);  
               
              If (productMasterIdSet .size() < (Limits.getLimitFutureCalls() - Limits.getFutureCalls()))
              {
              For(Id productMasterId: productMasterIdSet )
              {
                 SFDCToCPQProductMasterSyncServiceClass.callCPQProductMasterAsync(productMasterId);
              }
                 
               }
              
          }  
  
  }   
 
 //Map other relatedlist objects to Product.
 Private static void productRelatedListMapping(List<Product2> productList){
 
          map<id,id> productMasterProductIdMap = new map<id,id>();
          For (Product2 productRec:productList)
            {
                if(productRec.Product_Master__c != null)
                productMasterProductIdMap.put(productRec.Product_Master__c,productRec.id );
                
                
            } 
            
             if(productMasterProductIdMap.size()> 0)
             {
             
            List<Billing_Product__c> newBillingProductList = new List<Billing_Product__c>([Select id ,Product__c,Product_Master__r.id from Billing_Product__c  where Product_Master__c in :productMasterProductIdMap.keyset() ]);
            
            For(Billing_Product__c newBillingProductRec:newBillingProductList){
                newBillingProductRec.Product__c = productMasterProductIdMap.get(newBillingProductRec.Product_Master__r.id);
            } 
            
            Update newBillingProductList; 
            
            List<Product_Country__c> newproductCountryList = new List<Product_Country__c>([Select id , Product__c ,Product_Master__r.id from Product_Country__c  where Product_Master__c in :productMasterProductIdMap.keyset() ]);
             
            For(Product_Country__c newproductCountryRec :newproductCountryList ){
                 newproductCountryRec.Product__c =productMasterProductIdMap.get(newproductCountryRec.Product_Master__r.id);
             }  
             
             Update  newproductCountryList; 
             
             List<Product_Region__c> newproductRegionList = new List<Product_Region__c>([Select id , Product__c ,Product_Master__r.id from Product_Region__c where Product_Master__c in :productMasterProductIdMap.keyset() ]);
             
            For(Product_Region__c newproductRegionRec :newproductRegionList ){
                 newproductRegionRec .Product__c =productMasterProductIdMap.get(newproductRegionRec .Product_Master__r.id);
             }  
             
             Update  newproductRegionList ;
             
             }
 }
 
 
 //Map Products Field   
  Private static Product2 mapProductFields(Product_Master__c productMasterRecord)
  {
      Product2 newProductRec = new Product2();
          //Changed by RJ- to Map custom Product name -Product_Name__c to Product.Name
          //newProductRec.name = productMasterRecord.Name;
          newProductRec.name= productMasterRecord.Product_Name__c ;
          newProductRec.DE_Product_Name__c = productMasterRecord.Product_master_name__c;
          //This is added for I-139119 - The Description field is mapped wrongly to standard field
          //newProductRec.Description=productMasterRecord.Product_Description__c;
          newProductRec.Product_Desc__c=productMasterRecord.Product_Description__c;
          newProductRec.Types_of_Sale__c= productMasterRecord.Type_of_sale__c;
          newProductRec.Simple_or_complex__c = productMasterRecord.Simple_or_complex__c;
          newProductRec.Capability__c = productMasterRecord.Capability__c;
          newProductRec.Family= productMasterRecord.Product_Family__c;
          newProductRec.Product_Group__c = productMasterRecord.Product_Group__c ;
          newProductRec.Global_Business_Line__c = productMasterRecord.Product_Global_Business_Line__c;
          newProductRec.Business_Line__c= productMasterRecord.Line_of_business__c;
          newProductRec.Industry__c = productMasterRecord.Unique_industries_served__c;
          newProductRec.Sector__c= productMasterRecord.Sector__c;          
          if(productMasterRecord.Active__c)
          newProductRec.isActive= true;
          else
          newProductRec.isActive= false;
          //Added to enable RevenueSchedule.
          newProductRec.CanUseRevenueSchedule=true;
          newProductRec.Customer_Journey__c= productMasterRecord.Customer_Journey__c;
          newProductRec.Asset_type__c= productMasterRecord.Asset_type__c;
          //This is added for I-139119 - The Description field is mapped wrongly to standard field
          //newProductRec.Chart_of_Accounts_Product_Description__c= productMasterRecord.Chart_of_Accounts_Product_Description__c;
          newProductRec.Description=productMasterRecord.Chart_of_Accounts_Product_Description__c;
          newProductRec.FUSE_product_page_URL__c= productMasterRecord.FUSE_product_page_URL__c;
          newProductRec.Provides_insight_into__c= productMasterRecord.Provides_insight_into__c;
          newProductRec.Product_Master__c= productMasterRecord.id;
          newProductRec.PD_Code__c =productMasterRecord.Chart_of_Accounts_Subanaysis_PD_code__c;
          newProductRec.Lifecycle__c = productMasterRecord.Product_life_cycle__c;
          //RJ - Case # 584066 - To include Discover_Experian_Name__c and Include_in_Discover_Experian__c in Product Sync
          newProductRec.Discover_Experian_Name__c = productMasterRecord.Discover_Experian_Name__c ;
          newProductRec.Include_in_Discover_Experian__c  = productMasterRecord.Include_in_Discover_Experian__c  ;
          //CSDA fields
              newProductRec.CSDA_Product_Group__c  = productMasterRecord.CSDA_Product_Group__c  ;
              newProductRec.CSDA_Product_Org__c  = productMasterRecord.CSDA_Product_Org__c  ;
              newProductRec.CSDA_Product_Suite__c  = productMasterRecord.CSDA_Product_Suite__c  ;
                             
          
          return newProductRec ;
      
  }
  

   
 }