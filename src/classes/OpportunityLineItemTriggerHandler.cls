/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityLineItemTriggerHandler
 * Description: T-211312
 * Created Date: Nov 13th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Jan 30th, 2014       Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 19th, 2014       Naresh kr Ojha (Appirio)     T-250093: Change workflow to trigger (setOpptyProductSimpleOrComplex())
 * Feb 19th, 2014       Nathalie Le Guay (Appirio)   T-250093: change to amounts checks in setOpptyProductSimpleOrComplex()
 * Mar 20th, 2014       Naresh Kr Ojha               T-260617: Calculating Service start/end dates.
                                                     added methods updateOpptyDatesAndPopulateOLIdates() & populateOLIDates()
 * Mar 24th, 2014       Naresh Kr Ojha               T-260617: Updated code to use updateOpptyDatesAndPopulateOLIdates method on after insert too.
 * Apr 01st, 2014       Arpita Bose(Appirio)         T-268401: Removed the method updateOpptyDatesAndPopulateOLIdates() and 
 *                                                   updated populateOLIDates()to remove reference to Opp's Service Start/End dates
 * Apr 01, 2014         Nathalie Le Guay             Removed commented code relative to T-268401. Backup is on text file attached to task
 * Apr 02, 2014         Arpita Bose                  T-268405: Renamed OLI's Service Start/end dates to Start/End dates
 * Apr 04, 2014          Naresh Kr Ojha              T-268354: Revenue Schedule Rule Calculation: OLI Trigger
 *                                                   added calculateRevenueScheduleRules(), populateBillingProductsOnOLIs(),
 *                                                   retrieveRevenueScheduleMap(), isChangedAnyField()
 * Apr 08, 2014         Arpita Bose                  T-269372: Added addError()in try-catch block // NLG Fixes so that they are on the trigger record
 * Apr 16th, 2014       Arpita Bose                  T-272243: Added method setOppDeliveryDatesPlannedUncheck() to uncheck 
 *                                                   Opp.Delivery_Dates_Planned__c if any of the OLI's Start/End Date is updated
 * Apr 17th, 2014               Naresh Kr Ojha                           T-272569: Update Finance BU on OLI from Product Country Object, 
 *                                                                                                 Modified method populateBillingProductsOnOLIs() and added method populateFinancialBUOnOLIs()
 * May 01st, 2014       Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException
 * June 11th, 2014      James Weatherall             Added deletion of existing Revenue Schedules into calculateRevenueScheduleRules method 
 * Aug 8th, 2014        Tyaga Pati                   Case#0003593 :Added Code to retrieve Finance BU Code information from the product Country level to Opportunty prod level   
 * Sept 11th, 2014      Mohit Parnami                T-318596: Added method After delete to delete all the Royalties records with the same Line_Item_Reference_Number__c
                                                     as deleting oppLineItem.Reference_Number__c
 * Sep 16th, 2014       Naresh kr Ojha               T-319440: added method requoteAndLockingOLIs().
 * Sep 30th, 2014       Noopur                       T-321616 : Code refactoring. Added the method populateRenewalFieldsForOppLines()
 * Oct 9th, 2014        Nathalie                     T-325316: Replace references to Reference_Number__c with Item_Number__c
 * Oct 20th, 2014       Noopur                       Updated method populateRenewalFieldsForOppLines() for T-326528
 * Oct 21st, 2014       Naresh                       Fixed issue: I-135630, updated method requoteAndLockingOLIs() for CPQ User Admin setting check for null.- NLG removed 2014-10-22 (using OLI.Updates_From_CPQ__c)
 *                                                   Commented call to requoteAndLockingOLIs() on 2014-10-29 due to it firing in scenarios when we do not want it to fire
 * Nov, 27th, 2014      Naresh                       T-336651: Delete non associated RLIs with OLI.oppty + oli.Part# on after insert of OLI.
 * Dec 2nd, 2014        Nathalie                     Commented RetentionUtility.deleteRetentionLineItems(oldMap); (not needed per call with Terry)
 *                                                   Commented createRetentionAndRLIForLong_NonRenewalOpp() as not needing both RLI for non-Renewal opps, and no need to delete non-matched RLI/OLI
 * Dec 2nd, 2014        Naresh                       Removed commented code (code clean up) by Nathalie, code was related to T-336651 & T-336536 which are now cancelled.
 * Jan 12th, 2015       Nathalie Le Guay             Making Royalty__c query more specific (Opportunity__c filter added)
 * Jan 21st, 2015       Arpita Bose                  T-353894: moved the methods detectOLIScheduleChangesAndUpdateOLI(),calculateRevenueScheduleRules(),retrieveRevenueScheduleMap() and isChangedAnyField()
 *                                                   to the class OpportunityLI_RevenueSchedTriggerHandler
 * Jan 28th, 2015       Nathalie Le Guay             I-146888: Replace OLI.Discount with OLI.CPQ_Discount__c
 * Mar 31st, 2015       Arpita Bose                  T-372609: Added call to getOLIIds_BillingProduct() instead of calculateRevenueScheduleRules()
 =====================================================================*/

