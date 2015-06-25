/*
 * Copyright (C) 2014 TopCoder Inc., All Rights Reserved.
 */
  
/**
 * Test class for the Product Search Controller
 * N.B. The SeeAllData is mandatory in order to test PriceBook existence
 * @author TCCODER
 * @version 1.0
 */ 
 /**=====================================================================
 * Appirio, Inc
 * Name: ProductSearchController_Test
 * Description: THIS CLASS WAS CREATED FROM A TOP CODER CHALLENGE
 *              Test class for ProductSearchController.cls
 * Created Date: April 06, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 08th, 2014               Arpita Bose(Appirio)                  T-269840: Replaced API Name of Country_Product__c to Product_Country__c
 *                                                           and Region_Product__c to Product_Region__c
 * Apr 10th, 2014               Arpita Bose                  Added IsDataAdmin__c isDateAdmin to fixed the failure
 * Sep 25th, 2014               Noopur                       Added code to create user and then run tests as that user.
                                                             Added the testMethods to increase the test coverage.
 * Oct 20th, 2014               Arpita Bose                  Updated to remove IsDataAdmin__c                 
 * Feb 26th, 2015               Paul Kissick                 Case #49531 - Removed SeeAllData and fixed isactive on all products for successful test 
                                                             completion (updated to v30)                                   
 =====================================================================*/
@isTest
private class ProductSearchController_Test {
  
  static ID priceBookStandardId;
  static Product2 product;
  static Product2 product2;
  static Product2 product3;
  static Product2 product4;
  static Account account;
  static Opportunity opportunity;
  static User usr;
  static{
    priceBookStandardId = Test.getStandardPricebookId(); // PK : Case #49531 - To remove seealldata from above
    account = Test_Utils.insertAccount();
    
    //creates 2 products
    product = new Product2(Name = '_test_Prod1');
    product.Global_Business_Line__c = Constants.USER_GBL_CREDIT_SERVICES;
    product.IsActive = true;
    insert product;
    
    PriceBookEntry pbe = new PriceBookEntry(PriceBook2Id = priceBookStandardId,
                        UnitPrice = 0,
                        Product2Id = product.Id);
    insert pbe;
    
    product2 = new Product2(Name = '_test_Prod2');
    product2.Global_Business_Line__c = Constants.USER_GBL_CREDIT_SERVICES;
    product2.IsActive = true;
    insert product2;
    
    pbe = new PriceBookEntry(PriceBook2Id = priceBookStandardId,
                        UnitPrice = 0,
                        Product2Id = product2.Id);
    insert pbe;
    
    product3 = new Product2(Name = '_test_Prod3');
    product3.Global_Business_Line__c = Constants.USER_GBL_CREDIT_SERVICES;
    product3.IsActive = true; 
    insert product3;
    
    pbe = new PriceBookEntry(PriceBook2Id = priceBookStandardId,
                        UnitPrice = 0,
                        Product2Id = product3.Id);
    insert pbe;
    
    product4 = new Product2(Name = '_test_Prod4');
    product4.Global_Business_Line__c = Constants.USER_GBL_CREDIT_SERVICES;
    product4.IsActive = true;
    insert product4;
    
    pbe = new PriceBookEntry(PriceBook2Id = priceBookStandardId,
                        UnitPrice = 0,
                        Product2Id = product4.Id);
    pbe.IsActive = true;
    insert pbe;

    opportunity = new Opportunity(Name = 'test',
                      StageName = 'Closed',
                      CloseDate = System.today());
    opportunity.AccountId = account.ID;
    opportunity.StageName = Constants.OPPTY_STAGE_3;
    opportunity.Has_Senior_Approval__c = true;
    opportunity.Amount = 100;
    opportunity.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_INDIRECT;
    opportunity.Starting_Stage__c = Constants.OPPTY_STAGE_7;
    
    insert opportunity;
    
    Country__c c1 = new Country__c(Name = 'Italy');
    insert c1;
    Country__c c2 = new Country__c(Name = 'United States');
    insert c2;
    Region__c r1 = new Region__c(Name = 'EMEA');
    insert r1;
    Region__c r2 = new Region__c(Name = 'North America');
    insert r2;
    
    insert new Product_Country__c(Product__c = product.Id, Country__c = c1.Id);
    insert new Product_Country__c(Product__c = product2.Id, Country__c = c2.Id);
    insert new Product_Region__c(Product__c = product.Id, Region__c = r1.iD);
    insert new Product_Region__c(Product__c = product2.Id, Region__c = r2.Id);
    insert new Product_Country__c(Product__c = product3.Id, Country__c = c1.Id);
    insert new Product_Country__c(Product__c = product4.Id, Country__c = c2.Id);
    insert new Product_Region__c(Product__c = product3.Id, Region__c = r1.iD);
    insert new Product_Region__c(Product__c = product4.Id, Region__c = r2.Id); 

    usr = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
    usr.Business_Unit__c = Constants.USER_GBL_CREDIT_SERVICES;
    usr.Country__c = null;
    usr.Region__c = null;
    insert usr;
  } 
  
