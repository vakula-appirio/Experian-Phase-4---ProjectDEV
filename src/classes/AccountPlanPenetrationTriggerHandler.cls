/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanPenetrationTriggerHandler
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class AccountPlanPenetrationTriggerHandler {
  
  //============================================================================
  // Method called on Before Insert
  //============================================================================
  public static void beforeInsert(List<Account_Plan_Penetration__c> newList){
    synchCurrencyISOCodes(newList, null);
  }
  
  //============================================================================
  // Method called on Before Update
  //============================================================================
  public static void beforeUpdate(List<Account_Plan_Penetration__c> newList, 
                                  Map<Id, Account_Plan_Penetration__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Penetration
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Penetration__c> newList, 
                                            Map<ID, Account_Plan_Penetration__c> oldMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_Penetration__c> lstAPlanPen = new List<Account_Plan_Penetration__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find acc plan Ids related to Acc Plan Penetration
    for(Account_Plan_Penetration__c apPen : newList){
        if(oldMap == null || (oldMap.get(apPen.Id).Account_Plan__c  != apPen.Account_Plan__c )){
            lstAPlanPen.add(apPen);
            aPlanIDs.add(apPen.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_Penetrations__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Currency Iso code for Account Plan Penetration
        for(Account_Plan_Penetration__c apPen : lstAPlanPen){
            apPen.CurrencyISOCode = mapAPlanId_APlan.get(apPen.Account_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }

}