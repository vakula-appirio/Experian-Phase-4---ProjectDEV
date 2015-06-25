/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityUtility
 * Description: T-258164: Check opportunity dates with revenue schedules
 * Created Date: 10th April, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 29, 2014                 Nathalie Le Guay             Add OPPTY_ERR_CONTRACT_START_PRIOR_TO_CLOSEDATE error
 =====================================================================*/
public with sharing class OpportunityUtility {
    
  //Checks opportunity dates 
  public static List<String> checkOpportunityDates(Id OpportunityId) {
    Set<ID> opptyLineIDs = new Set<ID>();
    List<String> errorList = new List<String>();
    Set<String> errors = new Set<String>();
    Opportunity currentOpportunity;
    Boolean hasOLIearlyDate = false;
    Boolean hasScheduleEarlierThanContractDate = false;
    Boolean hasScheduleEarlierThanCloseDate = false;
    
    for (Opportunity oppty : [SELECT Id, CloseDate, Contract_Start_Date__c, 
                                     (SELECT Id, Start_Date__c FROM OpportunityLineItems) 
                              FROM Opportunity 
                              WHERE ID =: OpportunityId]) {
        if (oppty.Contract_Start_Date__c < oppty.CloseDate) {
          System.debug('--debug0.1--'+Label.OPPTY_ERR_CONTRACT_START_PRIOR_TO_CLOSEDATE);
          errorList.add(Label.OPPTY_ERR_CONTRACT_START_PRIOR_TO_CLOSEDATE);
        }
        for (OpportunityLineItem oli: oppty.OpportunityLineItems) {
          opptyLineIDs.add(oli.ID);
          ////A start date on an opp line item is before the expected close date
          if (oli.Start_Date__c < oppty.CloseDate) {
            if (hasOLIearlyDate) {
              break;
            }
            System.debug(oli.ID+'--debug1.0--'+Label.OPPTY_ERR_OLIE_DATE_PRIOR_OPPTY_CLOSE_DATE);
            errorList.add(Label.OPPTY_ERR_OLIE_DATE_PRIOR_OPPTY_CLOSE_DATE);
            hasOLIearlyDate = true;
          }
        }
        currentOpportunity = oppty;
    }
    
    if (opptyLineIDs.size() > 0) {
        for (OpportunityLineItemSchedule ols : [SELECT OpportunityLineItemId, Id, ScheduleDate
                                                FROM OpportunityLineItemSchedule
                                                WHERE OpportunityLineItemId IN: opptyLineIDs]) {
                                            
        //A OpportunityLineItemSchedule Schedule date is before the expected close date
        if (ols.ScheduleDate < currentOpportunity.CloseDate) {
          if (!hasScheduleEarlierThanCloseDate) {
            System.debug('--debug1.1--'+Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CLOSE_DATE);
            errorList.add(Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CLOSE_DATE);
            hasScheduleEarlierThanCloseDate = true;
          }
        }
        //A revenue schedule date is before the contract start date
        if (ols.ScheduleDate < currentOpportunity.Contract_Start_Date__c) {
          if (!hasScheduleEarlierThanContractDate) {
            System.debug('--debug1.2--'+Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CONTRACT_STRT_DATE);
            errorList.add(Label.OPPTY_ERR_REVSCH_DATE_PRIOR_OPPTY_CONTRACT_STRT_DATE);
            hasScheduleEarlierThanContractDate = true;
          }
        }
        }//End of for loop
    } //End of IF
    if (errors.size() > 0) {
        for (String e : errors) {
          //errorList.add(e);
        }
    }
    return errorList;
  }
  
  public static list<Opportunity> getRelatedOpportunities(Account_Segment__c accSeg) {
  	  if(accSeg.Segment_Type__c == 'Region') {
  	  	return accSeg.Opportunities_Regions__r;
  	  } else if(accSeg.Segment_Type__c == 'Country') {
  	  	return accSeg.Opportunities_Countries__r;
  	  } else if(accSeg.Segment_Type__c == 'Business Unit') {
  	  	return accSeg.Opportunities_Business_Units__r;
  	  } else if(accSeg.Segment_Type__c == 'Business Line') {
  	  	return accSeg.Opportunities_Business_Lines__r;
  	  } else if(accSeg.Segment_Type__c == 'Global Business Line') {
  	  	return accSeg.Opportunities_Global_Lines_of_Business__r;
  	  } else {
  	  	return new list<Opportunity>();
  	  }
  }
  
  public static Set<Id> getAllRelatedOrderIds(list<Account_Segment__c> accSegList) {
  	Set<Id> orderIds = new Set<Id>();
  	for(Account_Segment__c accSeg : accSegList) {
  	  for(Order__c ordr : accSeg.Orders_Business_Lines__r) {
  	  	orderIds.add(ordr.Id);
  	  }
  	  for(Order__c ordr : accSeg.Orders_Business_Units__r) {
  	  	orderIds.add(ordr.Id);
  	  }
  	  for(Order__c ordr : accSeg.Orders_Countries__r) {
  	  	orderIds.add(ordr.Id);
  	  }
  	  for(Order__c ordr : accSeg.Orders_Global_Business_Lines__r) {
  	  	orderIds.add(ordr.Id);
  	  }
  	  for(Order__c ordr : accSeg.Orders_Regions__r) {
  	  	orderIds.add(ordr.Id);
  	  }
  	}
  	return orderIds;
  }
  
  public static list<Order__c> getRelatedOrders(Account_Segment__c accSeg) {
  	  if(accSeg.Segment_Type__c == 'Region') {
  	  	return accSeg.Orders_Regions__r;
  	  } else if(accSeg.Segment_Type__c == 'Country') {
  	  	return accSeg.Orders_Countries__r;
  	  } else if(accSeg.Segment_Type__c == 'Business Unit') {
  	  	return accSeg.Orders_Business_Units__r;
  	  } else if(accSeg.Segment_Type__c == 'Business Line') {
  	  	return accSeg.Orders_Business_Lines__r;
  	  } else if(accSeg.Segment_Type__c == 'Global Business Line') {
  	  	return accSeg.Orders_Global_Business_Lines__r;
  	  } else {
  	  	return new list<Order__c>();
  	  }
  }
}