    static testMethod void unit_test_1() {

      
     
      System.runAs( usr ) {
      
        Test.startTest();
        
        //no valid opportunity passed to the controller
        ProductSearchController controller = new ProductSearchController(new ApexPages.StandardController(new Opportunity()));
        System.assert(ApexPages.getMessages().size() == 1, '1Why not an error? '+ApexPages.getMessages());
        
        //opportunity loaded
        opportunity.Pricebook2Id = priceBookStandardId;
        opportunity.Type = 'New From New';
        update opportunity;
        
        controller = new ProductSearchController(new ApexPages.StandardController(opportunity));

        //sets an initial filter to allow test filtering (we filter out real data...because of the seeAllData)
        controller.fakeProduct.ProductName = '_test_Prod';
        controller.loadData();
        system.debug('****' +controller.records);
        System.assert(controller.records.size() == 4,' Why not 4 products? '+controller.records);
        System.assert(controller.resultSize == 4,' Why not 2 results in totale? '+controller.resultSize);
        System.assert(controller.pageSize == 10, ' Why page size is not the default value? '+controller.pageSize);
        System.assert(controller.pageNumber == 1, ' Why not 1st page? '+controller.pageNumber);
        System.assert(controller.totalPages == 1, ' Why not 1 page in total? '+controller.totalPages);
        System.assert(controller.selectedProductsValues.size() == 0, ' Why selected products? '+controller.selectedProductsValues);
        System.assert(controller.itemsSelected == false,' Why items selected? ');
        
        //changes page size to 1: should be 4 pages
        controller.newPageSize = 1;
        controller.loadData();
        
        System.assert(controller.pageSize == 1, ' Why page size is not 1? '+controller.pageSize);
        System.assert(controller.totalPages == 4, ' Why not 4 pages in total? '+controller.totalPages);
        controller.goToLastPage();
        System.assert(controller.pageNumber == 4,' Why not 4th page? '+controller.pageNumber);
        controller.goToFirstPage();
        System.assert(controller.pageNumber == 1,' Why not first page? '+controller.pageNumber);
        controller.goToNextPage();
        System.assert(controller.pageNumber == 2,' Why not 2nd page? '+controller.pageNumber);
        controller.goToNext2Page();
        System.assert(controller.pageNumber == 4,' Why not 4th page? '+controller.pageNumber);
        controller.goToPrevPage();
        System.assert(controller.pageNumber == 3,' Why not 3th page? '+controller.pageNumber);
        controller.goToPrev2Page();
        System.assert(controller.pageNumber == 1,' Why not 1st page? '+controller.pageNumber);
        controller.sortRecordset();
        
        //no product followed
        controller.toggleFollowedProducts();
        System.assert(controller.totalPages == 0,' Why filtered products? '+controller.pageNumber);
        
        //back to all fields
        controller.toggleFollowedProducts();
        ProductSearchController.SelectableProduct sp = controller.records[0];
        sp.selected = true;
        sp.selectItem();
        sp.selectItem();
        List<Object> vList = controller.selectedProductsValues;//this reloads the "itemSelected" boolean
        System.assert(controller.itemsSelected, ' Why no item selected?'+vList);
        sp.removeSelected();
        vList = controller.selectedProductsValues;//this reloads the "itemSelected" boolean
        System.assert(controller.itemsSelected==false, ' Why items selected?');
        sp.selected = true;
        sp.selectItem();
        vList = controller.selectedProductsValues;//this reloads the "itemSelected" boolean
        
        //go to second step
        controller.goSecondStep();
        System.assert(controller.lineItems.size()==1,'Why not 1 line item?');
        
        //missing required fields
        controller.saveData();
        System.assert(ApexPages.getMessages().size() == 2, 'Why no other errors? '+ApexPages.getMessages());
        
        controller.lineItems[0].selected = true;
        controller.lineItems[0].lineItem.Quantity = null;
        controller.lineItems[0].lineItem.unitPrice = null;
        controller.lineItems[0].lineItem.Start_Date__c = null;
        controller.lineItems[0].lineItem.End_Date__c = null;
        controller.lineItems[0].lineItem.Opportunity_Country__c = null;
        controller.saveData();
        System.assert(ApexPages.getMessages().size() == 3,'Why no other errors? '+ApexPages.getMessages());
        
        //start date > end date and quantity < 0
        controller.lineItems[0].lineItem.Quantity = -1;
        controller.lineItems[0].lineItem.unitPrice = 1;
        controller.lineItems[0].lineItem.Start_Date__c = System.now().date();
        controller.lineItems[0].lineItem.End_Date__c = System.now().addDays(-1).date();
        controller.lineItems[0].lineItem.Opportunity_Country__c = 'Italy';
        controller.saveData();
        System.assert(ApexPages.getMessages().size() == 4,'Why no other errors? '+ApexPages.getMessages());
        
        //save ok
        controller.lineItems[0].lineItem.End_Date__c = System.today();
        controller.lineItems[0].lineItem.Quantity = 1;
        controller.saveData();
        System.assert(ApexPages.getMessages().size() == 4, 'Why no other errors? '+ApexPages.getMessages());
        
        controller.selectedProductsValues.sort();
        
        //back to first step
        controller.goFirstStep();
        
        //test remote action
        List<AggregateResult> arList = ProductSearchController.searchFilters('_test_Prod', 'Name');
        System.assert(arList.size() == 4, 'Why not 4 results? '+arList );
        
        product.family = 'F1';
        update product;
        controller.fakeProduct.ProductFamily = 'F1';
        controller.countryFilter = [Select Id From Country__c WHere Name = 'Italy' Limit 1].Id;
        controller.regionFilter = [Select Id From Region__c WHere Name = 'EMEA' Limit 1].Id;
        controller.loadData();
        controller.assignPriceBook();
        
        //tests compare to
        ProductSearchController.SelectableProduct selProd = new ProductSearchController.SelectableProduct(new Product2(Name = 'A'),false,controller);
        ProductSearchController.SelectableProduct selProd2 = new ProductSearchController.SelectableProduct(new Product2(Name = 'B'),false,controller);
        System.assert(selProd.compareTo('TEST') == 1,'Unexpected return value');
        System.assert(selProd.compareTo(selProd2 ) == -1,'Unexpected return value');
        Test.stopTest(); 
    }
        
    }

