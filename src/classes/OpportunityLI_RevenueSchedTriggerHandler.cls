/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityLI_RevenueSchedTriggerHandler
 * Description: T-353894: Added the methods detectOLIScheduleChangesAndUpdateOLI(),
                                            calculateRevenueScheduleRules(),
                                            retrieveRevenueScheduleMap() and 
                                            isChangedAnyField()
 *              from the class OpportunityLineItemTriggerHandler
 *              Purpose is to adhere with the recommended class size < 500 lines
 * Created Date: Jan 21st, 2015
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Jan 22nd, 2015       Arpita Bose                  T-353894: Added methods calculate_AmountPerInstallment(), calNBInstallments() and createNewOliSchedule()
 *                                                   to break the method calculateRevenueScheduleRules()
 * Mar 31st, 2015       Arpita Bose                  T-372609: Added method getOLIIds_BillingProduct() to call calculateRevenueScheduleRules()
 *=======================================================================**/
public class OpportunityLI_RevenueSchedTriggerHandler {
  
  

  //=========================================================================
  // This is functionality for OpportunityLineItemSchedule
  //=========================================================================
  public enum Period {DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY,UNKNOWN}
  public static Map<Period, String> mapPeriod = new Map<Period, String>{
                    Period.DAILY=>'Daily', Period.WEEKLY=>'Weekly', Period.MONTHLY=>'Monthly',
                    Period.QUARTERLY=>'Quarterly', Period.YEARLY=>'Yearly'};
                    
