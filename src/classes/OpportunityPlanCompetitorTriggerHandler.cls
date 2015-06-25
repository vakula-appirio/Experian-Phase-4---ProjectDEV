/**=====================================================================
 * Appirio, Inc
 * Class Name: OpportunityPlanCompetitorTriggerHandler
 * Description: I-120989: To synch currency with Opportunity Plan
 * Created Date: July 17th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class OpportunityPlanCompetitorTriggerHandler {
  
  //Before Insert method
  public static void beforeInsert (List<Opportunity_Plan_Competitor__c> newList) {
    synchCurrencyISOCodes(newList, null);
  }
  
  //Before Update method
  public static void beforeUpdate (List<Opportunity_Plan_Competitor__c> newList,
                                    Map<ID, Opportunity_Plan_Competitor__c> oldMap ) {
    synchCurrencyISOCodes(newList, oldMap);
  }
  
  //============================================================================
  // I-120989: Method to synch currencies with Opportunity Plan
  //============================================================================
  private static void synchCurrencyISOCodes(List<Opportunity_Plan_Competitor__c> newList, 
                                            Map<ID, Opportunity_Plan_Competitor__c> oldMap) {
    Set<String> oppPlnIDs = new Set<String>();
    List<Opportunity_Plan_Competitor__c> lstOppPlnCon = new List<Opportunity_Plan_Competitor__c>();
    Map<String, Opportunity_Plan__c> mapOppPlnId_OppPln = new Map<String, Opportunity_Plan__c>();
    
    //Find opp plan Ids related to Opp Plan Competitor
    for (Opportunity_Plan_Competitor__c oPlnCon : newList) {
        if (oldMap == null || (oldMap.get(oPlnCon.Id).Opportunity_Plan__c   != oPlnCon.Opportunity_Plan__c  )) {
            lstOppPlnCon.add(oPlnCon);
            oppPlnIDs.add(oPlnCon.Opportunity_Plan__c );
        }
    }
    
    if (!oppPlnIDs.isEmpty()) {
        for(Opportunity_Plan__c opp : [SELECT Id, CurrencyIsoCode, 
                                      (SELECT Id, CurrencyIsoCode From Opportunity_Plan_Competitors__r)
                                      From Opportunity_Plan__c 
                                      WHERE ID IN: oppPlnIDs]) {
            mapOppPlnId_OppPln.put(opp.Id, opp);
        }
        // Update Currency Iso code for Opp Plan Competitor
        for (Opportunity_Plan_Competitor__c oppPln : lstOppPlnCon) {
            oppPln.CurrencyISOCode = mapOppPlnId_OppPln.get(oppPln.Opportunity_Plan__c).CurrencyISOCode;
        }
    }

  }

}