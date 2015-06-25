/**=====================================================================
 * Appirio, Inc
 * Name: OrderSplitTriggerHandler
 * I-113908: Update Currency when inserting, currency should be same with parent
 * Created Date: Apr 30th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class OrderSplitTriggerHandler {
  //==========================================================================
  //On before insert trigger method
  //==========================================================================
  public static void onBeforeInsert(List<Order_Split__c> newList) {
    synchCurrencyWithParent(newList);
  }
  
  //Update currencyISOCode
  private static void synchCurrencyWithParent(List<Order_Split__c> newList) {
  	
  	Set<ID> orderIDs = new Set<ID>();
  	Map<ID, Order__c> orderMap = new Map<ID, Order__c>();
  	//Adding orders in collection 
  	for (Order_Split__c split : newList) {
  		if (split.Order__c != null) {
  			orderIDs.add(split.Order__c);
  		}
  	}
  	
  	//Querying orders (parent)
  	for (Order__c ord : [SELECT ID, CurrencyISOCode FROM Order__c WHERE ID IN : orderIDs]) {
  		orderMap.put(ord.ID, ord);
  	}
  	
  	//Assigning currencyIsoCode form parent
  	for (Order_Split__c split : newList) {
	  	if (orderMap.containsKey(split.Order__c) && split.CurrencyIsoCode != orderMap.get(split.Order__c).CurrencyISOCode) {
	  		split.CurrencyIsoCode = orderMap.get(split.Order__c).CurrencyISOCode;
	  	}
  	}
  }
}