  public static void detectOLIScheduleChangesAndUpdateOLI (Map<Id, OpportunityLineItem> newMap) {
    system.debug('###########newMap#############'+newMap); 
    Set<Id> oliIds = newMap.keyset();
    DateTime dtLastModified = System.now().addSeconds(-3);
    Map<Id,List<OpportunityLineItemSchedule>> mapOLIS = new Map<Id,List<OpportunityLineItemSchedule>>();
    Map<Id,Period> mapOLISPeriod = new Map<Id,Period>();
    Set<Id> setManuallyScheduleDtOLIs = new Set<Id>();
    Map<Id,Integer> mapManualAmoutOLIIndex = new Map<Id,Integer>();
    
    for (OpportunityLineItemSchedule recOLIS :[SELECT Id, OpportunityLineItemId, Type, Revenue, 
                                               Quantity, ScheduleDate, CurrencyIsoCode
                                               FROM OpportunityLineItemSchedule 
                                               WHERE OpportunityLineItemId=:oliIds
                                               AND LastModifiedDate >= :dtLastModified 
                                               ORDER BY OpportunityLineItemId, ScheduleDate]) {
                
       //If any OLIS's Schedule Date is manually changes then skip.
       if (setManuallyScheduleDtOLIs.contains(recOLIS.OpportunityLineItemId)) {
          continue;
       }      
       //Add first record to Map
       if (!mapOLIS.containsKey(recOLIS.OpportunityLineItemId)) {
          mapOLIS.put(recOLIS.OpportunityLineItemId,new List<OpportunityLineItemSchedule>{recOLIS});
       }
       else { 
          //From second OLIS record onward for an OLI 
          //Pickup the Period between first and second OLIS
         if (!mapOLISPeriod.containsKey(recOLIS.OpportunityLineItemId)) {
                        
            Date dtStart = mapOLIS.get(recOLIS.OpportunityLineItemId)[0].ScheduleDate;
            Date dtCurrent = recOLIS.ScheduleDate;
                        
            Integer intDaysDiff = dtStart.daysBetween(dtCurrent);
            Integer intMonthsDiff = dtStart.monthsBetween(dtCurrent);
                        
            Period enmPeriod = (intDaysDiff == 1)?Period.DAILY:(intDaysDiff == 7)?Period.WEEKLY:(intMonthsDiff == 1)?Period.MONTHLY:(intMonthsDiff == 3)?Period.QUARTERLY:(intMonthsDiff == 12)?Period.YEARLY:Period.UNKNOWN;
            mapOLISPeriod.put(recOLIS.OpportunityLineItemId,enmPeriod);
         }
                    
         //Get the Period for an OLI
         Period enmPeriod = mapOLISPeriod.get(recOLIS.OpportunityLineItemId);
    
         //Get the List of OLIS for an OLI
         List<OpportunityLineItemSchedule> lstOLIS = mapOLIS.get(recOLIS.OpportunityLineItemId);
                    
         //Get the recent previous record's Schedule Date, so to calculate next/current one, considering Period.
         //Date dtPreviousScheduleDate = lstOLIS[lstOLIS.size()-1].ScheduleDate;
          
         Date dtFirstScheduleDate = lstOLIS[0].ScheduleDate;
         Integer cntPeriod = lstOLIS.size();
          
         system.debug('########################'+enmPeriod);     
          
         //Caculate the potential next Period Date, from recent record added to list.
         Date dtNextDateShouldBe = (enmPeriod == Period.DAILY)?dtFirstScheduleDate.addDays(1*cntPeriod):
                                   (enmPeriod == Period.WEEKLY)?dtFirstScheduleDate.addDays(7*cntPeriod):
                                   (enmPeriod == Period.MONTHLY)?dtFirstScheduleDate.addMonths(1*cntPeriod):
                                   (enmPeriod == Period.QUARTERLY)?dtFirstScheduleDate.addMonths(3*cntPeriod):
                                   (enmPeriod == Period.YEARLY)?dtFirstScheduleDate.addMonths(12*cntPeriod):
                                   dtFirstScheduleDate;      
         
         if ((enmPeriod == Period.MONTHLY || enmPeriod == Period.QUARTERLY ||
           enmPeriod == Period.YEARLY) &&
           dtFirstScheduleDate.Day() == Date.daysInMonth(dtFirstScheduleDate.Year(),dtFirstScheduleDate.Month())) {
           dtNextDateShouldBe = Date.newinstance(dtNextDateShouldBe.Year(),dtNextDateShouldBe.Month(),Date.daysInMonth(dtNextDateShouldBe.Year(),dtNextDateShouldBe.Month()));
         }
                   
         system.debug('############dtNextDateShouldBe/recOLIS.ScheduleDate############'+dtNextDateShouldBe+'/'+recOLIS.ScheduleDate);                            
         //If previous and current date are not as per period, Meaning user has changed manually, so skip.
         if (dtNextDateShouldBe != recOLIS.ScheduleDate) {
           setManuallyScheduleDtOLIs.add(recOLIS.OpportunityLineItemId);
           continue;
         }                     
         //Add current record to list of Map.
         mapOLIS.get(recOLIS.OpportunityLineItemId).add(recOLIS);
         
         //If there is any variation in First and current record Amount then previous the Index. 
         //So to check later if the current record was last in list (which is valid)
         if (lstOLIS[0].Revenue != recOLIS.Revenue && !mapManualAmoutOLIIndex.containsKey(recOLIS.OpportunityLineItemId)) {
           mapManualAmoutOLIIndex.put(recOLIS.OpportunityLineItemId,mapOLIS.get(recOLIS.OpportunityLineItemId).size());
         }
        
      }//END: ELSE
    }//END: FOR recOLIS 
       
    //Populate fields only if there is any change recognised on OLIS
    if (mapOLIS != null && mapOLIS.size() > 0 && mapOLISPeriod != null && mapOLISPeriod.size() > 0) { 
       for (OpportunityLineItem recOLI : newMap.values()) {
         //If any OLIS's Schedule Date is manually changes then skip.
         if (setManuallyScheduleDtOLIs.contains(recOLI.Id)) {
           continue;
         }     
           
         if (mapManualAmoutOLIIndex.containsKey(recOLI.Id) && mapOLIS.get(recOLI.Id).size() != mapManualAmoutOLIIndex.get(recOLI.Id)) {
           continue;
         }      
               
         //Get the List of OLIS for an OLI
         List<OpportunityLineItemSchedule> lstOLIS = mapOLIS.get(recOLI.Id);
         if (lstOLIS == NULL) {
           continue;
         }
         recOLI.Revenue_Schedule_Amt_Per_Period__c = lstOLIS[0].Revenue;
         recOLI.Revenue_Schedule_Num_of_Periods__c = lstOLIS.size();
         recOLI.Revenue_Schedule_Period_Type__c = mapPeriod.get(mapOLISPeriod.get(recOLI.Id));
               
       }//END: FOR
    }//END:IF  
  }//END: METHOD detectOLIScheduleChangesAndUpdateOLI
  


