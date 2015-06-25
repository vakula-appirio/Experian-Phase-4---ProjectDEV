/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityPlanContactTriggerHandler
 * Description: T-280558: Create trigger to delete Plan Contact Relationships
 * Created Date: May 23th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * July  17th, 2014             Arpita Bose(Appirio)         I-120989: To synch currency with Opportunity Plan
 =====================================================================*/
public with sharing class OpportunityPlanContactTriggerHandler {
  
  //After delete method
  public static void beforeDelete (Map<ID, Opportunity_Plan_Contact__c> oldMap) {
    deleteAssociatedPlanContacts(oldMap);
  }

  //After unDelete method
  public static void afterUnDelete (List<Opportunity_Plan_Contact__c> newList) {
    unDeleteAssociatedPlanContacts(newList);
  }
  
  //Before Insert method
  public static void beforeInsert (List<Opportunity_Plan_Contact__c> newList) {
    synchCurrencyISOCodes(newList, null);
    linkManagerContact(newList, null);
  }
  
  //Before Update method
  public static void beforeUpdate (List<Opportunity_Plan_Contact__c> newList,
                                    Map<ID, Opportunity_Plan_Contact__c> oldMap ) {
    synchCurrencyISOCodes(newList, oldMap);
    linkManagerContact(newList, oldMap);
  }
  
  //delete associated plan contacts
  private static void deleteAssociatedPlanContacts (Map<ID, Opportunity_Plan_Contact__c> opptyPlanContMap) {
    
    List<Plan_Contact_Relationship__c> planContacts = new List<Plan_Contact_Relationship__c>();
    
    for (Plan_Contact_Relationship__c pcr : [SELECT ID, Contact_2__c 
                                             FROM Plan_Contact_Relationship__c 
                                             WHERE Contact_2__c  =: opptyPlanContMap.keySet()]) {
        planContacts.add(pcr);
    }
    //Deleting records
    if (planContacts.size() > 0) {
        delete planContacts;
    }
  }
  
   //delete associated plan contacts
  private static void unDeleteAssociatedPlanContacts (List<Opportunity_Plan_Contact__c> newList) {
    
    List<Plan_Contact_Relationship__c> planContacts = new List<Plan_Contact_Relationship__c>();
    
    for (Plan_Contact_Relationship__c pcr : [SELECT ID, Contact_2__c, isDeleted 
                                             FROM Plan_Contact_Relationship__c 
                                             WHERE isDeleted = true AND Contact_2__c IN: newList ALL ROWS]) {
        planContacts.add(pcr);
    }
    //Deleting records
    if (planContacts.size() > 0) {
        undelete planContacts;
    }
  }
  
  //============================================================================
  // I-120989: Method to synch currencies with Opportunity Plan
  //============================================================================
  private static void synchCurrencyISOCodes(List<Opportunity_Plan_Contact__c> newList, 
                                            Map<ID, Opportunity_Plan_Contact__c> oldMap){
    Set<String> oppPlnIDs = new Set<String>();
    List<Opportunity_Plan_Contact__c> lstOppPlnCon = new List<Opportunity_Plan_Contact__c>();
    Map<String, Opportunity_Plan__c> mapOppPlnId_OppPln = new Map<String, Opportunity_Plan__c>();
    
    //Find opp plan Ids related to Opp Plan contact
    for(Opportunity_Plan_Contact__c oPlnCon : newList){
        if(oldMap == null || (oldMap.get(oPlnCon.Id).Opportunity_Plan__c   != oPlnCon.Opportunity_Plan__c  )){
            lstOppPlnCon.add(oPlnCon);
            oppPlnIDs.add(oPlnCon.Opportunity_Plan__c );
        }
    }
    
    if(!oppPlnIDs.isEmpty()){
        for(Opportunity_Plan__c opp : [SELECT Id, CurrencyIsoCode, 
                                      (SELECT Id, CurrencyIsoCode From Opportunity_Plan_Contacts__r)
                                      From Opportunity_Plan__c 
                                      WHERE ID IN: oppPlnIDs]){
            mapOppPlnId_OppPln.put(opp.Id, opp);
        }
        // Update Currency Iso code for Opp Plan Contact
        for(Opportunity_Plan_Contact__c oppPln : lstOppPlnCon){
            oppPln.CurrencyISOCode = mapOppPlnId_OppPln.get(oppPln.Opportunity_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }
  //============================================================================
  // T-326275: Method to Link to Manager
  //============================================================================
  private static void linkManagerContact(List<Opportunity_Plan_Contact__c> newList, 
                                            Map<ID, Opportunity_Plan_Contact__c> oldMap) {
      
      map<Id, Id> mapOppPlnConManager = new map<Id, Id>();
      map<Id,Id> oppPlanIDs = new map<Id,Id>();
      map<Id, Opportunity_Plan_Contact__c> mapOppPlnCon = new map<Id, Opportunity_Plan_Contact__c>();
      map<Id, Opportunity_Plan_Contact__c> mapOppToInsert = new map<Id, Opportunity_Plan_Contact__c>();
      Opportunity_Plan_Contact__c oppPlanCon ;
      for (Opportunity_Plan_Contact__c oPlnCon : newList) {
        if (oldMap == null || (oldMap.get(oPlnCon.Id).Link_Manager__c != oPlnCon.Link_Manager__c  )) {
          if (oPlnCon.Link_Manager__c) {
            mapOppPlnCon.put(oPlnCon.Contact__c, oPlnCon);
             
          }
          else {
            oPlnCon.Reports_to__c = null;  
          }
      }
    }
    for (Contact con : [SELECT Id, ReportsToId 
                       FROM Contact 
                       WHERE Id IN : mapOppPlnCon.keySet()]) {
       oppPlanCon = mapOppPlnCon.get(con.Id);
       mapOppPlnCon.remove(con.Id); 
       mapOppPlnCon.put(con.ReportsToId, oppPlanCon);
       oppPlanIDs.put(con.ReportsToId, oppPlanCon.Opportunity_Plan__c); 
    }
    for (Opportunity_Plan_Contact__c opc : [SELECT Id, Contact__c 
                                           FROM Opportunity_Plan_Contact__c 
                                           WHERE Contact__c IN : mapOppPlnCon.keySet() 
                                           AND Opportunity_Plan__c IN :oppPlanIDs.values()]) {
       mapOppPlnConManager.put(opc.Contact__c, opc.Id);
    }
    for (Id conId : mapOppPlnCon.keySet()) {
      if (!mapOppPlnConManager.containsKey(conId)) {
        oppPlanCon = new Opportunity_Plan_Contact__c();
        oppPlanCon.Opportunity_Plan__c = mapOppPlnCon.get(conId).Opportunity_Plan__c;
        oppPlanCon.Contact__c = conId;
        mapOppToInsert.put(conId, oppPlanCon);
      }
    }
    if (!mapOppToInsert.isEmpty()) {
      try {
        insert mapOppToInsert.values();
      } catch (DMLException ex) {
        System.debug('[OpportunityPlanContactTriggerHandler:linkManagerContact]'+ex.getMessage()); 
        ApexLogHandler.createLogAndSave('OpportunityPlanContactTriggerHandler','linkManagerContact', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i));
        }
      }
    }
    for (Id conId : mapOppPlnCon.keySet()) {
      oppPlanCon = mapOppPlnCon.get(conId);
      
      if (mapOppPlnConManager.containsKey(conId)) {
          
          if(mapOppPlnCon.get(conId).Opportunity_Plan__c == oppPlanIDs.get(conId) ) {
             oppPlanCon.Reports_to__c = mapOppPlnConManager.get(conId);
          }
      }
      else if (mapOppToInsert.containsKey(conId)) {
        oppPlanCon.Reports_to__c = mapOppToInsert.get(conId).Id;
      }
    }
  }
}