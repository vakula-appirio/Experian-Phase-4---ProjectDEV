/**=====================================================================
 * Appirio, Inc
 * Name: OrderRevenueScheduleTriggerHandler
 * Description: Trigger Helper on Order Revenue Schedule
 * Created Date: Feb 10th, 2014
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified    Modified By                 Description of the update
 * Feb 10th, 2014   Nathalie Le Guay (Appirio)  recalculateSalesPrice()
 * Apr 30th, 2014   Naresh Kr Ojha							I-113908: Update Currency when inserting, 
 *                                              currency should be same with parent, added synchCurrencyISOCode()
 =====================================================================*/
public without sharing class OrderRevenueScheduleTriggerHandler {
  //==========================================================================
  //On Before insert trigger method
  //==========================================================================
  public static void onBeforeInsert(List<Order_Revenue_Schedule__c> newList) {
    synchCurrencyISOCode(newList);
  }

  //==========================================================================
  //On after insert trigger method
  //==========================================================================
  public static void onAfterInsert(List<Order_Revenue_Schedule__c> newList) {
    recalculateSalesPrice(newList, new Map<Id, Order_Revenue_Schedule__c>());
  }

  //==========================================================================
  //On after update trigger method
  //==========================================================================
  public static void onAfterUpdate(List<Order_Revenue_Schedule__c> newList, 
                                   Map<Id, Order_Revenue_Schedule__c> oldMap) {
    recalculateSalesPrice(newList, oldMap);
  }

  //==========================================================================
  //On before delete trigger method
  //==========================================================================
  public static void onAfterDelete(Map<Id, Order_Revenue_Schedule__c> oldMap) {
    recalculateSalesPrice(new List<Order_Revenue_Schedule__c>(), oldMap);
  }

  //==========================================================================
  // Will set a flag (Recalculate_Sales_Price__c) if there was an update to the
  // Revenue Schedule's Revenue__c field
  //==========================================================================
  private static void recalculateSalesPrice(List<Order_Revenue_Schedule__c> orderRevenueSchedulesList,
                                            Map<Id, Order_Revenue_Schedule__c> oldOrderRevenueSchedulesMap) {
    Set<Id> orderLineItemIds = new Set<Id>();

    for (Order_Revenue_Schedule__c sched: orderRevenueSchedulesList) {
      if (oldOrderRevenueSchedulesMap.size() == 0
          || (oldOrderRevenueSchedulesMap.size() > 0 && sched.Revenue__c != oldOrderRevenueSchedulesMap.get(sched.Id).Revenue__c)) {
        orderLineItemIds.add(sched.Order_Line_Item__c);
      }
    }
    for (Order_Revenue_Schedule__c sched: oldOrderRevenueSchedulesMap.values()) {
      orderLineItemIds.add(sched.Order_Line_Item__c);
    }

    List<Order_Line_Item__c> olis = getOrderLineItems(orderLineItemIds);
    for (Order_Line_Item__c oliNewSalesPrice: olis) {
      oliNewSalesPrice.Recalculate_Sales_Price__c = true;
    }
    try {
      update olis;
    } catch(DMLException e) {
      System.debug('\n[OrderRevenueScheduleTriggerHandler - recalculateSalesPrice]: ERROR: '+ e.getMessage());
      
      for (Integer i = 0; i < e.getNumDml(); i++) {
        orderRevenueSchedulesList.get(0).Revenue__c.addError(e.getDmlMessage(i));
      }
    }
  }

  //==========================================================================
  // Will query Order Line Items given a set of Ids
  //==========================================================================
  private static List<Order_Line_Item__c> getOrderLineItems(Set<Id> orderLineItemIds) {
    return [SELECT Id, Recalculate_Sales_Price__c
            FROM Order_Line_Item__c 
            WHERE Id in: orderLineItemIds];
  }
  
  //==========================================================================
  // I-113908: Update Currency when inserting
  //==========================================================================
  private static void synchCurrencyISOCode (List<Order_Revenue_Schedule__c> newList) {
  	Set<ID> ordLineSet = new Set<ID>();
  	Map<ID, Order_Line_Item__c> ordLineMap = new Map<ID, Order_Line_Item__c>();
  	for (Order_Revenue_Schedule__c schedule : newList) {
  		if (schedule.Order_Line_Item__c != null) {
  			ordLineSet.add(schedule.Order_Line_Item__c);
  		}
  	}
  	//Querying related Order Lines
  	for (Order_Line_Item__c ordLine : [SELECT ID, CurrencyISOCode FROM Order_Line_Item__c 
  	                                   WHERE ID IN : ordLineSet]) {
  		ordLineMap.put(ordLine.ID, ordLine);
  	}
  	//Updating currency for schedule if that is different than Order Line Item
  	for (Order_Revenue_Schedule__c schedule : newList) {
  		if (ordLineMap.containsKey(schedule.Order_Line_Item__c) &&
  		  schedule.CurrencyISOCode != ordLineMap.get(schedule.Order_Line_Item__c).CurrencyISOCode) {
  			schedule.CurrencyIsoCode = ordLineMap.get(schedule.Order_Line_Item__c).CurrencyISOCode;
  		} 
  	}
  }
}