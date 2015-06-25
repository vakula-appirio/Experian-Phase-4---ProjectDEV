/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanCompetitorTriggerHandler
 * Description: I-120524
 * Created Date: Jul 14th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class AccountPlanCompetitorTriggerHandler {
  
  //============================================================================
  // Method called on Before Insert
  //============================================================================
  public static void beforeInsert(List<Account_Plan_Competitor__c> newList){
    synchCurrencyISOCodes(newList, null);
  }
  
  //============================================================================
  // Method called on Before Update
  //============================================================================
  public static void beforeUpdate(List<Account_Plan_Competitor__c> newList, 
                                  Map<Id, Account_Plan_Competitor__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Competitor
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Competitor__c> newList, 
                                            Map<ID, Account_Plan_Competitor__c> oldMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_Competitor__c> lstAPlanComp = new List<Account_Plan_Competitor__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find account Ids related to competitors
    for(Account_Plan_Competitor__c aPComp : newList){
        if(oldMap == null || (oldMap.get(aPComp.Id).Account_Plan__c  != aPComp.Account_Plan__c )){
            lstAPlanComp.add(aPComp);
            aPlanIDs.add(aPComp.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_Competitors__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Competitor's Name from account name
        for(Account_Plan_Competitor__c aPcomp : lstAPlanComp){
            aPcomp.CurrencyISOCode = mapAPlanId_APlan.get(aPcomp.Account_Plan__c).CurrencyISOCode;
        }
    }                                        	
  	
  }

}