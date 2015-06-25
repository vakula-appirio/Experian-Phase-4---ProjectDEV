/**=============================================================================
 * Experian plc
 * Name: SalesSupportRequestTriggerHandler
 * Description: Case #9748
 * Created Date: Dec 8th, 2014
 * Created By: James Weatherall
 * 
 * Date Modified        Modified By                  Description of the update
 * Dec 12th, 2014		James Weatherall			 Changed method to createSalesSupportRelatedItems
 * 													 Added code to bring Contacts through.
 * Mar 5th, 2014 	 	James Weatherall			 Case #9748: Added beforeUpdate, beforeInsert and setOwnerManager methods
 =============================================================================*/

public class SalesSupportRequestTriggerHandler {

  public static void beforeInsert(List<Sales_Support_Request__c> newList) {
    setOwnerManager(newList);
  }    
    
  public static void beforeUpdate(Map<Id, Sales_Support_Request__c> newMap, Map<Id, Sales_Support_Request__c> oldMap) {
    setOwnerManager(newMap.values());
  }
    
  public static void afterInsert(Map<Id, Sales_Support_Request__c> newMap) {
    createSalesSupportRelatedItems(newMap);
  }
    
  public static void createSalesSupportRelatedItems(Map<Id, Sales_Support_Request__c> newMap) {
    List<Sales_Support_Competitor__c> lstSalesSupportComps = new List<Sales_Support_Competitor__c>();      
    List<Sales_Support_Key_Contact__c> lstSalesSupportKCs = new List<Sales_Support_Key_Contact__c>();      
    Map<Id, Sales_Support_Request__c> mapValidSSRs = new Map<Id, Sales_Support_Request__c>();
    Map<Id, List<Competitor__c>> mapOppComps = new Map<Id, List<Competitor__c>>();
    Map<Id, List<OpportunityContactRole>> mapOppContacts = new Map<Id, List<OpportunityContactRole>>();
    Set<Id> oppIds = new Set<Id>();      
      
    // Identify the Opp Ids
    for(Sales_Support_Request__c ssr : newMap.values()) {
      if(ssr.Opportunity__c != null) {
        mapValidSSRs.put(ssr.Id, ssr);
        oppIds.add(ssr.Opportunity__c);
      }
    }
    
    // Fetch all associated Competitors
    for(Opportunity opp : [select Id, (Select Id from Competitors__r), (Select Id, ContactId from OpportunityContactRoles) from Opportunity where Id in: oppIds]) {
      mapOppComps.put(opp.Id, opp.Competitors__r);
      mapOppContacts.put(opp.Id, opp.OpportunityContactRoles);
    }
    
    Set<Id> setContacts = new Set<Id>();
      
    for(Sales_Support_Request__c ssr : mapValidSSRs.values()) {
      for(Competitor__c comp : mapOppComps.get(ssr.Opportunity__c)) {
        lstSalesSupportComps.add(new Sales_Support_Competitor__c(Sales_Support_Request__c = ssr.Id, Opportunity_Competitor__c = comp.Id));    
      }
      // Loop around Contact Roles. If a Contact has multiple roles then only add them once.
      for(OpportunityContactRole cont : mapOppContacts.get(ssr.Opportunity__c)) {
        if(!setContacts.contains(cont.ContactId)) {
          setContacts.add(cont.ContactId);
          lstSalesSupportKCs.add(new Sales_Support_Key_Contact__c(Sales_Support_Request__c = ssr.Id, Contact__c = cont.ContactId));        
        }        
      }
      setContacts.clear();
    }
      
    if(lstSalesSupportComps.size() > 0) {
      try {
        insert lstSalesSupportComps;
      } catch(DMLException ex) {
          System.debug('\n[SalesSupportRequestTriggerHandler: createSalesSupportRelatedItems : Competitors]: ['+ex.getMessage()+']]');   
      }
    } 
      
    if(lstSalesSupportKCs.size() > 0) {
      try {
        insert lstSalesSupportKCs;
      } catch(DMLException ex) {
          System.debug('\n[SalesSupportRequestTriggerHandler: createSalesSupportRelatedItems : Key Contacts]: ['+ex.getMessage()+']]');   
      }
    } 
  }
    
  public static void setOwnerManager(List<Sales_Support_Request__c> newList) {
	Set<Id> ownerIds = new Set<Id>();
    Map<Id, User> ownerManagersMap = New Map<Id, User>();

    for(Sales_Support_Request__c owners : newList)
    {
      if(!ownerIds.contains(owners.OwnerId)) {
        ownerIds.add(owners.OwnerId);
      }
    }
      
    if(ownerIds.size() > 0) {
      ownerManagersMap.putAll([select ManagerId from User where Id IN: ownerIds]);
    }
      
    for(Sales_Support_Request__c ssr : newList)
    {
      try {
        ssr.Owner_Manager__c = ownerManagersMap.get(ssr.OwnerId).ManagerId;  
      } catch(Exception ex) {
        System.debug('\n[SalesSupportRequestTriggerHandler: setOwnerManager ]: ['+ex.getMessage()+']]'); 
      }          
    }
  }
}