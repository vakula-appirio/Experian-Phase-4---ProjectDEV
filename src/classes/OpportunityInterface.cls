/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityInterface
 * Description: T-313548 : Interface class for OpportunityTriggerHandler.cls 
 * Created Date: Aug 29th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Sep 15, 2014                  Nathalie Le Guay             Adding moveTaskToOpptyWhenCreatedFromContact() (Fast Track - Outcomes__c story)
 * Sep 23rd, 2014                Arpita Bose                  Removed moveTaskToOpptyWhenCreatedFromContact() as T-317502 Cancelled
 * Oct 07th, 2014                Noopur                       T-323348 : updates for Polymorphism designs. Instantiated the interface and used it instead of caling the static methods of classes.
 * Oct 14, 2014                  Nathalie                     Adding opportunityReopeningProcess()
 * Oct 25th, 2014                Nathalie                     Cleanup the interface by keeping only the necessary methods
 * Nov 10th, 2014                Nathalie Le Guay             I-136313: Add validateOpportunityContactAddressOnClosedWon()
 * Nov 14th, 2014                Noopur                       I-138684: Added validateProductsData()
 * Feb 23rd, 2015                Arpita Bose                  T-364931: Added method validateOpptyConAddressOnClosedWon_NonFreeTrial() 
 * Mar 03rd, 2015                Arpita Bose                  T-364941:Removed method validateOpptyAccAddressOnClosedWon_NonFreeTrial()
 =====================================================================*/
public interface OpportunityInterface {
  // methods implemented in OpportunityTriggerHandler.cls
  //void createOppContactRoles(Map<Id,Opportunity> opps);

  void checkOpptyChannelTypeOnClosedWon(List<Opportunity> closedWonOpportunities);
  void createOppLineItemsForRenewal ( List<Opportunity> newList ) ;
  
  void updateAccPlanOpptyRecs (Set<ID> opptyIDsToUpdateAccPlanOpptySet) ;
  
  void onDemandOpportunityLineItem(List<Opportunity> closedWonOpportunities, List<Opportunity> newList) ;
  void populateInvoiceToEndUser_OnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList);
  void validateOpptyContactRoleOnClosedWon(List<Opportunity> closedWonOpportunities, List<Opportunity> newList);
  //void validateOnePurchaseLedger_OpptyConRole(List<Opportunity> closedWonOpportunities, List<Opportunity> newList); T-326540
  void createOppContactRoles_RenewalOpps(Map<Id, Opportunity> newMap);
  void opportunityReopeningProcess (Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap);
  //void validateOpportunityContactAddressOnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList);
  
  void validateOppRelatedRecordsData(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList);
  
  // T-364931, T-364941
  void validateOpptyConAddressOnClosedWon_NonFreeTrial(List<Opportunity> closedWonOpportunities);
  
  //T-366560
  void validateOpptyAccWithSaasContact(List<Opportunity> closedWonOpportunities);
  //
  // I-138684 
  List<Opportunity> validateProductsData (List<Opportunity> closedWonOpportunities, List<Opportunity> newList);

  // declaring methods to be implemented in classes
  /*void beforeInsert (List<Opportunity> newList);
  void afterInsert (Map<ID, Opportunity> newMap);
  void beforeUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap);
  void afterUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap);
  List<Opportunity> fetchClosedWonRecords(Map<Id,Opportunity> oldMap, List<Opportunity> newList) ;

  // methods implemented in OpportunityTrigger_DatesUtility.cls
  void populateStartingStage(List<Opportunity> opps, Map<Id, Opportunity> oldOpps);
  void validateServiceDates(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap);
  void populateServiceDatesOnOLI(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap);

  // methods implemented in OpportunityTrigger_OrderHelper.cls
  void createOrderAndOrderLineItems (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap);
  void populateOpptyVsLineMapAndOpptyLineList (List<Opportunity> oppList);

  void createRevenueSchedules (Map<ID, Order_Line_Item__c> oliId_ordLIMap);
  void deleteOrderAndOppIfOppIsReopened(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap);

  // method implemented in Opportunity_ExitCriteriaUtility
  Boolean getOpportunitiesExitCriteriaNotMet (Map<Id, Opportunity> newOpps,Map<Id, Opportunity> oldOpps);
  Boolean isMeetingExitCriteria (Opportunity opp, String newStage, String oldStage);
  Boolean hasRequiredTask(Opportunity opp, String taskType);

  Boolean isOpptyFieldUpdated (Set<String> fieldSet, Opportunity newRec, Opportunity oldRec) ;

  // methods implemented in OpportunityTriggerHelper.cls
  void checkAccessOnAccountForUser (List<Opportunity> newList);
  void multiCurrencyFieldUpdate(List<Opportunity> newList, Map<ID, Opportunity> oldMap);
  void calculateStageDuration(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldOpps);
  void updateOppFieldsIfWonOrClosed(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldOpps);

  void checkOpptyDates (List<Opportunity> newList);
  void createOppTeamMembers(Map<Id, Opportunity> opportunityMap);
  void synchCurrencyISOCodes (Map<Id,Opportunity> newMap, Map<ID, Opportunity> oldMap);
  void moveOriginatingTaskToNewOppty (List<Opportunity> newList);
*/
}