/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlan_CSF_TriggerHandler
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class AccountPlan_CSF_TriggerHandler {
  
  //============================================================================
  // Method called on Before Insert
  //============================================================================
  public static void beforeInsert(List<Account_Plan_Critical_Success_Factor__c> newList){
    synchCurrencyISOCodes(newList, null);
  }
  
  //============================================================================
  // Method called on Before Update
  //============================================================================
  public static void beforeUpdate(List<Account_Plan_Critical_Success_Factor__c> newList, 
                                  Map<Id, Account_Plan_Critical_Success_Factor__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Critical Success Factor
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Critical_Success_Factor__c> newList, 
                                            Map<ID, Account_Plan_Critical_Success_Factor__c> oldMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_Critical_Success_Factor__c> lstAPlanCsf = new List<Account_Plan_Critical_Success_Factor__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find acc plan Ids related to Acc Plan CSF
    for(Account_Plan_Critical_Success_Factor__c aPCsf : newList){
        if(oldMap == null || (oldMap.get(aPCsf.Id).Account_Plan__c  != aPCsf.Account_Plan__c )){
            lstAPlanCsf.add(aPCsf);
            aPlanIDs.add(aPCsf.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_Critical_Success_Factors__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Currency Iso code for Account Plan Critical Success Factor
        for(Account_Plan_Critical_Success_Factor__c apCsf : lstAPlanCsf){
            apCsf.CurrencyISOCode = mapAPlanId_APlan.get(apCsf.Account_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }

}