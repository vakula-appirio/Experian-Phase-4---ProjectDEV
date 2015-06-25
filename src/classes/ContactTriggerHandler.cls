/**=====================================================================
 * Appirio, Inc
 * Name: ContactTriggerHandler
 * Description: Add Owner to Contact Team.
 * Created Date: Dec 12th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified       Modified By                  Description of the update
 * Jan 30th, 2014      Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014      Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Apr 08th, 2014      Arpita Bose (Appirio)        T-269372: Added addError()in try-catch block
 * May 01st, 2014      Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException Line#49
 * Aug 25th, 2014      Noopur (Appirio)             T-313856: Created Methods for befor Insert and Before Update also created two methods
 *                                                  checkContactHasContainerAccount - to check the contact,if it belongs to holding Account
 *                                                  checkContactCountForAccount - to check if holding account has crossed the number of contacts
 *                                                  as stated in the custom setting, if yes then create new account and change the accountId to the new one.
 * Sep 2nd, 2014       Nathalie Le Guay             Follow up on T-313856: Contacts need to be originally attached to the Account whose name is specified
 *                                                  on the Global_Setting__s, and this trigger will find the appropriate container to attach it to.
 * Sep 8th, 2014       Noopur (Appirio)             I-129046:  Added a check for ignoring the case in the Container Account name stored in the custom setting 
 *                                                  and the actual account name. Converting both to upper case before comparison.
 * Sep 8th, 2014       Naresh Kr Ojha               T-317847: added onDemandCOntact() to make other contact on account not to be on demand contact.
 * Sep 8th, 2014       Noopur(Appirio)              I-129046: modified the method checkContactCountForAccount to handle the situation where the contact is 
 *                                                  added to any of the accounts starting with the name stored in custom setting.
 * Sep 10th, 2014      Noopur(Appirio)              Broke the method "checkContactCountForAccount()" into sub methods. Created new methods named 
 *                                                  "getRunningAccount()" and "updateContactWithNewAccount()".
 * Oct 20, 2014        Nathalie Le Guay             I-135529: checks are made in the trigger because a WF Rule relies on the outcome. As of Winter 15 we cannot order
 *                                                  the WF Rules. Adding checkOnDemandSyncRequired()
 * Dec 12, 2014        Noopur                       T-339472 : added method orderOnDemandSync()
 * Jan 14, 2015        Sadar Yacob                  I-145611 : Fixed issue with Send to ON Demand Flag set to true for all Contacts 
 * Feb 06th, 2015      Naresh kr Ojha               T-330645: Updated code for best practice and better implementation, updated onDemandContact() method.
 * Feb 6th, 2015       Paul Kissick                 Case # 50069 : Fix for duplicate contact teams and addresses (checkMergeAndCleanup) post merge.
 * Feb 19th, 2015      Paul Kissick                 Case #29746 : Adding mergehistory creation when merges occur.
 * Apr 7th, 2015       Paul Kissick                 Case #50069 : Fixed merge failure by implementing a future method for the cleanup.
 * May 21st, 2015      Arpita Bose                  I-163339 : Updated method addOwnerToContactTeam() for Roles used in Gleam
 =====================================================================*/


public class ContactTriggerHandler {
    public static boolean hasOwnerAddedToTeam = false;
    
    //Before insert call
    public static void afterInsert (List<Contact> newList) {
      addOwnerToContactTeam(newList);
    }

    //before insert call
    public static void beforeInsert(List<Contact> newList){
     // checkContactHasContainerAccount(newList,null,true);
      checkOnDemandSyncRequired(newList, null);
    }
  
    //before update call
    public static void beforeUpdate(List<Contact> newList, Map<Id,Contact> oldMap){
      //checkContactHasContainerAccount(newList,oldMap,false);
      onDemandContact(newList, oldMap);
      checkOnDemandSyncRequired(newList, oldMap);
    }
    
     //after update call
    public static void afterUpdate (List<Contact> newList,Map<Id,Contact> oldMap) {
        refreshOppScoreCalculations();
        orderOnDemandSync(newList, oldMap );
    }
    
    // after delete call
    public static void afterDelete (Map<Id,Contact> oldMap) {
      createMergeHistory(oldMap);
      checkMergeAndCleanup(oldMap);
    }




