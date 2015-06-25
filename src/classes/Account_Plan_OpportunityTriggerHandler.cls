/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_OpportunityTriggerHandler
 * Description: Handler class for Account_Plan_OpportunityTrigger (for T-276706)
 * Created Date: May 6th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update
 * May 19th, 2014     Naresh Kr Ojha (Appirio)   T-278987: update Account Plan Parent Opps
 * Jul 14th, 2014     Arpita Bose (Appirio)      I-120524: Added method to synchcurrencyISO code on beforeInsert and beforeUpdate 
 =====================================================================*/
public class Account_Plan_OpportunityTriggerHandler {
    
    //=========================================================================
  //After Insert Call
  //=========================================================================
  public static void afterInsert(List<Account_Plan_Opportunity__c> newAccountPlanOpportunities){
    Account_Plan_OpportunityTriggerHandler.createAccountPlanOpportunitySwotEntries(newAccountPlanOpportunities);
  }
  
  //============================================================================
  // After Update Call
  //============================================================================
  public static void afterUpdate (List<Account_Plan_Opportunity__c> newList, Map<ID, Account_Plan_Opportunity__c> oldMap) {
    calculateAccPlanParentOppsRevenue (newList, oldMap);
  }

  //============================================================================
  // After Delete Call
  //============================================================================
  public static void afterDelete (Map<ID, Account_Plan_Opportunity__c> oldMap) {
    calParentOpptyRevOnDelAccPlanOppty(null, oldMap);
  }

  //============================================================================
  // After Update Call
  //============================================================================
  public static void afterUnDelete (List<Account_Plan_Opportunity__c> newList) {
    calParentOpptyRevOnDelAccPlanOppty (newList, null);
  }

  //============================================================================
  // Before Update Call
  //============================================================================
  public static void beforeUpdate(List<Account_Plan_Opportunity__c> newList, 
                                    Map<ID, Account_Plan_Opportunity__c> oldMap) {
    updateAccPlanOppFieldsForNewOpp(newList, oldMap); // update account plan for new opportunity.
    synchCurrencyISOCodes(newList, oldMap);  //I-120524                                 
  }
  
  //============================================================================
  // Before Insert Call
  //============================================================================
  public static void beforeInsert(List<Account_Plan_Opportunity__c> newList) {
    synchCurrencyISOCodes(newList, null);  //I-120524    
    updateAccPlanOppFieldsForNewOpp(newList, null);       //I-121001                      
  }
  
  //=========================================================================
  // Generic Utility methods for creating related account plan opp swot entries
  //=========================================================================
  public static void createAccountPlanOpportunitySwotEntries(List<Account_Plan_Opportunity__c> newAccountPlanOpportunities){
    // When an Account Plan Opportunity is created the code needs to create an Account Plan Opportunity SWOT record for that Account Plan 
    // Opportunity and associate it will all existing Account Plan SWOTs. That are associated with the related Account Plan.
    List<Account_Plan_Opportunity_SWOT__c> toBeInsertedAccPlanOppSwots = new List<Account_Plan_Opportunity_SWOT__c>();
    Map<Id, Account_Plan__c> idToAccountPlanMap = new Map<Id, Account_Plan__c>();
    Set<Id> accountPlanIds = new Set<Id>();
    // iterate trigger.new to get a set of related account plan ids
    for(Account_Plan_Opportunity__c accountPlanOpp : newAccountPlanOpportunities){
      if(accountPlanOpp.Account_Plan__c <> NULL){
        accountPlanIds.add(accountPlanOpp.Account_Plan__c);
      }
    }
    // query account plan with related account plan opportunities list based on the account plan ids set    
    if(!accountPlanIds.isEmpty()){
      idToAccountPlanMap = getAccountPlanSwotsMapOnAccountPlan(accountPlanIds);
    }
    
    // re-iterate trigger.new to execute the business logic to prepare a list of Account_Plan_Opportunity_SWOTs to be inserted
    for(Account_Plan_Opportunity__c accountPlanOpp : newAccountPlanOpportunities){
        // check if map contains account plan record
      if(accountPlanOpp.Account_Plan__c <> NULL && idToAccountPlanMap.containsKey(accountPlanOpp.Account_Plan__c)){
        Account_Plan__c accountPlan = idToAccountPlanMap.get(accountPlanOpp.Account_Plan__c);
        // iterate related account plan opportunities
        for(Account_Plan_SWOT__c accountPlanSwot : accountPlan.Account_Plan_SWOT__r){
          toBeInsertedAccPlanOppSwots.add(getAccountPlanOpportunitySWOT(accountPlanOpp.id, accountPlanSwot.id));
        }
      }
    }
    // verify if inserted list is not empty
    if(!toBeInsertedAccPlanOppSwots.isEmpty()){
      try{
        insert toBeInsertedAccPlanOppSwots;
      }catch(DMLException ex){
         apexLogHandler.createLogAndSave('Account_Plan_OpportunityTriggerHandler','createAccountPlanOpportunitySwotEntries', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newAccountPlanOpportunities.get(0).addError(ex.getDMLMessage(indx));
        }
      }
    }
  }
  
