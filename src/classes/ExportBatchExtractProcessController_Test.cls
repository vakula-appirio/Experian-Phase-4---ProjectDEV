/******************************************************************************
 * Name: ExportBatchExtractProcessController_Test.cls
 * Description: Test class for ExportBatchExtractProcessController.cls
 * Created Date: Nov 4th, 2014
 * Created By: Richard Joseph 
 * 
 * Date Modified        Modified By             Description 
 ******************************************************************************/
@isTest(seeAllData=true)
private class ExportBatchExtractProcessController_Test {
  enum exportFileTypes {RPMFile, SummitFile, RoyaltiesFile,PartnerFile,CustomerFile} 
  public static testmethod void testExportBatchExtractProcess(){
    // create test data
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
    
    //insert custSettings;
    
    // NLG - Creating this trigger setting so that the webservice in UserTriggerHandler doesn't run
    TriggerSettings__c triggerSetting = new TriggerSettings__c();
    triggerSetting.Name = 'UserTrigger';
    triggerSetting.isActive__c = false;
    insert triggerSetting;  
    
    User currentUser = new User();
    currentUser.Id = UserInfo.getUserId();
    currentUser.Region__c = 'UK&I';
    currentUser.Global_Business_Line__c = 'Marketing Services';
    currentUser.Business_Line__c = 'APAC Marketing Services';
    currentUser.Office_Location__c = 'Amsterdam';
    currentUser.Department__c = 5;
    currentUser.Payroll__c = 100;
    currentUser.Business_Unit__c = 'APAC MS Data Quality';
    update currentUser; 
    
    triggerSetting.IsActive__c = true;
    update triggerSetting;

    Account testAcc = Test_Utils.insertAccount();

    Contact con = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                                AccountId = testAcc.Id, Email = 'larrye@email.com');
    insert con;

    Opportunity testOpp = Test_Utils.insertOpportunity(testAcc.Id);
    
    Address__c addrs1 = Test_Utils.insertAddress(true);
    
    Opportunity_Contact_Address__c opConAdrs = new Opportunity_Contact_Address__c();
    opConAdrs.Contact__c = con.Id;
    opConAdrs.Opportunity__c = testOpp.Id;
    opConAdrs.Address__c = addrs1.Id;
    opConAdrs.Role__c = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER;
    insert opConAdrs;
     
     Export_Batch__c testBatch= new Export_Batch__c (Name='TestClass Batch');
     insert  testBatch;      
    Order__c testOrder1 = Test_Utils.insertOrder(false, testAcc.Id, con.Id, testOpp.Id);
    testOrder1.Owner_BU_on_Order_Create_Date__c = 'EDQ';
    testOrder1.OwnerId = currentUser.Id;
    
    testOrder1.Finance_Invoice_Export_Batch__c=testBatch.id;

    Order__c testOrder2 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder2.Owner_BU_on_Order_Create_Date__c = 'EDQ';
    testOrder2.OwnerId = currentUser.Id;
    testOrder2.Finance_Invoice_Export_Batch__c=testBatch.id;

    Order__c testOrder3 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder3.Owner_BU_on_Order_Create_Date__c = 'EDQ';
    testOrder3.OwnerId = currentUser.Id;
    testOrder3.Finance_Invoice_Export_Batch__c=testBatch.id;
    testOrder3.Close_Date__c = system.today();

    Order__c testOrder4 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder4.Owner_BU_on_Order_Create_Date__c = 'EDQ';
    testOrder4.OwnerId = currentUser.Id;
    testOrder4.Finance_Invoice_Export_Batch__c=testBatch.id;
    
    Product2 product = new Product2(Name = 'TestClass_test_Prod1');
        product.Global_Business_Line__c = 'Experian Data Quality';
        insert product;
        
        Pricebook2 standard = [Select Id,IsActive From Pricebook2 Where IsStandard = true limit 1];
        if (!standard.isActive) {
          standard.IsActive = true;
          update standard;
        }
    
