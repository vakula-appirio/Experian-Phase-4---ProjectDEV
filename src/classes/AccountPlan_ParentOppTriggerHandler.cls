/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlan_ParentOppTriggerHandler
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class AccountPlan_ParentOppTriggerHandler {
  
  //============================================================================
  // Method called on Before Insert
  //============================================================================
  public static void beforeInsert(List<Account_Plan_Parent_Opportunities__c> newList){
    synchCurrencyISOCodes(newList, null);
  }
  
  //============================================================================
  // Method called on Before Update
  //============================================================================
  public static void beforeUpdate(List<Account_Plan_Parent_Opportunities__c> newList, 
                                  Map<Id, Account_Plan_Parent_Opportunities__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Parent Opportunities
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Parent_Opportunities__c> newList, 
                                            Map<ID, Account_Plan_Parent_Opportunities__c> oldMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_Parent_Opportunities__c> lstApParentOpp = new List<Account_Plan_Parent_Opportunities__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find acc plan Ids related to Acc Plan Parent Oppty
    for(Account_Plan_Parent_Opportunities__c apParOpp : newList){
        if(oldMap == null || (oldMap.get(apParOpp.Id).Account_Plan__c  != apParOpp.Account_Plan__c )){
            lstApParentOpp.add(apParOpp);
            aPlanIDs.add(apParOpp.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_Parent_Opportunities__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Currency Iso code for Account Plan Parent Opportunities
        for(Account_Plan_Parent_Opportunities__c apParOpp : lstApParentOpp){
            apParOpp.CurrencyISOCode = mapAPlanId_APlan.get(apParOpp.Account_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }

}