  //===================================================================================
  // Generic Utility methods to get instance of Account_Plan_Opportunity_SWOT__c record
  //====================================================================================
  public static Account_Plan_Opportunity_SWOT__c getAccountPlanOpportunitySWOT(string idAccountPlanOpportunity, string idAccountPlanSwot){
    return new Account_Plan_Opportunity_SWOT__c(
                                                Account_Plan_Opportunity__c = idAccountPlanOpportunity,
                                                Account_Plan_SWOT__c = idAccountPlanSwot
                                               );
  }
  
  //===================================================================================
  // Generic Utility methods to get Map of related account plans
  //====================================================================================
  public static Map<Id, Account_Plan__c> getAccountPlanSwotsMapOnAccountPlan(Set<Id> accountPlanIds){
    return new Map<Id, Account_Plan__c>([SELECT Id, 
               (SELECT Id FROM Account_Plan_SWOT__r) 
            FROM Account_Plan__c 
            WHERE ID in : accountPlanIds]);
  }
 
  //===================================================================================
  // T-278987: Calculate AccountPlanParentOpps revenue
  //===================================================================================
  private static void calculateAccPlanParentOppsRevenue (List<Account_Plan_Opportunity__c> newList, 
                                                           Map<ID, Account_Plan_Opportunity__c> oldMap
                                                           ) {
    
    Set<ID> newAssociationAPOSet = new Set<ID>();
    Set<ID> remAssociationAPOSet = new Set<ID>();
    Map<ID, ID> chngAssociationAPOMap = new Map<ID, ID>();
    
    for (Account_Plan_Opportunity__c apo : newList) {
        //New association with Acc Plan Parent Oppty
        if (apo.Account_Plan_Parent_Opportunity__c != null && oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c == null) {
            newAssociationAPOSet.add(apo.Account_Plan_Parent_Opportunity__c);
        }
        //Removal association with Acc Plan Parent Oppty
        if (apo.Account_Plan_Parent_Opportunity__c == null && oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c != null) {
            remAssociationAPOSet.add(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
        }
        //Change association from old to new, transfer amount to new
        if (apo.Account_Plan_Parent_Opportunity__c != null && oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c != null) {
            chngAssociationAPOMap.put(apo.Account_Plan_Parent_Opportunity__c, oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
        }
    }

    Map<ID, Account_Plan_Parent_Opportunities__c> accPlanParentOppMap = new Map<ID, Account_Plan_Parent_Opportunities__c>();
    for (Account_Plan_Parent_Opportunities__c appo : [Select Annualised_Revenue__c, Id, Annualised_Won_Revenue__c, Annualised_Open_Revenue__c 
                                                      From Account_Plan_Parent_Opportunities__c 
                                                      WHERE ID IN: newAssociationAPOSet OR ID IN: remAssociationAPOSet
                                                           OR ID IN: chngAssociationAPOMap.keySet() 
                                                           OR ID IN: chngAssociationAPOMap.values()]) {
        accPlanParentOppMap.put(appo.ID, appo);
    }
    
    
    Account_Plan_Parent_Opportunities__c tempAppo;
    
    for (Account_Plan_Opportunity__c apo : newList) {
        //New association of Account Plan Parent Opportunity
        if (newAssociationAPOSet.contains(apo.Account_Plan_Parent_Opportunity__c) && apo.Annualised_Revenue__c != null) {
            tempAppo = accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = (tempAppo.Annualised_Revenue__c != null) ? tempAppo.Annualised_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            if (apo.Status__c == 'Open') {
                accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = (tempAppo.Annualised_Open_Revenue__c != null) ? tempAppo.Annualised_Open_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            } else if (apo.Status__c == 'Won') {
                accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = (tempAppo.Annualised_Won_Revenue__c != null) ? tempAppo.Annualised_Won_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            } 
        }
        //System.assertEquals(chngAssociationAPOMap.get(apo.Account_Plan_Parent_Opportunity__c), oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
      //Change association to other record of Account plan parent opportunity
      if (apo.Annualised_Revenue__c != null && chngAssociationAPOMap.containsKey(apo.Account_Plan_Parent_Opportunity__c) && 
               chngAssociationAPOMap.get(apo.Account_Plan_Parent_Opportunity__c) == oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c) {
        //Adding value to new AccPlanParentOppty
        tempAppo = accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c);
        accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = (tempAppo.Annualised_Revenue__c != null) ? tempAppo.Annualised_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
        //Removal value from old AccPlanParentOppty
        tempAppo = accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
        accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = ((tempAppo.Annualised_Revenue__c > 0 && tempAppo.Annualised_Revenue__c > apo.Annualised_Revenue__c) == true) ? tempAppo.Annualised_Revenue__c - apo.Annualised_Revenue__c : 0;

            if (apo.Status__c == 'Open') {
            //Adding value to new AccPlanParentOppty
            tempAppo = accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = (tempAppo.Annualised_Open_Revenue__c != null) ? tempAppo.Annualised_Open_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            //Removal value from old AccPlanParentOppty
            tempAppo = accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = ((tempAppo.Annualised_Open_Revenue__c > 0 && tempAppo.Annualised_Open_Revenue__c > apo.Annualised_Revenue__c) == true) ? tempAppo.Annualised_Open_Revenue__c - apo.Annualised_Revenue__c : 0;
            } else if (apo.Status__c == 'Won') {
            //Adding value to new AccPlanParentOppty
            tempAppo = accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = (tempAppo.Annualised_Won_Revenue__c != null) ? tempAppo.Annualised_Won_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            //Removal value from old AccPlanParentOppty
            tempAppo = accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = ((tempAppo.Annualised_Won_Revenue__c > 0 && tempAppo.Annualised_Won_Revenue__c > apo.Annualised_Revenue__c) == true) ? tempAppo.Annualised_Revenue__c - apo.Annualised_Revenue__c : 0;
            }


      }
        //Removal of association Account Plan Parent Opportunity
        else if (apo.Annualised_Revenue__c != null && remAssociationAPOSet.contains(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c)) {
        tempAppo = accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
            accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = (tempAppo.Annualised_Revenue__c != null) ? tempAppo.Annualised_Revenue__c-apo.Annualised_Revenue__c : 0;

            if (apo.Status__c == 'Open') {
              accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = (tempAppo.Annualised_Open_Revenue__c != null) ? tempAppo.Annualised_Open_Revenue__c-apo.Annualised_Revenue__c : 0;
            } else if (apo.Status__c == 'Won') {
              accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = (tempAppo.Annualised_Won_Revenue__c != null) ? tempAppo.Annualised_Won_Revenue__c-apo.Annualised_Revenue__c : 0;           
        }
            
        }
    }
    
    //Updation of final values    
    if (accPlanParentOppMap.values().size() > 0) {
        update accPlanParentOppMap.values();
    }
  }
  
  //============================================================================
  // Delete record should recalculate Account Plan Parent Oppty revenue
  //============================================================================
  private static void calParentOpptyRevOnDelAccPlanOppty (List<Account_Plan_Opportunity__c> newList, 
                                                        Map<ID, Account_Plan_Opportunity__c> oldMap) {
    
    Set<ID> remAccPlanAPOSet = new Set<ID>();
    Map<ID, ID> chngAssociationAPOMap = new Map<ID, ID>();
    Account_Plan_Parent_Opportunities__c tempAppo;
    List<Account_Plan_Opportunity__c> apoList;
    if (oldMap != null) {
      apoList = oldMap.values();
    } else {
        apoList = newList;
    }
        
    for (Account_Plan_Opportunity__c apo : apoList) {
        //New association with Acc Plan Parent Oppty
        if (apo.Account_Plan_Parent_Opportunity__c != null) {
            remAccPlanAPOSet.add(apo.Account_Plan_Parent_Opportunity__c);
        }
    }

    Map<ID, Account_Plan_Parent_Opportunities__c> accPlanParentOppMap = new Map<ID, Account_Plan_Parent_Opportunities__c>();
    for (Account_Plan_Parent_Opportunities__c appo : [Select Annualised_Revenue__c, Id, Annualised_Won_Revenue__c, Annualised_Open_Revenue__c 
                                                      From Account_Plan_Parent_Opportunities__c 
                                                      WHERE ID IN: remAccPlanAPOSet]) {
        accPlanParentOppMap.put(appo.ID, appo);
    }

    for (Account_Plan_Opportunity__c apo : apoList) {
        //Removal of association Account Plan Parent Opportunity
        if (oldMap != null && remAccPlanAPOSet.contains(apo.Account_Plan_Parent_Opportunity__c)) {
        //Removal value from old AccPlanParentOppty
        tempAppo = accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c);
        accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = 
                                   (tempAppo.Annualised_Revenue__c != null) ? 
                                           tempAppo.Annualised_Revenue__c - apo.Annualised_Revenue__c : 0;
            if (apo.Status__c == 'Open') {
            accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = 
                                       (tempAppo.Annualised_Open_Revenue__c != null) ? 
                                               tempAppo.Annualised_Open_Revenue__c - apo.Annualised_Revenue__c : 0;
            } else if (apo.Status__c == 'Won') {
            accPlanParentOppMap.get(oldMap.get(apo.ID).Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = 
                                       (tempAppo.Annualised_Won_Revenue__c != null) ? 
                                               tempAppo.Annualised_Won_Revenue__c - apo.Annualised_Revenue__c : 0;
        }

        } else if (newList != null && remAccPlanAPOSet.contains(apo.Account_Plan_Parent_Opportunity__c)) {
        //Removal value from old AccPlanParentOppty
        tempAppo = accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c);
        accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Revenue__c = (tempAppo.Annualised_Revenue__c != null) ? tempAppo.Annualised_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;

            if (apo.Status__c == 'Open') {
            accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Open_Revenue__c = (tempAppo.Annualised_Open_Revenue__c != null) ? tempAppo.Annualised_Open_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
            } else if (apo.Status__c == 'Won') {
            accPlanParentOppMap.get(apo.Account_Plan_Parent_Opportunity__c).Annualised_Won_Revenue__c = (tempAppo.Annualised_Won_Revenue__c != null) ? tempAppo.Annualised_Won_Revenue__c + apo.Annualised_Revenue__c : apo.Annualised_Revenue__c;
        }

        }
    }
    
    //  
    //Updation of final values    
    if (accPlanParentOppMap.values().size() > 0) {
        update accPlanParentOppMap.values();
    }    

  }
  
