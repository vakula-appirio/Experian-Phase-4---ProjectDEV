/**=====================================================================
 * Experian LLC
 * Name: AriaOrderTriggerHandler
 * Description: Doesnt allow to delete an Order that is <>Draft Status
 * Created Date: Apr 1st, 2014
 * Created By: Sadar Yacob to prevent Delete of an Order if Order Status <> Draft
 * 
 * Date Modified                Modified By                  Description of the update
 * Aug 05th, 2014               Arpita Bose(Appirio)         T-286337: Refactoring of ARIA classes
 =====================================================================*/

public with sharing class AriaOrderTriggerHandler {
  //=========================================================================
  // Before Delete Call
  //=========================================================================
  public static void beforeDelete(list<ARIA_Order__c> OrdersDel) {
    for(ARIA_Order__c ordr: OrdersDel) {
     if(ordr.Status__c!= 'Draft' ) {
       ordr.addError('Only Orders in DRAFT status can be deleted!!');
     }
    }
  }
  
}