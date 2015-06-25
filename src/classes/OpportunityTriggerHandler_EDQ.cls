/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTriggerHandler_EDQ
 * Description: T-313548 : EDQ specific class
 * Created Date: Aug 29th, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified                 Modified By                  Description of the update
 * Sep 19th, 2014                Arpita Bose                  T-320157: Added method populateInvoiceToEndUser_OnClosedWon()
 * Sep 24th, 2014                Arpita Bose                  T-321347: Added method createOppContactRoles_RenewalOpps()
 * Sep 26th, 2014                Arpita Bose                  T-322920: Added method validateOnePurchaseLedger_OpptyConRole()
 * Sep 26th, 2014                Arpita Bose                  T-322814: Added method validateOpptyContactRoleOnClosedWon()
 * Oct 08th, 2014                Noopur                       T-323348 : updates for Polymorphism designs. Instantiated the
                                                              interface and used it instead of caling the static methods of classes.
 * Oct 17/20th, 2014             Pallavi                      T-326540: Refactoring: Improve Opp Trigger
 * Nov 07th, 2014                Noopur                       I-138030: Add logic in checkOpptyChannelTypeOnClosedWon(), as it is EDQ-specific
 * Nov 10th, 2014                Nathalie Le Guay             I-136313: Add validateOpportunityContactAddressOnClosedWon()
 * Nov 14th, 2014                Noopur                       I-138684: Added validateProductsData()
 * Dec 11th, 2014                Naresh Kr Ojha               T-339471: Added validateOppRelatedRecordsData()
 * Mar 12th, 2015                Arpita Bose                  T-368849: Refactoring: Opportunity Contact Role queries: Added a method getOppTo_RelatedChild() and
                                                              Updated methods: 1) populateInvoiceToEndUser_OnClosedWon()
                                                              2) validateOpptyContactRoleOnClosedWon()
                                                              3) validateOppRelatedRecordsData()
 * Mar 12th, 2015                Paul Kissick                 Case #530104 - Adding more Contact Roles to createOppContactRoles_RenewalOpps, and addresses
 * Apr 14th, 2015                Paul Kissick                 Case #599431 - Default 'Primary' partner if only 1 exists, and is 'Indirect'
 =====================================================================*/
public class OpportunityTriggerHandler_EDQ extends OpportunityTriggerHandler implements OpportunityInterface {
  public static Map<ID, Opportunity> mapClosedWonOppTo_Child;

