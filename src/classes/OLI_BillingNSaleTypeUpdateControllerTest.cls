/**=====================================================================
 * Appirio, Inc
 * Name: TestOLI_BillingNSaleTypeUpdateController
 * Description: The following class is for testing the OLIBillingNSaleTypeUupdateController class.
                 Story:     S-135713
                 Task:      T-211882
 * Created Date: 
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)            T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose(Appirio)             T-243282: Added Constants in place of String
 * Mar 05th, 2014               Jinesh Goyal (Appirio)           T-253906: test class renaming
 * Mar 14th, 2014               Arpita Bose (Appirio)            T-253906: Fixed error
 * Apr 14th, 2014               Arpita Bose                      Updated methods testOLISave(),testOLICancel() and testOLIInnerClass()
                                                                 to fix the failure
 * Jul 31st, 2014               Arpita Bose                      T-286015: Phase 2 Sprint 0 refactoring: Fix test class requiring a specific user currency
 * Oct 21st, 2014               Pallavi Sharma                   Increase Test Coverage
 =====================================================================*/
        
@isTest(seealldata=true)
private class OLI_BillingNSaleTypeUpdateControllerTest {

    static testMethod void testOLISave() {
        
          // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
  
      System.runAs(testUser1) {
        Global_Settings__c setting = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        // Create an account        
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;
        
        //////////////////////
        // Create Opportunity Line Item
        Product2 product = Test_Utils.createProduct();
        product.Types_of_Sale__c = 'Data';
        insert product;
        
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);

        Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
        // method to add billingproduct to lineItem.
        
        //PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, priceBook.Id, 'USD');  // needed to remove this to avoid duplicate entry error
        //OpportunityLineItem opportunityLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
        OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (TotalPrice = 200, Quantity = 1, Order_Type__c = Constants.STATUS_NEW,
                                                   OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Type_of_Sale__c ='Ad-Hoc',
                                                   Start_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(10));
        insert opportunityLineItem;
        /////////////////////
        Test.startTest();
        // generate a vf page taking in the address id
        PageReference pageRef = Page.OLI_BillingNSaleTypeUpdate;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('oli',opportunityLineItem.Id);
        
        OLI_BillingNSaleTypeUpdateController testUpdateController = new OLI_BillingNSaleTypeUpdateController(new ApexPages.Standardcontroller(new Opportunity()));
        //AddressDynamicCountry_Controller testController =  new AddressDynamicCountry_Controller(new ApexPages.StandardController(new Address__c()));
        //testUpdateController.performCancel();
        //String nextPage = testUpdateController.performCancel().getUrl();
        //system.debug(nextPage);
        //system.assertEquals('/006/o',nextPage);
        testUpdateController.performSave();
        opportunityLineItem.Type_of_Sale__c = 'Appends';
        update opportunityLineItem;
        testUpdateController.performSave();      
        Test.stopTest();
      }
    }
    
    static testMethod void testOLICancel() {
        
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;

      System.runAs(testUser1) {

        Global_Settings__c setting = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        // Create an account        
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;
        
        //////////////////////
        // Create Opportunity Line Item
        Product2 product = Test_Utils.createProduct();
        product.Types_of_Sale__c = 'Data';
        insert product;
        
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);

        Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
        // method to add billingproduct to lineItem.
        
        //PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, priceBook.Id, 'USD');  // needed to remove this to avoid duplicate entry error
        //OpportunityLineItem opportunityLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
        OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (TotalPrice = 200, UnitPrice = null, Quantity = 1,
                                                   OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Order_Type__c = Constants.STATUS_NEW ,
                                                   Start_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(10));
        insert opportunityLineItem;

        /////////////////////
        
        // generate a vf page taking in the address id
        PageReference pageRef = Page.OLI_BillingNSaleTypeUpdate;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('oli',opportunityLineItem.Id);
        
        OLI_BillingNSaleTypeUpdateController testUpdateController = new OLI_BillingNSaleTypeUpdateController(new ApexPages.Standardcontroller(new Opportunity()));
        //AddressDynamicCountry_Controller testController =  new AddressDynamicCountry_Controller(new ApexPages.StandardController(new Address__c()));
        testUpdateController.performCancel();
        String nextPage = testUpdateController.performCancel().getUrl();
        system.debug(nextPage);
        system.assertEquals('/006/o',nextPage);
        //testUpdateController.performSave();
        
      }

    }
    
    static testMethod void testOLIInnerClass() {
        
      // create User
      Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
      User testUser1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert testUser1;
  
      System.runAs(testUser1) {
        Global_Settings__c setting = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
        // Create an account        
        Account testAccount = Test_Utils.insertAccount();
        // Create an opportunity
        Opportunity testOpp = Test_Utils.createOpportunity(testAccount.Id);
        testOpp.Type = Constants.OPPTY_NEW_FROM_NEW;
        insert testOpp;
        
        //////////////////////
        // Create Opportunity Line Item
        Product2 product = Test_Utils.createProduct();
        product.Types_of_Sale__c = 'Data';
        insert product;
        
        Pricebook2 pricebook = Test_Utils.getPriceBook2();
        Pricebook2 standardPricebook = Test_Utils.getPriceBook2(Constants.STANDARD_PRICE_BOOK);
        PricebookEntry stdPricebookEntry = Test_Utils.insertPricebookEntry(product.Id, standardPricebook.Id, Constants.CURRENCY_USD);

        Billing_Product__c oppLineItemBillingProduct = Test_Utils.insertBillingProduct(); // insert this, then create second insertOpportunityLineItem
        // method to add billingproduct to lineItem.
        
        //PricebookEntry pricebookEntry = Test_Utils.insertPricebookEntry(product.Id, priceBook.Id, 'USD');  // needed to remove this to avoid duplicate entry error
        //OpportunityLineItem opportunityLineItem = Test_Utils.insertOpportunityLineItem(testOpp.Id, stdPricebookEntry.Id);
        OpportunityLineItem opportunityLineItem =  new OpportunityLineItem (TotalPrice = 200, UnitPrice = null, Quantity = 1,
                                                   OpportunityId = testOpp.Id, PricebookEntryId = stdPricebookEntry.Id,
                                                   Billing_Product__c = oppLineItemBillingProduct.Id, Order_Type__c = Constants.STATUS_NEW,
                                                   Start_Date__c = Date.today().addDays(5), End_Date__c = Date.today().addDays(10));
        insert opportunityLineItem;

        /////////////////////
        
        // generate a vf page taking in the address id
        PageReference pageRef = Page.OLI_BillingNSaleTypeUpdate;
        Test.setCurrentPage(pageRef);
        system.debug('TEST PAGE REFERENCE: ' + pageRef);
        
        //passing in the address id as a parameter to the current vf page (generated in this test, not a real page)
        ApexPages.currentPage().getParameters().put('oli',opportunityLineItem.Id);
        
        OLI_BillingNSaleTypeUpdateController testUpdateController = new OLI_BillingNSaleTypeUpdateController(new ApexPages.Standardcontroller(new Opportunity()));
        system.assert(testUpdateController.OLIsToUpdate != null);
        List<SelectOption> testSelOption = testUpdateController.OLIsToUpdate.get(0).TypesOfSale;
        system.assert(testSelOption != null);
        testUpdateController.OLIsToUpdate.get(0).oliRec.Type_of_Sale__c = 'List';
        Billing_Product__c oppLineItemBillingProduct2 = Test_Utils.insertBillingProduct(); 
        testUpdateController.OLIsToUpdate.get(0).oliRec.Billing_Product__c = oppLineItemBillingProduct2.Id;
        testUpdateController.performSave();
        
        OLI_BillingNSaleTypeUpdateController.Record testRec = new OLI_BillingNSaleTypeUpdateController.Record(opportunityLineItem);
        testUpdateController.performCancel();
        String nextPage = testUpdateController.performCancel().getUrl();
        system.debug(nextPage);
        system.assertEquals('/006/o',nextPage);
      }

    }   
    
}