public class OpportunityLineItemTriggerHandler {
    public static Boolean hasRunLockCheck = false;
    public static Boolean hasRunRetentionUpdates = false;

    public static void beforeInsert(List<OpportunityLineItem> newList) {
      populateOLIDates(newList);
      populateBillingProductsOnOLIs(newList, null);
      //T-321616
     // populateRenewalFieldsForOppLines (newList);
 
    }//END: METHOD beforeUpdate

    public static void afterInsert(Map<Id, OpportunityLineItem> newMap) {
      setOpptyProductSimpleOrComplex(newMap);
      
      //OpportunityLI_RevenueSchedTriggerHandler.calculateRevenueScheduleRules(newMap, null); //T-353894
      OpportunityLI_RevenueSchedTriggerHandler.getOLIIds_BillingProduct(newMap, null); //updated the call of method as per T-372609
      if (!hasRunRetentionUpdates && OpportunityTriggerHandler.isRunningOpportunityTrigger == true) {//As per T-337155: Added oppty trigger running
        RetentionUtility.processRetentionLineItems(newMap.values(), null); // T-335658
        hasRunRetentionUpdates = true;
      }
       
    }//END: METHOD beforeUpdate

    public static void beforeUpdate(Map<Id, OpportunityLineItem> newMap, Map<ID, OpportunityLineItem> oldMap) {
      OpportunityLI_RevenueSchedTriggerHandler.detectOLIScheduleChangesAndUpdateOLI(newMap); //T-353894
      if (!hasRunLockCheck) {
        //requoteAndLockingOLIs (newMap.values(), oldMap);
        hasRunLockCheck = true;
      }
      populateBillingProductsOnOLIs(newMap.values(), null);
    }//END: METHOD beforeUpdate
    
    public static void afterUpdate(Map<Id, OpportunityLineItem> newMap,
                                    Map<Id, OpportunityLineItem> oldMap) {
      setOpptyProductSimpleOrComplex(newMap);
      //T-353894
      //OpportunityLI_RevenueSchedTriggerHandler.calculateRevenueScheduleRules(newMap, oldMap);
      OpportunityLI_RevenueSchedTriggerHandler.getOLIIds_BillingProduct(newMap, oldMap); //updated the call of method as per T-372609
      setOppDeliveryDatesPlannedUncheck(newMap, oldMap);
      
      if (!hasRunRetentionUpdates && OpportunityTriggerHandler.isRunningOpportunityTrigger == true) {//As per T-337155: Added oppty trigger running
        RetentionUtility.processRetentionLineItems(newMap.values(), oldMap); // T-335658
        hasRunRetentionUpdates = true;
      }
    }//END: METHOD afterUpdate 

    public static void afterDelete(Map<Id, OpportunityLineItem> oldMap) {
      deleteOrphanRoyalties(oldMap);
      //RetentionUtility.deleteRetentionLineItems(oldMap);
    }

