/**=====================================================================
 *  Name: SiteWebtoProductMasterCaseExtCntlr_Test
 * Description: Test Class for SiteWebtoProductMasterCaseExtCntlr 
 * Created Date: Dec 15th 2014
 * Created By: Richard Joseph
 *
 * Date Modified      Modified By                Description of the update
 * 
 =====================================================================*/
@isTest(seeAllData=true)
private class SiteWebtoProductMasterCaseExtCntlr_Test{

 static testMethod void testCreateRelatedAccountPlanOppSwotEntries() {
 
  Product_Master__c  testProductMaster = new Product_Master__c (name='Test');
  ApexPages.StandardController stdCntrl = new ApexPages.StandardController(testProductMaster );
      SiteWebtoProductMasterCaseExtCntlr testController= new SiteWebtoProductMasterCaseExtCntlr(stdCntrl );
 
     testController.ReqNewProduct();
     testController.ReqUpdateProduct();
     testController.CreateCase();
     testController.CreateUpdateCase();
 }
 }