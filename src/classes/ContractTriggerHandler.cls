/**********************************************************************************
 * Appirio, Inc
 * Name: ContractTriggerHandler
 * Description: T-365858
 * Created Date: March 3rd, 2015
 * Created By: Gaurav kumar Chadha (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Mar 13th, 2015       Naresh Kr Ojha               T-369590: updated code for before insert and update, to populate InitialTermPeriod End Date.
 **********************************************************************************/
public class ContractTriggerHandler {

  //=========================================================================
  // Before Insert call
  //========================================================================= 
  public static void beforeInsert (List<Contract__c> newList) {
    populateInitialTermPeriodEndDate (newList, null);
  }
  
  //=========================================================================
  // Before Update call
  //========================================================================= 
  public static void beforeUpdate (List<Contract__c> newList, Map<Id,Contract__c> oldMap) {
    populateInitialTermPeriodEndDate (newList, oldMap);
    populateValidatedByAndValidatedDate(newList, oldMap);
  }
  
  //===============================================================================
  //T-365858 : If validation status is changed populate Validated_By__c and Validated_Date__c  
  //===============================================================================
  public static void populateValidatedByAndValidatedDate(List<Contract__c> newList, 
                                                          Map<Id,Contract__c> oldMap){
    for (Contract__c contract : newList) { 
      if (contract.Validation_Status__c <> null && 
            contract.Validation_Status__c != oldMap.get(contract.id).Validation_Status__c) {
        contract.Validated_By__c = UserInfo.getUserId();
        contract.Validated_Date__c = System.today();
      }
    }
  }
  
  //===========================================================================
  //T-369590: when contract has to populate Initial Term Period End Date field.
  //===========================================================================
  public static void populateInitialTermPeriodEndDate (List<Contract__c> newList, 
                                                          Map<Id,Contract__c> oldMap) {
    Boolean fieldSAreNull = false;
    Boolean fieldsUpdated = false;
    
    String recTypeCSDA_ContractHeader_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CONTRACT, Constants.RECORDTYPE_CONTRACT_CSDA_HEADER);
    
    for (Contract__c contract : newList) { 
      //check field is null or not
      fieldSAreNull = (contract.Initial_Term_Period__c == null || contract.Contract_Effective_Date__c == null) ? true : false;

      //Check field is updated or not - format is for ease of read
      Contract__c oldContract = (oldMap == null) ? null : oldMap.get(contract.Id);
      if (oldContract == null) {
        fieldsUpdated = true;
      } else if (oldContract.Initial_Term_Period__c != contract.Initial_Term_Period__c
              || oldContract.Contract_Effective_Date__c != contract.Contract_Effective_Date__c) {
        fieldsUpdated = true;
      }

      //As per T-369590
      if (fieldsAreNull || contract.RecordTypeId != recTypeCSDA_ContractHeader_ID) {
        continue;
      } else if (fieldsUpdated) {
        contract.Initial_Term_Period_End_Date__c = contract.Contract_Effective_Date__c.addMonths(Integer.valueOf(contract.Initial_Term_Period__c)).addDays(1);
      }
        
    }
  }
}