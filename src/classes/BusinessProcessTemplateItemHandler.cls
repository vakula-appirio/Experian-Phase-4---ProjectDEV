/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTemplateItemHandler
 * Description:  
 *  - T-375024: defaults the business hours on the business process template item to global crm's default business hours
 * Created Date: Apr 1st, 2015
 * Created By: Terri Kellough
 * 
 * Date Modified                Modified By                  Description of the update
  =====================================================================*/
global class BusinessProcessTemplateItemHandler {
  private static String defaultBusinessHour;

  //==========================================================================
  // Before insert
  //==========================================================================
  public static void beforeInsert(List<Business_Process_Template_Item__c> newLst){
    processBPTIRecords(newLst, null);      
  }    

  //==========================================================================
  // Before update
  //==========================================================================    
  public static void beforeUpdate(List<Business_Process_Template_Item__c> newList, Map<Id, Business_Process_Template_Item__c> oldMap){
    processBPTIRecords(newList, oldMap);    
  }

  //==========================================================================
  // Will populate the Business_Hours__c field if blank
  //==========================================================================
  private static void processBPTIRecords(List<Business_Process_Template_Item__c> newList, Map<Id, Business_Process_Template_Item__c> oldMap){

    String defaultBusinessHourId = getDefaultBusinessHours();
    if (defaultBusinessHourId ==  null) {
      newList.get(0).addError(Label.BUSINESS_PROCESS_STD_BUSINESSHOUR_MISSING);
    }
  
    for (Business_Process_Template_Item__c bpti : newList) {
      if (bpti.Business_Hours__c == null) {
        
        bpti.Business_Hours__c = defaultBusinessHourId;
      }
    }

  }

  //==========================================================================
  // Will get the default Business Hours set for the company
  //==========================================================================
  private static String getDefaultBusinessHours() {
    try{
      return  [SELECT Id 
               FROM BusinessHours
               WHERE IsDefault = true AND IsActive = true
               LIMIT 1].Id;
    } catch (Exception ex){
      apexLogHandler.createLogAndSave('BusinessProcessTemplateItemHandler','getDefaultBusinessHours', ex.getStackTraceString(), ex);
    }
    return null;
  }
}