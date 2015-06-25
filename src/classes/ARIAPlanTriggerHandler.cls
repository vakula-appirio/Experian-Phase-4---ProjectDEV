/**=====================================================================
 * Appirio, Inc
 * Name: ARIAPlanTriggerHandler
 * Description: T-264687: Update related AriaBillingAccount to push to ARIA
 * Created Date: Apr 02nd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Aug 05th, 2014               Arpita Bose(Appirio)         T-286337: Refactoring of ARIA classes
 =====================================================================*/
public with sharing class ARIAPlanTriggerHandler {

  //=========================================================================
  // After Update Call
  //=========================================================================
  public static void afterUpdate(List<ARIA_Plan__c> newList, Map<ID, ARIA_Plan__c> oldMap) {
    updateRelatedAriaBilingAccounts(newList, oldMap);
  }

  //=========================================================================
  // T-264687: Update related AriaBilingAccount.SendBillAccToAria = true
  //=========================================================================
  private static void updateRelatedAriaBilingAccounts (List<ARIA_Plan__c> newList, 
                                                       Map<ID, ARIA_Plan__c> oldMap) {
    Set<String> ARIA_PlanIDs = new Set<String>();
    Map<ID, ARIA_Billing_Account__c> ARIABillingAccountMap = new Map<ID, ARIA_Billing_Account__c>();

    // Check whether the AriaPlan getting updated with PlanName or PlanNumber
    for (ARIA_Plan__c ARIAPlan : newList) {
      if ((ARIAPLan.Plan_Name__c != oldMap.get(ARIAPLan.ID).Plan_Name__c) || 
              (ARIAPLan.Plan_Number__c != oldMap.get(ARIAPLan.ID).Plan_Number__c)) {
        ARIA_PlanIDs.add(ARIAPLan.ID);
      }
    }
    // Fetch related ARIA billing account with Push to Aria = yes 
    // and update them with Send billingAccountToAria = true
    if (ARIA_PlanIDs.size() > 0) {
      for (ARIA_Billing_Account__c billingAccount : [SELECT ID, Push_To_Aria__c, SendBillingAccntToAria__c 
                                                     FROM ARIA_Billing_Account__c 
                                                     WHERE Master_Plan__c IN :ARIA_PlanIDs 
                                                     AND Push_To_Aria__c =: Constants.PICKLISTVAL_YES]) {
        billingAccount.SendBillingAccntToAria__c = true;
        ARIABillingAccountMap.put(billingAccount.ID, billingAccount);
      }
      if (ARIABillingAccountMap.values().size() > 0) {
        update ARIABillingAccountMap.values();
      }
    }
  }
}