  //=========================================================================
  // T-372609 : Utility method to call calculateRevenueScheduleRules() method
  //=========================================================================
  public static void getOLIIds_BillingProduct(Map<ID, OpportunityLineItem> newMap, Map<ID, OpportunityLineItem> oldMap) {
    Set<ID> oliIDs = new Set<ID>();
    Set<String> fieldNames = new Set<String>{'Type_of_Sale__c', 'Start_Date__c', 'End_Date__c'};
    
    for (OpportunityLineItem oli : newMap.values()) {
      // If billing product is null, do not add it to process
      // Insert or update with check whether above mentioned fields (in set) has been updated.
      if (oli.Billing_Product__c <> null && oldMap == null || (oldMap != null && isChangedAnyField(fieldNames, oli, oldMap.get(oli.ID)))) {
        oliIDs.add(oli.ID);
      }
    }
    //call calculateRevenueScheduleRules() method 
    calculateRevenueScheduleRules (oliIDs, newMap);
  }

  //=========================================================================
  // T-268354: Revenue Schedule Rule Calculation: OLI Trigger
  // Passing new map for errors in case is run from trigger
  //=========================================================================
  public static void calculateRevenueScheduleRules (Set<ID> oliIDs, Map<ID, OpportunityLineItem> newMap) {
    //Set<String> fieldNames = new Set<String>{'Type_of_Sale__c', 'Start_Date__c', 'End_Date__c'};
    Set<ID> revScheduleRuleIds = new Set<ID>();
    //Set<ID> oliIDs = new Set<ID>();
    Map<ID, OpportunityLineItem> opptyLinesToBeProcessed = new Map<ID, OpportunityLineItem>();
    
    /* Arpita Bose - moved to getOLIIds_BillingProduct() so this method can be called from other classes
    for (OpportunityLineItem oli : newMap.values()) {
      // If billing product is null, do not add it to process
      // Insert or update with check whether above mentioned fields (in set) has been updated.
      if (oli.Billing_Product__c <> null && oldMap == null || (oldMap != null && isChangedAnyField(fieldNames, oli, oldMap.get(oli.ID)))) {
        oliIDs.add(oli.ID);
      }
    }*/
    // If there is no OLI to process, return
    if (oliIDs.size() < 1) {
      return;
    }  
    for (OpportunityLineItem oli : [SELECT ID, Billing_Product__r.Revenue_Schedule_Rule__c, Start_Date__c,
                                           End_Date__c, Billing_Product__c, Quantity, UnitPrice  
                                    FROM OpportunityLineItem
                                    WHERE ID IN: oliIDs]) {
      if (oli.Billing_Product__r.Revenue_Schedule_Rule__c <> null) {
        revScheduleRuleIds.add(oli.Billing_Product__r.Revenue_Schedule_Rule__c);
        opptyLinesToBeProcessed.put(oli.ID, oli);
      }
    }   
    // Populates revenue schedule map
    Map<ID, Revenue_Schedule_Rule__c> revenueScheduleMap = retrieveRevenueScheduleMap (revScheduleRuleIds);   
    // If there is no revenueScheduleRule exist
    if (revScheduleRuleIds.size() < 1 || revenueScheduleMap.size() < 1) {
      return;
    }
    
    OpportunityLineItemSchedule oliSchedule;
    Revenue_Schedule_Rule__c revenueScheduleRule;
    List<OpportunityLineItemSchedule> oliScheduleList = new List<OpportunityLineItemSchedule>();
    try {
      for (OpportunityLineItem oli : opptyLinesToBeProcessed.values()) {
        OpportunityLineItemSchedule firstPayment;
        if (revenueScheduleMap.containsKey(oli.Billing_Product__r.Revenue_Schedule_Rule__c)) {
          revenueScheduleRule = revenueScheduleMap.get(oli.Billing_Product__r.Revenue_Schedule_Rule__c);
          //c)Integer nbInstallments = rule.Number_of_installments__c == 0 ? rule.Number_of_installments__c : endDate.monthsBetween(startDate);
          Integer nbInstallments = calNBInstallments(revenueScheduleRule, oli);                   
          if (nbInstallments <= 0) {
            nbInstallments = 1;
          }
          
          Date tempDate = oli.Start_Date__c;
          
          //Revenue schedule rule for this OLI.
          Double firstPaymentRevenue;
          if (revenueScheduleRule.Initial_Recognized_Amount__c > 0) {
            firstPaymentRevenue = revenueScheduleRule.Initial_Recognized_Amount__c/100 * oli.UnitPrice;
          } else {
            firstPaymentRevenue = (revenueScheduleRule.Schedule_Type__c == Constants.REVENUE_TYPE_REPEAST_AMT_EACH_INST) ? oli.UnitPrice : oli.UnitPrice / nbInstallments;
          }
          //a) If there is an Initial_Recognized_Amount__c:
          if (revenueScheduleRule.Initial_Recognized_Amount__c != null) {
            firstPayment = createNewOliSchedule(oli.ID, tempDate, firstPaymentRevenue, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);
          }        
          //b) If Recognize_in_Month__c is not null
          if (revenueScheduleRule.Recognize_In_Month__c != null) {
            //Added recognized months in OLI.Start Date and that will be scheduled date for first payment
            tempDate = tempDate.addMonths(Integer.valueOf(revenueScheduleRule.Recognize_In_Month__c));
            if (firstPayment != null) {
              firstPayment.ScheduleDate = tempDate; //Added recognized month
            } else {
              firstPayment = createNewOliSchedule(oli.ID, tempDate, firstPaymentRevenue, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);        
            }
          }
          //First payment is exists so installment reduced
          if (firstPayment != null) {
            oliScheduleList.add(firstPayment);
            nbInstallments--;
          }
          //If Revenue schedule type is devide amount in multiple installment
          if (revenueScheduleRule.Schedule_Type__c == Constants.REVENUE_TYPE_DIVIDE_AMT_MULTIPLE_INST && nbInstallments > 0) {
            Double amountPerInstallment = calculate_AmountPerInstallment(oli, firstPayment, nbInstallments);
            for (Integer i = 0; i < nbInstallments; i++) {
              //If installment period on rule is monthly
              if (revenueScheduleRule.Installment_Period__c.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_MONTHLY)) {
                oliSchedule = createNewOliSchedule(oli.ID, tempDate.addMonths(1), amountPerInstallment, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);
                oliScheduleList.add(oliSchedule);
                tempDate = tempDate.addMonths(1);
              }             
              //If installment period on rule is Quaterly
              else if (revenueScheduleRule.Installment_Period__c.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_QUATERLY)) {
                oliSchedule = createNewOliSchedule(oli.ID, tempDate.addMonths(3), amountPerInstallment, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);
                oliScheduleList.add(oliSchedule);
                tempDate = tempDate.addMonths(3);
              }
            }
          } //If Revenue schedule type is repeast amount each installment 
          else if (revenueScheduleRule.Schedule_Type__c == Constants.REVENUE_TYPE_REPEAST_AMT_EACH_INST && nbInstallments > 0) {
            Double tempRev = oli.UnitPrice;
            for (Integer i = 0; i < nbInstallments; i++) {
              if (revenueScheduleRule.Installment_Period__c.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_MONTHLY)) {
                oliSchedule = createNewOliSchedule(oli.ID, tempDate.addMonths(1), tempRev, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);
                oliScheduleList.add(oliSchedule);
                tempDate = tempDate.addMonths(1);
              }
              else if (revenueScheduleRule.Installment_Period__c.equalsIgnoreCase(Constants.INSTALLMENT_PERIOD_QUATERLY)) {
                oliSchedule = createNewOliSchedule(oli.ID, tempDate.addMonths(3), tempRev, Constants.REVENUE_SCHEDULED_TYPE_REVENUE);
                oliScheduleList.add(oliSchedule);
                tempDate = tempDate.addMonths(3);
              }
            }
          }
        }
      }
    } 
    catch (DMLException ex) {
      System.debug('\n[OpportunityLineItemTriggerHandler: calculateRevenueScheduleRules]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','calculateRevenueScheduleRules', ex.getStackTraceString(), ex);
      if (newMap != null) {
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newMap.values().get(0).addError(ex.getDmlMessage(i));
        }
      }
    }
    catch (Exception ex) {
      System.debug('\n[OpportunityLineItemTriggerHandler: calculateRevenueScheduleRules]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','calculateRevenueScheduleRules', ex.getStackTraceString(), ex);
      if (newMap != null) {
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newMap.values().get(0).addError(ex.getMessage());
        }
      }
    } 
    //Inserting revenue schedules  
    if (!oliScheduleList.isEmpty()) {
      List<OpportunityLineItemSchedule> oliScheduleDelete = new List<OpportunityLineItemSchedule>();    
      // Identify existing OpportunityLineItemSchedules
      for (OpportunityLineItemSchedule olis : [SELECT Id FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId IN: oliIDs]) {
        oliScheduleDelete.add(olis);
      } 
      try {
        if (!oliScheduleDelete.isEmpty()) {
            delete oliScheduleDelete;
        }
        insert oliScheduleList;
      } catch (Dmlexception ex) {
        System.debug('\n[OpportunityLineItemTriggerHandler: calculateRevenueScheduleRules: DMLException]: ['+ex.getMessage()+']]');
        apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','calculateRevenueScheduleRules: DMLException', ex.getStackTraceString(), ex);        
        if (newMap != null) {
          for (Integer i = 0; i < ex.getNumDml(); i++) {
            newMap.values().get(0).addError(ex.getDmlMessage(i));
          }
        }
      }
    }
  }

  //=========================================================================
  //Calculate number of Installments
  //=========================================================================
  private static Integer calNBInstallments(Revenue_Schedule_Rule__c revScheduleRule, OpportunityLineItem oli){
    Integer nbInstallments = (revScheduleRule.Number_of_installments__c != 0) ? (Integer)revScheduleRule.Number_of_installments__c : 
                                   oli.Start_Date__c.monthsBetween(oli.End_Date__c);
    return nbInstallments;                               
  }

  //=========================================================================
  //Populates revenueScheduleMap
  //=========================================================================
  private static Map<ID, Revenue_Schedule_Rule__c> retrieveRevenueScheduleMap (Set<ID> revScheduleRuleIds) {
    Map<ID, Revenue_Schedule_Rule__c> revenueScheduleMap = new Map<ID, Revenue_Schedule_Rule__c>();
    for (Revenue_Schedule_Rule__c revScheduleRule : [SELECT Id, Initial_Recognized_Amount__c, 
                                                            Number_of_installments__c, Recognize_In_Month__c, 
                                                            Schedule_Type__c, Installment_Period__c 
                                                     FROM Revenue_Schedule_Rule__c
                                                     WHERE Id IN :revScheduleRuleIds]) {
      revenueScheduleMap.put(revScheduleRule.ID, revScheduleRule);
    }
    return revenueScheduleMap;
  }

  //=========================================================================
  //Returns true if any field changed from the passed set of fields.
  //=========================================================================
  private static Boolean isChangedAnyField (Set<String> fieldNameSet, OpportunityLineItem newRecord, OpportunityLineItem oldRecord) {
    for (String fieldName : fieldNameSet) {
      if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
        return true;
      }
    }
    return false;
  }
  //=========================================================================
  //Calculate amount per Installment
  //=========================================================================
  private static Double calculate_AmountPerInstallment(OpportunityLineItem oli, OpportunityLineItemSchedule firstPayment,
                                                         Integer nbInstallments){
    Double amountPerInstallment;                                                       
    if (firstPayment != null) {
       amountPerInstallment = (oli.UnitPrice - firstPayment.Revenue) / nbInstallments;
    } else {
       amountPerInstallment = oli.UnitPrice / nbInstallments;
    }
    return amountPerInstallment;
  }

  //========================================================================
  //Creating new oliSchedule
  //========================================================================
  private static OpportunityLineItemSchedule createNewOliSchedule(Id oliID, Date tempDate, Double revenue, String oliType) {
    return new OpportunityLineItemSchedule(
      OpportunityLineItemId = oliID,
      ScheduleDate = tempDate,
      Revenue = revenue,
      Type = oliType);
  }

}