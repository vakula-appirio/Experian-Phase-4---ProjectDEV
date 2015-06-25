/**======================================================================================================
 * Appirio, Inc
 * Name             : OpportunityContactAddressHelper
 * Description      : T-325888: EDQ Opportunity Contact Addresses Javascript button
 * Created Date     : Oct 14th, 2014
 * Created By       : Pallavi Sharma(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Nov 5th, 2014                 Arpita Bose(Appirio)         I-137466: Updated method populateAddresses()
 * Nov 11th, 2014                Nathalie Le Guay             I-137466: update to inform user on which contact missing Registered Address
 * Feb 23rd, 2015                Paul Kissick                 Case #551906 - Fix for removing contact from opportunity
 =======================================================================================================*/ 
 global class OpportunityContactAddressHelper {
  
  //======================================================================================================
  // Webservice to create Opportunity Contact Address with related 
  // Contact Address and Opportunity Contact Role
  //======================================================================================================
  webservice static String populateAddresses(Id oppId) {
    Map<Id, Boolean> oppContactMapToRegistered = new Map<Id, Boolean>();
    List<OpportunityContactRole> lstOpportunityContactRole = new List<OpportunityContactRole>();
    List<Contact_Address__c> lstContactAddr = new List<Contact_Address__c>();
    Map<String,Opportunity_Contact_Address__c> mapExistingOppContactAddr = new Map<String,Opportunity_Contact_Address__c>();
    List<Opportunity_Contact_Address__c> lstOppContactAddr = new List<Opportunity_Contact_Address__c>();
    List<Opportunity_Contact_Address__c> lstOppContactAddrToDelete = new List<Opportunity_Contact_Address__c>(); // PK Case #551906 - Adding to hold addresses to delete
    Opportunity_Contact_Address__c oppConAddress;
    Map<String, String> contactIdToName = new Map<String, String>(); // PK Case #551906 - Moving this up here
    Set<String> ocaIds = new Set<String>();
     
    //Fecth Opportunity Contact Role for current opportunity
    for (OpportunityContactRole oppConRole : [ SELECT Role, ContactId, Contact.Name 
                                               FROM OpportunityContactRole 
                                               WHERE OpportunityId = :oppId]) {
      oppContactMapToRegistered.put(oppConRole.ContactId, false);
      contactIdToName.put(oppConRole.ContactId,oppConRole.Contact.Name);
      lstOpportunityContactRole.add(oppConRole);    
    }
    if (oppContactMapToRegistered.keySet().isEmpty()) {
      //If no Contact Role found then show error
      return system.label.OPPTY_CONT_ADD_NO_OPPORTUNITY_CONTACT_ROLE;
    }
    
    //I-137466
    //Fetch Registered Addresses for related Contact
    // Noopur - added for issue I-137466
    Boolean showErrorForRegisteredAddress = false;
    String contactsWithErrors = '';
    

    for (Contact_Address__c contactAddr : [ SELECT Contact__c, Address__c, Address_Type__c
                                            FROM Contact_Address__c 
                                            WHERE Contact__c IN :oppContactMapToRegistered.keySet() 
                                            ORDER BY Contact__c] ) { 

      if (contactAddr.Address_Type__c == Constants.ADDRESS_TYPE_REGISTERED) {
        lstContactAddr.add(contactAddr);
        oppContactMapToRegistered.put(contactAddr.Contact__c, true);
      }
    }

    for (String contactId: oppContactMapToRegistered.keySet()) {
      if (oppContactMapToRegistered.get(contactId) == false) {
        contactsWithErrors += '\n'+ contactIdToName.get(contactId);
        showErrorForRegisteredAddress = true;
      }
    }

    if (showErrorForRegisteredAddress) {
      String errorMessage = system.label.OPPTY_CONT_ADD_NO_REGISTERED_CONTACT_ADDRESS + ' ' + contactsWithErrors;
      return errorMessage;
    }

    //Get Existing Opportunity Contact Address
    for (Opportunity_Contact_Address__c oppContactAddr : [SELECT Id, Contact__c , Address__c, Role__c
                                                          FROM Opportunity_Contact_Address__c
                                                          WHERE Opportunity__c = : oppId 
                                                          //AND Contact__c IN :oppContactMapToRegistered.keySet() // PK Case #551906 - Removing to query all addresses on opp
                                                          ]) {
      if (oppContactMapToRegistered.containsKey(oppContactAddr.Contact__c)) {
      	// address is there for existing contact
      	mapExistingOppContactAddr.put(oppContactAddr.Contact__c + '' + oppContactAddr.Role__c, oppContactAddr);
      }
      else {
      	// contact has an address, but not on the opp anymore...
      	lstOppContactAddrToDelete.add(oppContactAddr);
      }
    }


    //Fetch Registered Addresses for related Contact
    for (Contact_Address__c contactAddr : lstContactAddr ) { 
    // If Registered Address found on Contact_Address__c
    //Loop for each Role
      for (OpportunityContactRole oppConRole : lstOpportunityContactRole) {
        if (oppConRole.ContactId != contactAddr.Contact__c) {
          continue;
        }
        //Check If address exists 
        if (mapExistingOppContactAddr.containsKey(contactAddr.Contact__c + '' + oppConRole.Role)) {
          oppConAddress = mapExistingOppContactAddr.get(contactAddr.Contact__c + '' + oppConRole.Role);
          //Verify address changes
          //If address is chagned than update existing Opportunity Contact Address
          if (oppConAddress.Address__c != contactAddr.Address__c && !ocaIds.contains(oppConAddress.Id)) {
            oppConAddress.Address__c = contactAddr.Address__c;
            lstOppContactAddr.add(oppConAddress);
            ocaIds.add(oppConAddress.Id);
          }
          //I-137466
          //if all Address exists on Opportunity Contact Address, then show confirmation message
          //return system.label.OPPTY_CONT_ADD_ALREADY_EXISTS;
        }
        else {
          //Create New Opportunity Contact Address
          lstOppContactAddr.add(new Opportunity_Contact_Address__c(Address__c = contactAddr.Address__c,
                                                                   Contact__c = contactAddr.Contact__c,
                                                                   Opportunity__c = oppId,
                                                                   Role__c = oppConRole.Role)); 
        } 
      }                                 
    }
    // PK Case #551906 - Finally, remove those addresses no longer required.
    if (!lstOppContactAddrToDelete.isEmpty()) {
    	try {
    		delete lstOppContactAddrToDelete;
    	}
    	catch (Exception ex) {
    		apexLogHandler.createLogAndSave('OpportunityContactAddressHelper', 
                                        'populateAddresses', 
                                        'Error in Deleting Opportunity Contact Address. List is : ' + lstOppContactAddrToDelete, 
                                        ex);
    	}
    }
    if (!lstOppContactAddr.isEmpty()) {
        try {
            //Update existing and create new Addresses
            upsert lstOppContactAddr;
        } catch(Exception ex) {
            //save Log for Error 
            apexLogHandler.createLogAndSave('OpportunityContactAddressHelper', 
                                            'populateAddresses', 
                                            'Error in inserting Opportunity Contact Address. List is : ' + lstOppContactAddr, 
                                            ex);
          //Show error
          return system.label.OPPTY_CONT_ADD_ERROR_IN_INSERTION;
        }
    } /*else {
        //If no Registered Address found than show error
        return system.label.OPPTY_CONT_ADD_NO_REGISTERED_CONTACT_ADDRESS;
    }*/
     //Return success message if Address saved successfully
     return system.label.OPPTY_CONT_ADD_SAVED_SUCCESSFULLY;
     
  }
}