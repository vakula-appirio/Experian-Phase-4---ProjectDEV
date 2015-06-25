/******************************************************************************
 * Appirio, Inc
 * Name: Exports_FinanceInvoicingController_Test.cls
 * Description: Test class for Exports_FinanceInvoicingController.cls
 * Created Date: Sept 24th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified        Modified By             Description 
 * Dec 3rd 2014         Terri Kelllough         S-274030/T-337168: Added code coverage for the country filter
 * Dec 12th, 2014       Naresh Kr Ojha          T-340042: Added lines to test functionality for Business unit filter.
 * Mar 17th, 2014       Tyaga Pati              Changed Selected Status from String to List of String 
 ******************************************************************************/
@isTest(seeAllData=false)
private class Exports_FinanceInvoicingController_Test {
  
  public static testmethod void testBuildBatchOrderList(){
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
    currentUser.Region__c = 'APAC';
    currentUser.Global_Business_Line__c = 'Marketing Services';
    currentUser.Business_Line__c = 'APAC Marketing Services';
    currentUser.Office_Location__c = 'Amsterdam';
    currentUser.Department__c = 5;
    currentUser.Payroll__c = 100;
    currentUser.Business_Unit__c = 'APAC MS Data Quality';
    currentUser.Country__c = 'Ireland';
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
            
    Order__c testOrder1 = Test_Utils.insertOrder(false, testAcc.Id, con.Id, testOpp.Id);
    testOrder1.Owner_BU_on_Order_Create_Date__c = 'APAC MS Data Quality';
    testOrder1.OwnerId = currentUser.Id;

    Order__c testOrder2 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder2.Owner_BU_on_Order_Create_Date__c = 'APAC MS Data Quality';
    testOrder2.OwnerId = currentUser.Id;

    Order__c testOrder3 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder3.Owner_BU_on_Order_Create_Date__c = 'APAC MS Data Quality';
    testOrder3.OwnerId = currentUser.Id;
    testOrder3.Close_Date__c = system.today();

    Order__c testOrder4 = Test_Utils.insertOrder (false, testAcc.Id, con.Id, testOpp.Id );
    testOrder4.Owner_BU_on_Order_Create_Date__c = 'APAC MS Data Quality';
    testOrder4.OwnerId = currentUser.Id;

    

    // start test
    Test.startTest();
    List<Order__c> edqOrders = new List<Order__c>();
    edqOrders.add(testOrder1);
    edqOrders.add(testOrder2);
    edqOrders.add(testOrder3);
    edqOrders.add(testOrder4);
    insert edqOrders;
    
    Exports_FinanceInvoicingController controller = new Exports_FinanceInvoicingController();
    ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(edqOrders);
    
    //T-340042
    System.assertEquals(controller.getBatches().size(), 4); 
    controller.selectedBusinessUnits.add('APAC Marketing Services');
    System.assertEquals(controller.getBatches().size(), 4);
    
    controller.selectedRegion = 'EMEA';
    controller.searchOrders();
    
    controller.selectedCountries.add('Ireland');
    controller.selectedCountries.add('United States of America');
    controller.searchOrders();
    
    controller.selectedStatus.add(Label.EXPORT_BATCH_FILTER_EXPIRED);
    controller.searchOrders();
    
    controller.selectedOrderDate = 'Null';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedOrderDate = 'Not Null';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedOrderDate = 'Null Or Not Null';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedOrderDate = 'Specific Date';
    controller.selectedClosedDate = String.valueOf('11/03/2014');
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedOrderDate = 'Date Range Include';
    controller.dateRange1 = '11/03/2013';
    controller.dateRange2 = '11/03/2014';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedOrderDate = 'Date Range Exclude';
    controller.dateRange1 = '11/05/2011';
    controller.dateRange2 = '11/07/2014';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedBatchRecLink = Label.EXPORT_BATCH_FILTER_ORDER_PREV_NOT_EXPORTED;
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedBatchRecLink = Label.EXPORT_BATCH_FILTER_ORDER_PREV_EXPORTED;
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    controller.selectedBatchRecLink = Label.EXPORT_BATCH_FILTER_SELECT_A_BATCH_NO;
    controller.specificBatchNo = 'Batch #100';
    controller.searchOrders();
    controller.exportBatchSearch();
    controller.exportBatches();
    
    /*controller.exportCustFile();
    controller.exportRPMFile();
    controller.exportRoyaltyFile();
    controller.exportPartnerFile();
    controller.exportSummitFile();
    */
    
    system.debug('controller.batchList>>>>' +controller.batchList);
    //Exports_FinanceInvoicingController.orderWrapper ordWrap = controller.batchList[0];
    
    controller.refresh();
    
    controller.pageNumber = 1;
    
    controller.first();
    controller.last();
    controller.previous();
    controller.next();
    
    controller.hasNext = true;
    controller.hasPrevious = true;
    
    // stop test
    Test.stopTest();
    
  }

}