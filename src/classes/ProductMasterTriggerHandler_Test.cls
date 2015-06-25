/**=========================================================================================
 * Name           : ProductMasterTriggerHandler_Test
 * Description    : Unit test coverage for ProductMasterTriggerHandler.cls
 * Created Date   : Oct 22th, 2014
 * Created By     : Pallavi Sharma (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 *==============================================================================================*/
@isTest(seealldata=true) 
private class ProductMasterTriggerHandler_Test {
  
  static User usr;
  static{
    usr = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    usr.Business_Unit__c = Constants.USER_GBL_CREDIT_SERVICES;
    usr.Country__c = null;
    usr.Region__c = null;
    insert usr;
  }
  
  static testMethod void unit_test() {
      CPQ_Settings__c testCPQSetting = CPQ_Settings__c.getInstance('CPQ');
     if(testCPQSetting == null){
     testCPQSetting= new CPQ_Settings__c ();
         testCPQSetting.Name = 'CPQ';
         testCPQSetting.Company_Code__c= 'Experian';
         testCPQSetting.CPQ_API_Access_Word__c = 'Accessword';
         testCPQSetting.CPQ_API_Endpoint__c= 'https://test.webcomcpq.com/';
         testCPQSetting.CPQ_API_UserName__c= 'TestUser#Experian';
         Insert testCPQSetting; 
     }
  
    System.runAs( usr ) {
      Test.startTest();
      Product_Master__c productMaster = Test_Utils.createProductMaster(false);
      productMaster.Product_life_cycle__c = 'Beta';
      insert productMaster;
      
      system.assert([SELECT Id FROM Product2 WHERE Product_Master__c =: productMaster.Id] != null);
      
      Country__c country = Test_Utils.createCountry(true);
      Region__c region = Test_Utils.createRegion(true); 
      
      Billing_Product__c billingProduct = Test_Utils.createBillingProduct(false);
      billingProduct.Product_Master__c = productMaster.Id;
      insert billingProduct;
      
      Product_Country__c productCountry = Test_Utils.createProductCountry(false, country.Id);
      productCountry.Product_Master__c = productMaster.Id;
      insert productCountry;
      
      Product_Region__c productRegion = Test_Utils.createProductRegion(false, region.Id);
      productRegion.Product_Master__c = productMaster.Id;
      insert productRegion;
      
      ProductMasterUpdateHelper.isRecursive=false;
      productMaster.Product_life_cycle__c = 'Live';
      productMaster.CpqTableEntryId__c='aaa';
      productMaster.Product_Name__c = 'test';
      update productMaster;
      
      ProductMasterUpdateHelper.isRecursive=false;
      Billing_Product__c billingProduct1 = Test_Utils.createBillingProduct(false);
      billingProduct1.Product_Master__c = productMaster.Id;
      insert billingProduct1;
      ProductMasterUpdateHelper.isRecursive=false;
      Product_Country__c productCountry1 = Test_Utils.createProductCountry(false, country.Id);
      productCountry1.Product_Master__c = productMaster.Id;
      insert productCountry1;
      ProductMasterUpdateHelper.isRecursive=false;
      Product_Region__c productRegion1 = Test_Utils.createProductRegion(false, region.Id);
      productRegion1.Product_Master__c = productMaster.Id;
      insert productRegion1;
      ProductMasterUpdateHelper.isRecursive=false;
      update productCountry1;
      ProductMasterUpdateHelper.isRecursive=false;
      update productRegion1;
      ProductMasterUpdateHelper.isRecursive=false;
      billingProduct1.name = 'Test';
      update billingProduct1;
      ProductMasterUpdateHelper.isRecursive=false;
      productMaster.Product_life_cycle__c = 'Phased Out';
      update productMaster;
      
      system.assert([SELECT Id, Product__c FROM Billing_Product__c WHERE ID =: billingProduct.Id].Product__c != null);
      
      system.assert([SELECT Id, Product__c FROM Product_Country__c WHERE ID =: productCountry.Id].Product__c != null);
      
      system.assert([SELECT Id, Product__c FROM Product_Region__c WHERE ID =: productRegion.Id].Product__c != null);
      Test.stopTest();
    }
  }
}