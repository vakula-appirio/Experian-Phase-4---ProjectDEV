/**=====================================================================
 * Appirio, Inc
 * Name: OrderTriggerHandler_EDQ
 * Description: Implements the OrderInterface
 * Created Date: Sep 18th, 2014
 * Created By: Nathalie Le Guay(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Sep 18, 2014                  Nathalie Le Guay             Created
 * Oct 20, 2014                  Nathalie Le Guay             Adding updateOpportunityContactAddresses()
 * Oct 28th, 2014                Naresh Kr Ojha    I-136491: added method populateAddressFieldsOnOrders() 
 * Apr 13th, 2015                Paul Kissick                 Added createCreditOrderIfCredited()
 =====================================================================*/
public class OrderTriggerHandler_EDQ extends OrderTriggerHandler implements OrderInterface {

  
  public override void createOrderSplitRecord(Map<Id, Order__c> newOrdersMap) { super.createOrderSplitRecord(newOrdersMap); }
  public override void checkAccessOnAccountForUser(List<Order__c> orderList) { super.checkAccessOnAccountForUser(orderList); }
  public override void deleteOppIfOrderCancelled (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) { super.deleteOppIfOrderCancelled(newMap, oldMap); }
  public override void processOrderClosing (Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) { super.processOrderClosing(newMap, oldMap); }

  public override void validateServiceDates(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) { super.validateServiceDates(newOrdersMap, oldOrdersMap); }
  public override void populateServiceDatesOnOLI(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) { super.populateServiceDatesOnOLI(newOrdersMap, oldOrdersMap); }
  public override void multiCurrencyFieldUpdate(List<Order__c> newList, Map<ID, Order__c> oldMap) { super.multiCurrencyFieldUpdate(newList, oldMap); }
  public override void synchCurrencyISOCodes (List<Order__c> newOrders, Map<ID, Order__c> oldOrderMap) { super.synchCurrencyISOCodes(newOrders, oldOrderMap); }
  public override void updateOrderOwnerFields(List<Order__c> newOrders, Map<Id, Order__c> oldOrdersMap) { super.updateOrderOwnerFields(newOrders, oldOrdersMap); }
  public override void updateOpportunityContactAddresses(Map<Id, Order__c> newOrdersMap) { super.updateOpportunityContactAddresses(newOrdersMap); }
  public override void checkOnDemandSyncRequired(List<Order__c> orders, Map<Id, Order__c> oldOrders) { super.checkOnDemandSyncRequired(orders, oldOrders); }
  public override void populateAddressFieldsOnOrders(List<Order__c> orderList) { super.populateAddressFieldsOnOrders(orderList); }
  
  public override void createCreditOrderIfCredited(Map<ID, Order__c> newMap, Map<ID, Order__c> oldMap) { super.createCreditOrderIfCredited(newMap,oldMap); }


  //public override void deleteOppties (Set<String> opptyIDs) { super.deleteOppties(); }
  //public override void createRenewalsOnInsert (Set<ID> closedOrderIDs) { super.createRenewalsOnInsert(); }
  //public override void createRenewalsOnUpdate (Set<ID> closedOrderIDs) { super.createRenewalsOnUpdate(); }
  //public override void populateOrderAndOrderLineMaps (Set<ID> closedOrderIDs, Map<String, Order__c> ordId_ClosedOrderMap, 
  //                                    Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map) { super.populateOrderAndOrderLineMaps(); }
  //public override List<Opportunity> createOpportunitiesForClosedOrders (Map<String, Order__c> ordId_ClosedOrderMap,
  //                        Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map) { super.createOpportunitiesForClosedOrders(); }
  /*public override void createOLIs_Team_ContactRoleForNewOppty (List<Opportunity> newOpptyList,
                                    Map<String, Opportunity> oldOpptyMap,
                                    Map<String, Order__c> ordId_ClosedOrderMap,
                                    Map<String, List<Order_Line_Item__c>> serviceDate_orderLineItemList_Map) { super.createOLIs_Team_ContactRoleForNewOppty(); }*/
  /*
  public override void beforeInsert(List<Order__c> newOrders) { super.beforeInsert(newOrders); }
  public override void afterInsert(Map<Id, Order__c> newOrdersMap) { super.afterInsert(newOrdersMap); } 
  public override void beforeUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) { super.beforeUpdate(newOrdersMap, oldOrdersMap); }
  public override void afterUpdate(Map<Id, Order__c> newOrdersMap, Map<Id, Order__c> oldOrdersMap) { super.afterUpdate(newOrdersMap, oldOrdersMap); }
  */

}