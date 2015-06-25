/**=====================================================================
 * Appirio, Inc
 * Name: Order_Lock_WS
 * Description: Web-Service to Lock an Order
 * Created Date: Feb 11th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 31st, 2014               Naresh kr Ojha               T-266919: Moved getRecType() method to DescribeUtility
 * Apr 3rd, 2014                Nathalie Le Guay             set order.Locked__c to true
 * Apr 8th, 2014                Naresh Kr Ojha               T-269235: in method lockOrder(), stamping Order_Original_Value with Order.Total__c
 * Apr 9th, 2014                Arpita Bose                  T-269372: Added addError()in try-catch block
 * Apr 9th, 2014                Nathalie Le Guay             T-270470: update lockOrder(): Order Revenue Schedules RT = 'Read Only'
 =====================================================================*/
global without sharing class Order_Lock_WS {
  webservice static void lockOrder(Id recordId) {
    String oliReadOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER_LINE_ITEM, Constants.READ_ONLY);
    String orderReadOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    String orderScheduleReadOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER_REVENUE_SCHEDULE, Constants.READ_ONLY);

    List<Order__c> orderToUpdate = new List<Order__c>();
    List<Order_Line_Item__c> olisToUpdate = new List<Order_Line_Item__c>();
    List<Order_Revenue_Schedule__c> orderSchedulesToUpdate = new List<Order_Revenue_Schedule__c>();

    if (orderReadOnlyRT != null) {
      for (Order__c orderRecord: [SELECT Id, RecordTypeId, Total__c, Original_Order_Value__c
                                FROM Order__c
                                WHERE Id =: recordId]) {
        orderRecord.RecordTypeId = orderReadOnlyRT; 
        orderRecord.Locked__c = true;
        orderRecord.Original_Order_Value__c = orderRecord.Total__c;
        orderToUpdate.add(orderRecord);
      }
    }

    if (olisToUpdate != null) {
      for (Order_Line_Item__c oli : [SELECT Id, RecordTypeId,
                                            (SELECT Id, RecordTypeId 
                                             FROM Order_Revenue_Schedules__r)
                                     FROM Order_Line_Item__c 
                                     WHERE Order__c = :recordId]) {
        oli.RecordTypeId = oliReadOnlyRT;
        olisToUpdate.add(oli);
        for (Order_Revenue_Schedule__c schedule: oli.Order_Revenue_Schedules__r) {
          schedule.RecordTypeId = orderScheduleReadOnlyRT;
          orderSchedulesToUpdate.add(schedule);
        }
      }
    }

    try {
      update orderToUpdate;
    } catch(DMLException e) {
      System.debug  ('\nError updating Order: '+ e.getMessage());
      apexLogHandler.createLogAndSave('Order_Lock_WS','lockOrder', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {
        orderToUpdate.get(0).addError(e.getDMLMessage(i));
      }
    }
    try {
      update olisToUpdate;
    } catch(DMLException e) {
      System.debug('\nError updating Order Line Item: '+ e.getMessage());
      apexLogHandler.createLogAndSave('Order_Lock_WS','lockOrder', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {
        olisToUpdate.get(0).addError(e.getDMLMessage(i));
      }
    }
    try {
      update orderSchedulesToUpdate;
    } catch(DMLException e) {
      System.debug('\nError updating Order Revenue Schedule: '+ e.getMessage());
      apexLogHandler.createLogAndSave('Order_Lock_WS','lockOrder', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {
        orderSchedulesToUpdate.get(0).addError(e.getDMLMessage(i));
      }
    }
  }
  

}