  // T-320157: Method to populate Opp.Invoice_to_End_User__c and validate data on Opp Close/Won
  public override void populateInvoiceToEndUser_OnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList) {
    Set<ID> closingOpptyIds = new Set<ID>();
    Set<ID> contactIDs = new Set<ID>();
    Map<ID, Opportunity> mapOppTo_ConRole_Oli = new Map<ID, Opportunity>();
    Map<ID, Contact> contactMap = new Map<ID, Contact>();

    mapClosedWonOppTo_Child = getOppTo_RelatedChild(closedWonOpportunities);

    // query all the Oppty meeting above condition along with the Opportunity Contact roles and OLIs
    // and store it in a map
    /*for (Opportunity opp : [Select Id,
                             (Select Id, OpportunityLineItem.Product2.Business_Line__c From OpportunityLineItems
                                 WHERE OpportunityLineItem.Product2.Business_Line__c =: Constants.BUSINESSLINE_DATA_QUALITY),
                             (Select Id, ContactId, Role From OpportunityContactRoles
                                    WHERE Role = :Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER)
                            From Opportunity
                            WHERE Id IN :closedWonOpportunities]) {
        mapOppTo_ConRole_Oli.put(opp.Id, opp);

        //loop through the OpportunityContactRoles and store ContactId in a set 'contactIDs'
        for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
          contactIDs.add(ocr.ContactId);
        }
    }*/

    for (Opportunity opp : mapClosedWonOppTo_Child.values()) {
      if (opp.OpportunityContactRoles.size() > 0 && opp.OpportunityLineItems.size() > 0) {
        for (OpportunityLineItem oli : opp.OpportunityLineItems) {
          if (oli.Product2.Business_Line__c == Constants.BUSINESSLINE_DATA_QUALITY) {
            mapOppTo_ConRole_Oli.put(opp.Id, opp);
          }
        }
        for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
          if (ocr.Role == Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER) {
            contactIDs.add(ocr.ContactId);
          }
        }
      }
    }

    // query all Contacts Id, AccountId WHERE Id in 'contactIDs', and Store in a Map
    if (contactIDs.size() > 0) {
      for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIDs]) {
         contactMap.put(con.Id, con);
      }
    }

    // loops through the Opps records from the trigger
    if (!mapOppTo_ConRole_Oli.isEmpty() && !contactMap.isEmpty()) {
	    for (Opportunity opp : newList) {
	      if (mapOppTo_ConRole_Oli.containsKey(opp.ID)) {
	        Opportunity queryOpp = mapOppTo_ConRole_Oli.get(opp.ID);
	        if (queryOpp.OpportunityContactRoles.size() > 0 && queryOpp.OpportunityLineItems.size() > 0) {
	          OpportunityContactRole opptyContact = queryOpp.OpportunityContactRoles.get(0);
	          if (contactMap.containsKey(opptyContact.ContactId) && contactMap.get(opptyContact.ContactId).AccountId == opp.AccountId) {
	            opp.Invoice_to_End_User__c = 'Yes';
	          } else {
	            opp.Invoice_to_End_User__c = 'No';
	          }
	        }
	      }
	    }
    }
  }
  // Method End

  // T-321347: Method to create new contact roles and assign them to new opportunity
  // Case #530104 - Adding more roles, and addresses for renewals.
  public override void createOppContactRoles_RenewalOpps(Map<Id, Opportunity> newMap) {
    Set<String> oppRoleRec = new Set<String>{Constants.OPPTY_CONTACT_ROLE_RENEWAL,
                                             Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER,
                                             Constants.OPPTY_CONTACT_ROLE_UPDATE,
                                             Constants.OPPTY_CONTACT_ROLE_SHIPTO, 
                                             Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL,
                                             Constants.OPPTY_CONTACT_ROLE_COMMERCIAL};
    Set<Id> prevOppIds = new Set<Id>();
    Map<String, Opportunity> previousOpptyMap = new Map<String, Opportunity>();
    List<OpportunityContactRole> oppRolesToInsert = new List<OpportunityContactRole>();
    List<Opportunity_Contact_Address__c> opptyContactAddressList = new List<Opportunity_Contact_Address__c>();

    // get the previous opportunity
    for (Opportunity opp : newMap.values()) {
      if (opp.Type != null && opp.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_RENEWAL)) {
        if (opp.Previous_Opportunity__c != null) {
          prevOppIds.add(opp.Previous_Opportunity__c);
        }
      }
    }

    // query all the Original Opportunity along with OpportunityContactRoles stored on Previous Opportunity
    // and store it in a Map 'previousOpptyMap'
    for(Opportunity prevOpp : [SELECT Id, Previous_Opportunity__c,
                                (SELECT Id, Role, OpportunityId, ContactId, IsPrimary, Contact.Inactive__c
                                  FROM OpportunityContactRoles
                                  WHERE Role IN : oppRoleRec),
                                (SELECT Id, Opportunity__c, Address__c, Role__c, Contact__c, Contact__r.Inactive__c
                                  FROM Opportunity_Contact_Addresses__r) 
                              FROM Opportunity
                              WHERE Id IN :prevOppIds]) {
      previousOpptyMap.put(prevOpp.ID, prevOpp);
    }

    // Loop over the Opportunity
    for (Opportunity opp : newMap.values()) {

      if (opp.Type != null && opp.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_RENEWAL) &&
          opp.Previous_Opportunity__c != NULL &&
          previousOpptyMap.containsKey(opp.Previous_Opportunity__c) &&
          previousOpptyMap.get(opp.Previous_Opportunity__c).OpportunityContactRoles.size() > 0) {

        for (OpportunityContactRole ocr : previousOpptyMap.get(opp.Previous_Opportunity__c).OpportunityContactRoles) {
          //Create new contact role, only if the contact is active
          if (!ocr.Contact.Inactive__c) {
            OpportunityContactRole newOppContRole = new OpportunityContactRole();
            newOppContRole.OpportunityID = opp.ID; //New oppty
            newOppContRole.ContactId = ocr.ContactId;
            newOppContRole.Role = ocr.Role;
            newOppContRole.IsPrimary = ocr.IsPrimary;

            oppRolesToInsert.add(newOppContRole);
          }
        }
        for (Opportunity_Contact_Address__c opptyContAdd : previousOpptyMap.get(opp.Previous_Opportunity__c).Opportunity_Contact_Addresses__r) {
          if (!opptyContAdd.Contact__r.Inactive__c) {
            Opportunity_Contact_Address__c newOpptyContAdd = new Opportunity_Contact_Address__c();
            newOpptyContAdd.Contact__c = opptyContAdd.Contact__c;
            newOpptyContAdd.Address__c = opptyContAdd.Address__c;
            newOpptyContAdd.Role__c = opptyContAdd.Role__c;
            newOpptyContAdd.Opportunity__c = opp.ID;
            opptyContactAddressList.add(newOpptyContAdd);
          }
        }
      }
    }

    // Insert new opportunityContactRoles
    try {
      if (oppRolesToInsert.size() > 0) {
        insert oppRolesToInsert;
      }
      if (!opptyContactAddressList.isEmpty()) {
        insert opptyContactAddressList;
      }
    } catch (DMLException ex) {
        system.debug('[OpportunityTriggerHandler_EDQ: createOppContactRoles_RenewalOpps] Exception: ' + ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler_EDQ','createOppContactRoles_RenewalOpps', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newMap.values().get(0).addError(ex.getDMLMessage(i));
        }
    }
  }


  // Pallavi Sharma @ Oct 20th 2014
  // T-326540: Refactoring: Improve Opp Trigger
  // Merge validation on role that there should be one oppty contact roles with a Role of Bill-To (previously called 'Purchase Ledger') to
  // a closedWon opportunity
  // T-322814: method to validate there is atleast one of each of the following Contact roles
  // (Ship-to, Bill-To, Contractual, Renewals, Updates, Commercial ) on closed/Won Oppty
  public override void validateOpptyContactRoleOnClosedWon(List<Opportunity> closedWonOpportunities, List<Opportunity> newList){
    Integer purchaseLedgerCounter = 0;
    Integer shipToCounter = 0;
    super.validateOpptyContactRoleOnClosedWon(closedWonOpportunities, newList);
    Set<String> oppRoleRec = new Set<String>{Constants.OPPTY_CONTACT_ROLE_SHIPTO,
                                             Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER,
                                             Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL,
                                             Constants.OPPTY_CONTACT_ROLE_RENEWAL,
                                             Constants.OPPTY_CONTACT_ROLE_UPDATE,
                                             Constants.OPPTY_CONTACT_ROLE_COMMERCIAL };

    Map<ID, Opportunity> mapOppTo_ConRole = new Map<ID, Opportunity>();
    Boolean foundOppContact = false;
    mapClosedWonOppTo_Child = getOppTo_RelatedChild(closedWonOpportunities);

    // query all the oppty contact roles having the same oppty id and roles in above Set
    // and store it in a map
    /*for (Opportunity opp : [SELECT Id,
                              (SELECT Id, ContactId, Role FROM OpportunityContactRoles
                                WHERE Role IN :oppRoleRec)
                            FROM Opportunity
                            WHERE Id IN :closedWonOpportunities]) {
      mapOppTo_ConRole.put(opp.Id, opp);

    }*/

    for (Opportunity opp : mapClosedWonOppTo_Child.values()) {
      if (opp.OpportunityContactRoles.size() > 0) {
        for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
          if (oppRoleRec.contains(ocr.Role)) {
            mapOppTo_ConRole.put(opp.Id, opp);
          }
        }
      }
    }
        
    Map<ID, Set<String>> opptyID_ContactRoleSet_Map = new Map<ID, Set<String>>();

    // loop through the Oppty Contact roles for the given Opportunity
    if (!mapOppTo_ConRole.isEmpty()) {
	    for (Opportunity opp : newList) {
	      if (mapOppTo_ConRole.containsKey(opp.ID)) {
	        Opportunity queryOpp = mapOppTo_ConRole.get(opp.ID);
	        if (queryOpp.OpportunityContactRoles.size() > 0 ) {
	          for (OpportunityContactRole ocr : queryOpp.OpportunityContactRoles) {
	            if (!opptyID_ContactRoleSet_Map.containsKey(opp.ID)) {
	              opptyID_ContactRoleSet_Map.put(opp.ID, new Set<String>());
	            }
	            opptyID_ContactRoleSet_Map.get(opp.ID).add(ocr.Role);
	            if (ocr.Role.equalsIgnoreCase(Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER)) {
	              purchaseLedgerCounter += 1;
	            } else if (ocr.Role.equalsIgnoreCase(Constants.OPPTY_CONTACT_ROLE_SHIPTO)) {
	              shipToCounter += 1;
	            }
	          }
	        }
	        // check if atleast one of each of Ship-To, Bill-To (previously called Purchase Ledger), Contractual, Renewal,
	        // Update and Commercial Contact roles exists on Oppty or not
	        if (opptyID_ContactRoleSet_Map.containsKey(opp.ID)) {
	          Set<String> contactRoles = opptyID_ContactRoleSet_Map.get(opp.ID);
	          if (contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_SHIPTO) &&
	                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER) &&
	                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL) &&
	                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_RENEWAL) &&
	                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_UPDATE) &&
	                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_COMMERCIAL)) {
	
	            foundOppContact = true;
	          }
	        }
	        if (!foundOppContact) {
	          opp.addError(Label.OPPTY_ERR_CONTACT_ROLE_CHECK_FOR_EDQ);
	        }
	        if (purchaseLedgerCounter > 1 || shipToCounter > 1) {
	          opp.addError(Label.OPPTY_ERR_CONTACT_ROLE_CHECK);
	        }
	      }
	    }
    }
  }


  //****************************************************************************
  // Case #599431 - Rewrote to set primary if only 1 partner and indirect.
  //****************************************************************************
  public override void checkOpptyChannelTypeOnClosedWon(List<Opportunity> closedWonOpportunities) {
    super.checkOpptyChannelTypeOnClosedWon( closedWonOpportunities);

    Set<ID> closingOpptyIDs = new Set<ID>();
    
    Map<String, List<Partner>> opptyID_ListOfOpptyPartner = 
                                              new Map<String, List<Partner>>();
    // List<String> oppChannelType = new List<String>{Constants.OPPTY_CHANNEL_TYPE_DIRECT, // PK Commented out as isn't used 
    //                                               Constants.OPPTY_CHANNEL_TYPE_INDIRECT};                                          
    
    Map<String, List<Partner>> opptyID_ListOfAllOpptyPartner = new Map<String, List<Partner>>();
    // Return all partners, irrespective if primary or not.
    List<Partner> oppPartners = [
      SELECT Id, IsPrimary, OpportunityId, AccountToId, Opportunity.AccountId, Role
      FROM Partner
      WHERE // IsPrimary = true AND
      OpportunityId IN: closedWonOpportunities
    ];
    for(Partner opr : oppPartners) {
      if (opr.AccountToId != opr.Opportunity.AccountId) {
        if (!opptyID_ListOfAllOpptyPartner.containsKey(opr.OpportunityId)) {
          opptyID_ListOfAllOpptyPartner.put(opr.OpportunityId, new List<Partner>());
        }
        opptyID_ListOfAllOpptyPartner.get(opr.OpportunityId).add(opr);
        if (opr.IsPrimary) {
          if (!opptyID_ListOfOpptyPartner.containsKey(opr.OpportunityId)) {
            opptyID_ListOfOpptyPartner.put(opr.OpportunityId, new List<Partner>());
          }
          opptyID_ListOfOpptyPartner.get(opr.OpportunityId).add(opr);
        }
      }
    }


    // loop through oppty
    for (Opportunity opp : closedWonOpportunities) {
      if (String.isBlank(opp.Channel_Type__c)) {
        opp.Channel_Type__c.addError(Label.OPPTY_CHANNELTYPE_REQUIRED);
      }
      // Direct Channel, no primary partner allowed. 
      if (!String.isBlank(opp.Channel_Type__c) && opp.Channel_Type__c.equalsIgnoreCase(Constants.OPPTY_CHANNEL_TYPE_DIRECT)) {
        if (opptyID_ListOfOpptyPartner.containsKey(opp.Id) && opptyID_ListOfOpptyPartner.get(opp.Id).size() > 0) {
          opp.addError(Label.OPPTY_CHANNELTYPE_DIRECT_NO_PARTNER_ALLOWED );
        }
      }
      // Indirect Channel, primary required.
      else if (!String.isBlank(opp.Channel_Type__c) && opp.Channel_Type__c.equalsIgnoreCase(Constants.OPPTY_CHANNEL_TYPE_INDIRECT)) {
        if (opptyID_ListOfOpptyPartner.containsKey(opp.Id)) continue; // Skip out as this is fine.
        if (!opptyID_ListOfOpptyPartner.containsKey(opp.Id) && opptyID_ListOfAllOpptyPartner.containsKey(opp.Id) 
            && opptyID_ListOfAllOpptyPartner.get(opp.Id).size() == 1) {
          // only 1 partner, so let's fix the primary partner
          Partner partToDel = opptyID_ListOfAllOpptyPartner.get(opp.Id).get(0);
          Partner partToCreate = new Partner(
            OpportunityId = partToDel.OpportunityId,
            IsPrimary = true, 
            AccountToId = partToDel.AccountToId, 
            Role = partToDel.Role
          );
          SavePoint sp1 = Database.setSavepoint();
          try {
            // Updates are not allowed on Partner object, so it must be recreated...
            delete partToDel;
            insert partToCreate;
          }
          catch (Exception e) {
            Database.rollback(sp1);
            opp.addError('A problem occurred: '+e.getMessage());
          }
        }
        else {
          opp.addError(Label.OPPTY_CHANNELTYPE_INDIRECT_PARTNER_REQUIRED );
        }
      }
    }
  }
  
  //As per Task T-339471
  public override void validateOppRelatedRecordsData (List<Opportunity> closedWonOpportunities ,List<Opportunity> newList)  {
    super.validateOppRelatedRecordsData(closedWonOpportunities, newList);

    Set<String> oppRoleRec = new Set<String>{Constants.OPPTY_CONTACT_ROLE_SHIPTO,
                                             Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER,
                                             Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL,
                                             Constants.OPPTY_CONTACT_ROLE_RENEWAL,
                                             Constants.OPPTY_CONTACT_ROLE_UPDATE,
                                             Constants.OPPTY_CONTACT_ROLE_COMMERCIAL };

    Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>();
    mapClosedWonOppTo_Child = getOppTo_RelatedChild(closedWonOpportunities);

    // query all the oppty contact roles having the same oppty id and roles in above Set
    // and store it in a map
    /*for (Opportunity opp : [SELECT Id,
                              (SELECT Id, Contact__c, Role__c FROM Opportunity_Contact_Addresses__r
                                WHERE Role__c IN :oppRoleRec),
                               (Select Id From OpportunityLineItems WHERE EDQ_On_Demand_Product__c  = true),
                               (Select Id, Role From OpportunityContactRoles
                                   WHERE Role =: Constants.DECIDER AND Contact.EDQ_On_Demand__c = true)
                            FROM Opportunity
                            WHERE Id IN :closedWonOpportunities]) {
      oppMap.put(opp.Id, opp);
    }*/

    for (Opportunity opp : mapClosedWonOppTo_Child.values()) {
      if (opp.Opportunity_Contact_Addresses__r.size() > 0 &&
            opp.OpportunityLineItems.size() > 0 &&
              opp.OpportunityContactRoles.size() > 0) {
        for (Opportunity_Contact_Address__c oca : opp.Opportunity_Contact_Addresses__r) {
          if (oppRoleRec.contains(oca.Role__c)) {
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
              if (oli.EDQ_On_Demand_Product__c == true) {
                for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
                  if (ocr.Role == Constants.DECIDER && ocr.Contact.EDQ_On_Demand__c == true) {
                    oppMap.put(opp.Id, opp);
                  }
                }
              }
            }
          }
        }
      }
    }

    validateOpportunityContactAddressOnClosedWon(closedWonOpportunities, newList, oppMap);
    validateOnDemandOpportunityData(closedWonOpportunities, newList, oppMap);
  }

  //On Demand opportunity validation.
  public void validateOnDemandOpportunityData (List<Opportunity> closedWonOpportunities ,List<Opportunity> newList, Map<ID, Opportunity> oppMap) {

    // loop through the Oppty Contact roles for the given Opportunity
    for (Opportunity opp : newList) {
      //as per task T-339471
      if (oppMap.containsKey(opp.ID) && oppMap.get(opp.ID).OpportunityLineItems.size() > 0) {
        if (!(oppMap.get(opp.ID).OpportunityContactRoles.size() > 0)) {
          opp.addError(Label.OPPTY_CLSWON_REQ_ONDEMAND_CONTACT);
        }
      }
    }
  }

  public void validateOpportunityContactAddressOnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList, Map<ID, Opportunity> oppMap) {
    //super.validateOpportunityContactAddressOnClosedWon(closedWonOpportunities, newList);

    //Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>();
    Boolean foundOppContact = false;

    Map<ID, Set<String>> opptyID_ContactRoleSet_Map = new Map<ID, Set<String>>();

    // loop through the Oppty Contact roles for the given Opportunity
    for (Opportunity opp : newList) {
      if (oppMap.containsKey(opp.ID)) {
        Opportunity queryOpp = oppMap.get(opp.ID);
        if (queryOpp.Opportunity_Contact_Addresses__r.size() > 0 ) {
          for (Opportunity_Contact_Address__c ocr : queryOpp.Opportunity_Contact_Addresses__r) {
            if (!opptyID_ContactRoleSet_Map.containsKey(opp.ID)) {
              opptyID_ContactRoleSet_Map.put(opp.ID, new Set<String>());
            }
            opptyID_ContactRoleSet_Map.get(opp.ID).add(ocr.Role__c);
          }
        }
        // check if atleast one of each of Ship-To, Bill-To (previously called Purchase Ledger), Contractual, Renewal,
        // Update and Commercial Contact roles exists on Oppty or not
        if (opptyID_ContactRoleSet_Map.containsKey(opp.ID)) {
          Set<String> contactRoles = opptyID_ContactRoleSet_Map.get(opp.ID);
          if (contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_SHIPTO) &&
                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER) &&
                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_CONTRACTUAL) &&
                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_RENEWAL) &&
                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_UPDATE) &&
                contactRoles.contains(Constants.OPPTY_CONTACT_ROLE_COMMERCIAL)) {

            foundOppContact = true;
          }
        }

        if (!foundOppContact) {
          opp.addError(Label.OPPTY_ERR_CONTACT_ADDRESS_CHECK_FOR_EDQ + '. Roles gathered on this opportunity: '+ opptyID_ContactRoleSet_Map.get(opp.ID));
        }
      }

    }
  }

  public override void createOppLineItemsForRenewal ( List<Opportunity> newList ) {
    super.createOppLineItemsForRenewal ( newList );
  }

  public override void updateAccPlanOpptyRecs (Set<ID> opptyIDsToUpdateAccPlanOpptySet) {
    super.updateAccPlanOpptyRecs ( opptyIDsToUpdateAccPlanOpptySet) ;
  }


  public override void onDemandOpportunityLineItem(List<Opportunity> closedWonOpportunities, List<Opportunity> newList) {
    super.onDemandOpportunityLineItem (closedWonOpportunities, newList);
  }
  public override void opportunityReopeningProcess(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
    super.opportunityReopeningProcess(newMap, oldMap);
  }

  // I-138684 - Method to Validate if the products are all EDQ or all Non-EDQ. There cannot me a mix of both in the list.
  public override List<Opportunity> validateProductsData(List<Opportunity> closedWonOpportunities, List<Opportunity> newList){
    List<Opportunity> validOpps = new List<Opportunity> ();
    Set<String> oppWithNonEDQProd = new Set<String>();
    Set<String> oppWithEDQProd = new Set<String> ();
    mapClosedWonOppTo_Child = getOppTo_RelatedChild(closedWonOpportunities);
    for ( Opportunity opp : mapClosedWonOppTo_Child.values()) {
    	for ( OpportunityLineItem oli : opp.OpportunityLineItems) {
	      System.debug('--oli.PricebookEntry.Product2.Business_Line__c--->>>'+oli.PricebookEntry.Product2.Business_Line__c);
	      if ( oli.PricebookEntry.Product2.Business_Line__c == Constants.BUSINESSLINE_DATA_QUALITY ) {
	        oppWithEDQProd.add( oli.OpportunityId );
	      }
	      else if ( oli.PricebookEntry.Product2.Business_Line__c != Constants.BUSINESSLINE_DATA_QUALITY ) {
	        oppWithNonEDQProd.add(oli.OpportunityId);
	      }
	    }
    }
    /*for ( OpportunityLineItem oli : [SELECT Id, Global_Business_Line__c, OpportunityId,
                                            PricebookEntry.Product2.Business_Line__c
                                     FROM OpportunityLineItem
                                     WHERE OpportunityId IN :closedWonOpportunities]) {
      System.debug('--oli.PricebookEntry.Product2.Business_Line__c--->>>'+oli.PricebookEntry.Product2.Business_Line__c);
      if ( oli.PricebookEntry.Product2.Business_Line__c == Constants.BUSINESSLINE_DATA_QUALITY ) {
        oppWithEDQProd.add( oli.OpportunityId );
      }
      else if ( oli.PricebookEntry.Product2.Business_Line__c != Constants.BUSINESSLINE_DATA_QUALITY ) {
        oppWithNonEDQProd.add(oli.OpportunityId);
      }
    }*/
    for ( Opportunity opp : newList) {
      if ( oppWithEDQProd.contains(opp.Id) && oppWithNonEDQProd.contains(opp.Id) ) {
        opp.addError(Label.OPPTY_ERROR_EDQ_MIX_OF_PRODUCT_NOT_ALLOWED);
      }
      else if ( oppWithEDQProd.contains(opp.Id) && !oppWithNonEDQProd.contains(opp.Id) ) {
        validOpps.add (opp) ;
      }
    }
    return validOpps;
  }
  // T-368849 : method to get Opportunity and its related child object records
  private static Map<ID, Opportunity> getOppTo_RelatedChild(List<Opportunity> closedWonOpportunities) {
    if (mapClosedWonOppTo_Child == null) {
      mapClosedWonOppTo_Child = new Map<ID, Opportunity> (
                                  [SELECT Id,
                                    (SELECT Id, Contact__c, Role__c FROM Opportunity_Contact_Addresses__r),
                                      (SELECT Id, OpportunityLineItem.Product2.Business_Line__c,
                                              EDQ_On_Demand_Product__c,Global_Business_Line__c,
                                              OpportunityId,PricebookEntry.Product2.Business_Line__c
                                       FROM OpportunityLineItems),
                                        (SELECT Id, ContactId, Role, Contact.EDQ_On_Demand__c FROM OpportunityContactRoles)
                                   FROM Opportunity
                                   WHERE Id IN :closedWonOpportunities]);
    }
    return mapClosedWonOppTo_Child;
  }

  /*public override void beforeInsert (List<Opportunity> newList) {
    super.beforeInsert (newList);
  }

  public override void afterInsert (Map<ID, Opportunity> newMap) {
    super.afterInsert (newMap);
  }

  public override void beforeUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    super.beforeUpdate (newMap, oldMap);
  }

  public override void afterUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    super.afterUpdate (newMap, oldMap);
  }*/
  /*public override List<Opportunity> fetchClosedWonRecords(Map<Id,Opportunity> oldMap, List<Opportunity> newList) {
    return super.fetchClosedWonRecords(oldMap, newList);
  }*/