    // Sets opportunity.Has_Complex_Product__c to true if matches specific conditions
    private static void setOpptyProductSimpleOrComplex (Map<Id, OpportunityLineItem> newMap) {
      Map<ID, Opportunity> opptyMapToUpdate = new Map<ID, Opportunity>();
      
      /*********Code Added By Mohit Begins **************************************/
      Set<String> setOppCurrencyISOCode = new Set<String>();
      for (OpportunityLineItem oli : [SELECT Opportunity.Amount, Opportunity.CurrencyIsoCode, Opportunity.CloseDate
                                      FROM OpportunityLineItem 
                                      WHERE Id IN: newMap.keySet()]){
        setOppCurrencyISOCode.add(oli.Opportunity.CurrencyIsoCode);

      }
      
      CurrencyUtility currencyUtil = new CurrencyUtility(setOppCurrencyISOCode);
      /*********Code Added By Mohit Ends **************************************/
    
      try {
        Decimal adjustedRate = 0.00;
        Decimal currencyRate = 1.00;
        for (OpportunityLineItem oli : [SELECT Opportunity.Amount, Opportunity.CurrencyIsoCode, Opportunity.CloseDate, 
                                               Billing_Product__r.Simple_or_Complex__c,
                                               PricebookEntry.Product2.Simple_or_Complex__c,
                                               OpportunityID, ID, Opportunity.Has_Complex_Product__c 
                                        FROM OpportunityLineItem 
                                        WHERE Id IN: newMap.keySet()]) {
      
      //Edited by Mohit : added Opportunity.CloseDate as a passing parameter
          if (oli.Opportunity.CurrencyIsoCode == Constants.CURRENCY_USD) {
            currencyRate = currencyUtil.convertCurrency(Constants.CURRENCY_USD, 1, Constants.CURRENCY_GBP, oli.Opportunity.CloseDate);
          }
          else if (oli.Opportunity.CurrencyIsoCode  == Constants.CURRENCY_EUR) {
            currencyRate = currencyUtil.convertCurrency(Constants.CURRENCY_EUR, 1, Constants.CURRENCY_GBP, oli.Opportunity.CloseDate);
          }
          adjustedRate = 1 - currencyRate;

          //Oppty Product Simple or Complex
          if (
               (Integer.valueOf(oli.Opportunity.Amount) > 10000 && oli.Opportunity.CurrencyIsoCode == Constants.CURRENCY_GBP && 
                  (oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX ||
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX)
                ) || 
                ( 
                  Integer.valueOf(oli.Opportunity.Amount) > ((10000 * adjustedRate) + 10000) && 
                    // oli.Opportunity.CurrencyIsoCode  == Constants.CURRENCY_USD && 
                  (oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX ||
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX)
                ) ||
                ( 
                  Integer.valueOf(oli.Opportunity.Amount) > ((10000 * adjustedRate) + 10000) && 
                    // oli.Opportunity.CurrencyIsoCode == Constants.CURRENCY_EUR && 
                  (oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.PricebookEntry.Product2.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX || 
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_COMPLEX || 
                      oli.Billing_Product__r.Simple_or_Complex__c == Constants.PRODUCT_SIMPLE_COMPLEX)
                )
             ) {
             //Adding oppty to update
             if (!opptyMapToUpdate.containsKey(oli.OpportunityId) && oli.Opportunity.Has_Complex_Product__c == false) {
                 opptyMapToUpdate.put(oli.OpportunityID, new Opportunity(
                                                         ID = oli.OpportunityID, 
                                                         Has_Complex_Product__c = true));
             }
          }//End of If
        }//End of loop: for

        //Calling update
        if (opptyMapToUpdate.values().size() > 0) {
          update opptyMapToUpdate.values();
        }
       }
       catch (DMLException ex) {
         apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','setOpptyProductSimpleOrComplex', ex.getStackTraceString(), ex);
         System.debug('\n[OpportunityLineItemTriggerHandler: setOpptyProductSimpleOrComplex]: ['+ex.getMessage()+']]');
         for (Integer i = 0; i < ex.getNumDml(); i++) {
           newMap.values().get(0).addError(ex.getDmlMessage(i));
         }
       }
    }