    //Method to add Owner to Contact Team.
    public static void addOwnerToContactTeam(List<Contact> lstContact)
    {
        //If method has completed adding Contact to Team then skip, to avoid recursive update.
        if(hasOwnerAddedToTeam) return;
        
        List<Contact_Team__c> lstCTs = new List<Contact_Team__c>();
        // I-163339
        Set<String> userId = new Set<String>();
        Set<string> notPrimaryUserRole = new Set<String> {'EMEA_MS_France_Client_Services_Manager','France_Evolution','France_Level_1_Client_Services_Agent',
                                                          'France_Level_2_Client_Services_Agent','France_Onboarding','EMEA_MS_Germany_Client_Services_Manager',
                                                          'Germany_Evolution','Germany_Level_1_Client_Services_Agent','Germany_Level_2_Client_Services_Agent',
                                                          'Germany_Onboarding','EMEA_MS_Spain_Client_Services_Manager','Spain_Evolution',
                                                          'Spain_Level_1_Client_Services_Agents','Spain_Level_2_Client_Services_Agents','Spain_Onboarding'};
        
        Set<Id> currentRoleIds = new Set<Id>();
        
        for(UserRole userRole :[select Id from UserRole where DeveloperName IN :notPrimaryUserRole ]){
          currentRoleIds.add(userRole.Id);
        }
          
        for(User userRec : [SELECT Id, UserRoleId FROM User WHERE UserRoleId IN :currentRoleIds ]){
          userId.add(userRec.Id);
        }
                                                          
        for(Contact conRec:lstContact) {
            //If Owner is user then Add to Team
            if(((String)conRec.OwnerId).startsWith('005')) {
                // I-163339 : if user role is in the set of Roles notPrimaryUserRole, set Primary_User__c = false
                if(userId.contains(conRec.OwnerId)) {
                  lstCTs.add( new Contact_Team__c(Contact__c = conRec.id,
                    Relationship_Owner__c=conRec.CreatedById, Primary_User__c = false));
                }
                else {
                  lstCTs.add( new Contact_Team__c(Contact__c=conRec.id,
                    Relationship_Owner__c=conRec.CreatedById,Primary_User__c =true)); 
                }                   
            }
        }//END: for conRec.
        
        
        if(lstCTs.size() > 0) {
          try {
             insert lstCTs;
           } catch(DMLException ex) {
             ApexLogHandler.createLogAndSave('ContactTriggerHandler','addOwnerToContactTeam', ex.getStackTraceString(), ex);
             system.debug('##########ex##########'+ex);
             for (Integer i = 0; i < ex.getNumDml(); i++) {
               lstContact.get(0).addError(ex.getDmlMessage(i));
             }
           }   
        }//END: if
        
        //Update flag.
        hasOwnerAddedToTeam = true;   
    }//END: method addOwnerToContactTeam
    
    
   //blank update on all opp plan for score calculation
  public static void refreshOppScoreCalculations(){
    Set<Id> contactIds = new Set<Id>();
    for (Contact contact : (List<Contact>) Trigger.new) {
      if( contact.get('Title') != Trigger.oldMap.get(contact.id).get('Title') || 
         contact.get('Contact_Role__c') != Trigger.oldMap.get(contact.id).get('Contact_Role__c') ){
        contactIds.add(contact.Id);
      }
    }
    try {
      if(contactIds.size() > 0) {
        update [Select Id From Opportunity_Plan__c Where Id IN (Select Opportunity_Plan__c From Opportunity_Plan_Contact__c Where Contact__c = :contactIds or Reports_To__r.Contact__c = :contactIds )];
      }
    }
    catch(Exception ex) {
      
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','refreshOppScoreCalculations', ex.getStackTraceString(), ex);
    }
  }

  
  //===========================================================================
  // T-317847: Checks on account and created one contact per account as per task.
  //===========================================================================
  private static void onDemandContact (List<Contact> newList, Map<Id,Contact> oldMap) {
    Set<ID> accountIDs = new Set<ID>();
    Map<ID, Account> accountMap = new Map<ID, Account>();
    Map<ID, List<Contact>> accID_ContactListMap = new Map<ID, List<Contact>>();
    List<Contact> contactsNotToBeOnDemand = new List<Contact>();
    //As per T-330645

    for (Contact newContact : newList) {
      if (newContact.EDQ_On_Demand__c != oldMap.get(newContact.ID).EDQ_On_Demand__c 
             && newContact.EDQ_On_Demand__c == true && newContact.AccountId != null) {
        accountIDs.add(newContact.AccountId);
      }  
    }
    
    //If there is no update, return as per T-330645
    if (accountIDs.isEmpty()) {
      return;
    }
    
    for (Contact c : [SELECT Id, EDQ_On_Demand__c, AccountId 
                                    FROM Contact WHERE EDQ_On_Demand__c = true
                                    AND ID != : newList
                                    AND AccountID IN: accountIDs]) {
      if (!accID_ContactListMap.containsKey(c.AccountID)) {
        accID_ContactListMap.put(c.AccountID, new List<Contact>());
      }
      accID_ContactListMap.get(c.AccountID).add(c);
    }

    try {
      //Checking weather there is any on demand contact on account if any then current one
      //wont be no more on demand.
      for (Contact newContact : newList) {
        if (newContact.EDQ_On_Demand__c == true && 
              accID_ContactListMap.containsKey(newContact.AccountID) && 
                accID_ContactListMap.get(newContact.AccountID).size() > 0) {
           //Setting on demand to false
           for (Contact c : accID_ContactListMap.get(newContact.AccountID)) {
             if (c.EDQ_On_Demand__c == true) { //As per T-330645
               c.EDQ_On_Demand__c = false;

               contactsNotToBeOnDemand.add(c);
             }
           }
        }
      }

      //Updating other contacts for Not to be on demand anymore.
      if (contactsNotToBeOnDemand.size() > 0) {
        update contactsNotToBeOnDemand;
      }
    } catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','onDemandContact', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDMLMessage(i)); 
      }
    }
  }
  
  //===================================================================================
  // I-135529: Checks for any update of field needing to trigger a sync with On Demand
  //===================================================================================
  private static void checkOnDemandSyncRequired(List<Contact> contacts, Map<Id, Contact> oldMap) {
    for (Contact cont: contacts) {
      if (oldMap == null && cont.EDQ_On_Demand__c) {
        cont.EDQ_Send_to_On_Demand__c = true;
      }
      else if (oldMap != null && cont.EDQ_On_Demand__c &&
                                 (cont.FirstName != oldMap.get(cont.Id).FirstName ||
                                  cont.LastName != oldMap.get(cont.Id).LastName ||
                                  cont.Email != oldMap.get(cont.Id).Email ||
                                  cont.MobilePhone != oldMap.get(cont.Id).MobilePhone ||
                                  cont.Phone != oldMap.get(cont.Id).Phone ||
                                  cont.Title != oldMap.get(cont.Id).Title ||
                                  cont.Salutation != oldMap.get(cont.Id).Salutation ||
                                  cont.EDQ_On_Demand__c != oldMap.get(cont.Id).EDQ_On_Demand__c
                                  ) ) {
        cont.EDQ_Send_to_On_Demand__c = true;
      }
    }
  }
  
  //============================================================================
  //Method to populate the Order's EDQ_Send_to_On_Demand__c when contacts same field is changed.
  //============================================================================
  private static void orderOnDemandSync(List<Contact> contacts, Map<Id, Contact> oldMap) {
    try{
      Set<String> contactIds = new Set<String>();
      List<Order__c> orderToBeUpdated = new List<Order__c> ();
      for (Contact cont: contacts) {
        if (cont.EDQ_Send_to_On_Demand__c == false && oldMap.get(cont.Id).EDQ_Send_to_On_Demand__c != false) {
          contactIds.add(cont.Id);
        }
      }
      for (Order__c ordObj : [SELECT Id, EDQ_Send_to_On_Demand__c, Contact__c
                              FROM Order__c
                              WHERE Contact__c IN :contactIds AND Number_of_On_Demand_Order_Line_Items__c > 0]) {
        ordObj.EDQ_Send_to_On_Demand__c = true;
        orderToBeUpdated.add(ordObj);
      }
      if (!orderToBeUpdated.isEmpty()) {
        update orderToBeUpdated;
      }
    }
    catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','orderOnDemandSync', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        contacts.get(0).addError(ex.getDMLMessage(i)); 
      }
    }
  }

  //===========================================================================
  // Case #29746: Merge History
  //===========================================================================
  private static void createMergeHistory(Map<Id, Contact> oldMap) {
    Map<Id,Id> loserToWinnerIds = new Map<Id,Id>();
    Set<Id> winningIds = new Set<Id>();
    for(Contact deletedContact : oldMap.values()) {
      if (deletedContact.MasterRecordId != null) {
        // master is winning record.
        loserToWinnerIds.put(deletedContact.Id,deletedContact.MasterRecordId);
        // Set to hold which accounts won in the merge (normally only 1 record here, as merges don't get bulked.)
        winningIds.add(deletedContact.MasterRecordId);
      }
    }
    if (loserToWinnerIds.size() > 0) {
      // From these we need to get the CSDA_Integration_Id__c and EDQ_Integration_Id__c from both winner and loser (loser will be in the trigger, winner won't)
      List<MergeHistory__c> newHistory = new List<MergeHistory__c>();
      try {
        Map<Id,Contact> winners = new Map<Id,Contact>([
          SELECT EDQ_Integration_Id__c, 
            // CSDA_Integration_Id__c, //PK: Not on Contact object yet. 
            Global_Unique_ID__c,
            Experian_ID__c,
            Saas__c
          FROM Contact 
          WHERE Id IN :winningIds
        ]);
        for(Id loserId : loserToWinnerIds.keySet()) {
          Contact loserAcc = oldMap.get(loserId);
          Contact winnerAcc = winners.get(loserToWinnerIds.get(loserId));
          // Calls new utility class to build the MergeHistory
          MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(loserAcc,winnerAcc);
          newHistory.add(mh);
        }
        insert newHistory;
        
      } catch(DMLException e){
        System.debug('\n[ContactTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('ContactTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
      }
    }
  }

  // Case #50069
  private static void checkMergeAndCleanup(Map<Id, Contact> oldMap) {
    Set<Id> winningContacts = new Set<Id>();
    for(Contact oldCont : oldMap.values()) {
      if (oldCont.MasterRecordId != null) {
        // we have a merged record, so we must now tidy up the related list records (Contact_Team__c and Contact_Address__c of the winning record...)
        winningContacts.add(oldCont.MasterRecordId);
      }
    }
    if (!winningContacts.isEmpty()) {
        // Due to a SELF_REFERENCE_FROM_TRIGGER DML exception, the update of the winning records must be in a future method.
        ContactTriggerHandler.fixContactRelatedPostMerge(winningContacts);
      }
    }

    // Fix for rollup fields preventing the merge.
    // 2015-04-07 Added as future method. 
    @future
    public static void fixContactRelatedPostMerge (Set<Id> winningContacts) {
      List<Contact> fixContacts = [
        SELECT Id, 
        (SELECT Id, Relationship_Owner__c, Contact_Team_Role__c, Contact__c, Communication_Notes__c, Primary_User__c FROM Contact_Teams__r WHERE Relationship_Owner__c != null ORDER BY LastModifiedDate DESC),
        (SELECT Id, Contact__c, Address__c, Address_Type__c FROM Contact_Addresses__r ORDER BY LastModifiedDate DESC)
        FROM Contact
        WHERE Id IN :winningContacts
      ];
      List<Contact_Team__c> toDeleteTeam = new List<Contact_Team__c>();
      List<Contact_Address__c> toDeleteAddress = new List<Contact_Address__c>();
      for(Contact c : fixContacts) {
        // run through each member and verify uniqueness...
        List<Contact_Team__c> contactTeamMembers = c.Contact_Teams__r;
        List<Contact_Address__c> contactAddresses = c.Contact_Addresses__r;
        Set<Id> extraUserIds = new Set<Id>();
        Id primaryRelationshipId;
        if (contactTeamMembers != null) {
          // Remove the extra relationships, keeping only unique ones. This doesn't check for other data in the  Communication_Notes__c field, or Contact_Team_Role__c field.
          for(Contact_Team__c ctm : contactTeamMembers) {
            // system.debug('Contact : ' + ctm.Contact__c + ' & Team Member : ' + ctm.Relationship_Owner__c);
            // Check to see if the primary user is true, and the relationship hasn't been set already
            if (ctm.Primary_User__c == true && primaryRelationshipId == null) {
              primaryRelationshipId = ctm.Id;
            }
            // Add to the extra users set (unique) if not already there, and if not, prepare to add for deletion.
            if (!extraUserIds.contains(ctm.Relationship_Owner__c)) {
              extraUserIds.add(ctm.Relationship_Owner__c);
            }
            else {
              // does contain the user, so add for deletion, unless it's the primary relationship!
              if (ctm.Id != primaryRelationshipId) toDeleteTeam.add(ctm);
            }
          }
        }
        if (contactAddresses != null) {
          Set<Id> extraAddressIds = new Set<Id>();
          Id regAddressId;
          for(Contact_Address__c cadd : contactAddresses) {
            // Keep the first registered address we find
            if (cadd.Address_Type__c == 'Registered' && regAddressId == null) {
              regAddressId = cadd.Id;
            }
            // Of the others, if not already unique...
            if (!extraAddressIds.contains(cadd.Address__c)) {
              extraAddressIds.add(cadd.Address__c);
            }
            else {
              // delete them of not the registered address found above.
              if (cadd.Id != regAddressId) toDeleteAddress.add(cadd);
            }
          }
        }
      }

      if (!toDeleteTeam.isEmpty()) delete toDeleteTeam;
      if (!toDeleteAddress.isEmpty()) delete toDeleteAddress;
  }

}//END: Class