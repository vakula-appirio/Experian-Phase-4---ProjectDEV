/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger_RenewalUtility
 * Description: T-264797: Refactoring of OpportunityTriggerHandler and Helper classes.
 *              The following methods were moved from OpportunityTriggerHandler:
 *                - createRenewalOpportunties
 *                - populateRenewalData
 *                - hasValueChanged
 *                - hasCriteriaMet
 *              FOR HISTORY, REFER TO OpportunityTriggerHandler.cls
 * Created Date: Mar 26th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 28th, 2014               Arpita Bose(Appirio)         T-266095: Removing reference to the field 
 *                                                           Opportunity.Status__c which is removed
 * Apr 08th, 2014               Arpita Bose                  T-269372: Added addError()in try-catch block
 * Apr 10th, 2014               Arpita Bose(Appirio)         T-270419: Contract_Term__c the field type is changed
 * Apr 16th, 2014               Arpita Bose                  T-271695: Renamed fields Has_Stage_4_Approval__c to Has_Stage_3_Approval__c 
 *                                                           and Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 23rd, 2014               Nathalie Le Guay             Commenting createRenewalOpportunties() & hasCriteriaMet() because they belong to the old
 *                                                           logic from EA, and we implemented another logic
 =====================================================================*/
public without sharing class OpportunityTrigger_RenewalUtility {

  //============================================================================================
  // Method to check Opportunities for which Renewals need to be created.
  //============================================================================================  
  /*public static void createRenewalOpportunties (Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap) {

       //MIrfan. 07Dec13. TriggerStateVariable to stop creating duplicate Renewl Opps.
       if(OpportunityTriggerHandler.hasRenewalOpportunityCheckFinshed != null && 
                             OpportunityTriggerHandler.hasRenewalOpportunityCheckFinshed) {
               return;  
       }
       
       
       Map<Id,List<OpportunityLineItem>> mapOppLineItems = new Map<Id,List<OpportunityLineItem>>();

       List<Id> lstOpportunityIdsToRenew = new List<Id>();
       List<Opportunity> lstOpportunitiesToRenew = new List<Opportunity>();
       
       //Itereate through Opportunity and identify which meet renewal criterias.
       for(Opportunity oppRec:newMap.values()) {
           if(hasValueChanged(oldMap.get(oppRec.id),oppRec) && hasCriteriaMet(oldMap.get(oppRec.id),oppRec)) {
               lstOpportunityIdsToRenew.add(oppRec.id);
               lstOpportunitiesToRenew.add(populateRenewalData(oppRec.clone()));
           }
       }
       
       //Retrieve OpportunityLineItems.
       for (OpportunityLineItem oppLnRec: [Select ServiceDate,Discount,ListPrice,OpportunityId,PriceBookEntryId,
               Quantity,UnitPrice,Subtotal From OpportunityLineItem where OpportunityId =: lstOpportunityIdsToRenew]) {
                  if(!mapOppLineItems.containsKey(oppLnRec.OpportunityId)) {
                      mapOppLineItems.put(oppLnRec.OpportunityId,new List<OpportunityLineItem>{oppLnRec.clone()});
                  } else {
                      mapOppLineItems.get(oppLnRec.OpportunityId).add(oppLnRec.clone());
                  }
       }

      if (lstOpportunityIdsToRenew.size() > 0) {
          List<OpportunityLineItem> lstOpportunityLineItemsToCreate = new List<OpportunityLineItem>();

          Database.SaveResult[] srList = Database.insert(lstOpportunitiesToRenew, false);
          Integer idxCounter = 0;

          //MIrfan. 07Dec13. TriggerStateVariable to stop creating duplicate Renewl Opps.
          OpportunityTriggerHandler.hasRenewalOpportunityCheckFinshed = true; 

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    //Fetch all LineItems for Opporunity and link to new Opportunity Created.
                    if(mapOppLineItems.containsKey(lstOpportunityIdsToRenew[idxCounter])) {
                            for(OpportunityLineItem oppLnRec:mapOppLineItems.get(lstOpportunityIdsToRenew[idxCounter])) {
                                oppLnRec.OpportunityId=sr.getId();
                                lstOpportunityLineItemsToCreate.add(oppLnRec);
                            }
                        }
                } else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('[OpportunityTriggerHandler:createRenewalOpportunties][Message1:The following error has occurred.]');                    
                        System.debug('[OpportunityTriggerHandler:createRenewalOpportunties][getStatusCode:'+err.getStatusCode() + ': ' + err.getMessage()+']');
                        System.debug('[OpportunityTriggerHandler:createRenewalOpportunties][Message2: Opportunity fields that affected this error: ' + err.getFields()+']');
                    }
                }
             //Increment counter   
             idxCounter++;
          }//END: FOR sr 

          if(lstOpportunityLineItemsToCreate.size()>0) {
            try {
              insert lstOpportunityLineItemsToCreate;
            } catch(Exception e) {
            	for (Integer i=0; i < e.getNumDml(); i++) {
                newMap.values()[0].addError(e.getDMLMessage(i));
            	}
            }
          }
       }//END: IF Opportunity Creation   
   }//END: METHOD afterUpdate*/

  //============================================================================================
  // Populate Renewal Opportunities with fields from Global Custom setting
  //============================================================================================
  public static Opportunity populateRenewalData(Opportunity oppRec) {
    oppRec.CloseDate = oppRec.CloseDate.addMonths((oppRec.Contract_Term__c == null) ? 0 : Integer.valueOf(oppRec.Contract_Term__c));
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);

    oppRec.StageName = custSettings.Opp_Renewal_StageName__c;//'3-Qualify Opportunity';
    oppRec.Name = custSettings.Opp_Renewal_Name_Format__c.replace('####',oppRec.Name);//'Renewal - '+oppRec.Name;

    //MIrfan. 07Dec13. Additional fields reset.
    oppRec.Primary_Reason_W_L__c = null;
    oppRec.Campaign = null;
    oppRec.Type = custSettings.Opp_Renewal_Type__c;
    oppRec.Revenue_Type__c = null;
    oppRec.Has_Complex_Product__c = false;
    oppRec.Has_Stage_3_Approval__c = false;
    oppRec.Has_Senior_Approval__c = false;
   // oppRec.Status__c = 'Open -In Process'; //There is validation on this field so when stage is 3, the Status cannot be Won
    return oppRec;
  }

  //============================================================================================
  // Check if any of these field values changed, to avoid duplicate creation on every opp update
  //============================================================================================
  /*public static boolean hasValueChanged(Opportunity oldOpp, Opportunity newOpp) {
    return (oldOpp.IsClosed != newOpp.IsClosed &&  oldOpp.IsWon != newOpp.IsWon);
  }*/

  //============================================================================================
  // Criteria to create Renewal
  //============================================================================================
  /*public static boolean hasCriteriaMet(Opportunity oldOpp, Opportunity newOpp) {
    return false; // NLG - RENEWAL ON HOLD Feb 28th, 2014
    return (newOpp.IsClosed && newOpp.IsWon/* && newOpp.Auto_Create_Renewal_on_Close_Win__c.equalsIgnoreCase('Yes')*///);
  //}

}