    // before insert logic 
    // T-260617: Opp Start/End Dates: Opportunity Line Item Trigger to update Opp dates & populate OLI dates
    private static void populateOLIDates (List<OpportunityLineItem> oliList) {
        Set<ID> opptyIDs = new Set<ID>();
        Map<ID, Opportunity> opptyID_opptyMap = new Map<ID, Opportunity>();
        for (OpportunityLineItem oli : oliList) {
            if (oli.Start_Date__c == null || oli.End_Date__c == null) {
                opptyIDs.add(oli.OpportunityID);
            }
        }
        if (opptyIDs.size() > 0) {
            opptyID_opptyMap = new Map<Id, Opportunity>([SELECT ID, Contract_End_Date__c, Contract_Start_Date__c FROM Opportunity WHERE ID IN : opptyIDs]);
        }

        // T-268401: update service dates on OLIs from oppportunity Contract Start/end Dates
        // Validating service dates on OLIs if null than updated them from opportunity as per T-260617
        for (OpportunityLineItem oli : oliList) {
            if (oli.Start_Date__c == null && opptyID_opptyMap.containsKey(oli.OpportunityID)
                                                  && opptyID_opptyMap.get(oli.OpportunityID).Contract_Start_Date__c != null) {
                oli.Start_Date__c = opptyID_opptyMap.get(oli.OpportunityID).Contract_Start_Date__c;
            }
            if (oli.End_Date__c == null && opptyID_opptyMap.containsKey(oli.OpportunityID)
                                                && opptyID_opptyMap.get(oli.OpportunityID).Contract_End_Date__c != null) {
                oli.End_Date__c = opptyID_opptyMap.get(oli.OpportunityID).Contract_End_Date__c;
            }
        }
    }
    
