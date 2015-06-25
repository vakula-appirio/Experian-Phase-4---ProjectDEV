/**============================================================================
 * Appirio, Inc
 * Name             : MembershipTriggerHandler
 * Description      : T-362372: Handler class for MembershipTrigger
 * Created Date     : Feb 16th, 2015
 * Created By       : Noopur
 *
 * Date Modified          Modified By          Description of the update
 * Feb 26th, 2015      Gaurav Kumar Chadha     T-365462 - added onAfterUpdate and HistoryTrackingUtility.statusIsUpdated
 =============================================================================*/
public class MembershipTriggerHandler {
  
  //========================================================================
  // MethodName : onAfterInsert
  // Description : Method to be called on After insert event
  //========================================================================
  public static void onAfterInsert ( List<Membership__c> newList) {
    createAndPopulateProductRequested (newList);
    HistoryTrackingUtility.logHistory(newList , null);
  }
  //========================================================================
  // MethodName : onAfterUpdate
  // Description : Method to be called on After update event
  //========================================================================
  public static void onAfterUpdate ( List<Membership__c> newList , Map<ID , Membership__c > oldMap) {
    HistoryTrackingUtility.logHistory(newList , oldMap);
  }
  
    
  //========================================================================
  // MethodName : CreateandPopulateProductRequested
  // Description : Method to create Product Requested records for the New Membership
  //               and link their fields to the Opportunity Products of the Opportunity
  //               of the Membership
  //========================================================================
   private static void createAndPopulateProductRequested ( List<Membership__c> newList ) {
    
    // properties
    Set<Id> oppIdSet = new Set<Id> ();
    Map <Id, List<OpportunityLineItem>> opportunityProductsMap = new Map<Id,List<OpportunityLineItem>> ();
    List<Product_Requested__c> productRequestedToInsert = new List<Product_Requested__c>();
    
    try{
      // fetch the opportunity ids
      for (Membership__c mem : newList) {
        if ( mem.Opportunity__c != null ) {
          oppIdSet.add(mem.Opportunity__c);
        }
      }
      
      // create map of Opportunity and its products list
      for ( OpportunityLineItem oli : [SELECT Id, Name,Product2.Name,Global_Business_Line__c,
                                               Quantity,OpportunityId,CPQ_Quantity__c
                                       FROM OpportunityLineItem
                                       WHERE OpportunityId IN :oppIdSet]) {
        if ( opportunityProductsMap.containsKey(oli.OpportunityId) ) {
          opportunityProductsMap.get(oli.OpportunityId).add(oli);
        }
        else {
          opportunityProductsMap.put( oli.OpportunityId, new List<OpportunityLineItem>{oli} );
        }
      }
      
      // iterate through the new memberships and create product requested for the records
      // where the related opportunity has line items associated to it
      for ( Membership__c mem : newList ) {
        if ( mem.Opportunity__c != null && opportunityProductsMap.containsKey(mem.Opportunity__c) &&
        opportunityProductsMap.get(mem.Opportunity__c) != null) {
          for ( OpportunityLineItem oli : opportunityProductsMap.get(mem.Opportunity__c)) {
            Product_Requested__c requestedProduct = new Product_Requested__c();
            requestedProduct.Membership_Number__c = mem.Id;
            requestedProduct.Line_of_Business__c = oli.Global_Business_Line__c;
            requestedProduct.Product_Name__c = oli.Product2.Name ;
            requestedProduct.Quantity__c = oli.CPQ_Quantity__c ;
            productRequestedToInsert.add(requestedProduct);
          }
        }
      }
      
      // insert the list if not empty
      if ( !productRequestedToInsert.isEmpty() ) {
        insert productRequestedToInsert;
      }
    }
    // catch the exception, if any
    catch ( Exception ex) {
      //save Log for Error
      apexLogHandler.createLogAndSave('MembershipTriggerHandler', 'createAandPopulateProductRequested',
                                       ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDMLMessage(i));
      }
    }
  }
}