  //T-282465
  //update I-121001
  private static void updateAccPlanOppFieldsForNewOpp (List<Account_Plan_Opportunity__c> newList, 
                                                      Map<ID, Account_Plan_Opportunity__c> oldMap) {
    Set<ID> opptyIDset = new Set<ID>();
    Map<ID, Opportunity> opptyMap = new Map<ID, Opportunity>();
    Boolean isInsert = oldMap == null;
    
    for (Account_Plan_Opportunity__c apo : newList) {
        if (apo.Opportunity__c == null || (!isInsert && apo.Opportunity__c == oldMap.get(apo.ID).Opportunity__c)) {
            continue;
        }
        opptyIDset.add(apo.Opportunity__c);
    }
    
    for (Opportunity opp : [SELECT ID, Name, CloseDate, Contract_Start_Date__c, Contract_End_Date__c, Amount, StageName 
                            FROM Opportunity 
                            WHERE ID IN : opptyIDset]) {
        opptyMap.put(opp.ID, opp);
    }

    Opportunity opp;
    for (Account_Plan_Opportunity__c accPlanOppty : newList) {
        if (accPlanOppty.Opportunity__c != null && 
              (isInsert || accPlanOppty.Opportunity__c != oldMap.get(accPlanOppty.ID).Opportunity__c)) {
                
                Integer monthDiff = 1;
          opp = opptyMap.get(accPlanOppty.Opportunity__c);
          accPlanOppty.Opportunity_Name__c = opp.Name;
            if (opp.Contract_Start_Date__c != null && opp.Contract_End_Date__c != null) {
              monthDiff = (opp.Contract_Start_Date__c.monthsBetween(opp.Contract_End_Date__c));
            }
            accPlanOppty.Annualised_Revenue__c = opp.Amount != null ? opp.Amount / (monthDiff < 1 ? 1 : monthDiff)*12 : accPlanOppty.Annualised_Revenue__c;
            accPlanOppty.Sales_Stage__c = opp.StageName;
            if (opp.CloseDate != null) {
                accPlanOppty.Close_Date__c = opp.CloseDate;
            }
            accPlanOppty.TCV__c = opp.Amount;
        }
    }
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Opportunity
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Opportunity__c> newList, 
                                            Map<ID, Account_Plan_Opportunity__c> oldMap){
    Set<Id> oppIDs = new Set<Id>();
    LIst<Account_Plan_Opportunity__c> lstAPlanOpp = new LIst<Account_Plan_Opportunity__c> ();
    
    //Find acc plan Ids related to Acc Plan Oppty
    for(Account_Plan_Opportunity__c apOpp : newList){
        if((oldMap == null ||( apOpp.Opportunity__c != null && oldMap.get(apOpp.Id).Opportunity__c != apOpp.Opportunity__c )) && apOpp.Opportunity__c != null){
            lstAPlanOpp.add(apOpp);
            oppIDs.add(apOpp.Opportunity__c);
        }
    }
    
    if(!oppIDs.isEmpty()){
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity> ([Select Id , currencyISOCode From Opportunity Where Id IN : oppIDs]);
        // Update Currency Iso code for Account Plan Opportunity
        for(Account_Plan_Opportunity__c apOpp : lstAPlanOpp){
            if (oppMap.get(apOpp.Opportunity__c) != null)
                apOpp.CurrencyISOCode = oppMap.get(apOpp.Opportunity__c).CurrencyISOCode;
        }
    }                                           
    
  }
}