  //T-268354: populate billing products on OLIs
  private static void populateBillingProductsOnOLIs (List<OpportunityLineItem> newList, 
                                                  Map<ID, OpportunityLineItem> oldMap) {
    Set<String> typeOfSellSet = new Set<String>();
    Set<ID> productSet = new Set<ID>();
    Set<String> pbEntryIDs = new Set<String>();
    //T-272569
    Set<String> oliCountrySet = new Set<String>();
    Map<String, Product_Country__c> prodCountryMap = new Map<String, Product_Country__c>();
    
    //Loop through OLIs
    for (OpportunityLineItem oli : newList) {
      if (oli.PricebookEntryId <> null) {
        pbEntryIDs.add(oli.PricebookEntryId);
      }
      if (oli.Type_of_Sale__c != null) {
        typeOfSellSet.add(oli.Type_of_Sale__c);
      }
      //T-272569
      if (!String.isEmpty(oli.Opportunity_Country__c)) {
        oliCountrySet.add(oli.Opportunity_Country__c);
      }
    }
    


    Map<String, String> pbeID_prodIDMap = new Map<String, String>();
    for (PricebookEntry pbe : [SELECT Product2Id, Id FROM PricebookEntry WHERE ID IN : pbEntryIDs]) {
      pbeID_prodIDMap.put(pbe.ID, pbe.Product2Id);
      productSet.add(pbe.Product2Id);
    }//end of loop
    
    //Getting product + '~~' + country, product_country__c map
    prodCountryMap = populateFinancialBUOnOLIs(oliCountrySet, productSet);
    
    Map<String, Billing_Product__c> prodTypOfSell_bilProdMap = new Map<String, Billing_Product__c>();
    try {
      //To populate map of Billing products
      for (Billing_Product__c billProduct : [SELECT Type_of_Sale__c, Product__c, Id 
                                             FROM Billing_Product__c 
                                             WHERE Type_of_Sale__c IN : typeOfSellSet AND Product__c IN: productSet]) {
        String mapKey = '';
        if (billProduct.Type_of_Sale__c <> null && billProduct.Product__c <> null) {
          mapKey = billProduct.Type_of_Sale__c + '~~' + billProduct.Product__c;
          if (!prodTypOfSell_bilProdMap.containsKey(mapKey)) {
            prodTypOfSell_bilProdMap.put(mapKey, billProduct);
          }
        }
      }//End of BillingProduct loop
      
      for (OpportunityLineItem oli : newList) {
        ID prodId = (pbeID_prodIDMap.containsKey(oli.PricebookEntryId))?pbeID_prodIDMap.get(oli.PricebookEntryId):null;
        String mapKey = oli.Type_of_Sale__c + '~~' + prodId;
        if (prodId <> null && prodTypOfSell_bilProdMap.containsKey(mapKey)) {
          oli.Billing_Product__c = prodTypOfSell_bilProdMap.get(mapKey).ID;
        }
        
        if (!String.isEmpty(oli.Opportunity_Country__c) && oli.PricebookEntryId != null && prodId != null &&
               prodCountryMap.containsKey(prodId + '~~' + oli.Opportunity_Country__c)) {
            oli.Finance_BU__c = prodCountryMap.get(prodId + '~~' + oli.Opportunity_Country__c).Finance_BU__c;
            //Aug 8th 14 - Tyaga Pati Added code to add the new Finance BU code and Name to the Map.
            oli.Product_Finance_BU__c = prodCountryMap.get(prodId + '~~' + oli.Opportunity_Country__c).Product_Finance_BU__r.Name;
            oli.Finance_BU_Name__c = prodCountryMap.get(prodId + '~~' + oli.Opportunity_Country__c).Finance_BU_Name__c;
        }
      }
    } catch (DMLException ex) {
      System.debug('\n[OpportunityLineItemTriggerHandler: populateBillingProductsOnOLIs]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','populateBillingProductsOnOLIs', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDmlMessage(i));
      }      
    } catch (Exception ex) {
      System.debug('\n[OpportunityLineItemTriggerHandler: populateBillingProductsOnOLIs]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','populateBillingProductsOnOLIs', ex.getStackTraceString(), ex);
      newList.get(0).addError(ex.getMessage());
    }
    
  }
  //T-272569: Update Finance BU on OLI from Product Country Object
  //Aug 8th 14- Tyaga Pati : Added Finance BU Code and Finance BU Name to the query
  private static Map<String, Product_Country__c> populateFinancialBUOnOLIs (Set<String> countrySet, 
                                                                                 Set<ID> prodSet) {
                
    Map<String, Product_Country__c> oliProdOliCountryToProductCountryMap = 
                                                      new Map<String, Product_Country__c>();
    for (Product_Country__c pc : [SELECT Product__c, Id, Finance_BU_Name__c, Product_Finance_BU__c, Finance_BU__c, Product_Finance_BU__r.Name,
                                         Country__c, Country__r.Name 
                                  FROM Product_Country__c
                                  WHERE Country__r.Name IN: countrySet AND Product__c IN: prodSet]) {
      if (!oliProdOliCountryToProductCountryMap.containsKey(pc.Product__c + '~~' + pc.Country__r.Name)) {
        oliProdOliCountryToProductCountryMap.put(pc.Product__c + '~~' + pc.Country__r.Name, pc);
      }
    }
    
    return oliProdOliCountryToProductCountryMap;
  } 

  //===============================================================================================
  // T-272243: Uncheck Opp.Delivery_Dates_Planned__c if any of the OLI's Start/End Date is updated
  //===============================================================================================
  public static void setOppDeliveryDatesPlannedUncheck(Map<Id, OpportunityLineItem> newMap,
                                    Map<Id, OpportunityLineItem> oldMap) {
    Set<ID> oppIDs = new Set<ID>(); 
    Set<ID> oliWithOppIDs = new Set<ID>();                               
    Map<ID, Opportunity> oppMapToUpdate = new Map<ID, Opportunity>();
    for (OpportunityLineItem oli: newMap.values()) {
      if (oli.OpportunityID <> null){
        oliWithOppIDs.add(oli.OpportunityID);
      }
    }
    Map<ID, Opportunity> mapOpp = new Map<ID, Opportunity>([SELECT Id, Delivery_Dates_Planned__c
                                                              FROM Opportunity WHERE ID IN:oliWithOppIDs ]);
    for (OpportunityLineItem oli: newMap.values()) {
      if ((oli.Start_Date__c <> oldMap.get(oli.ID).Start_Date__c || oli.End_Date__c <> oldMap.get(oli.ID).End_Date__c)
            && mapOpp.get(oli.OpportunityID).Delivery_Dates_Planned__c == true) {
        if(oli.OpportunityID <> null){
          oppIDs.add(oli.OpportunityID);
        }
      }
      if (oppIDs.size() > 0) {
        for (ID opptyID: oppIDs) {
          if (mapOpp.containsKey(opptyID)) {
            mapOpp.get(opptyID).Delivery_Dates_Planned__c = false;
            oppMapToUpdate.put(opptyID, mapOpp.get(opptyID));
          }
        }
      }
    }
    if (oppMapToUpdate.size() > 0) {
      try {
        update oppMapToUpdate.values();
      } catch (DMLException e) {
        System.debug('\n[OpportunityLineItemTriggerHandler: setOppDeliveryDatesPlannedUncheck: DMLException]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','setOppDeliveryDatesPlannedUncheck: DMLException', e.getStackTraceString(), e); 

        for (Integer i = 0; i < e.getNumDml(); i++) {
          newMap.values().get(0).addError(e.getDmlMessage(i));
        }
      }
    }
  }


  //Method to delete all the Royalties with same Ref No. as deleting oppLineItem's Ref Number
  private static void deleteOrphanRoyalties(Map<Id, OpportunityLineItem> oldMap) {
    Set<String> setItemNumbers = new Set<String>();
    List<Royalty__c> listRoyalties = new List<Royalty__c>();
    Set<Id> oppIds = new Set<Id>();

    for (OpportunityLineItem oppLineItem : oldMap.values()) {
      setItemNumbers.add(oppLineItem.Item_Number__c);
      oppIds.add(oppLineItem.OpportunityId);
    }

    system.debug('===setItemNumbers===' + setItemNumbers);
    for (Royalty__c royalty : [SELECT Id, Line_Item_Reference_Number__c
                               FROM Royalty__c
                               WHERE Line_Item_Reference_Number__c IN : setItemNumbers AND Opportunity__c in: oppIds]) {
      listRoyalties.add(royalty);
    }
    system.debug('===listRoyalties===' + listRoyalties);
    if (listRoyalties != null && listRoyalties.size() > 0) {
      try {
        delete listRoyalties;
      } catch (DMLException e) {
        System.debug('\n[OpportunityLineItemTriggerHandler: deleteOrphanRoyalties: DMLException]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','deleteOrphanRoyalties: DMLException', e.getStackTraceString(), e); 

        for (Integer i = 0; i < e.getNumDml(); i++) {
          oldMap.values().get(0).addError(e.getDmlMessage(i));
        }
      }
    }
  }

  //=================================================================================
  //Allows opportunity line itmes to get updated if its oppty do not have any quote
  //Only certain fields can be updated
  //=================================================================================
  /*private static void requoteAndLockingOLIs (List<OpportunityLineItem> newList, 
                                               Map<ID, OpportunityLineItem> oldMap) {
     Set<ID> opptyIDs = new Set<ID>();
     Set<String> excludedFields = getExcludedFieldsForOLI();
     Set<String> fieldsToIgnoreCheck = new Set<String>();
     OpportunityLineItem oliObj = new OpportunityLineItem();
     Map<String, Schema.SObjectField> oliFieldMap = DescribeUtility.getFieldMap(oliObj);
     //Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
     User currentUser = [SELECT Id, CPQ_User__c FROM User WHERE Id =: UserInfo.getUserId()];
     for (OpportunityLineItem oli : newList) {
       opptyIDs.add(oli.OpportunityID);
     }
     
     if (opptyIDs.size() < 1) {
      return;
     }

     //Check weather OLI should go through validation rule
     for (OpportunityLineItem oli: newList) {  
       system.debug('\nTHE FLAG: CPQ USER: '+ oli.Update_from_CPQ__c + '  and CPQ User?? '+ currentUser.CPQ_User__c );
       if (currentUser.CPQ_User__c && !oli.Update_from_CPQ__c) {
         for (String fld : oliFieldMap.keySet()) {
           if (oli.get(fld) != oldMap.get(oli.ID).get(fld) && !excludedFields.contains(fld.toLowerCase())) {
              oli.addError(Label.OLI_READ_ONLY);
           } 
         }
       }
     }
  }*/

  //excluded fields from validation to updated: T-319440
  private static Set<String> getExcludedFieldsForOLI() {
    Set<String> exclFields = new Set<String>();
     exclFields.add(Constants.OLI_FLD_UPDATE_FREQENCY);
     exclFields.add(Constants.OLI_FLD_DELIVERY_METHOD);
     exclFields.add(Constants.OLI_FLD_TYPE);
     exclFields.add(Constants.OLI_FLD_LAST_MODIFIED_DT);
     exclFields.add(Constants.OLI_FLD_LAST_MODIFIED_BY);
     return exclFields;
  }

  // T-321616 : Method to populate the renewal fields in the opportunityLineItems
  private static void populateRenewalFieldsForOppLines ( List<OpportunityLineItem> newList) {
    Set<String> oliSet = new Set<String>();
    Map<String, OpportunityLineItem> oliMap = new Map<String, OpportunityLineItem>();
    for ( OpportunityLineItem oli : newList ) {
      if ( oli.Type__c == Constants.OPPTY_TYPE_RENEWAL ) {
        oliSet.add(oli.Original_Opportunity_Line_Item_Id__c);
      }
    }
    for ( OpportunityLineItem originalOLI : [SELECT Id, OpportunityId, Quantity, UnitPrice, PricebookEntryId, Start_Date__c, End_Date__c,
                                                    Renewal_Discount__c, Renewal_Discount_Amount__c, Renewal_EDQ_Margin__c,
                                                    Renewal_Extended_Amount__c, Renewal_Partner__c, Renewal_Partner_Amount__c,
                                                    Renewal_Registration__c, Renewal_Sale_Price__c, Renewals_Exclude__c
                                             FROM OpportunityLineItem
                                             WHERE ID IN :oliSet]) {
      oliMap.put(originalOLI.Id, originalOLI);
    }
    String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
    for ( OpportunityLineItem oli : newList ) {
      if ( oli.Type__c == Constants.OPPTY_TYPE_RENEWAL && String.isNotBlank(groupName) && 
        groupName.equalsIgnoreCase(Constants.EDQ)) {
        if (oliMap.containsKey(oli.Original_Opportunity_Line_Item_Id__c)) {
          OpportunityLineItem originalLI = oliMap.get(oli.Original_Opportunity_Line_Item_Id__c);
          //oli.Sale_Price__c         = originalLI.Renewal_Sale_Price__c;//Commented as per Task T-323241
          oli.Renewal_Sale_Price__c = originalLI.Renewal_Sale_Price__c;
          oli.CPQ_Discount__c /*oli.Discount*/ = originalLI.Renewal_Discount__c; // I-146888
          oli.Discount_Amount__c    = originalLI.Renewal_Discount_Amount__c;
          oli.EDQ_Margin__c         = originalLI.Renewal_EDQ_Margin__c;
          oli.Extended_Amount__c    = originalLI.Renewal_Extended_Amount__c;
          oli.Partner__c            = originalLI.Renewal_Partner__c;
          oli.Partner_Amount__c     = originalLI.Renewal_Partner_Amount__c;
          //oli.EDQ_Margin__c         = originalLI.Renewal_QAS_Margin__c;
          oli.Manual_Registration__c= originalLI.Renewal_Registration__c;
          oli.UnitPrice             = originalLI.Renewal_Sale_Price__c;
        }
      }
    }

  }
  
}//END: CLASS OpportunityLineItemTriggerHandler