/**=====================================================================
 * Appirio, Inc
 * Name: OrderInterface
 * Description: Interface class for OrderTriggerHandler.cls 
 * Created Date: Sep 18th, 2014
 * Created By: Nathalie Le Guay(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Sep 18, 2014                  Nathalie Le Guay             Created
 * Oct 20, 2014                  Nathalie Le Guay             Adding updateOpportunityContactAddresses()
 * Oct 28th, 2014                Naresh Kr Ojha               I-136491: added method populateAddressFieldsOnOrders() 
 * Feb 23rd, 2014				 James Weatherall			  Case #540469 : added method updateAssetIfOrderCancelled()
 * Apr 13th, 2015                Paul Kissick                 Case #607717 - Added createCreditOrderIfCredited() method
 =====================================================================*/
public interface OrderInterface {

  void createOrderSplitRecord(Map<Id, Order__c> newOrdersMap);
  void checkAccessOnAccountForUser(List<Order__c> orderList);
  void deleteOppIfOrderCancelled (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap);
  void updateAssetIfOrderCancelled (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap);
  //void deleteOppties (Set<String> opptyIDs);
  void processOrderClosing (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap);

  void validateServiceDates(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap);
  void populateServiceDatesOnOLI(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap);
  void multiCurrencyFieldUpdate(List<Order__c> newList, Map<ID, Order__c> oldMap);
  void synchCurrencyISOCodes (List<Order__c> newOrders, Map<ID, Order__c> oldOrderMap);
  void updateOrderOwnerFields(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap);
  void updateOpportunityContactAddresses(Map<Id, Order__c> newOrdersMap);
  void checkOnDemandSyncRequired(List<Order__c> orders, Map<Id, Order__c> oldOrders);
  void populateAddressFieldsOnOrders(List<Order__c> orderList);
  void createCreditOrderIfCredited(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap);
  
  /*void createRenewalsOnInsert (Set<ID> closedOrderIDs);
  void createRenewalsOnUpdate (Set<ID> closedOrderIDs);
  void populateOrderAndOrderLineMaps (Set<ID> closedOrderIDs, Map<String, Order__c> ordId_ClosedOrderMap, 
                                      Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map);
  List<Opportunity> createOpportunitiesForClosedOrders (Map<String, Order__c> ordId_ClosedOrderMap,
                          Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map);*/
  /*void createOLIs_Team_ContactRoleForNewOppty (List<Opportunity> newOpptyList, 
                                    Map<String, Opportunity> oldOpptyMap,
                                    Map<String, Order__c> ordId_ClosedOrderMap,
                                    Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map);*/

  /*
  void beforeInsert(List<Order__c> newOrders);
  void afterInsert(Map<Id, Order__c> newOrdersMap);
  void beforeUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap);
  void afterUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap);
  */
 
}