    static testMethod void unit_test_2() {

      
     
      System.runAs( usr ) {
      
        Test.startTest();
        
            //no valid opportunity passed to the controller
            ProductSearchController controller = new ProductSearchController(new ApexPages.StandardController(new Opportunity()));
            System.assert(ApexPages.getMessages().size() == 1, '1Why not an error? '+ApexPages.getMessages());
            
            //opportunity loaded
            opportunity.Pricebook2Id = priceBookStandardId;
            opportunity.Type = 'New From Existing';
            update opportunity;
            
            controller = new ProductSearchController(new ApexPages.StandardController(opportunity));

            //sets an initial filter to allow test filtering (we filter out real data...because of the seeAllData)
            controller.fakeProduct.ProductName = '_test_Prod';
            controller.loadData();
            system.debug('****' +controller.records);
            System.assert(controller.records.size() == 4,' Why not 4 products? '+controller.records);
            System.assert(controller.resultSize == 4,' Why not 2 results in totale? '+controller.resultSize);
            System.assert(controller.pageSize == 10, ' Why page size is not the default value? '+controller.pageSize);
            System.assert(controller.pageNumber == 1, ' Why not 1st page? '+controller.pageNumber);
            System.assert(controller.totalPages == 1, ' Why not 1 page in total? '+controller.totalPages);
            System.assert(controller.selectedProductsValues.size() == 0, ' Why selected products? '+controller.selectedProductsValues);
            System.assert(controller.itemsSelected == false,' Why items selected? ');
            
          Test.stopTest();
        }
    }

