/**============================================================================
 * Appirio, Inc
 * Name             : MembershipTrigger_Test
 * Description      : T-362372: Test class for MembershipTrigger
 * Created Date     : Feb 16th, 2015
 * Created By       : Noopur
 *
 * Date Modified          Modified By          Description of the update
 * Apr 29th, 2015         Noopur               Update to createHistoryRecord() to verify History__c records status are updated
 =============================================================================*/
@isTest(seealldata=false)
private class MembershipTrigger_Test {

    static list<Opportunity> opportunities ;

    //=========================================
    // MethodName : createTestData
    // Description: Method to create Test data
    //=========================================
    static void createTestData() {
      Account acc = Test_Utils.createAccount();
      acc.Name ='testAcc';
      insert acc;
      opportunities = new List<Opportunity> ();
      opportunities.add(Test_Utils.createOpportunity(acc.Id));
      opportunities.add(Test_Utils.createOpportunity(acc.Id));
      opportunities.add(Test_Utils.createOpportunity(acc.Id));
      opportunities.add(Test_Utils.createOpportunity(acc.Id));
      opportunities.add(Test_Utils.createOpportunity(acc.Id));
      insert opportunities ;
      
         
      //=====================================
      // Create Opportunity Line Item
      //======================================
      Product2 product = Test_Utils.insertProduct();
      product.RevenueScheduleType = Constants.REVENUE_SCHEDULED_TYPE_REPEAT;
      product.RevenueInstallmentPeriod = Constants.INSTALLMENT_PERIOD_DAILY;
      product.NumberOfRevenueInstallments = 2;
      //product.CanUseQuantitySchedule = false;
      product.CanUseRevenueSchedule = true;

      update product;
      PricebookEntry stdPricebookEntryObj = Test_Utils.insertPricebookEntry(product.Id, Test.getStandardPricebookId(), Constants.CURRENCY_USD);
      //insert OLI
      List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
      for ( Integer i = 0; i < 5; i++ ) {
        OpportunityLineItem oli1 = Test_Utils.createOpportunityLineItem(opportunities[i].Id, Test.getStandardPricebookId(), opportunities[i].Type);
        OpportunityLineItem oli2 = Test_Utils.createOpportunityLineItem(opportunities[i].Id, Test.getStandardPricebookId(), opportunities[i].Type);
        oli1.Start_Date__c = Date.today().addDays(-10);
        oli1.End_Date__c = Date.today().addDays(10);
        oli2.Start_Date__c = Date.today().addDays(-10);
        oli2.End_Date__c = Date.today().addDays(10);
        olis.add(oli1);
        if ( i != 4) {
          olis.add(oli2);
        }

      }
      insert olis;
    }

    //@isTest
    static void basicTest() {
       createTestData();
       list<Membership__c> memberships = new list<Membership__c> ();
       for( Integer i = 0; i < 5; i++ ) {
          Membership__c mem = new Membership__c();
          mem.Opportunity__c = opportunities[i].Id;
          mem.Service_Area__c = '123';
          mem.Bill_Code__c = '123';
          memberships.add(mem);
       }
       test.startTest() ;
       insert memberships;
       test.stopTest();

       // Verify that the Product Requested records have been created
       Map<Id, List<Product_Requested__c>> productRequestedMap = new Map<Id, List<Product_Requested__c>>();
       for ( Product_Requested__c pr : [SELECT Id,Membership_Number__c ,Line_of_Business__c,
                                               Product_Name__c, Quantity__c
                                        FROM Product_Requested__c
                                        WHERE Membership_Number__c IN : memberships] ) {
          if ( productRequestedMap.containsKey(pr.Membership_Number__c) ) {
             productRequestedMap.get(pr.Membership_Number__c).add(pr);
          }
          else {
             productRequestedMap.put(pr.Membership_Number__c, new List<Product_Requested__c>{pr});
          }
       }

       system.assert (productRequestedMap.get(memberships[0].Id).size() == 2);
       system.assert (productRequestedMap.get(memberships[1].Id).size() == 2);
       system.assert (productRequestedMap.get(memberships[2].Id).size() == 2);
       system.assert (productRequestedMap.get(memberships[3].Id).size() == 2);
       system.assert (productRequestedMap.get(memberships[4].Id).size() == 1);
    }

    @isTest
    private static void createHistoryRecord(){
      
      List<History_Tracking_Object_Fields__c> historyTrackingObjectFields = new List<History_Tracking_Object_Fields__c>();
      History_Tracking_Object_Fields__c historyFields = new History_Tracking_Object_Fields__c();
      historyFields.Change_Type__c = 'Owner';
      historyFields.Field_To_Track__c = 'OwnerId';
      historyFields.Object_Name__c = 'Membership__c';
      historyFields.Name = 'Membership__c-OwnerId';
      historyTrackingObjectFields.add(historyFields);
      
      History_Tracking_Object_Fields__c historyFields1 = new History_Tracking_Object_Fields__c();
      historyFields1.Change_Type__c = 'Status';
      historyFields1.Field_To_Track__c = 'Status__c';
      historyFields1.Object_Name__c = 'Membership__c';
      historyFields1.Name = 'Membership__c-Status__c';
      historyTrackingObjectFields.add(historyFields1);
      
      insert historyTrackingObjectFields;
      
      
      Membership__c mem = new Membership__c();
      mem.Service_Area__c = '123';
      mem.Bill_Code__c = '123';
      mem.Physical_Fee__c = 'Charge My Cost Center';
      mem.Status__c = 'Not Started';
      
      Test.startTest();
      insert mem;
      
      List<History__c> hisRec1 = [ SELECT ID , Membership__c, New_Status__c
                             FROM History__c 
                             WHERE Membership__c = :mem.Id];
      system.debug('hisRec1 : ' + hisRec1);
      system.assert(hisRec1 != null);
      system.assert(hisRec1.size() == 2);

      //mem.Service_Area__c = '124';
      //mem.Bill_Code__c = '1234';
      //mem.Physical_Fee__c = 'Payment Information Provided';
      HistoryTrackingUtility.hasRun = false;
      mem.Status__c = 'In Progress';
      update mem;
      
      Test.stopTest();
      
      System.debug('Anydatatype_msg');
      System.debug('mem>>'+mem); 
      System.debug('historyRec>>'+[SELECT ID , Membership__c , New_Status__c 
								                    FROM History__c 
								                    WHERE Membership__c = :mem.ID]);
                    
      List<History__c> hisRec2 = [ SELECT ID , Membership__c , New_Status__c 
                             FROM History__c 
                             WHERE Membership__c = :mem.ID 
                             AND New_Status__c = 'In Progress' ];

      system.assert(hisRec2 != null); 
      system.assertEquals(1,hisRec2.size());   

    } 
}