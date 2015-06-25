/**=====================================================================
 * Experian LLC
 * Name: AriaOrderItemDetailTriggerHandler
 * Description: Doesnt allow to delete an Order that is <>Draft Status
 * Created Date: May27th 2015
 * Created By: Sadar Yacob to prevent Delete of an Order if Order Status <> Draft
 * 
 * Date Modified                Modified By                  Description of the update
 * May 27th, 2015               Sadar Yacob          Dont allow to Delete an Order Line if the Order is not in Draft Status
 =====================================================================*/

public with sharing class AriaOrderItemDtlTriggerHandler {
  //=========================================================================
  // Before Delete Call
  //=========================================================================
  public static void beforeDelete(list<ARIA_Order_Items_Detail__c> OrdersDel) {
    for(ARIA_Order_Items_Detail__c ordl: OrdersDel) {
     if(ordl.Order_Status__c != 'Draft'  ) {
     system.debug('debug: Order ID:' + ordl.Aria_Order__r.Id + ' ,OrderLineID:' + ordl.Id + ' status:' +   ordl.Order_Status__c );
       ordl.addError('Only Order Lines in DRAFT status can be deleted!!');
     }
    }
  }
  
}