    static testMethod void unit_test_3() {

      
     
      System.runAs( usr ) {
      
        Test.startTest();
        
            //no valid opportunity passed to the controller
            ProductSearchController controller = new ProductSearchController(new ApexPages.StandardController(new Opportunity()));
            System.assert(ApexPages.getMessages().size() == 1, '1Why not an error? '+ApexPages.getMessages());
            
            //opportunity loaded
            opportunity.Pricebook2Id = priceBookStandardId;
            opportunity.Type = Constants.OPPTY_TYPE_RENEWAL;
            update opportunity;
            
            controller = new ProductSearchController(new ApexPages.StandardController(opportunity));

            //sets an initial filter to allow test filtering (we filter out real data...because of the seeAllData)
            controller.fakeProduct.ProductName = '_test_Prod';
            controller.loadData();
            system.debug('****' +controller.records);
            System.assert(controller.records.size() == 4,' Why not 4 products? '+controller.records);
            System.assert(controller.resultSize == 4,' Why not 2 results in totale? '+controller.resultSize);
            System.assert(controller.pageSize == 10, ' Why page size is not the default value? '+controller.pageSize);
            System.assert(controller.pageNumber == 1, ' Why not 1st page? '+controller.pageNumber);
            System.assert(controller.totalPages == 1, ' Why not 1 page in total? '+controller.totalPages);
            System.assert(controller.selectedProductsValues.size() == 0, ' Why selected products? '+controller.selectedProductsValues);
            System.assert(controller.itemsSelected == false,' Why items selected? ');
            
        Test.stopTest();
        }
    }

    static testMethod void unit_test_4() {

      
     
      System.runAs( usr ) {
      
        Test.startTest();
        
            //no valid opportunity passed to the controller
            ProductSearchController controller = new ProductSearchController(new ApexPages.StandardController(new Opportunity()));
            System.assert(ApexPages.getMessages().size() == 1, '1Why not an error? '+ApexPages.getMessages());
            
            //opportunity loaded
            opportunity.Pricebook2Id = priceBookStandardId;
            opportunity.Type = 'Change';
            update opportunity;
            
            controller = new ProductSearchController(new ApexPages.StandardController(opportunity));

            //sets an initial filter to allow test filtering (we filter out real data...because of the seeAllData)
            controller.fakeProduct.ProductName = '_test_Prod';
            controller.loadData();
            System.assert(controller.records.size() == 4,' Why not 4 products? '+controller.records);
            System.assert(controller.resultSize == 4,' Why not 2 results in totale? '+controller.resultSize);
            System.assert(controller.pageSize == 10, ' Why page size is not the default value? '+controller.pageSize);
            System.assert(controller.pageNumber == 1, ' Why not 1st page? '+controller.pageNumber);
            System.assert(controller.totalPages == 1, ' Why not 1 page in total? '+controller.totalPages);
            System.assert(controller.selectedProductsValues.size() == 0, ' Why selected products? '+controller.selectedProductsValues);
            System.assert(controller.itemsSelected == false,' Why items selected? ');
          Test.stopTest();
        }
    }
}