/*
  public override void populateStartingStage(List<Opportunity> opps, Map<Id, Opportunity> oldOpps) {
    super.populateStartingStage(opps, oldOpps);
  }
  public override void validateServiceDates(Map<ID, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
    super.validateServiceDates(newOpps, oldOpps);
  }
  public override void populateServiceDatesOnOLI(Map<ID, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
    super.populateServiceDatesOnOLI(newOpps, oldOpps);
  }
*/

/*
  public override void createOrderAndOrderLineItems (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    super.createOrderAndOrderLineItems (newMap, oldMap);
  }
 public override void populateOpptyVsLineMapAndOpptyLineList (List<Opportunity> oppList) {
  super.populateOpptyVsLineMapAndOpptyLineList (oppList);
 }
*/

/*
 public override void createRevenueSchedules (Map<ID, Order_Line_Item__c> oliId_ordLIMap){
  super.createRevenueSchedules (oliId_ordLIMap);
 }
 public override void deleteOrderAndOppIfOppIsReopened(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap){
  super.deleteOrderAndOppIfOppIsReopened( newMap, oldMap);
 }
 */

 /*
  public override Boolean getOpportunitiesExitCriteriaNotMet(Map<ID, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
    return super.getOpportunitiesExitCriteriaNotMet(newOpps, oldOpps);
  }
  public override Boolean isMeetingExitCriteria (Opportunity opp, String newStage, String oldStage) {
    return super.isMeetingExitCriteria (opp,newStage,oldStage);
  }
  public override Boolean hasRequiredTask(Opportunity opp, String taskType) {
    return super.hasRequiredTask (opp,taskType);
  }
*/
/*
 public override Boolean isOpptyFieldUpdated (Set<String> fieldSet, Opportunity newRec, Opportunity oldRec) {
  return super.isOpptyFieldUpdated (fieldSet , newRec, oldRec);
 }
*/
/*
  public override void checkAccessOnAccountForUser (List<Opportunity> newList){
    super.checkAccessOnAccountForUser (newList);
  }
  public override void multiCurrencyFieldUpdate(List<Opportunity> newList, Map<ID, Opportunity> oldMap) {
    super.multiCurrencyFieldUpdate(newList, oldMap);
  }

  public override void calculateStageDuration(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldMap) {
    super.calculateStageDuration(newOpps, oldMap);
  }

  public override void updateOppFieldsIfWonOrClosed(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldMap) {
    super.updateOppFieldsIfWonOrClosed(newOpps, oldMap);
  }
*/

/*
 public override void checkOpptyDates (List<Opportunity> newList){
  super.checkOpptyDates ( newList);
 }

 public override void createOppTeamMembers(Map<Id, Opportunity> opportunityMap){
  super.createOppTeamMembers(opportunityMap);
 }

 public override void synchCurrencyISOCodes (Map<Id,Opportunity> newMap, Map<ID, Opportunity> oldMap) {
  super.synchCurrencyISOCodes ( newMap, oldMap);
 }

 public override void moveOriginatingTaskToNewOppty (List<Opportunity> newList){
  super.moveOriginatingTaskToNewOppty ( newList);
 }
*/

}