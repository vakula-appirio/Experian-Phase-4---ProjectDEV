/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineItem_ScheduleSetupControl_Test
 * Description: Test class to test behaviour of OrderLineItem_ScheduleSetupController.cls web service
 * Created Date: Feb 12th, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 13th, 2014               Jinesh Goyal                 T-248802
 * Mar 04th, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Apr 03rd, 2014               Arpita Bose                  T-268982: Updated a Test_Utils method from insertOrder() to insertOrderLineItems()
 * Apr 14th, 2014               Arpita Bose                  Updated oliRevenueScheduleTest()method to fix the failure
 =====================================================================*/
@isTest (seeAllData = false)
private class OrderLineItem_ScheduleSetupControl_Test {
	private static Order__c ordr;
  private static Order_Line_Item__c oli = new Order_Line_Item__c();
  private static Account acc;
  private static Contact contact;
  private static Opportunity opp;
  private static Billing_Product__c billProd;
  private static Order_Revenue_Schedule__c oRSchedule;
//============================================================//
//test method
//============================================================//  
    static testMethod void oliRevenueScheduleTest() {
      //insert test Account
      acc = Test_Utils.insertAccount ();
      //insert test Contact
      contact = Test_Utils.insertContact (acc.Id);
      //insert test Opportunity
      opp = Test_Utils.createOpportunity (acc.Id);
      insert opp;
      //insert test Order__c
      ordr = Test_Utils.insertOrder (true, acc.Id, contact.Id, opp.Id );
      //insert Billing Product
      billProd = Test_Utils.insertBillingProduct ();
      //insert test Order_Line_Item__c
      oli = Test_Utils.insertOrderLineItems (true, ordr.Id, billProd.Id); 
      //actual test begins..                               
      Test.startTest ();
      PageReference ref = new PageReference('/apex/OrderLineItem_ScheduleSetup');
      Test.setCurrentPage(ref); 
      System.currentPageReference().getParameters().put('id', oli.id); 
      System.currentPageReference().getParameters().put('editMode', 'false'); 
      OrderLineItem_ScheduleSetupController controller = new OrderLineItem_ScheduleSetupController ();
      controller.getInstallmentPeriods ();
      controller.parentURL ();
      controller.installmentPeriodSelected = Constants.INSTALLMENT_PERIOD_YEARLY;
      controller.numberOfInstallments = 5;
      //insert mode
      controller.save ();  
      controller.saveORS ();
      System.assertEquals (5, [SELECT Id FROM Order_Revenue_Schedule__c WHERE Order_Line_Item__c = :oli.Id].size());
      controller.reCalculateRevenue ();      
      System.currentPageReference().getParameters().put('editMode', 'true');
      //edit mode 
      controller = new OrderLineItem_ScheduleSetupController ();
      controller.saveORS ();
      //re-establish mode
      System.currentPageReference().getParameters().put('editMode', 'false');
      controller = new OrderLineItem_ScheduleSetupController ();
      controller.save ();
      controller.saveORS ();
      Test.stopTest ();
   }// END OF createAssetTest method
}