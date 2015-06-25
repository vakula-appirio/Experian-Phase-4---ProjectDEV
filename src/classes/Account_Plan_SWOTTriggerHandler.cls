/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_SWOTTriggerHandler
 * Description: Handler class for Account_Plan_SWOTTrigger trigger (for T-276704)
 * Created Date: May 6th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update
 * Jul 14th, 2014     Arpita Bose(Appirio)       I-120524: Added method beforeInsert and beforeUpdate 
 =====================================================================*/
public class Account_Plan_SWOTTriggerHandler {	
  //=========================================================================
  //After Insert Call
  //=========================================================================
  public static void afterInsert(List<Account_Plan_SWOT__c> newAccountPlanSwots){
  	// invoke creation of related account plan opp swot entries
  	Account_Plan_SWOTTriggerHandler.createRelatedAccountPlanOppSwotEntries(newAccountPlanSwots);    
  }
  //=========================================================================
  // Before Insert Call
  //=========================================================================
  public static void beforeInsert(List<Account_Plan_SWOT__c> newList){
    synchCurrencyISOCodes(newList, null);    
  }
  //=========================================================================
  // Before Update Call
  //=========================================================================
  public static void beforeUpdate(List<Account_Plan_SWOT__c> newList, Map<Id, Account_Plan_SWOT__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap);   
  }
  
  //=========================================================================
  // Generic Utility methods for creating related account plan opp swot entries
  //=========================================================================
  public static void createRelatedAccountPlanOppSwotEntries(List<Account_Plan_SWOT__c> newAccountPlanSwots){
  	//When an Account Plan SWOT is created the code needs to create an Account Plan Opportunity SWOT record for that SWOT 
    //and associate it will all existing Account Plan Opportunities. That are associated with the related Account Plan
    List<Account_Plan_Opportunity_SWOT__c> toBeInsertedAccPlanOppSwots = new List<Account_Plan_Opportunity_SWOT__c>();
    Map<Id, Account_Plan__c> idToAccountPlanMap = new Map<Id, Account_Plan__c>();
    Set<Id> accountPlanIds = new Set<Id>();
    // iterate trigger.new to get a set of related account plan ids
    for(Account_Plan_SWOT__c accountPlanSwot : newAccountPlanSwots){
      if(accountPlanSwot.Account_Plan__c <> NULL){
        accountPlanIds.add(accountPlanSwot.Account_Plan__c);
      }
    }
    // query account plan with related account plan opportunities list based on the account plan ids set    
    if(!accountPlanIds.isEmpty()){
      idToAccountPlanMap = getAccountPlanOpportunitiesMapOnAccountPlan(accountPlanIds);
    }    
    // re-iterate trigger.new to execute the business logic to prepare a list of Account_Plan_Opportunity_SWOTs to be inserted
    for(Account_Plan_SWOT__c accountPlanSwot : newAccountPlanSwots){
    	// check if map contains account plan record
      if(accountPlanSwot.Account_Plan__c <> NULL && idToAccountPlanMap.containsKey(accountPlanSwot.Account_Plan__c)){
        Account_Plan__c accountPlan = idToAccountPlanMap.get(accountPlanSwot.Account_Plan__c);
        // iterate related account plan opportunities
        for(Account_Plan_Opportunity__c accountPlanOpp : accountPlan.Account_Plan_Opportunity__r){
          toBeInsertedAccPlanOppSwots.add(getAccountPlanOpportunitySWOT(accountPlanOpp.id, accountPlanSwot.id));
        }
      }
    }
    // verify if inserted list is not empty
    if(!toBeInsertedAccPlanOppSwots.isEmpty()){
    	try{
        insert toBeInsertedAccPlanOppSwots;
    	}catch(DMLException ex){
    		 apexLogHandler.createLogAndSave('Account_Plan_SWOTTriggerHandler','createRelatedAccountPlanOppSwotEntries', ex.getStackTraceString(), ex);
		    for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
		      newAccountPlanSwots.get(0).addError(ex.getDMLMessage(indx));
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
  public static Map<Id, Account_Plan__c> getAccountPlanOpportunitiesMapOnAccountPlan(Set<Id> accountPlanIds){
  	return new Map<Id, Account_Plan__c>([SELECT Id, 
  	           (SELECT Id FROM Account_Plan_Opportunity__r) 
  	        FROM Account_Plan__c 
  	        WHERE ID in : accountPlanIds]);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan SWOT
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_SWOT__c> newList, 
                                            Map<ID, Account_Plan_SWOT__c> oldMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_SWOT__c> lstAPlanSwot = new List<Account_Plan_SWOT__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find acc plan Ids related to Acc Plan SWOT
    for(Account_Plan_SWOT__c aPlanSwot : newList){
        if(oldMap == null || (oldMap.get(aPlanSwot.Id).Account_Plan__c  != aPlanSwot.Account_Plan__c )){
            lstAPlanSwot.add(aPlanSwot);
            aPlanIDs.add(aPlanSwot.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_SWOT__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Currency Iso code for Account Plan SWOT
        for(Account_Plan_SWOT__c apSwot : lstAPlanSwot){
            apSwot.CurrencyISOCode = mapAPlanId_APlan.get(apSwot.Account_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }
  
}