     List<Order__c> edqOrders = new List<Order__c>();
    edqOrders.add(testOrder1);
    edqOrders.add(testOrder2);
    edqOrders.add(testOrder3);
    edqOrders.add(testOrder4);
    insert edqOrders;
        
    
    Billing_Product__c billProd = Test_Utils.insertBillingProduct();
      
      List<Order_Line_Item__c> ordLnList = new list<Order_Line_Item__c>();
      //create Order Line Item
      Order_Line_Item__c ordrli1 = Test_Utils.insertOrderLineItems(false, testOrder1.Id, billProd.Id);
      ordrli1.CurrencyIsoCode = Constants.CURRENCY_USD;    
      ordrli1.Product__c=product.id;
      ordrli1.Total__c=1500;
      ordLnList.add(ordrli1);
      Order_Line_Item__c ordrli2 = Test_Utils.insertOrderLineItems(false, testOrder2.Id, billProd.Id);
      ordrli2.CurrencyIsoCode = Constants.CURRENCY_USD;
      ordrli2.Product__c=product.id;
      ordrli2.Partner_Amount__c= 1100;
      ordrli2.Total__c=2500;
      ordLnList.add(ordrli2);
      Order_Line_Item__c ordrli3 = Test_Utils.insertOrderLineItems(false, testOrder3.Id, billProd.Id);
      ordrli3.CurrencyIsoCode = Constants.CURRENCY_USD;
      ordrli3.Product__c=product.id;
      ordrli3.Total__c=1500;
      ordLnList.add(ordrli3);
      Order_Line_Item__c ordrli4 = Test_Utils.insertOrderLineItems(false, testOrder4.Id, billProd.Id);
      ordrli4.CurrencyIsoCode = Constants.CURRENCY_USD;
      ordrli4.Product__c=product.id;
      ordrli4.Total__c=1500;
      ordLnList.add(ordrli4);
      
      
      insert ordLnList;
      
      Royalty__c royalty1 = new Royalty__c(Name = 'test royalty #1', Line_Item_Reference_Number__c='1234',Order_Line_Item__c=ordrli3.id);
        insert royalty1;    
        
	Royalty__c royalty2 = new Royalty__c(Name = 'test royalty #2', Line_Item_Reference_Number__c='1234',Order_Line_Item__c=ordrli2.id);
        insert royalty2; 
	
    

    // start test
    Test.startTest();
   
    
    ExportBatchExtractProcessController testExportBatchController = new ExportBatchExtractProcessController();
    
    ApexPages.currentPage().getParameters().put('BatchID',testBatch.id );
    ApexPages.currentPage().getParameters().put('ExportFile',exportFileTypes.CustomerFile.name() );
    testExportBatchController.exportFileProcess();
    testExportBatchController.getfileName();
    
     ApexPages.currentPage().getParameters().put('BatchID',testBatch.id );
    ApexPages.currentPage().getParameters().put('ExportFile',exportFileTypes.PartnerFile.name() );
    testExportBatchController.exportFileProcess();
    testExportBatchController.getfileName();
    
     ApexPages.currentPage().getParameters().put('BatchID',testBatch.id );
    ApexPages.currentPage().getParameters().put('ExportFile',exportFileTypes.RoyaltiesFile.name() );
    testExportBatchController.exportFileProcess();
    testExportBatchController.getfileName();
    
     ApexPages.currentPage().getParameters().put('BatchID',testBatch.id );
    ApexPages.currentPage().getParameters().put('ExportFile',exportFileTypes.SummitFile.name() );
    testExportBatchController.exportFileProcess();
    testExportBatchController.getfileName();
    
     ApexPages.currentPage().getParameters().put('BatchID',testBatch.id );
    ApexPages.currentPage().getParameters().put('ExportFile',exportFileTypes.RPMFile.name() );
    testExportBatchController.exportFileProcess();
    testExportBatchController.getfileName();
    

    Test.stopTest();
    
  }

}